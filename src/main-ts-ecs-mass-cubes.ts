import "./style.css";
import {
	Query,
	World,
	type ByteView,
	type ComponentTypeId,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";

const ENTITY_COUNT = 800_000;
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
	readonly canvas: HTMLCanvasElement;
	readonly context: GPUCanvasContext;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly pipeline: GPURenderPipeline;
	readonly depthTexture: GPUTexture;
	readonly depthView: GPUTextureView;
	readonly vertexBuffer: GPUBuffer;
	readonly instanceBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly transformStorage: GPUBuffer;
	readonly cameraUniform: GPUBuffer;
	readonly bindTransforms: GPUBindGroup;
	readonly bindCamera: GPUBindGroup;
	readonly world: World;
	readonly transformComponent: ComponentTypeId;
	readonly globalTransformComponent: ComponentTypeId;
	readonly perSide: number;
	frame: number;
	lastFrameStartMs: number;
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

function gridXzForIndex(index: number, perSide: number): [number, number] {
	const ix = index % perSide;
	const iz = Math.floor(index / perSide);
	const half = (perSide - 1) * 0.5;
	return [(ix - half) * GRID_SPACING, (iz - half) * GRID_SPACING];
}

function instanceBytes(indices: number[]): Uint8Array {
	const bytes = new Uint8Array(indices.length * INSTANCE_STRIDE);
	indices.forEach((index, i) => {
		const [r, g, b] = instanceColorRgb(index);
		const base = i * INSTANCE_STRIDE;
		writeF32(bytes, base, index);
		writeF32(bytes, base + 4, r);
		writeF32(bytes, base + 8, g);
		writeF32(bytes, base + 12, b);
	});
	return bytes;
}

function initializeTransformRows(
	world: World,
	transformComponent: ComponentTypeId,
	perSide: number,
): void {
	Query.new([transformComponent]).forEach(world, (row) => {
		const index = row.entity().index();
		const [x, z] = gridXzForIndex(index, perSide);
		row.write(transformComponent, (bytes) => {
			bytes.setF32(0, x);
			bytes.setF32(4, 0);
			bytes.setF32(8, z);
			bytes.setF32(12, 0);
			bytes.setF32(16, 0);
			bytes.setF32(20, 0);
			bytes.setF32(24, 1);
			bytes.setF32(28, CUBE_SCALE);
			bytes.setF32(32, CUBE_SCALE);
			bytes.setF32(36, CUBE_SCALE);
			bytes.setF32(40, 0);
			bytes.setF32(44, 0);
		});
	});
}

function animateTransformsQuery(
	world: World,
	transformComponent: ComponentTypeId,
	perSide: number,
	t: number,
): void {
	Query.new([transformComponent]).forEach(world, (row) => {
		const index = row.entity().index();
		const [x, z] = gridXzForIndex(index, perSide);
		const y = Math.sin(index * 0.09 + t * 1.8) * 0.12;
		row.write(transformComponent, (bytes) => {
			bytes.setF32(0, x);
			bytes.setF32(4, y);
			bytes.setF32(8, z);
		});
	});
}

function uploadGlobalTransformWrites(
	queue: GPUQueue,
	buffer: GPUBuffer,
	writes: ReturnType<World["drainGpuWriteViews"]>,
): void {
	for (const write of writes) {
		const bytes = write.bytes();
		queue.writeBuffer(
			buffer,
			write.byteOffset(),
			bytes.asUint8Array() ?? bytes.toUint8ArrayCopy(),
		);
	}
}

function rangeAsF32(bytes: ByteView): Float32Array | null {
	const view = bytes.asUint8Array();
	if (view === null || (view.byteOffset & 3) !== 0) {
		return null;
	}
	return new Float32Array(view.buffer, view.byteOffset, view.byteLength >> 2);
}

function writeMassCubesFullRange(
	bytes: ByteView,
	stride: number,
	firstEntityIndex: number,
	count: number,
	perSide: number,
	waveTime: number,
): void {
	const matrices = rangeAsF32(bytes);
	if (matrices === null || stride !== 48) {
		for (let i = 0; i < count; i += 1) {
			const index = firstEntityIndex + i;
			const [x, z] = gridXzForIndex(index, perSide);
			const y = Math.sin(index * 0.09 + waveTime) * 0.12;
			const base = i * stride;
			bytes.setF32(base, CUBE_SCALE);
			bytes.setF32(base + 4, 0);
			bytes.setF32(base + 8, 0);
			bytes.setF32(base + 12, x);
			bytes.setF32(base + 16, 0);
			bytes.setF32(base + 20, CUBE_SCALE);
			bytes.setF32(base + 24, 0);
			bytes.setF32(base + 28, y);
			bytes.setF32(base + 32, 0);
			bytes.setF32(base + 36, 0);
			bytes.setF32(base + 40, CUBE_SCALE);
			bytes.setF32(base + 44, z);
		}
		return;
	}

	const half = (perSide - 1) * 0.5;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let row = Math.trunc(firstEntityIndex / perSide);
	let column = firstEntityIndex % perSide;
	let out = 0;
	while (localIndex < count) {
		const rowCount = Math.min(perSide - column, count - localIndex);
		let x = (column - half) * GRID_SPACING;
		const z = (row - half) * GRID_SPACING;
		const globalIndex = firstEntityIndex + localIndex;
		let waveSin = Math.sin(globalIndex * 0.09 + waveTime);
		let waveCos = Math.cos(globalIndex * 0.09 + waveTime);
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

function writeMassCubesYRange(
	bytes: ByteView,
	stride: number,
	firstEntityIndex: number,
	count: number,
	waveTime: number,
): void {
	const matrices = rangeAsF32(bytes);
	if (matrices === null || stride !== 48) {
		for (let i = 0; i < count; i += 1) {
			const index = firstEntityIndex + i;
			bytes.setF32(i * stride + 28, Math.sin(index * 0.09 + waveTime) * 0.12);
		}
		return;
	}

	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let out = 0;
	let waveSin = Math.sin(firstEntityIndex * 0.09 + waveTime);
	let waveCos = Math.cos(firstEntityIndex * 0.09 + waveTime);
	while (localIndex < count) {
		matrices[out + 7] = waveSin * 0.12;
		const nextSin = waveSin * cosStep + waveCos * sinStep;
		waveCos = waveCos * cosStep - waveSin * sinStep;
		waveSin = nextSin;
		localIndex += 1;
		out += 12;
	}
}

function uploadInitialGlobalTransforms(renderer: Renderer): void {
	uploadGlobalTransformWrites(
		renderer.queue,
		renderer.transformStorage,
		renderer.world.writeGlobalTransformsDenseRangeViews(
			ENTITY_COUNT,
			(bytes, stride, firstEntityIndex, count) =>
				writeMassCubesFullRange(
					bytes,
					stride,
					firstEntityIndex,
					count,
					renderer.perSide,
					0,
				),
		),
	);
}

function updateAndDrainGlobalTransforms(renderer: Renderer, t: number): void {
	const waveTime = t * 1.8;
	const writes = renderer.world.writeGlobalTransformsDenseRangeViews(
		ENTITY_COUNT,
		(bytes, stride, firstEntityIndex, count) =>
			writeMassCubesYRange(
				bytes,
				stride,
				firstEntityIndex,
				count,
				waveTime,
			),
	);
	if (writes.length > 0) {
		uploadGlobalTransformWrites(renderer.queue, renderer.transformStorage, writes);
		return;
	}

	const fullWrites = renderer.world.writeGlobalTransformsDenseRangeViews(
		ENTITY_COUNT,
		(bytes, stride, firstEntityIndex, count) =>
			writeMassCubesFullRange(
				bytes,
				stride,
				firstEntityIndex,
				count,
				renderer.perSide,
				waveTime,
			),
	);
	if (fullWrites.length > 0) {
		uploadGlobalTransformWrites(renderer.queue, renderer.transformStorage, fullWrites);
		return;
	}

	animateTransformsQuery(
		renderer.world,
		renderer.transformComponent,
		renderer.perSide,
		t,
	);
	renderer.world.updateGlobalTransformsFromTransforms();
	uploadGlobalTransformWrites(
		renderer.queue,
		renderer.transformStorage,
		renderer.world.drainGpuWriteViews(renderer.globalTransformComponent),
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

	const world = World.new();
	const globalTransformComponent = world.globalTransformComponent();
	const transformComponent = world.transformComponent();
	const perSide = gridSideLen(ENTITY_COUNT);
	const entities = world.spawnTransformGlobalBatchIdentity(ENTITY_COUNT);
	initializeTransformRows(world, transformComponent, perSide);
	const maxIndexSlot = entities.reduce(
		(max, entity) => Math.max(max, entity.index() + 1),
		0,
	);
	const resizeCapacity = world
		.drainResizeEvents()
		.filter((event) => event.component().index() === globalTransformComponent.index())
		.reduce((max, event) => Math.max(max, event.requiredCapacity()), 0);
	const transformStride = world.componentGpuLayout(globalTransformComponent)?.stride() ?? 48;
	const transformStorage = device.createBuffer({
		size: Math.max(maxIndexSlot, resizeCapacity) * transformStride,
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
	const instanceData = instanceBytes(entities.map((entity) => entity.index()));
	const instanceBuffer = device.createBuffer({
		size: instanceData.byteLength,
		usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(instanceBuffer, 0, instanceData);
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
	const depthView = depthTexture.createView();

	const renderer: Renderer = {
		canvas,
		context,
		device,
		queue,
		pipeline,
		depthTexture,
		depthView,
		vertexBuffer,
		instanceBuffer,
		indexBuffer,
		transformStorage,
		cameraUniform,
		bindTransforms,
		bindCamera,
		world,
		transformComponent,
		globalTransformComponent,
		perSide,
		frame: 0,
		lastFrameStartMs: -1,
	};
	uploadInitialGlobalTransforms(renderer);
	return renderer;
}

function updatePerfOverlay(fps: number, cpuMs: number): void {
	const el = document.getElementById("ecs-mass-cubes-perf");
	if (el === null) {
		return;
	}
	el.textContent = `FPS ${fps.toFixed(1)}  ·  CPU ${cpuMs.toFixed(2)} ms / frame (submit まで)`;
}

function renderFrame(renderer: Renderer): void {
	const frameStart = performance.now();
	const fps =
		renderer.lastFrameStartMs >= 0
			? 1000 / Math.max(frameStart - renderer.lastFrameStartMs, 1.0e-9)
			: 0;
	renderer.lastFrameStartMs = frameStart;
	renderer.frame += 1;
	updateAndDrainGlobalTransforms(renderer, renderer.frame * 0.018);

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
	pass.setVertexBuffer(0, renderer.vertexBuffer, 0, VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL);
	pass.setVertexBuffer(1, renderer.instanceBuffer, 0, ENTITY_COUNT * INSTANCE_STRIDE);
	pass.drawIndexed(INDEX_U16_COUNT, ENTITY_COUNT);
	pass.end();
	renderer.queue.submit([encoder.finish()]);
	updatePerfOverlay(fps, performance.now() - frameStart);
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
		void createRenderer(canvas)
			.then((renderer) => {
				const loop = () => {
					renderFrame(renderer);
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
