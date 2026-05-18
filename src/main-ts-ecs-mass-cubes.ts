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
	type ComponentTypeId,
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
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	runPlatform,
	runBrowserWebGpuCanvasDemo,
	type FrameState,
} from "./app-runtime";
import {
	MASS_CUBES_CANVAS_HEIGHT,
	MASS_CUBES_CANVAS_WIDTH,
	MASS_CUBES_CAMERA_ELEVATION_RAD,
	MASS_CUBES_CUBE_SCALE,
	MASS_CUBES_ENTITY_COUNT,
	MASS_CUBES_GRID_SPACING,
	MASS_CUBES_INSTANCE_STRIDE,
	createMassCubesRenderResourcesFromCameraStorage,
	gridSideLen,
	instanceColorRgb,
	massCubesCameraMatrices,
	releaseMassCubesRenderResources,
	renderMassCubesScene,
	writeF32,
	type MassCubesRenderResources,
} from "./ecs-mass-cubes-renderer";
import { writeMassCubesDenseYTransformWaveToByteView } from "./ecs-mass-cubes-transform-writer";
import {
	addCameraLensOrthographic,
	addOrbitCameraControllerWithDistance,
	readOrbitCameraControllerComponent,
	registerCameraHomeTransformComponent,
	registerCameraLensComponent,
	registerOrbitCameraControllerComponent,
	setCameraHomeFromCurrentTransform,
	syncOrbitCameraTransformComponent,
	updateOrbitCameraControllerComponentFromInput,
	type OrbitCameraController,
} from "./orbit-camera-controller";

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
	readonly orbitControllerComponent: ComponentTypeId;
	readonly cameraHomeComponent: ComponentTypeId;
	readonly cameraLensComponent: ComponentTypeId;
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
	const cameraGlobal = mat4Inverse(matrices.view);
	if (cameraGlobal === null) {
		throw new Error("Failed to invert Camera view matrix.");
	}
	if (!world.setGlobalTransform(camera, cameraGlobal)) {
		throw new Error("Failed to update Camera GlobalTransform.");
	}
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

function mat4Inverse(m: Float32Array): Float32Array | null {
	const a00 = m[0] ?? 0;
	const a01 = m[1] ?? 0;
	const a02 = m[2] ?? 0;
	const a03 = m[3] ?? 0;
	const a10 = m[4] ?? 0;
	const a11 = m[5] ?? 0;
	const a12 = m[6] ?? 0;
	const a13 = m[7] ?? 0;
	const a20 = m[8] ?? 0;
	const a21 = m[9] ?? 0;
	const a22 = m[10] ?? 0;
	const a23 = m[11] ?? 0;
	const a30 = m[12] ?? 0;
	const a31 = m[13] ?? 0;
	const a32 = m[14] ?? 0;
	const a33 = m[15] ?? 0;
	const b00 = a00 * a11 - a01 * a10;
	const b01 = a00 * a12 - a02 * a10;
	const b02 = a00 * a13 - a03 * a10;
	const b03 = a01 * a12 - a02 * a11;
	const b04 = a01 * a13 - a03 * a11;
	const b05 = a02 * a13 - a03 * a12;
	const b06 = a20 * a31 - a21 * a30;
	const b07 = a20 * a32 - a22 * a30;
	const b08 = a20 * a33 - a23 * a30;
	const b09 = a21 * a32 - a22 * a31;
	const b10 = a21 * a33 - a23 * a31;
	const b11 = a22 * a33 - a23 * a32;
	let det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
	if (Math.abs(det) <= Number.EPSILON) {
		return null;
	}
	det = 1 / det;
	return new Float32Array([
		(a11 * b11 - a12 * b10 + a13 * b09) * det,
		(a02 * b10 - a01 * b11 - a03 * b09) * det,
		(a31 * b05 - a32 * b04 + a33 * b03) * det,
		(a22 * b04 - a21 * b05 - a23 * b03) * det,
		(a12 * b08 - a10 * b11 - a13 * b07) * det,
		(a00 * b11 - a02 * b08 + a03 * b07) * det,
		(a32 * b02 - a30 * b05 - a33 * b01) * det,
		(a20 * b05 - a22 * b02 + a23 * b01) * det,
		(a10 * b10 - a11 * b08 + a13 * b06) * det,
		(a01 * b08 - a00 * b10 - a03 * b06) * det,
		(a30 * b04 - a31 * b02 + a33 * b00) * det,
		(a21 * b02 - a20 * b04 - a23 * b00) * det,
		(a11 * b07 - a10 * b09 - a12 * b06) * det,
		(a00 * b09 - a01 * b07 + a02 * b06) * det,
		(a31 * b01 - a30 * b03 - a32 * b00) * det,
		(a20 * b03 - a21 * b01 + a22 * b00) * det,
	]);
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
	if (demoState.denseTransformLayout !== null) {
		const denseLayout = demoState.denseTransformLayout;
		uploadGlobalTransformWrites(
			demoState.queue,
			demoState.transformStorage,
			world.writeGlobalTransformBlobRangeViews(
				demoState.transformWordUploadFirst,
				demoState.transformWordUploadCount,
				(bytes) =>
					writeMassCubesDenseYTransformWaveToByteView(
						bytes,
						MASS_CUBES_ENTITY_COUNT,
						demoState.transformWordUploadFirst,
						denseLayout.wordsPerEntity,
						denseLayout.format,
						t * 1.8,
					),
			),
		);
		return;
	}
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
	const world = demoState.scene.world();
	const camera = sceneMainCameraOrThrow(demoState.scene);
	pushCameraMatrices(
		world,
		camera,
		readOrbitCameraControllerComponent(
			world,
			camera,
			demoState.orbitControllerComponent,
		),
	);
}

