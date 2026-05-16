import "./style.css";
import {
	World,
	computeGlobalTransformUploadRange,
	createCameraWordsBuffer,
	createGlobalTransformWordsBuffer,
	detectDenseGlobalTransformLayout,
	drainAndUploadCameraWrites,
	uploadGlobalTransformWrites,
	writeGlobalTransformBlobRangeByRefs,
	type EntityId,
	type GlobalTransformBlobWriter,
	type GlobalTransformDenseLayout,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	createRgba8ReadbackTarget,
	destroyReadbackTarget,
	readRgba8Texture,
} from "./visual-regression/webgpu-readback";
import {
	Engine,
	Phase,
	PhaseSlot,
	Scene,
	installBrowserInput,
	type BrowserInputBinding,
	type FrameState,
} from "./app-runtime";
import {
	MASS_CUBES_CANVAS_HEIGHT,
	MASS_CUBES_CANVAS_WIDTH,
	MASS_CUBES_CUBE_SCALE,
	MASS_CUBES_ENTITY_COUNT,
	MASS_CUBES_GRID_SPACING,
	MASS_CUBES_INSTANCE_STRIDE,
	createMassCubesOrbitCameraController,
	createMassCubesRenderResourcesFromCameraStorage,
	gridSideLen,
	instanceColorRgb,
	massCubesCameraMatrices,
	releaseMassCubesRenderResources,
	renderMassCubesScene,
	updateOrbitCameraControllerFromInput,
	writeF32,
	type MassCubesRenderResources,
	type OrbitCameraController,
} from "./ecs-mass-cubes-renderer";

type GlobalTransformPrecisionMode =
	| "all-f32"
	| "all-f16"
	| "first-half-f32-second-half-f16"
	| "even-id-f32-odd-id-f16";
const GLOBAL_TRANSFORM_PRECISION_MODE: GlobalTransformPrecisionMode = "all-f16";

type DemoState = {
	readonly canvas: HTMLCanvasElement;
	readonly context: GPUCanvasContext;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly render: MassCubesRenderResources;
	readonly transformStorage: GPUBuffer;
	readonly scene: Scene<World, EntityId>;
	readonly orbitController: OrbitCameraController;
	readonly transformRefs: Uint32Array;
	readonly transformWordUploadFirst: number;
	readonly transformWordUploadCount: number;
	readonly denseTransformLayout: GlobalTransformDenseLayout | null;
	readonly perSide: number;
	snapshotColorView?: GPUTextureView;
	snapshotDepthView?: GPUTextureView;
	frame: number;
	lastFrameStartMs: number;
	cpuFrameStartMs: number;
	browserInputBinding?: BrowserInputBinding;
};

function globalTransformDefaultIsF16(): boolean {
	return GLOBAL_TRANSFORM_PRECISION_MODE !== "all-f32";
}

function entityUsesF32(entityIndex: number, localIndex: number): boolean {
	switch (GLOBAL_TRANSFORM_PRECISION_MODE) {
		case "all-f32":
			return true;
		case "all-f16":
			return false;
		case "first-half-f32-second-half-f16":
			return localIndex < Math.floor(MASS_CUBES_ENTITY_COUNT / 2);
		case "even-id-f32-odd-id-f16":
			return (entityIndex & 1) === 0;
	}
}

function applyGlobalTransformPrecisionMode(
	world: World,
	entities: ReturnType<World["spawnTransformGlobalBatchIdentity"]>,
): void {
	if (
		GLOBAL_TRANSFORM_PRECISION_MODE === "all-f32" ||
		GLOBAL_TRANSFORM_PRECISION_MODE === "all-f16"
	) {
		return;
	}
	entities.forEach((entity, localIndex) => {
		if (entityUsesF32(entity.index(), localIndex)) {
			world.setGlobalTransformFormat(entity, 0);
		}
	});
}

