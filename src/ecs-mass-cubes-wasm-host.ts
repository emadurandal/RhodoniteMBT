import "./style.css";

const ENTITY_COUNT = 600_000;
const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;
const VERTEX_STRIDE_LOCAL = 12;
const INSTANCE_STRIDE = 16;
const VERTS_PER_CUBE = 8;
const INDEX_U16_COUNT = 36;
const CAMERA_ELEVATION_RAD = 0.42;
const GRID_SPACING = 0.14;
const CUBE_SCALE = 0.055;

type Mat4 = Float32Array;

type Renderer = {
	readonly context: GPUCanvasContext;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly pipeline: GPURenderPipeline;
	readonly depthView: GPUTextureView;
	readonly vertexBuffer: GPUBuffer;
	readonly instanceBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly transformStorage: GPUBuffer;
	readonly bindTransforms: GPUBindGroup;
	readonly bindCamera: GPUBindGroup;
	readonly transformData: Float32Array;
	perSide: number;
	transformStride: number;
};

type WasmExports = {
	_start?: () => void;
	memory?: WebAssembly.Memory;
	create_wasm_renderer: () => void;
	ecs_mass_cubes_wasm_render_tick: () => void;
};

function gridSideLen(count: number): number {
	return Math.ceil(Math.sqrt(count));
}

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(
		offset,
		value,
		true,
	);
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setUint16(
		offset,
		value,
		true,
	);
}

function mat4Identity(): Mat4 {
	const out = new Float32Array(16);
	out[0] = 1;
	out[5] = 1;
	out[10] = 1;
	out[15] = 1;
	return out;
}

function mat4Translation(x: number, y: number, z: number): Mat4 {
	const out = mat4Identity();
	out[12] = x;
	out[13] = y;
	out[14] = z;
	return out;
}

function mat4RotationX(rad: number): Mat4 {
	const out = mat4Identity();
	const c = Math.cos(rad);
	const s = Math.sin(rad);
	out[5] = c;
	out[6] = s;
	out[9] = -s;
	out[10] = c;
	return out;
}

