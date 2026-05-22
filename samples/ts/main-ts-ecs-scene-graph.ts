// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	World,
	createOrbitOrthographicCameraDescFromYzPosition,
	registerCameraHomeTransformComponent,
	registerCameraLensComponent,
	registerOrbitCameraControllerComponent,
	setupOrbitOrthographicCamera,
	syncOrbitCameraBlobComponent,
	syncOrbitCameraTransformComponent,
	type ComponentTypeId,
	type EntityId,
} from "../../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	CubeMeshDesc,
	Engine,
	MaterialHandle,
	MeshHandle,
	Phase,
	PhaseSlot,
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	RenderableComponent,
	RenderableDesc,
	Renderer,
	Scene,
	UnlitMaterialDesc,
	addRenderable,
	cubePosition3VertexLayout,
	registerRenderableComponent,
	runBrowserWebGpuCanvasDemo,
	runPlatform,
	updateOrbitCameraControllerComponentFromInput,
	type FrameState,
} from "../../moon/rhodonite/src/app/ts/index.ts";
import {
	readPresentedCanvasRgba8,
} from "../../visual-regression/webgpu-readback";

const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;
const CAMERA_ELEVATION_RAD = 0.38;

type DemoObjects = {
	readonly sun: EntityId;
	readonly earth: EntityId;
	readonly moon: EntityId;
};

type DemoState = {
	readonly engine: Engine;
	readonly renderer: Renderer;
	readonly scene: Scene<World, EntityId>;
	readonly world: World;
	readonly renderableComponent: RenderableComponent;
	readonly orbitControllerComponent: ComponentTypeId;
	readonly cameraLensComponent: ComponentTypeId;
	readonly objects: DemoObjects;
	rendererWidth: number;
	rendererHeight: number;
};

function identity(): Float32Array {
	return new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}

function quatY(angle: number): readonly [number, number, number, number] {
	const half = angle * 0.5;
	return [0, Math.sin(half), 0, Math.cos(half)];
}

function setTransformTrs(
	world: World,
	entity: EntityId,
	x: number,
	y: number,
	z: number,
	qx: number,
	qy: number,
	qz: number,
	qw: number,
	scale: number,
): void {
	if (!world.setTransformTrs(entity, x, y, z, qx, qy, qz, qw, scale, scale, scale)) {
		throw new Error("Failed to update Transform3D.");
	}
}

function setYRotationTrs(
	world: World,
	entity: EntityId,
	x: number,
	y: number,
	z: number,
	yaw: number,
	scale: number,
): void {
	const [qx, qy, qz, qw] = quatY(yaw);
	setTransformTrs(world, entity, x, y, z, qx, qy, qz, qw, scale);
}

function pushLocalTransforms(world: World, objects: DemoObjects, t: number): void {
	setYRotationTrs(world, objects.sun, 0, 0, 0, t * 0.35, 0.55);

	const earthOrbit = t * 0.9;
	setYRotationTrs(
		world,
		objects.earth,
		Math.cos(earthOrbit) * 2.35,
		0,
		Math.sin(earthOrbit) * 2.35,
		t * 2.2,
		0.22,
	);

	const moonOrbit = t * 2.8;
	setTransformTrs(
		world,
		objects.moon,
		Math.cos(moonOrbit) * 1.05,
		0,
		Math.sin(moonOrbit) * 1.05,
		0,
		0,
		0,
		1,
		0.5,
	);
}

function addRenderableObject(
	world: World,
	renderableComponent: RenderableComponent,
	cubeMesh: MeshHandle,
	material: MaterialHandle,
): EntityId {
	const entity = world.createEntity();
	setYRotationTrs(world, entity, 0, 0, 0, 0, 1);
	if (!world.setGlobalTransform(entity, identity())) {
		throw new Error("Failed to add GlobalTransform.");
	}
	if (
		!addRenderable(
			world,
			entity,
			renderableComponent,
			RenderableDesc.new(cubeMesh, material),
		)
	) {
		throw new Error("Failed to add Renderable.");
	}
	return entity;
}

