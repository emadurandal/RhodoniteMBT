// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	World,
	WorldHistory,
	createOrbitOrthographicCameraDescFromYzPosition,
	setupOrbitOrthographicCamera,
	type EntityId,
} from "../../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	CubeMeshDesc,
	Engine,
	MaterialHandle,
	MeshHandle,
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	RenderableDesc,
	Renderer,
	RenderTargetResources,
	Scene,
	UnlitMaterialDesc,
	addRenderable,
	runBrowserWebGpuCanvasDemo,
	runPlatform,
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
	readonly target: RenderTargetResources;
	readonly scene: Scene<World, EntityId>;
	readonly world: World;
	readonly objects: DemoObjects;
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
	scene: Scene<World, EntityId>,
	cubeMesh: MeshHandle,
	material: MaterialHandle,
): EntityId {
	const world = scene.world();
	const entity = world.createEntity();
	setYRotationTrs(world, entity, 0, 0, 0, 0, 1);
	if (!world.setGlobalTransform(entity, identity())) {
		throw new Error("Failed to add GlobalTransform.");
	}
	if (
		!addRenderable(
			scene,
			entity,
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

	const camera = world.createEntity();

	if (
		!setupOrbitOrthographicCamera(
			world,
			camera,
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

	const renderer = engine.renderer;
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
		sun: addRenderableObject(scene, cubeMesh, sunMaterial),
		earth: addRenderableObject(scene, cubeMesh, earthMaterial),
		moon: addRenderableObject(scene, cubeMesh, moonMaterial),
	};
	if (!world.setChildOf(objects.earth, objects.sun)) {
		throw new Error("Failed to set earth ChildOf.");
	}
	if (!world.setChildOf(objects.moon, objects.earth)) {
		throw new Error("Failed to set moon ChildOf.");
	}

	pushLocalTransforms(world, objects, 0);
	scene.prepareRenderState();

	return {
		engine,
		renderer,
		target: engine.renderTargetResources,
		scene,
		world,
		objects,
	};
}

function updateScene(demo: DemoState, frame: FrameState): void {
	pushLocalTransforms(demo.world, demo.objects, frame.elapsedSeconds);
}

function renderCurrentFrame(demo: DemoState): void {
	const colorView = demo.engine.context.getCurrentTexture().createView();
	demo.renderer.renderSceneRenderables(demo.scene, demo.target, colorView);
}

function registerEngineHandlers(engine: Engine, demo: DemoState): void {
	engine.onSceneUpdate(demo.scene, (frame) => {
		updateScene(demo, frame);
	});
	engine.onSceneRender(demo.scene, () => {
		renderCurrentFrame(demo);
	});
}

function applyUndoRedoVisualEdit(demo: DemoState): void {
	const history = WorldHistory.new();
	const ok = history.withTransaction(demo.world, "Scene Graph Visual Move", () =>
		history.setTransformTrs(
			demo.world,
			demo.objects.earth,
			1.15,
			0,
			1.65,
			0,
			0,
			0,
			1,
			0.36,
			0.36,
			0.36,
		)
	);
	if (!ok) {
		throw new Error("Failed to apply tracked scene graph visual edit.");
	}
	if (!history.undo(demo.world)) {
		throw new Error("Failed to undo scene graph visual edit.");
	}
	if (!history.redo(demo.world)) {
		throw new Error("Failed to redo scene graph visual edit.");
	}
	demo.scene.prepareRenderState();
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

export async function renderTsEcsSceneGraphUndoRedoBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = CANVAS_WIDTH;
	canvas.height = CANVAS_HEIGHT;
	const platform = await runPlatform(
		new PlatformConfig(canvas),
		PlatformApp.defaultEngine((engine) => {
			const demo = createDemoStateForEngine(engine);
			applyUndoRedoVisualEdit(demo);
			engine.onSceneRender(demo.scene, () => {
				renderCurrentFrame(demo);
			});
		}),
		PlatformOptions.singleFrame(),
	);
	if (platform === undefined) {
		throw new Error("TypeScript ECS scene graph Undo/Redo platform failed to initialize.");
	}
	try {
		return await readPresentedCanvasRgba8(canvas, platform.engine.queue);
	} finally {
		platform.dispose();
	}
}

function runUndoRedoDemoFromModuleUrl(): boolean {
	return new URL(import.meta.url).searchParams.get("undoRedo") === "1";
}

runBrowserWebGpuCanvasDemo({
	initialize: async (canvas) => {
		await runPlatform(
			new PlatformConfig(canvas),
			PlatformApp.defaultEngine((engine) => {
				const demo = createDemoStateForEngine(engine);
				if (runUndoRedoDemoFromModuleUrl()) {
					applyUndoRedoVisualEdit(demo);
					engine.onSceneRender(demo.scene, () => {
						renderCurrentFrame(demo);
					});
				} else {
					registerEngineHandlers(engine, demo);
				}
			}),
			PlatformOptions.interactive(),
		);
	},
});