function mat4Mul(a: Mat4, b: Mat4): Mat4 {
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

function mat4Ortho(
	left: number,
	right: number,
	bottom: number,
	top: number,
	near: number,
	far: number,
): Mat4 {
	const out = new Float32Array(16);
	out[0] = 2 / (right - left);
	out[5] = 2 / (top - bottom);
	out[10] = 1 / (near - far);
	out[12] = -(right + left) / (right - left);
	out[13] = -(top + bottom) / (top - bottom);
	out[14] = near / (near - far);
	out[15] = 1;
	return out;
}

function transformPoint(m: Mat4, x: number, y: number, z: number): [number, number, number] {
	return [
		m[0] * x + m[4] * y + m[8] * z + m[12],
		m[1] * x + m[5] * y + m[9] * z + m[13],
		m[2] * x + m[6] * y + m[10] * z + m[14],
	];
}

function viewSpaceRangeCorners(
	viewRot: Mat4,
	extentXz: number,
	waveY: number,
	axis: 1 | 2,
): [number, number] {
	const sides = [-1, 1];
	let min = 0;
	let max = 0;
	let first = true;
	for (const sx of sides) {
		for (const sy of sides) {
			for (const sz of sides) {
				const v = transformPoint(
					viewRot,
					sx * extentXz,
					sy * waveY,
					sz * extentXz,
				)[axis];
				if (first) {
					min = v;
					max = v;
					first = false;
				} else {
					min = Math.min(min, v);
					max = Math.max(max, v);
				}
			}
		}
	}
	return [min, max];
}

function cameraUniformBytes(): Uint8Array {
	const viewRot = mat4Mul(
		mat4RotationX(CAMERA_ELEVATION_RAD),
		mat4Translation(0, 0, -16),
	);
	const perSide = gridSideLen(ENTITY_COUNT);
	const half = (perSide - 1) * 0.5;
	const extentXz = half * GRID_SPACING;
	const wave = 0.12;
	const margin = CUBE_SCALE * 2.5;
	const waveY = wave + CUBE_SCALE * 1.1;
	const [yLo, yHi] = viewSpaceRangeCorners(viewRot, extentXz, waveY, 1);
	const cy = (yLo + yHi) * 0.5;
	let halfH = (yHi - yLo) * 0.5 + margin;
	let halfW = extentXz + margin;
	const aspect = CANVAS_WIDTH / CANVAS_HEIGHT;
	if (halfW / halfH < aspect) {
		halfW = halfH * aspect;
	} else {
		halfH = halfW / aspect;
	}
	const [zLo, zHi] = viewSpaceRangeCorners(viewRot, extentXz, waveY, 2);
	const pullZ = zHi > -0.15 ? -zHi - 1 : 0;
	const view = mat4Mul(mat4Translation(0, 0, pullZ), viewRot);
	const farNeed = -(zLo + pullZ) + 8;
	const farClip = Math.max(farNeed, 80);
	const proj = mat4Ortho(-halfW, halfW, cy - halfH, cy + halfH, 0.1, farClip);
	const vp = mat4Mul(proj, view);
	const bytes = new Uint8Array(256);
	new Float32Array(bytes.buffer, 0, 16).set(vp);
	return bytes;
}

function cubeLocalCorners(): [number, number, number][] {
	return [
		[-1, -1, -1],
		[1, -1, -1],
		[1, 1, -1],
		[-1, 1, -1],
		[-1, -1, 1],
		[1, -1, 1],
		[1, 1, 1],
		[-1, 1, 1],
	];
}

function vertexPositionBytes(scale: number): Uint8Array {
	const bytes = new Uint8Array(VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL);
	cubeLocalCorners().forEach(([x, y, z], vertexIndex) => {
		const base = vertexIndex * VERTEX_STRIDE_LOCAL;
		writeF32(bytes, base, x * scale);
		writeF32(bytes, base + 4, y * scale);
		writeF32(bytes, base + 8, z * scale);
	});
	return bytes;
}

function indexCubeU16Bytes(): Uint8Array {
	const indices = [
		0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 0, 4, 7, 7, 3, 0, 1, 5, 6, 6, 2,
		1, 0, 1, 5, 5, 4, 0, 3, 2, 6, 6, 7, 3,
	];
	const bytes = new Uint8Array(indices.length * 2);
	indices.forEach((index, i) => writeU16(bytes, i * 2, index));
	return bytes;
}

function instanceColorRgb(index: number): [number, number, number] {
	const i = index % 125;
	return [
		(i % 5) * 0.22 + 0.12,
		(Math.floor(i / 5) % 5) * 0.22 + 0.08,
		(Math.floor(i / 25) % 5) * 0.22 + 0.1,
	];
}

function instanceBytes(): Uint8Array {
	const bytes = new Uint8Array(ENTITY_COUNT * INSTANCE_STRIDE);
	const view = new Float32Array(bytes.buffer);
	for (let index = 0; index < ENTITY_COUNT; index += 1) {
		const [r, g, b] = instanceColorRgb(index);
		const base = index * 4;
		view[base] = index;
		view[base + 1] = r;
		view[base + 2] = g;
		view[base + 3] = b;
	}
	return bytes;
}

function writeMassCubesFullTransformData(
	renderer: Renderer,
	perSide: number,
	waveTime: number,
): void {
	if (renderer.transformStride !== 48) {
		throw new Error(`Unsupported transform stride: ${renderer.transformStride}`);
	}
	const matrices = renderer.transformData;
	const half = (perSide - 1) * 0.5;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let row = 0;
	let column = 0;
	let out = 0;
	while (localIndex < ENTITY_COUNT) {
		const rowCount = Math.min(perSide - column, ENTITY_COUNT - localIndex);
		let x = (column - half) * GRID_SPACING;
		const z = (row - half) * GRID_SPACING;
		let waveSin = Math.sin(localIndex * 0.09 + waveTime);
		let waveCos = Math.cos(localIndex * 0.09 + waveTime);
		for (let ix = 0; ix < rowCount; ix += 1) {
			matrices[out] = CUBE_SCALE;
			matrices[out + 1] = 0;
			matrices[out + 2] = 0;
			matrices[out + 3] = x;
			matrices[out + 4] = 0;
			matrices[out + 5] = CUBE_SCALE;
			matrices[out + 6] = 0;
			matrices[out + 7] = waveSin * 0.12;
			matrices[out + 8] = 0;
			matrices[out + 9] = 0;
			matrices[out + 10] = CUBE_SCALE;
			matrices[out + 11] = z;

			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			localIndex += 1;
			out += 12;
			x += GRID_SPACING;
		}
		row += 1;
		column = 0;
	}
}

function writeMassCubesYTransformData(renderer: Renderer, waveTime: number): void {
	if (renderer.transformStride !== 48) {
		throw new Error(`Unsupported transform stride: ${renderer.transformStride}`);
	}
	const matrices = renderer.transformData;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let out = 0;
	let waveSin = Math.sin(waveTime);
	let waveCos = Math.cos(waveTime);
	while (localIndex < ENTITY_COUNT) {
		matrices[out + 7] = waveSin * 0.12;
		const nextSin = waveSin * cosStep + waveCos * sinStep;
		waveCos = waveCos * cosStep - waveSin * sinStep;
		waveSin = nextSin;
		localIndex += 1;
		out += 12;
	}
}

function writeTransformBytesFromWasmMemory(
	renderer: Renderer,
	memory: WebAssembly.Memory | undefined,
	ptr: number,
	byteLength: number,
): void {
	if (memory === undefined) {
		throw new Error("WASM linear memory is not exported.");
	}
	if (ptr <= 0 || byteLength <= 0) {
		throw new Error(`Invalid WASM transform byte range: ${ptr}, ${byteLength}`);
	}
	renderer.queue.writeBuffer(
		renderer.transformStorage,
		0,
		new Uint8Array(memory.buffer, ptr, byteLength),
	);
}

function shaderWgsl(): string {
	return `
struct CameraUniform {
  view_proj: mat4x4<f32>,
}

struct WorldAffine3x4 {
  row0: vec4<f32>,
  row1: vec4<f32>,
  row2: vec4<f32>,
}

@group(0) @binding(0) var<storage, read> world_from_entity: array<WorldAffine3x4>;
@group(1) @binding(0) var<uniform> camera: CameraUniform;

struct VertexOut {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec3<f32>,
};

@vertex
fn vertexMain(
  @location(0) local_pos: vec3<f32>,
  @location(1) inst: vec4<f32>,
) -> VertexOut {
  let idx = u32(inst.x);
  let color = vec3<f32>(inst.y, inst.z, inst.w);
  let world_m = world_from_entity[idx];
  let local_h = vec4<f32>(local_pos, 1.0);
  let world_pos = vec4<f32>(
    dot(world_m.row0, local_h),
    dot(world_m.row1, local_h),
    dot(world_m.row2, local_h),
    1.0,
  );
  let clip = camera.view_proj * world_pos;
  var o: VertexOut;
  o.position = clip;
  o.color = color;
  return o;
}

@fragment
fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  return vec4<f32>(color, 1.0);
}
`;
}

async function createRenderer(canvas: HTMLCanvasElement): Promise<Renderer> {
	const adapter = await navigator.gpu.requestAdapter();
	if (adapter === null) {
		throw new Error("WebGPU adapter is not available.");
	}
	const device = await adapter.requestDevice();
	const queue = device.queue;
	const context = canvas.getContext("webgpu");
	if (context === null) {
		throw new Error("WebGPU canvas context is not available.");
	}
	const format = navigator.gpu.getPreferredCanvasFormat();
	context.configure({ device, format, alphaMode: "opaque" });

	const shader = device.createShaderModule({ code: shaderWgsl() });
	const pipeline = device.createRenderPipeline({
		layout: "auto",
		vertex: {
			module: shader,
			entryPoint: "vertexMain",
			buffers: [
				{
					arrayStride: VERTEX_STRIDE_LOCAL,
					stepMode: "vertex",
					attributes: [{ shaderLocation: 0, offset: 0, format: "float32x3" }],
				},
				{
					arrayStride: INSTANCE_STRIDE,
					stepMode: "instance",
					attributes: [{ shaderLocation: 1, offset: 0, format: "float32x4" }],
				},
			],
		},
		fragment: {
			module: shader,
			entryPoint: "fragmentMain",
			targets: [{ format }],
		},
		primitive: { topology: "triangle-list" },
		depthStencil: {
			format: "depth24plus",
			depthWriteEnabled: true,
			depthCompare: "less",
		},
	});

	const transformStorage = device.createBuffer({
		size: ENTITY_COUNT * 48,
		usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
	});
	const cameraUniform = device.createBuffer({
		size: 256,
		usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(cameraUniform, 0, cameraUniformBytes());

	const bindTransforms = device.createBindGroup({
		layout: pipeline.getBindGroupLayout(0),
		entries: [{ binding: 0, resource: { buffer: transformStorage } }],
	});
	const bindCamera = device.createBindGroup({
		layout: pipeline.getBindGroupLayout(1),
		entries: [{ binding: 0, resource: { buffer: cameraUniform } }],
	});

	const vertexBuffer = device.createBuffer({
		size: VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL,
		usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(vertexBuffer, 0, vertexPositionBytes(0.42));
	const instanceBuffer = device.createBuffer({
		size: ENTITY_COUNT * INSTANCE_STRIDE,
		usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(instanceBuffer, 0, instanceBytes());
	const indexData = indexCubeU16Bytes();
	const indexBuffer = device.createBuffer({
		size: indexData.byteLength,
		usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(indexBuffer, 0, indexData);
	const depthTexture = device.createTexture({
		size: [CANVAS_WIDTH, CANVAS_HEIGHT],
		format: "depth24plus",
		usage: GPUTextureUsage.RENDER_ATTACHMENT,
	});

	return {
		context,
		device,
		queue,
		pipeline,
		depthView: depthTexture.createView(),
		vertexBuffer,
		instanceBuffer,
		indexBuffer,
		transformStorage,
		bindTransforms,
		bindCamera,
		transformData: new Float32Array(ENTITY_COUNT * 12),
		perSide: gridSideLen(ENTITY_COUNT),
		transformStride: 48,
	};
}

function updatePerfOverlay(label: string, fps: number, cpuMs: number): void {
	const el = document.getElementById("ecs-mass-cubes-perf");
	if (el === null) {
		return;
	}
	el.textContent = `FPS ${fps.toFixed(1)}  ·  ${label} ${cpuMs.toFixed(2)} ms / frame (submit まで)`;
}

function createHostImports(
	renderer: Renderer,
	label: string,
	getMemory: () => WebAssembly.Memory | undefined,
): WebAssembly.Imports {
	return {
		rhodonite_ecs_mass_cubes_host: {
			now_ms: () => performance.now(),
			initialize_renderer: (perSide: number, transformStride: number) => {
				renderer.perSide = perSide;
				renderer.transformStride = transformStride;
			},
			write_initial_global_transforms: (perSide: number, waveTime: number) => {
				writeMassCubesFullTransformData(renderer, perSide, waveTime);
				renderer.queue.writeBuffer(renderer.transformStorage, 0, renderer.transformData);
			},
			write_global_transform_y: (waveTime: number) => {
				writeMassCubesYTransformData(renderer, waveTime);
				renderer.queue.writeBuffer(renderer.transformStorage, 0, renderer.transformData);
			},
			write_initial_global_transform_bytes: (ptr: number, byteLength: number) => {
				writeTransformBytesFromWasmMemory(renderer, getMemory(), ptr, byteLength);
			},
			write_global_transform_bytes: (ptr: number, byteLength: number) => {
				writeTransformBytesFromWasmMemory(renderer, getMemory(), ptr, byteLength);
			},
			render_frame: (fps: number, cpuMs: number) => {
				const colorView = renderer.context.getCurrentTexture().createView();
				const encoder = renderer.device.createCommandEncoder();
				const pass = encoder.beginRenderPass({
					colorAttachments: [
						{
							view: colorView,
							clearValue: { r: 0.03, g: 0.04, b: 0.09, a: 1 },
							loadOp: "clear",
							storeOp: "store",
						},
					],
					depthStencilAttachment: {
						view: renderer.depthView,
						depthClearValue: 1,
						depthLoadOp: "clear",
						depthStoreOp: "store",
					},
				});
				pass.setPipeline(renderer.pipeline);
				pass.setBindGroup(0, renderer.bindTransforms);
				pass.setBindGroup(1, renderer.bindCamera);
				pass.setIndexBuffer(renderer.indexBuffer, "uint16", 0, INDEX_U16_COUNT * 2);
				pass.setVertexBuffer(
					0,
					renderer.vertexBuffer,
					0,
					VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL,
				);
				pass.setVertexBuffer(
					1,
					renderer.instanceBuffer,
					0,
					ENTITY_COUNT * INSTANCE_STRIDE,
				);
				pass.drawIndexed(INDEX_U16_COUNT, ENTITY_COUNT);
				pass.end();
				renderer.queue.submit([encoder.finish()]);
				updatePerfOverlay(label, fps, cpuMs);
			},
		},
	};
}

async function instantiateWasm(
	renderer: Renderer,
	wasmUrl: string,
	label: string,
): Promise<WasmExports> {
	const bytes = await fetch(wasmUrl).then((response) => {
		if (!response.ok) {
			throw new Error(`Failed to fetch WASM module: ${response.status}`);
		}
		return response.arrayBuffer();
	});
	let memory: WebAssembly.Memory | undefined;
	const { instance } = await WebAssembly.instantiate(
		bytes,
		createHostImports(renderer, label, () => memory),
	);
	const exports = instance.exports as unknown as WasmExports;
	memory = exports.memory;
	return exports;
}

export function runEcsMassCubesWasmDemo(wasmUrl: string, label: string): void {
	if (!navigator.gpu) {
		document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
		return;
	}

	window.addEventListener("load", () => {
		const canvas = document.getElementById("webgpu-canvas");
		if (!(canvas instanceof HTMLCanvasElement)) {
			document.body.innerHTML = "<h1>Missing WebGPU canvas.</h1>";
			return;
		}
		void createRenderer(canvas)
			.then(async (renderer) => {
				const wasm = await instantiateWasm(renderer, wasmUrl, label);
				wasm._start?.();
				wasm.create_wasm_renderer();
				const loop = () => {
					wasm.ecs_mass_cubes_wasm_render_tick();
					requestAnimationFrame(loop);
				};
				requestAnimationFrame(loop);
			})
			.catch((error: unknown) => {
				console.error("Failed to initialize WebGPU/WASM:", error);
				document.body.innerHTML =
					"<h1>Failed to initialize WebGPU/WASM. Check the console for errors.</h1>";
			});
	});
}