function createDemoStateForEngine(engine: Engine): DemoState {
	const scene = engine.mainScene<World, EntityId>();
	const world = World.new();
	scene.setWorld(world);

	const orbitControllerComponent = registerOrbitCameraControllerComponent(world);
	const cameraHomeComponent = registerCameraHomeTransformComponent(world);
	const cameraLensComponent = registerCameraLensComponent(world);
	const renderableComponent = registerRenderableComponent(world);
	const camera = world.createEntity();

	if (
		!setupOrbitOrthographicCamera(
			world,
			camera,
			orbitControllerComponent,
			cameraHomeComponent,
			cameraLensComponent,
			createOrbitOrthographicCameraDescFromYzPosition(
				CAMERA_ELEVATION_RAD,
				2,
				5.6,
				0.1,
				50,
				1,
				3.8,
			),
		)
	) {
		throw new Error("Failed to setup orbit orthographic camera.");
	}
	scene.setMainCamera(camera);
	scene.useCommonRuntime(
		{
			orbitControllerComponent,
			homeComponent: cameraHomeComponent,
			updateOrbitCameraControllerFromInput:
				updateOrbitCameraControllerComponentFromInput,
			syncOrbitCameraTransform: syncOrbitCameraTransformComponent,
		},
		{ transformPropagation: true },
	);

	const renderer = new Renderer(
		engine.device,
		engine.queue,
		engine.format,
		CANVAS_WIDTH,
		CANVAS_HEIGHT,
		cubePosition3VertexLayout(),
	);
	const cubeMesh = renderer.registerCubeMesh(CubeMeshDesc.new(0.42));
	const sunMaterial = renderer.registerUnlitMaterial(
		UnlitMaterialDesc.new(1.0, 0.65, 0.15),
	);
	const earthMaterial = renderer.registerUnlitMaterial(
		UnlitMaterialDesc.new(0.2, 0.55, 1.0),
	);
	const moonMaterial = renderer.registerUnlitMaterial(
		UnlitMaterialDesc.new(1.0, 0.0, 1.0),
	);
	const objects = {
		sun: addRenderableObject(world, renderableComponent, cubeMesh, sunMaterial),
		earth: addRenderableObject(world, renderableComponent, cubeMesh, earthMaterial),
		moon: addRenderableObject(world, renderableComponent, cubeMesh, moonMaterial),
	};
	if (!world.setChildOf(objects.earth, objects.sun)) {
		throw new Error("Failed to set earth ChildOf.");
	}
	if (!world.setChildOf(objects.moon, objects.earth)) {
		throw new Error("Failed to set moon ChildOf.");
	}

	pushLocalTransforms(world, objects, 0);
	scene.setSchedule(
		(systemWorld) => {
			syncOrbitCameraBlobComponent(
				systemWorld,
				camera,
				orbitControllerComponent,
				cameraLensComponent,
			);
		},
		Phase.RenderExtract,
	);
	scene.prepareRenderState();

	return {
		engine,
		renderer,
		scene,
		world,
		renderableComponent,
		orbitControllerComponent,
		cameraLensComponent,
		objects,
		rendererWidth: CANVAS_WIDTH,
		rendererHeight: CANVAS_HEIGHT,
	};
}

function updateScene(demo: DemoState, frame: FrameState): void {
	pushLocalTransforms(demo.world, demo.objects, frame.elapsedSeconds);
}

function resizeRendererIfNeeded(demo: DemoState, frame: FrameState): void {
	const width = Math.max(frame.surface.width, 1);
	const height = Math.max(frame.surface.height, 1);
	if (demo.rendererWidth === width && demo.rendererHeight === height) {
		return;
	}
	demo.renderer.resizeSurfaceResources(width, height);
	demo.rendererWidth = width;
	demo.rendererHeight = height;
}

function renderCurrentFrame(demo: DemoState): void {
	const colorView = demo.engine.context.getCurrentTexture().createView();
	demo.renderer.renderSceneRenderables(
		demo.scene,
		demo.renderableComponent,
		colorView,
	);
}

function registerEngineHandlers(engine: Engine, demo: DemoState): void {
	engine.addPhaseHandler(Phase.Surface, (_engine, frame) => {
		if (frame.surfaceChanged && frame.surface.active) {
			resizeRendererIfNeeded(demo, frame);
		}
	});
	engine.addPhaseHandler(Phase.Update, (_engine, frame) => {
		updateScene(demo, frame);
	});
	engine.addPhaseHandler(
		Phase.Render,
		() => {
			if (demo.scene.visible()) {
				renderCurrentFrame(demo);
			}
		},
		PhaseSlot.AfterSystems,
	);
	engine.addPhaseHandler(Phase.Shutdown, () => demo.renderer.release());
}

export async function renderTsEcsSceneGraphBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = CANVAS_WIDTH;
	canvas.height = CANVAS_HEIGHT;
	const platform = await runPlatform(
		new PlatformConfig(canvas),
		PlatformApp.defaultEngine((engine) => {
			const demo = createDemoStateForEngine(engine);
			registerEngineHandlers(engine, demo);
		}),
		PlatformOptions.singleFrame(),
	);
	if (platform === undefined) {
		throw new Error("TypeScript ECS scene graph platform failed to initialize.");
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
				const demo = createDemoStateForEngine(engine);
				registerEngineHandlers(engine, demo);
			}),
			PlatformOptions.interactive(),
		);
	},
});