function instanceBytes(entities: ReturnType<World["spawnTransformGlobalBatchIdentity"]>, refs: Uint8Array): Uint8Array {
	const bytes = new Uint8Array(entities.length * MASS_CUBES_INSTANCE_STRIDE);
	entities.forEach((entity, i) => {
		const index = entity.index();
		const [r, g, b] = instanceColorRgb(index);
		const base = i * MASS_CUBES_INSTANCE_STRIDE;
		bytes.set(refs.subarray(i * 8, i * 8 + 8), base);
		writeF32(bytes, base + 8, r);
		writeF32(bytes, base + 12, g);
		writeF32(bytes, base + 16, b);
	});
	return bytes;
}

function writeMassCubesTransformBlob(
	writer: GlobalTransformBlobWriter,
	perSide: number,
	t: number,
	fullRows: boolean,
): void {
	const waveTime = t * 1.8;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	if (!fullRows) {
		const setY = writer.elementSetter(1, 3);
		let i = 0;
		let waveSin = Math.sin(waveTime);
		let waveCos = Math.cos(waveTime);
		while (i < MASS_CUBES_ENTITY_COUNT) {
			setY(i, waveSin * 0.12);
			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			i += 1;
		}
		return;
	}
	const half = (perSide - 1) * 0.5;
	let localIndex = 0;
	let row = 0;
	let column = 0;
	const setAffine3x4At = writer.setAffine3x4At;
	while (localIndex < MASS_CUBES_ENTITY_COUNT) {
		const rowCount = Math.min(perSide - column, MASS_CUBES_ENTITY_COUNT - localIndex);
		let x = (column - half) * MASS_CUBES_GRID_SPACING;
		const z = (row - half) * MASS_CUBES_GRID_SPACING;
		let waveSin = Math.sin(localIndex * 0.09 + waveTime);
		let waveCos = Math.cos(localIndex * 0.09 + waveTime);
		for (let ix = 0; ix < rowCount; ix += 1) {
			const y = waveSin * 0.12;
			setAffine3x4At(
				localIndex,
				MASS_CUBES_CUBE_SCALE,
				0,
				0,
				x,
				0,
				MASS_CUBES_CUBE_SCALE,
				0,
				y,
				0,
				0,
				MASS_CUBES_CUBE_SCALE,
				z,
			);
			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			localIndex += 1;
			x += MASS_CUBES_GRID_SPACING;
		}
		row += 1;
		column = 0;
	}
}

function pushCameraMatrices(
	world: World,
	camera: EntityId,
	orbitController: OrbitCameraController,
): void {
	const matrices = massCubesCameraMatrices(orbitController);
	if (
		!world.setCameraMatrices(
			camera,
			matrices.view,
			matrices.proj,
			matrices.near,
			matrices.far,
			matrices.aspect,
			matrices.projectionKind,
			matrices.flags,
		)
	) {
		throw new Error("Failed to update Camera matrices.");
	}
}

function uploadInitialGlobalTransforms(demoState: DemoState): void {
	const world = demoState.scene.world();
	uploadGlobalTransformWrites(
		demoState.queue,
		demoState.transformStorage,
		writeGlobalTransformBlobRangeByRefs(world, {
			refs: demoState.transformRefs,
			count: MASS_CUBES_ENTITY_COUNT,
			range: {
				firstWord: demoState.transformWordUploadFirst,
				wordCount: demoState.transformWordUploadCount,
			},
			denseLayout: demoState.denseTransformLayout,
			write: (writer) =>
				writeMassCubesTransformBlob(writer, demoState.perSide, 0, true),
		}),
	);
}

function updateAndDrainGlobalTransforms(demoState: DemoState, t: number): void {
	const world = demoState.scene.world();
	uploadGlobalTransformWrites(
		demoState.queue,
		demoState.transformStorage,
		writeGlobalTransformBlobRangeByRefs(world, {
			refs: demoState.transformRefs,
			count: MASS_CUBES_ENTITY_COUNT,
			range: {
				firstWord: demoState.transformWordUploadFirst,
				wordCount: demoState.transformWordUploadCount,
			},
			denseLayout: demoState.denseTransformLayout,
			write: (writer) =>
				writeMassCubesTransformBlob(writer, demoState.perSide, t, false),
		}),
	);
}

