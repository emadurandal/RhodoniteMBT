// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	World,
	computeGlobalTransformUploadRange,
	createOrbitOrthographicCameraDesc,
	detectDenseGlobalTransformLayout,
	writeGlobalTransformBlobRangeByRefs,
	mat4Inverse,
	readOrbitCameraControllerComponent,
	setupOrbitOrthographicCamera,
	type ComponentTypeId,
	type EntityId,
	type GlobalTransformBlobWriter,
	type GlobalTransformDenseLayout,
	type OrbitCameraController,
} from "../../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	readPresentedCanvasRgba8,
} from "../../visual-regression/webgpu-readback";
import {
	CubeMeshDesc,
	Engine,
	type InstanceBufferHandle,
	type MeshHandle,
	Phase,
	PhaseSlot,
	Renderer,
	Scene,
	PlatformConfig,
	PlatformApp,
	PlatformOptions,
	cubePosition3VertexLayout,
	runBrowserWebGpuCanvasDemo,
	runPlatform,
	type FrameState,
} from "../../moon/rhodonite/src/app/ts/index.ts";
import {
	MASS_CUBES_CANVAS_HEIGHT,
	MASS_CUBES_CANVAS_WIDTH,
	MASS_CUBES_CAMERA_ELEVATION_RAD,
	MASS_CUBES_CUBE_SCALE,
	MASS_CUBES_ENTITY_COUNT,
	MASS_CUBES_GRID_SPACING,
	MASS_CUBES_INSTANCE_STRIDE,
	gridSideLen,
	instanceColorRgb,
	massCubesCameraMatrices,
	writeF32,
} from "./ecs-mass-cubes-renderer";
import { writeMassCubesDenseYTransformWaveToByteView } from "./ecs-mass-cubes-transform-writer";
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
	readonly renderer: Renderer;
	readonly cubeMesh: MeshHandle;
	readonly instanceBuffer: InstanceBufferHandle;
	readonly scene: Scene<World, EntityId>;
	readonly orbitControllerComponent: ComponentTypeId;
	readonly cameraHomeComponent: ComponentTypeId;
	readonly cameraLensComponent: ComponentTypeId;
	readonly transformRefs: Uint32Array;
	readonly transformWordUploadFirst: number;
	readonly transformWordUploadCount: number;
	readonly denseTransformLayout: GlobalTransformDenseLayout | null;
	readonly perSide: number;
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

function uploadInitialGlobalTransforms(demoState: DemoState): void {
	const world = demoState.scene.world();
	demoState.renderer.uploadGlobalTransformWrites(
		world,
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
		demoState.renderer.uploadGlobalTransformWrites(
			world,
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
	demoState.renderer.uploadGlobalTransformWrites(
		world,
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
	const orbitControllerComponent = world.orbitCameraControllerComponent();
	const cameraHomeComponent = world.cameraHomeTransformComponent();
	const cameraLensComponent = world.cameraLensComponent();
	const camera = world.createEntity();
	if (
		!setupOrbitOrthographicCamera(
			world,
			camera,
			createOrbitOrthographicCameraDesc(
				0,
				MASS_CUBES_CAMERA_ELEVATION_RAD,
				0,
				0,
				1,
				16,
				0.1,
				80,
				MASS_CUBES_CANVAS_WIDTH / MASS_CUBES_CANVAS_HEIGHT,
				1,
			),
		)
	) {
		throw new Error("Failed to setup orbit orthographic camera.");
	}
	scene.useCommonRuntime({
		transformPropagation: false,
		orbitCameraBlobSync: false,
	});
	scene.setMainCamera(camera);
	const instanceData = instanceBytes(entities, transformRefsBytes);
	const renderer = new Renderer(
		device,
		queue,
		targetFormat,
		MASS_CUBES_CANVAS_WIDTH,
		MASS_CUBES_CANVAS_HEIGHT,
		cubePosition3VertexLayout(),
	);
	const cubeMesh = renderer.registerCubeMesh(CubeMeshDesc.new(0.42));
	const instanceBuffer = renderer.registerStaticInstanceBuffer(instanceData);

	const demoState: DemoState = {
		canvas,
		context,
		device,
		queue,
		renderer,
		cubeMesh,
		instanceBuffer,
		scene,
		orbitControllerComponent,
		cameraHomeComponent,
		cameraLensComponent,
		transformRefs,
		transformWordUploadFirst: transformUploadRange.firstWord,
		transformWordUploadCount: transformUploadRange.wordCount,
		denseTransformLayout,
		perSide,
		frame: 0,
		lastFrameStartMs: -1,
		cpuFrameStartMs: -1,
	};
	addMassCubesCameraSyncSystem(demoState);
	demoState.scene.prepareRenderState();
	uploadInitialGlobalTransforms(demoState);
	return demoState;
}

function registerEngineHandlers(engine: Engine, demoState: DemoState): void {
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

	const colorView = demoState.context.getCurrentTexture().createView();
	renderScene(demoState, demoState.scene, colorView);
	updatePerfOverlay(fps, performance.now() - frameStart);
	demoState.cpuFrameStartMs = -1;
}

function renderScene(
	demoState: DemoState,
	scene: Scene<World, EntityId>,
	colorView: GPUTextureView,
): void {
	demoState.renderer.renderInstancedMesh(
		scene,
		demoState.cubeMesh,
		demoState.instanceBuffer,
		MASS_CUBES_ENTITY_COUNT,
		colorView,
	);
}

function releaseDemoState(demoState: DemoState): void {
	demoState.renderer.release();
}

export async function renderTsEcsMassCubesBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = MASS_CUBES_CANVAS_WIDTH;
	canvas.height = MASS_CUBES_CANVAS_HEIGHT;
	const platform = await runPlatform(
		new PlatformConfig(canvas),
		new PlatformApp({
			createEngine: (config) =>
				Engine.create(config.canvas, {
					mainScene: new Scene<World, EntityId>("ts-ecs-mass-cubes"),
				}),
			setupEngine: (engine) => {
				const demoState = createDemoStateForEngine(engine);
				registerEngineHandlers(engine, demoState);
			},
		}),
		PlatformOptions.singleFrame(),
	);
	if (platform === undefined) {
		throw new Error("TypeScript ECS mass cubes platform failed to initialize.");
	}
	try {
		return await readPresentedCanvasRgba8(canvas, platform.engine.queue);
	} finally {
		platform.dispose();
	}
}

runBrowserWebGpuCanvasDemo({
	initialize: async (canvas) => {
		await runPlatform(
			new PlatformConfig(canvas),
			PlatformApp.defaultEngine((engine) => {
				const demoState = createDemoStateForEngine(engine);
				registerEngineHandlers(engine, demoState);
			}),
			PlatformOptions.interactive(),
		);
	},
});
