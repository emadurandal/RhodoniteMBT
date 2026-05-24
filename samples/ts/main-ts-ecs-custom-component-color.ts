// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	Query,
	World,
	createOrbitOrthographicCameraDescFromYzPosition,
	setupOrbitOrthographicCamera,
	type ByteView,
	type ComponentTypeId,
	type EntityId,
} from "../../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	CubeMeshDesc,
	Engine,
	InstanceBufferHandle,
	MeshHandle,
	Phase,
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	Renderer,
	RenderTargetResources,
	Scene,
	runBrowserWebGpuCanvasDemo,
	runPlatform,
} from "../../moon/rhodonite/src/app/ts/index.ts";
import { readPresentedCanvasRgba8 } from "../../visual-regression/webgpu-readback";

const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;
const ENTITY_COUNT = 25;
const GRID_SIDE = 5;
const PULSE_COLOR_STRIDE = 24;
const INSTANCE_STRIDE = 24;
const CAMERA_ELEVATION_RAD = 0.52;

type DemoState = {
	readonly engine: Engine;
	readonly renderer: Renderer;
	readonly target: RenderTargetResources;
	readonly scene: Scene<World, EntityId>;
	readonly world: World;
	readonly cubeMesh: MeshHandle;
	readonly instanceBuffer: InstanceBufferHandle;
	readonly entities: EntityId[];
	readonly instanceBytes: Uint8Array;
	readonly pulseColor: ComponentTypeId;
};

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(
		offset,
		value,
		true,
	);
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setUint32(
		offset,
		value >>> 0,
		true,
	);
}

function readU32View(bytes: ByteView, offset: number): number {
	return (
		bytes.get(offset) |
		(bytes.get(offset + 1) << 8) |
		(bytes.get(offset + 2) << 16) |
		(bytes.get(offset + 3) << 24)
	) >>> 0;
}

function pulsePaletteChannel(index: number, channel: number): number {
	const band = (index * 7 + channel * 11) % 17;
	return 0.18 + band * 0.045;
}

function pulseColorBytes(index: number, slot: number): Uint8Array {
	const bytes = new Uint8Array(PULSE_COLOR_STRIDE);
	writeF32(bytes, 0, pulsePaletteChannel(index, 0));
	writeF32(bytes, 4, pulsePaletteChannel(index, 1));
	writeF32(bytes, 8, pulsePaletteChannel(index, 2));
	writeF32(bytes, 12, index * 0.37);
	writeF32(bytes, 16, 0.75 + (index % 5) * 0.18);
	writeU32(bytes, 20, slot);
	return bytes;
}

function identity(): Float32Array {
	return new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}

function setupGridEntity(
	world: World,
	entity: EntityId,
	pulseColor: ComponentTypeId,
	index: number,
): void {
	const col = index % GRID_SIDE;
	const row = Math.floor(index / GRID_SIDE);
	const half = (GRID_SIDE - 1) * 0.5;
	const x = (col - half) * 1.05;
	const z = (row - half) * 1.05;
	if (!world.setTransformTrs(entity, x, 0, z, 0, 0, 0, 1, 0.36, 0.36, 0.36)) {
		throw new Error("Failed to set Transform3D.");
	}
	if (!world.setGlobalTransform(entity, identity())) {
		throw new Error("Failed to set GlobalTransform.");
	}
	if (!world.addComponentBytes(entity, pulseColor, pulseColorBytes(index, index))) {
		throw new Error("Failed to add PulseColor component.");
	}
}

function writeInstanceTransformRefs(instanceBytes: Uint8Array, refs: Uint8Array): void {
	for (let i = 0; i < ENTITY_COUNT; i += 1) {
		instanceBytes.set(refs.subarray(i * 8, i * 8 + 8), i * INSTANCE_STRIDE);
	}
}

function updatePulseColors(
	world: World,
	component: ComponentTypeId,
	deltaSeconds: number,
): void {
	Query.new([component]).forEach(world, (row) => {
		row.write(component, (bytes) => {
			const phase = bytes.getF32(12);
			const speed = bytes.getF32(16);
			bytes.setF32(12, phase + deltaSeconds * speed);
		});
	});
}

function writeInstanceColor(
	bytes: Uint8Array,
	slot: number,
	r: number,
	g: number,
	b: number,
): void {
	if (slot < 0 || slot >= ENTITY_COUNT) {
		return;
	}
	const base = slot * INSTANCE_STRIDE;
	writeF32(bytes, base + 8, r);
	writeF32(bytes, base + 12, g);
	writeF32(bytes, base + 16, b);
}