function sceneMainCameraOrThrow(scene: Scene<World, EntityId>): EntityId {
	const camera = scene.mainCamera();
	if (camera === null) {
		throw new Error("syncMassCubesCameraBlob requires Scene.mainCamera.");
	}
	return camera;
}

function syncMassCubesCameraBlob(demoState: DemoState): void {
	pushCameraMatrices(
		demoState.scene.world(),
		sceneMainCameraOrThrow(demoState.scene),
		demoState.orbitController,
	);
}

function createDemoStateForEngine(
	engine: Engine,
	renderFormat?: GPUTextureFormat,
): DemoState {
	const { canvas, context, device, queue, format } = engine;
	const scene = engine.mainScene<World, EntityId>();
	const targetFormat = renderFormat ?? format;

	const world = globalTransformDefaultIsF16()
		? World.newWithGlobalTransformF16()
		: World.new();
	scene.setWorld(world);
	const perSide = gridSideLen(MASS_CUBES_ENTITY_COUNT);
	const entities = world.spawnTransformGlobalBatchIdentity(MASS_CUBES_ENTITY_COUNT);
	applyGlobalTransformPrecisionMode(world, entities);
	const transformRefsBytes = world.extractGlobalTransformRefs(entities);
	const transformRefs = new Uint32Array(
		transformRefsBytes.buffer,
		transformRefsBytes.byteOffset,
		transformRefsBytes.byteLength >>> 2,
	);
	const denseTransformLayout = detectDenseGlobalTransformLayout(
		transformRefs,
		MASS_CUBES_ENTITY_COUNT,
	);
	const transformUploadRange = computeGlobalTransformUploadRange(
		transformRefs,
		MASS_CUBES_ENTITY_COUNT,
		denseTransformLayout,
	);
	const transformStorage = createGlobalTransformWordsBuffer(device, world);
	const orbitController = createMassCubesOrbitCameraController();
	const camera = world.createEntity();
	pushCameraMatrices(world, camera, orbitController);
	scene.setMainCamera(camera);
	const cameraStorage = createCameraWordsBuffer(device, world);
	const instanceData = instanceBytes(entities, transformRefsBytes);
	const render = createMassCubesRenderResourcesFromCameraStorage({
		device,
		queue,
		targetFormat,
		transformStorage,
		cameraStorage,
		instanceData,
	});

	const demoState: DemoState = {
		canvas,
		context,
		device,
		queue,
		render,
		transformStorage,
		scene,
		orbitController,
		transformRefs,
		transformWordUploadFirst: transformUploadRange.firstWord,
		transformWordUploadCount: transformUploadRange.wordCount,
		denseTransformLayout,
		perSide,
		snapshotColorView: undefined,
		snapshotDepthView: undefined,
		frame: 0,
		lastFrameStartMs: -1,
		cpuFrameStartMs: -1,
	};
	uploadInitialGlobalTransforms(demoState);
	drainAndUploadCameraWrites(queue, render.cameraBuffer, world);
	return demoState;
}

function registerEngineHandlers(engine: Engine, demoState: DemoState): void {
	engine.onPhase(Phase.Input, (engine) => {
		updateOrbitCameraControllerFromInput(demoState.orbitController, engine.input);
	});
	engine.onPhase(Phase.Update, (_engine, frame) => {
		beginPerfFrame(demoState);
		updateScene(demoState, frame);
	});
	engine.onPhase(Phase.RenderExtract, () => {
		syncMassCubesCameraBlob(demoState);
	});
	engine.onPhase(
		Phase.Render,
		() => {
			if (demoState.scene.visible()) {
				renderCurrentFrame(demoState);
			}
		},
		PhaseSlot.AfterSchedule,
	);
	engine.onPhase(Phase.Shutdown, () => releaseDemoState(demoState));
}

function updatePerfOverlay(fps: number, cpuMs: number): void {
	const el = document.getElementById("ecs-mass-cubes-perf");
	if (el === null) {
		return;
	}
	el.textContent = `FPS ${fps.toFixed(1)}  ·  CPU ${cpuMs.toFixed(2)} ms / frame (submit まで)`;
}