function addMassCubesCameraSyncSystem(demoState: DemoState): void {
	demoState.scene.setSchedule(() => {
		syncMassCubesCameraBlob(demoState);
	}, Phase.RenderExtract);
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
	const orbitControllerComponent = registerOrbitCameraControllerComponent(world);
	const cameraHomeComponent = registerCameraHomeTransformComponent(world);
	const cameraLensComponent = registerCameraLensComponent(world);
	const camera = world.createEntity();
	if (!world.setTransformTrs(camera, 0, 0, 16, 0, 0, 0, 1, 1, 1, 1)) {
		throw new Error("Failed to add camera Transform3D.");
	}
	if (!world.addComponent(camera, world.globalTransformComponent())) {
		throw new Error("Failed to add camera GlobalTransform.");
	}
	if (
		!addOrbitCameraControllerWithDistance(
			world,
			camera,
			orbitControllerComponent,
			0,
			MASS_CUBES_CAMERA_ELEVATION_RAD,
			16,
		)
	) {
		throw new Error("Failed to add OrbitCameraController.");
	}
	if (!setCameraHomeFromCurrentTransform(world, camera, cameraHomeComponent)) {
		throw new Error("Failed to add CameraHomeTransform.");
	}
	if (
		!addCameraLensOrthographic(
			world,
			camera,
			cameraLensComponent,
			0.1,
			80,
			MASS_CUBES_CANVAS_WIDTH / MASS_CUBES_CANVAS_HEIGHT,
			1,
			0,
		)
	) {
		throw new Error("Failed to add CameraLens.");
	}
	pushCameraMatrices(
		world,
		camera,
		readOrbitCameraControllerComponent(
			world,
			camera,
			orbitControllerComponent,
		),
	);
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
		orbitControllerComponent,
		cameraHomeComponent,
		cameraLensComponent,
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
	addMassCubesCameraSyncSystem(demoState);
	uploadInitialGlobalTransforms(demoState);
	drainAndUploadCameraWrites(queue, render.cameraBuffer, world);
	return demoState;
}

function registerEngineHandlers(engine: Engine, demoState: DemoState): void {
	engine.addCommonHandlers(demoState.scene, {
		orbitControllerComponent: demoState.orbitControllerComponent,
		homeComponent: demoState.cameraHomeComponent,
		updateOrbitCameraControllerFromInput:
			updateOrbitCameraControllerComponentFromInput,
		syncOrbitCameraTransform: syncOrbitCameraTransformComponent,
	});
	engine.addPhaseHandler(Phase.Update, (_engine, frame) => {
		beginPerfFrame(demoState);
		updateScene(demoState, frame);
	});
	engine.addPhaseHandler(
		Phase.Render,
		() => {
			if (demoState.scene.visible()) {
				renderCurrentFrame(demoState);
			}
		},
		PhaseSlot.AfterSystems,
	);
	engine.addPhaseHandler(Phase.Shutdown, () => releaseDemoState(demoState));
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
		engine.runFrame(0);
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

runBrowserWebGpuCanvasDemo({
	initialize: async (canvas) => {
		await runPlatform(
			new PlatformConfig(canvas, {
				mainScene: new Scene<World, EntityId>("ts-ecs-mass-cubes"),
			}),
			PlatformApp.defaultEngine((engine) => {
				const demoState = createDemoStateForEngine(engine);
				registerEngineHandlers(engine, demoState);
			}),
			PlatformOptions.interactive(),
		);
	},
});
