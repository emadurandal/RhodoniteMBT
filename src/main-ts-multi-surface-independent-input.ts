// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	World,
	createOrbitOrthographicCameraDescFromYzPosition,
	registerCameraHomeTransformComponent,
	registerCameraLensComponent,
	registerOrbitCameraControllerComponent,
	setCameraLensOrthographic,
	setupOrbitOrthographicCamera,
	syncOrbitCameraBlobComponent,
	syncOrbitCameraTransformComponent,
	type ComponentTypeId,
	type EntityId,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	CubeMeshDesc,
	Engine,
	InputState,
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
	runMultiSurfacePlatform,
	updateOrbitCameraControllerComponentFromInput,
	type FrameState,
	type SurfaceId,
} from "../moon/rhodonite/src/app/ts/index.ts";

type DemoObjects = {
	readonly sun: EntityId;
	readonly earth: EntityId;
	readonly moon: EntityId;
};

type SurfaceRenderState = {
	readonly id: SurfaceId;
	readonly input: InputState;
	readonly scene: Scene<World, EntityId>;
	readonly world: World;
	readonly camera: EntityId;
	readonly orbitControllerComponent: ComponentTypeId;
	readonly cameraLensComponent: ComponentTypeId;
	readonly renderableComponent: RenderableComponent;
	readonly objects: DemoObjects;
};

type DemoState = {
	readonly engine: Engine;
	readonly renderer: Renderer;
	readonly cubeMesh: MeshHandle;
	readonly sunMaterial: MaterialHandle;
	readonly earthMaterial: MaterialHandle;
	readonly moonMaterial: MaterialHandle;
	readonly surfaces: SurfaceRenderState[];
	rendererWidth: number;
	rendererHeight: number;
};

function requireCanvas(id: string): HTMLCanvasElement {
	const element = document.getElementById(id);
	if (!(element instanceof HTMLCanvasElement)) {
		throw new Error(`Missing canvas '${id}'.`);
	}
	return element;
}

function identity(): Float32Array {
	return new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
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
	const half = yaw * 0.5;
	const ok = world.setTransformTrs(
		entity,
		x,
		y,
		z,
		0,
		Math.sin(half),
		0,
		Math.cos(half),
		scale,
		scale,
		scale,
	);
	if (!ok) {
		throw new Error("Failed to update Transform3D.");
	}
}

function createDemoStateForEngine(engine: Engine): DemoState {
	const surface = engine.surfaceState();
	const renderer = new Renderer(
		engine.device,
		engine.queue,
		engine.format,
		surface.width,
		surface.height,
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
	return {
		engine,
		renderer,
		cubeMesh,
		sunMaterial,
		earthMaterial,
		moonMaterial,
		surfaces: [],
		rendererWidth: surface.width,
		rendererHeight: surface.height,
	};
}

function createRenderableObject(
	demo: DemoState,
	world: World,
	renderableComponent: RenderableComponent,
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
			RenderableDesc.new(demo.cubeMesh, material),
		)
	) {
		throw new Error("Failed to add Renderable.");
	}
	return entity;
}

function addSurfaceState(demo: DemoState, id: SurfaceId, input: InputState): void {
	const cameraElevation = 0.38;
	const world = World.new();
	const scene = new Scene<World, EntityId>(`ts-multi-surface-${id}`, world);
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
				cameraElevation,
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
		{ transformPropagation: false },
	);
	demo.engine.setSurfaceScene(id, scene);
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
	const objects = {
		sun: createRenderableObject(
			demo,
			world,
			renderableComponent,
			demo.sunMaterial,
		),
		earth: createRenderableObject(
			demo,
			world,
			renderableComponent,
			demo.earthMaterial,
		),
		moon: createRenderableObject(
			demo,
			world,
			renderableComponent,
			demo.moonMaterial,
		),
	};
	world.updateGlobalTransformsFromTransforms();
	demo.surfaces.push({
		id,
		input,
		scene,
		world,
		camera,
		orbitControllerComponent,
		cameraLensComponent,
		renderableComponent,
		objects,
	});
}

function surfaceStateIndex(demo: DemoState, id: SurfaceId): number {
	return demo.surfaces.findIndex((surface) => surface.id === id);
}