function beginPerfFrame(demoState: DemoState): void {
	demoState.cpuFrameStartMs = performance.now();
}

function updateScene(demoState: DemoState, frame: FrameState): void {
	demoState.frame = frame.frameIndex;
	updateAndDrainGlobalTransforms(demoState, demoState.frame * 0.018);
}

function renderCurrentFrame(demoState: DemoState): void {
	const renderStart = performance.now();
	const frameStart =
		demoState.cpuFrameStartMs >= 0 ? demoState.cpuFrameStartMs : renderStart;
	const fps =
		demoState.lastFrameStartMs >= 0
			? 1000 / Math.max(frameStart - demoState.lastFrameStartMs, 1.0e-9)
			: 0;
	demoState.lastFrameStartMs = frameStart;

	const colorView =
		demoState.snapshotColorView ?? demoState.context.getCurrentTexture().createView();
	renderScene(demoState, demoState.scene, colorView);
	updatePerfOverlay(fps, performance.now() - frameStart);
	demoState.cpuFrameStartMs = -1;
}

function renderScene(
	demoState: DemoState,
	scene: Scene<World, EntityId>,
	colorView: GPUTextureView,
): void {
	const world = scene.world();
	drainAndUploadCameraWrites(
		demoState.queue,
		demoState.render.cameraBuffer,
		world,
	);
	renderMassCubesScene({
		device: demoState.device,
		queue: demoState.queue,
		render: demoState.render,
		colorView,
		depthView: demoState.snapshotDepthView,
	});
}

function releaseDemoState(demoState: DemoState): void {
	releaseMassCubesRenderResources(demoState.render);
	demoState.transformStorage.destroy();
	demoState.browserInputBinding?.dispose();
}

export async function renderTsEcsMassCubesBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = MASS_CUBES_CANVAS_WIDTH;
	canvas.height = MASS_CUBES_CANVAS_HEIGHT;
	const engine = await Engine.create(canvas, {
		mainScene: new Scene<World, EntityId>("ts-ecs-mass-cubes"),
	});
	const demoState = createDemoStateForEngine(engine, "rgba8unorm");
	registerEngineHandlers(engine, demoState);
	engine.initialize();
	const target = createRgba8ReadbackTarget(demoState.device, MASS_CUBES_CANVAS_WIDTH, MASS_CUBES_CANVAS_HEIGHT);
	try {
		demoState.snapshotColorView = target.view;
		demoState.snapshotDepthView = target.depthView;
		engine.runRenderFrame();
		demoState.snapshotColorView = undefined;
		demoState.snapshotDepthView = undefined;
		return await readRgba8Texture(
			demoState.device,
			demoState.queue,
			target.texture,
			MASS_CUBES_CANVAS_WIDTH,
			MASS_CUBES_CANVAS_HEIGHT,
		);
	} finally {
		demoState.snapshotColorView = undefined;
		demoState.snapshotDepthView = undefined;
		engine.shutdown();
		destroyReadbackTarget(target);
	}
}

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", () => {
		const canvas = document.getElementById("webgpu-canvas");
		if (!(canvas instanceof HTMLCanvasElement)) {
			document.body.innerHTML = "<h1>Missing WebGPU canvas.</h1>";
			return;
		}
		void Engine.create(canvas, {
			mainScene: new Scene<World, EntityId>("ts-ecs-mass-cubes"),
		})
			.then((engine) => {
				const demoState = createDemoStateForEngine(engine);
				demoState.browserInputBinding = installBrowserInput(engine);
				registerEngineHandlers(engine, demoState);
				engine.initialize();
				const loop = () => {
					engine.runRenderFrame();
					requestAnimationFrame(loop);
				};
				requestAnimationFrame(loop);
			})
			.catch((error: unknown) => {
				console.error("Failed to initialize WebGPU:", error);
				document.body.innerHTML =
					"<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
			});
	});
}