function syncInstanceColorsFromComponents(demo: DemoState): void {
	Query.new([demo.pulseColor]).forEach(demo.world, (row) => {
		row.read(demo.pulseColor, (bytes) => {
			const baseR = bytes.getF32(0);
			const baseG = bytes.getF32(4);
			const baseB = bytes.getF32(8);
			const phase = bytes.getF32(12);
			const slot = readU32View(bytes, 20);
			const intensity = 0.68 + 0.32 * Math.sin(phase);
			writeInstanceColor(
				demo.instanceBytes,
				slot,
				baseR * intensity,
				baseG * intensity,
				baseB * intensity,
			);
		});
	});
	if (!demo.renderer.updateStaticInstanceBuffer(demo.instanceBuffer, demo.instanceBytes)) {
		throw new Error("Failed to update custom component instance buffer.");
	}
}

function addPulseColorSystems(demo: DemoState): void {
	demo.scene.setSchedule((world, frame) => {
		updatePulseColors(world, demo.pulseColor, frame.deltaSeconds);
	}, Phase.Update);
	demo.scene.setSchedule(() => {
		syncInstanceColorsFromComponents(demo);
	}, Phase.RenderExtract);
}

function createDemoStateForEngine(engine: Engine): DemoState {
	const scene = engine.mainScene<World, EntityId>();
	const world = World.new();
	scene.setWorld(world);
	const pulseColor = world.registerCpuComponent(
		"RhodoniteExamplePulseColor",
		PULSE_COLOR_STRIDE,
	);
	const camera = world.createEntity();
	if (
		!setupOrbitOrthographicCamera(
			world,
			camera,
			createOrbitOrthographicCameraDescFromYzPosition(
				CAMERA_ELEVATION_RAD,
				2,
				7,
				0.1,
				80,
				1,
				4.2,
			),
		)
	) {
		throw new Error("Failed to setup orbit orthographic camera.");
	}
	scene.setMainCamera(camera);
	const entities: EntityId[] = [];
	for (let i = 0; i < ENTITY_COUNT; i += 1) {
		const entity = world.createEntity();
		setupGridEntity(world, entity, pulseColor, i);
		entities.push(entity);
	}
	world.updateGlobalTransformsFromTransforms();
	const instanceBytes = new Uint8Array(ENTITY_COUNT * INSTANCE_STRIDE);
	writeInstanceTransformRefs(instanceBytes, world.extractGlobalTransformRefs(entities));
	const renderer = engine.renderer;
	const cubeMesh = renderer.registerCubeMesh(CubeMeshDesc.new(0.42));
	const instanceBuffer = renderer.registerStaticInstanceBuffer(instanceBytes);
	const demo: DemoState = {
		engine,
		renderer,
		target: engine.renderTargetResources,
		scene,
		world,
		cubeMesh,
		instanceBuffer,
		entities,
		instanceBytes,
		pulseColor,
	};
	syncInstanceColorsFromComponents(demo);
	addPulseColorSystems(demo);
	scene.prepareRenderState();
	return demo;
}

function renderCurrentFrame(demo: DemoState): void {
	const colorView = demo.engine.context.getCurrentTexture().createView();
	demo.renderer.renderInstancedMesh(
		demo.scene,
		demo.cubeMesh,
		demo.instanceBuffer,
		demo.entities.length,
		demo.target,
		colorView,
	);
}

function registerEngineHandlers(engine: Engine, demo: DemoState): void {
	engine.onSceneRender(demo.scene, () => {
		renderCurrentFrame(demo);
	});
}

export async function renderTsEcsCustomComponentColorBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = CANVAS_WIDTH;
	canvas.height = CANVAS_HEIGHT;
	const platform = await runPlatform(
		new PlatformConfig(canvas),
		new PlatformApp({
			createEngine: (config) =>
				Engine.create(config.canvas, {
					mainScene: new Scene<World, EntityId>("ts-ecs-custom-component-color"),
				}),
			setupEngine: (engine) => {
				const demo = createDemoStateForEngine(engine);
				registerEngineHandlers(engine, demo);
			},
		}),
		PlatformOptions.singleFrame(),
	);
	if (platform === undefined) {
		throw new Error("TypeScript ECS custom component color platform failed to initialize.");
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
