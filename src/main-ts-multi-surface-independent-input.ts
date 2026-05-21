// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	World,
	cameraHelpersDefault,
	cameraWordsBindGroup,
	cameraWordsBindingDefault,
	createCameraWordsBuffer,
	drainAndUploadCameraWrites,
	addOrbitCameraControllerWithPose,
	registerCameraHomeTransformComponent,
	registerCameraLensComponent,
	registerOrbitCameraControllerComponent,
	setCameraHomeFromCurrentTransform,
	setCameraLensOrthographic,
	syncOrbitCameraBlobComponent,
	syncOrbitCameraTransformComponent,
	type ComponentTypeId,
	type EntityId,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	Engine,
	GpuSurface,
	InputState,
	Phase,
	PhaseSlot,
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	Scene,
	runMultiSurfacePlatform,
	updateOrbitCameraControllerComponentFromInput,
	type FrameState,
	type SurfaceId,
} from "../moon/rhodonite/src/app/ts/index.ts";

type SurfaceRenderState = {
	readonly id: SurfaceId;
	readonly input: InputState;
	readonly scene: Scene<World, EntityId>;
	readonly world: World;
	readonly camera: EntityId;
	readonly orbitControllerComponent: ComponentTypeId;
	readonly cameraLensComponent: ComponentTypeId;
	readonly cameraStorage: GPUBuffer;
	readonly cameraBindGroup: GPUBindGroup;
	depthTexture: GPUTexture;
	depthView: GPUTextureView;
};

type DemoState = {
	readonly engine: Engine;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly pipeline: GPURenderPipeline;
	readonly vertexBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly objectBuffer: GPUBuffer;
	readonly bindGroup: GPUBindGroup;
	readonly surfaces: SurfaceRenderState[];
	frame: number;
};

const INDEX_COUNT = 36;
const OBJECT_STRIDE_FLOATS = 20;
const OBJECT_STRIDE_BYTES = OBJECT_STRIDE_FLOATS * 4;

function requireCanvas(id: string): HTMLCanvasElement {
	const element = document.getElementById(id);
	if (!(element instanceof HTMLCanvasElement)) {
		throw new Error(`Missing canvas '${id}'.`);
	}
	return element;
}

function cubeVertices(): Float32Array {
	return new Float32Array([
		-1, -1, -1, 1, -1, -1, 1, 1, -1, -1, 1, -1,
		-1, -1, 1, 1, -1, 1, 1, 1, 1, -1, 1, 1,
	]);
}

function cubeIndices(): Uint16Array {
	return new Uint16Array([
		0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 0, 4, 7, 7, 3, 0,
		1, 5, 6, 6, 2, 1, 0, 1, 5, 5, 4, 0, 3, 2, 6, 6, 7, 3,
	]);
}

function identity(): Float32Array {
	return new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}

function multiply(a: Float32Array, b: Float32Array): Float32Array {
	const out = new Float32Array(16);
	for (let col = 0; col < 4; col += 1) {
		for (let row = 0; row < 4; row += 1) {
			out[col * 4 + row] =
				a[0 * 4 + row] * b[col * 4 + 0] +
				a[1 * 4 + row] * b[col * 4 + 1] +
				a[2 * 4 + row] * b[col * 4 + 2] +
				a[3 * 4 + row] * b[col * 4 + 3];
		}
	}
	return out;
}

function translate(x: number, y: number, z: number): Float32Array {
	const m = identity();
	m[12] = x;
	m[13] = y;
	m[14] = z;
	return m;
}

function scale(s: number): Float32Array {
	const m = identity();
	m[0] = s;
	m[5] = s;
	m[10] = s;
	return m;
}

function rotateY(angle: number): Float32Array {
	const c = Math.cos(angle);
	const s = Math.sin(angle);
	return new Float32Array([c, 0, -s, 0, 0, 1, 0, 0, s, 0, c, 0, 0, 0, 0, 1]);
}

function createShader(): string {
	return (
		cameraWordsBindingDefault() +
		cameraHelpersDefault() +
		`
struct ObjectData {
  model: mat4x4<f32>,
  color: vec4<f32>,
};
@group(0) @binding(0) var<storage, read> objects: array<ObjectData>;
struct VertexOut {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec4<f32>,
};
@vertex
fn vertexMain(@location(0) localPos: vec3<f32>, @builtin(instance_index) instanceIndex: u32) -> VertexOut {
  let object = objects[instanceIndex];
  let camera = rn_load_camera(0u);
  var out: VertexOut;
  out.position = camera.view_proj * object.model * vec4<f32>(localPos, 1.0);
  out.color = object.color;
  return out;
}
@fragment
fn fragmentMain(in: VertexOut) -> @location(0) vec4<f32> {
  return in.color;
}`
	);
}

