import "./style.css";
import {
	Engine,
	GpuSurface,
	InputState,
	MouseButton,
	Phase,
	PhaseSlot,
	PlatformOptions,
	Scene,
	attachCanvasSurface,
	installBrowserInputState,
	startBrowserFrameLoop,
	type FrameState,
	type SurfaceId,
} from "./app-runtime";

type SurfaceRenderState = {
	readonly id: SurfaceId;
	readonly input: InputState;
	depthTexture: GPUTexture;
	depthView: GPUTextureView;
	yaw: number;
	pitch: number;
	dolly: number;
	baseDistance: number;
	panX: number;
	panY: number;
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

function normalize(v: [number, number, number]): [number, number, number] {
	const len = Math.hypot(v[0], v[1], v[2]) || 1;
	return [v[0] / len, v[1] / len, v[2] / len];
}

function cross(a: [number, number, number], b: [number, number, number]): [number, number, number] {
	return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
}

function dot(a: [number, number, number], b: [number, number, number]): number {
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

function lookAt(eye: [number, number, number], center: [number, number, number], up: [number, number, number]): Float32Array {
	const f = normalize([center[0] - eye[0], center[1] - eye[1], center[2] - eye[2]]);
	const s = normalize(cross(f, up));
	const u = cross(s, f);
	return new Float32Array([
		s[0], u[0], -f[0], 0,
		s[1], u[1], -f[1], 0,
		s[2], u[2], -f[2], 0,
		-dot(s, eye), -dot(u, eye), dot(f, eye), 1,
	]);
}

function orthographic(aspect: number, halfHeight: number, near = 0.1, far = 50): Float32Array {
	const halfWidth = halfHeight * aspect;
	const left = -halfWidth;
	const right = halfWidth;
	const bottom = -halfHeight;
	const top = halfHeight;
	return new Float32Array([
		2 / (right - left), 0, 0, 0,
		0, 2 / (top - bottom), 0, 0,
		0, 0, 1 / (near - far), 0,
		-(right + left) / (right - left),
		-(top + bottom) / (top - bottom),
		near / (near - far),
		1,
	]);
}

function quatMul(
	a: readonly [number, number, number, number],
	b: readonly [number, number, number, number],
): [number, number, number, number] {
	const [ax, ay, az, aw] = a;
	const [bx, by, bz, bw] = b;
	return [
		aw * bx + ax * bw + ay * bz - az * by,
		aw * by - ax * bz + ay * bw + az * bx,
		aw * bz + ax * by - ay * bx + az * bw,
		aw * bw - ax * bx - ay * by - az * bz,
	];
}

function quatX(angle: number): [number, number, number, number] {
	const half = angle * 0.5;
	return [Math.sin(half), 0, 0, Math.cos(half)];
}

function quatY(angle: number): [number, number, number, number] {
	const half = angle * 0.5;
	return [0, Math.sin(half), 0, Math.cos(half)];
}

function quatRotateVec3(
	q: readonly [number, number, number, number],
	x: number,
	y: number,
	z: number,
): [number, number, number] {
	const [qx, qy, qz, qw] = q;
	const tx = 2 * (qy * z - qz * y);
	const ty = 2 * (qz * x - qx * z);
	const tz = 2 * (qx * y - qy * x);
	return [
		x + qw * tx + (qy * tz - qz * ty),
		y + qw * ty + (qz * tx - qx * tz),
		z + qw * tz + (qx * ty - qy * tx),
	];
}

function createShader(): string {
	return `
struct ObjectData {
  mvp: mat4x4<f32>,
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
  var out: VertexOut;
  out.position = object.mvp * vec4<f32>(localPos, 1.0);
  out.color = object.color;
  return out;
}
@fragment
fn fragmentMain(in: VertexOut) -> @location(0) vec4<f32> {
  return in.color;
}`;
}

function createDemoState(engine: Engine): DemoState {
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
	demo.surfaces.push({
		id,
		input,
		depthTexture: texture,
		depthView: view,
		yaw: 0,
		pitch: cameraElevation,
		dolly: 1,
		baseDistance: cameraDistance,
		panX: 0,
		panY: cameraPanY,
	});
}

function surfaceState(demo: DemoState, id: SurfaceId): SurfaceRenderState {
	const state = demo.surfaces.find((surface) => surface.id === id);
	if (state === undefined) {
		throw new Error(`Unknown surface ${id}`);
	}
	return state;
}

function handleInput(surface: SurfaceRenderState): void {
	const input = surface.input;
	if (input.mouseDown(MouseButton.Left) && !input.mousePressed(MouseButton.Left)) {
		surface.yaw += input.pointerDeltaX() * 0.006;
		surface.pitch = Math.max(-1.25, Math.min(1.25, surface.pitch + input.pointerDeltaY() * 0.006));
	}
	if (input.mouseDown(MouseButton.Middle) && !input.mousePressed(MouseButton.Middle)) {
		surface.panX += input.pointerDeltaX() * 0.01 * surface.dolly;
		surface.panY -= input.pointerDeltaY() * 0.01 * surface.dolly;
	}
	if (input.wheelDeltaY() !== 0) {
		surface.dolly = Math.max(0.01, Math.min(4, surface.dolly + input.wheelDeltaY() * 0.001 * surface.dolly));
	}
}

function writeObjects(demo: DemoState, surface: SurfaceRenderState, frame: FrameState): void {
	const t = frame.elapsedSeconds;
	const aspect = Math.max(frame.surface.width, 1) / Math.max(frame.surface.height, 1);
	const q = quatMul(quatY(-surface.yaw), quatX(-surface.pitch));
	const [dx, dy, dz] = quatRotateVec3(q, -surface.panX, -surface.panY, 0);
	const eye: [number, number, number] = [
		dx,
		dy,
		dz + surface.baseDistance,
	];
	const forward = quatRotateVec3(q, 0, 0, -1);
	const up = quatRotateVec3(q, 0, 1, 0);
	const target: [number, number, number] = [
		eye[0] + forward[0],
		eye[1] + forward[1],
		eye[2] + forward[2],
	];
	const vp = multiply(orthographic(aspect, 3.8 * surface.dolly), lookAt(eye, target, up));
	const sun = multiply(rotateY(t * 0.35), scale(0.55));
	const earth = multiply(multiply(rotateY(t * 0.9), translate(2.35, 0, 0)), multiply(rotateY(t * 2.2), scale(0.22)));
	const moon = multiply(earth, multiply(multiply(rotateY(t * 2.8), translate(1.05, 0, 0)), scale(0.11)));
	const colors = [[1, 0.65, 0.15, 1], [0.2, 0.55, 1, 1], [1, 0, 1, 1]];
	const out = new Float32Array(OBJECT_STRIDE_FLOATS * 3);
	for (const [index, model] of [sun, earth, moon].entries()) {
		out.set(multiply(vp, model), index * OBJECT_STRIDE_FLOATS);
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
	const pass = encoder.beginRenderPass({
		colorAttachments: [{ view: colorView, clearValue: frame.surfaceId === 1 ? { r: 0.02, g: 0.04, b: 0.12, a: 1 } : { r: 0.02, g: 0.11, b: 0.07, a: 1 }, loadOp: "clear", storeOp: "store" }],
		depthStencilAttachment: { view: surface.depthView, depthClearValue: 1, depthLoadOp: "clear", depthStoreOp: "store" },
	});
	pass.setPipeline(demo.pipeline);
	pass.setBindGroup(0, demo.bindGroup);
	pass.setVertexBuffer(0, demo.vertexBuffer);
	pass.setIndexBuffer(demo.indexBuffer, "uint16");
	pass.drawIndexed(INDEX_COUNT, 3);
	pass.end();
	demo.queue.submit([encoder.finish()]);
}

async function initialize(first: HTMLCanvasElement, second: HTMLCanvasElement): Promise<void> {
	const engine = await Engine.create(first, { mainScene: new Scene("ts-multi-surface") });
	const demo = createDemoState(engine);
	const firstId = attachCanvasSurface(engine, first);
	const secondId = attachCanvasSurface(engine, second);
	addSurfaceState(demo, firstId, engine.surfaceInput(firstId));
	addSurfaceState(demo, secondId, engine.surfaceInput(secondId));
	const options = PlatformOptions.interactive();
	const bindings = [
		installBrowserInputState(engine.surfaceInput(firstId), first, { keyboardTarget: options.keyboardTarget, onInput: () => engine.requestRender("input") }),
		installBrowserInputState(engine.surfaceInput(secondId), second, { keyboardTarget: options.keyboardTarget, onInput: () => engine.requestRender("input") }),
	];
	engine.addPhaseHandler(Phase.Surface, (_engine, frame) => {
		if (frame.surfaceId !== undefined) {
			resizeDepthIfNeeded(demo, surfaceState(demo, frame.surfaceId), frame);
		}
	});
	engine.addPhaseHandler(Phase.Input, (_engine, frame) => {
		if (frame.surfaceId !== undefined) {
			handleInput(surfaceState(demo, frame.surfaceId));
		}
	});
	engine.addPhaseHandler(Phase.Render, (_engine, frame) => renderSurface(demo, frame), PhaseSlot.AfterSystems);
	engine.addPhaseHandler(Phase.Shutdown, () => {
		for (const binding of bindings) binding.dispose();
		for (const surface of demo.surfaces) surface.depthTexture.destroy();
		demo.vertexBuffer.destroy();
		demo.indexBuffer.destroy();
		demo.objectBuffer.destroy();
	});
	engine.initialize();
	startBrowserFrameLoop((deltaSeconds) => engine.runMultiSurfaceFrame(deltaSeconds));
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