function ensureSurfaceState(demo: DemoState, id: SurfaceId): SurfaceRenderState {
	const index = surfaceStateIndex(demo, id);
	if (index >= 0) {
		return demo.surfaces[index]!;
	}
	addSurfaceState(demo, id, demo.engine.surfaceInput(id));
	return demo.surfaces[demo.surfaces.length - 1]!;
}

function writeScene(surface: SurfaceRenderState, frame: FrameState): void {
	const t = frame.elapsedSeconds;
	const aspect = Math.max(frame.surface.width, 1) / Math.max(frame.surface.height, 1);
	if (
		!setCameraLensOrthographic(
			surface.world,
			surface.camera,
			surface.cameraLensComponent,
			0.1,
			50,
			aspect,
			3.8,
			0,
		)
	) {
		throw new Error("Failed to update CameraLens.");
	}
	syncOrbitCameraBlobComponent(
		surface.world,
		surface.camera,
		surface.orbitControllerComponent,
		surface.cameraLensComponent,
	);
	const earthAngle = t * 0.9;
	const moonAngle = t * 2.8;
	const earthX = Math.cos(earthAngle) * 2.35;
	const earthZ = Math.sin(earthAngle) * 2.35;
	const moonX = earthX + Math.cos(moonAngle) * 1.05;
	const moonZ = earthZ + Math.sin(moonAngle) * 1.05;
	setYRotationTrs(surface.world, surface.objects.sun, 0, 0, 0, t * 0.35, 0.55);
	setYRotationTrs(
		surface.world,
		surface.objects.earth,
		earthX,
		0,
		earthZ,
		t * 2.2,
		0.22,
	);
	setYRotationTrs(
		surface.world,
		surface.objects.moon,
		moonX,
		0,
		moonZ,
		t * 4.1,
		0.11,
	);
	surface.world.updateGlobalTransformsFromTransforms();
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

function renderSurface(demo: DemoState, frame: FrameState): void {
	if (frame.surfaceId === undefined || !frame.surface.active) {
		return;
	}
	const surface = ensureSurfaceState(demo, frame.surfaceId);
	writeScene(surface, frame);
	resizeRendererIfNeeded(demo, frame);
	const colorView = demo.engine.surfaceGpuSurface(frame.surfaceId).acquireView();
	demo.renderer.renderSceneRenderables(
		surface.scene,
		surface.renderableComponent,
		colorView,
	);
}

function registerEngineHandlers(engine: Engine, demo: DemoState): void {
	engine.addPhaseHandler(Phase.Startup, () => {
		for (let index = 0; index < engine.surfaceCount(); index += 1) {
			ensureSurfaceState(demo, engine.surfaceIdAt(index));
		}
	});
	engine.addPhaseHandler(Phase.Surface, (_engine, frame) => {
		if (frame.surfaceId !== undefined) {
			ensureSurfaceState(demo, frame.surfaceId);
		}
	});
	engine.addPhaseHandler(
		Phase.Render,
		(_engine, frame) => renderSurface(demo, frame),
		PhaseSlot.AfterSystems,
	);
	engine.addPhaseHandler(Phase.Shutdown, () => {
		demo.renderer.release();
	});
}

async function initialize(first: HTMLCanvasElement, second: HTMLCanvasElement): Promise<void> {
	const platform = await runMultiSurfacePlatform(
		[
			new PlatformConfig(first),
			new PlatformConfig(second),
		],
		PlatformApp.defaultEngine((engine) => {
			const demo = createDemoStateForEngine(engine);
			registerEngineHandlers(engine, demo);
		}),
		PlatformOptions.interactive(),
	);
	if (platform === undefined) {
		throw new Error("Failed to create TypeScript multi-surface platform.");
	}
}

window.addEventListener("load", () => {
	if (!navigator.gpu) {
		document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
		return;
	}
	Promise.resolve(
		initialize(requireCanvas("webgpu-canvas-a"), requireCanvas("webgpu-canvas-b")),
	).catch((error: unknown) => {
		console.error("Failed to initialize TypeScript multi-surface demo:", error);
		document.body.innerHTML =
			"<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
	});
});