function createDemoStateForEngine(engine: Engine): DemoState {
	const device = engine.device;
	const shader = device.createShaderModule({ code: createShader() });
	const objectBuffer = device.createBuffer({
		size: OBJECT_STRIDE_BYTES * 3,
		usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
	});
	const pipeline = device.createRenderPipeline({
		layout: "auto",
		vertex: {
			module: shader,
			entryPoint: "vertexMain",
			buffers: [{ arrayStride: 12, attributes: [{ shaderLocation: 0, offset: 0, format: "float32x3" }] }],
		},
		fragment: { module: shader, entryPoint: "fragmentMain", targets: [{ format: engine.format }] },
		primitive: { topology: "triangle-list" },
		depthStencil: { format: "depth24plus", depthWriteEnabled: true, depthCompare: "less" },
	});
	const bindGroup = device.createBindGroup({
		layout: pipeline.getBindGroupLayout(0),
		entries: [{ binding: 0, resource: { buffer: objectBuffer } }],
	});
	const vertexBuffer = device.createBuffer({ size: cubeVertices().byteLength, usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST });
	engine.queue.writeBuffer(vertexBuffer, 0, cubeVertices());
	const indexBuffer = device.createBuffer({ size: cubeIndices().byteLength, usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST });
	engine.queue.writeBuffer(indexBuffer, 0, cubeIndices());
	return { engine, device, queue: engine.queue, pipeline, vertexBuffer, indexBuffer, objectBuffer, bindGroup, surfaces: [], frame: 0 };
}

function createDepth(device: GPUDevice, width: number, height: number): { texture: GPUTexture; view: GPUTextureView } {
	const texture = device.createTexture({ size: [Math.max(width, 1), Math.max(height, 1)], format: "depth24plus", usage: GPUTextureUsage.RENDER_ATTACHMENT });
	return { texture, view: texture.createView() };
}

function addSurfaceState(demo: DemoState, id: SurfaceId, input: InputState): void {
	const { texture, view } = createDepth(demo.device, 800, 600);
	const cameraElevation = 0.38;
	const cameraPanY = -2.0 / Math.cos(cameraElevation);
	const cameraDistance = 5.6 - cameraPanY * Math.sin(cameraElevation);
	const world = World.new();
	const scene = new Scene<World, EntityId>(`ts-multi-surface-${id}`, world);
	const orbitControllerComponent = registerOrbitCameraControllerComponent(world);
	const cameraHomeComponent = registerCameraHomeTransformComponent(world);
	const cameraLensComponent = registerCameraLensComponent(world);
	const camera = world.createEntity();
	const cameraQx = -Math.sin(cameraElevation * 0.5);
	const cameraQw = Math.cos(cameraElevation * 0.5);
	if (!world.setTransformTrs(camera, 0, 2, 5.6, cameraQx, 0, 0, cameraQw, 1, 1, 1)) {
		throw new Error("Failed to add camera Transform3D.");
	}
	if (!world.setGlobalTransform(camera, identity())) {
		throw new Error("Failed to add camera GlobalTransform.");
	}
	if (
		!addOrbitCameraControllerWithPose(
			world,
			camera,
			orbitControllerComponent,
			0,
			cameraElevation,
			0,
			cameraPanY,
			1,
			cameraDistance,
		)
	) {
		throw new Error("Failed to add OrbitCameraController.");
	}
	if (!setCameraHomeFromCurrentTransform(world, camera, cameraHomeComponent)) {
		throw new Error("Failed to add CameraHomeTransform.");
	}
	if (
		!setCameraLensOrthographic(
			world,
			camera,
			cameraLensComponent,
			0.1,
			50,
			1,
			3.8,
			0,
		)
	) {
		throw new Error("Failed to add CameraLens.");
	}
	scene.setMainCamera(camera);
	scene.addCommonSystems({
		orbitControllerComponent,
		homeComponent: cameraHomeComponent,
		updateOrbitCameraControllerFromInput:
			updateOrbitCameraControllerComponentFromInput,
		syncOrbitCameraTransform: syncOrbitCameraTransformComponent,
	});
	scene.installCommonSystems({ transformPropagation: false });
	syncOrbitCameraTransformComponent(
		world,
		camera,
		orbitControllerComponent,
		cameraHomeComponent,
	);
	syncOrbitCameraBlobComponent(
		world,
		camera,
		orbitControllerComponent,
		cameraLensComponent,
	);
	const cameraStorage = createCameraWordsBuffer(demo.device, world);
	drainAndUploadCameraWrites(demo.queue, cameraStorage, world);
	const cameraBindGroup = cameraWordsBindGroup(demo.device, demo.pipeline, cameraStorage);
	demo.surfaces.push({
		id,
		input,
		scene,
		world,
		camera,
		orbitControllerComponent,
		cameraLensComponent,
		cameraStorage,
		cameraBindGroup,
		depthTexture: texture,
		depthView: view,
	});
	demo.engine.setSurfaceScene(id, scene);
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

function surfaceState(demo: DemoState, id: SurfaceId): SurfaceRenderState {
	const state = demo.surfaces.find((surface) => surface.id === id);
	if (state === undefined) {
		throw new Error(`Unknown surface ${id}`);
	}
	return state;
}

function handleInput(surface: SurfaceRenderState): void {
	updateOrbitCameraControllerComponentFromInput(
		surface.world,
		surface.camera,
		surface.orbitControllerComponent,
		surface.input,
	);
}

function writeObjects(demo: DemoState, surface: SurfaceRenderState, frame: FrameState): void {
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
	drainAndUploadCameraWrites(demo.queue, surface.cameraStorage, surface.world);
	const sun = multiply(rotateY(t * 0.35), scale(0.55));
	const earth = multiply(multiply(rotateY(t * 0.9), translate(2.35, 0, 0)), multiply(rotateY(t * 2.2), scale(0.22)));
	const moon = multiply(earth, multiply(multiply(rotateY(t * 2.8), translate(1.05, 0, 0)), scale(0.11)));
	const colors = [[1, 0.65, 0.15, 1], [0.2, 0.55, 1, 1], [1, 0, 1, 1]];
	const out = new Float32Array(OBJECT_STRIDE_FLOATS * 3);
	for (const [index, model] of [sun, earth, moon].entries()) {
		out.set(model, index * OBJECT_STRIDE_FLOATS);
		out.set(colors[index], index * OBJECT_STRIDE_FLOATS + 16);
	}
	demo.queue.writeBuffer(demo.objectBuffer, 0, out);
}

function resizeDepthIfNeeded(demo: DemoState, surface: SurfaceRenderState, frame: FrameState): void {
	if (!frame.surfaceChanged || !frame.surface.active) {
		return;
	}
	surface.depthTexture.destroy();
	const depth = createDepth(demo.device, frame.surface.width, frame.surface.height);
	surface.depthTexture = depth.texture;
	surface.depthView = depth.view;
}

function renderSurface(demo: DemoState, frame: FrameState): void {
	if (frame.surfaceId === undefined || !frame.surface.active) {
		return;
	}
	const surface = surfaceState(demo, frame.surfaceId);
	writeObjects(demo, surface, frame);
	const gpuSurface: GpuSurface = demo.engine.surfaceGpuSurface(frame.surfaceId);
	const colorView = gpuSurface.acquireView();
	const encoder = demo.device.createCommandEncoder();
	const surfaceIndex = surfaceStateIndex(demo, frame.surfaceId);
	const clearValue =
		surfaceIndex === 0
			? { r: 0.02, g: 0.04, b: 0.12, a: 1 }
			: { r: 0.02, g: 0.11, b: 0.07, a: 1 };
	const pass = encoder.beginRenderPass({
		colorAttachments: [{ view: colorView, clearValue, loadOp: "clear", storeOp: "store" }],
		depthStencilAttachment: { view: surface.depthView, depthClearValue: 1, depthLoadOp: "clear", depthStoreOp: "store" },
	});
	pass.setPipeline(demo.pipeline);
	pass.setBindGroup(0, demo.bindGroup);
	pass.setBindGroup(1, surface.cameraBindGroup);
	pass.setVertexBuffer(0, demo.vertexBuffer);
	pass.setIndexBuffer(demo.indexBuffer, "uint16");
	pass.drawIndexed(INDEX_COUNT, 3);
	pass.end();
	demo.queue.submit([encoder.finish()]);
}

function registerEngineHandlers(engine: Engine, demo: DemoState): void {
	engine.addPhaseHandler(Phase.Startup, () => {
		for (let index = 0; index < engine.surfaceCount(); index += 1) {
			ensureSurfaceState(demo, engine.surfaceIdAt(index));
		}
	});
	engine.addPhaseHandler(Phase.Surface, (_engine, frame) => {
		if (frame.surfaceId !== undefined) {
			resizeDepthIfNeeded(demo, ensureSurfaceState(demo, frame.surfaceId), frame);
		}
	});
	engine.addPhaseHandler(Phase.Input, (_engine, frame) => {
		if (frame.surfaceId !== undefined) {
			handleInput(ensureSurfaceState(demo, frame.surfaceId));
		}
	});
	engine.addPhaseHandler(Phase.Render, (_engine, frame) => renderSurface(demo, frame), PhaseSlot.AfterSystems);
	engine.addPhaseHandler(Phase.Shutdown, () => {
		for (const surface of demo.surfaces) {
			surface.depthTexture.destroy();
			surface.cameraStorage.destroy();
		}
		demo.vertexBuffer.destroy();
		demo.indexBuffer.destroy();
		demo.objectBuffer.destroy();
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
	Promise.resolve(initialize(requireCanvas("webgpu-canvas-a"), requireCanvas("webgpu-canvas-b"))).catch((error: unknown) => {
		console.error("Failed to initialize TypeScript multi-surface demo:", error);
		document.body.innerHTML = "<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
	});
});
