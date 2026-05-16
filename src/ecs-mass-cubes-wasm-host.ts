import "./style.css";
import {
	createGlobalTransformWordsBuffer,
	globalTransformHelpersDefault,
	globalTransformRefInstanceVertexBufferLayout,
	globalTransformWordsBindGroup,
	globalTransformWordsBindingDefault,
	uploadGlobalTransformBytes,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	createRgba8ReadbackTarget,
	destroyReadbackTarget,
	readRgba8Texture,
} from "./visual-regression/webgpu-readback";
import { InputState, installBrowserInputState } from "./app-runtime";
import {
	createOrbitCameraController,
	updateOrbitCameraControllerFromInput,
	type OrbitCameraController,
} from "./orbit-camera-controller";

const ENTITY_COUNT = 800_000;
type GlobalTransformPrecisionMode =
	| "all-f32"
	| "all-f16"
	| "first-half-f32-second-half-f16"
	| "even-id-f32-odd-id-f16";
const GLOBAL_TRANSFORM_PRECISION_MODE: GlobalTransformPrecisionMode = "all-f16";
const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;
const VERTEX_STRIDE_LOCAL = 12;
const INSTANCE_STRIDE = 24;
const VERTS_PER_CUBE = 8;
const INDEX_U16_COUNT = 36;
const CAMERA_ELEVATION_RAD = 0.42;
const GRID_SPACING = 0.14;
const CUBE_SCALE = 0.055;
const GLOBAL_TRANSFORM_FORMAT_F32 = 0;
const GLOBAL_TRANSFORM_FORMAT_F16 = 1;
const TRANSFORM_WORDS_PER_ENTITY_F16 = 6;
const TRANSFORM_WORDS_PER_ENTITY_F32 = 12;
const F16_SCRATCH_F32 = new Float32Array(1);
const F16_SCRATCH_U32 = new Uint32Array(F16_SCRATCH_F32.buffer);
const F32_TO_F16_BASE = new Uint16Array(512);
const F32_TO_F16_SHIFT = new Uint8Array(512);
type Float16ArrayLike = {
	readonly length: number;
	[index: number]: number;
};
type Float16ArrayConstructorLike = {
	new (
		buffer: ArrayBufferLike,
		byteOffset?: number,
		length?: number,
	): Float16ArrayLike;
};
const Float16ArrayCtor = (
	globalThis as typeof globalThis & {
		Float16Array?: Float16ArrayConstructorLike;
	}
).Float16Array;

type Mat4 = Float32Array;

type TransformLayout = {
	readonly refs: Uint32Array;
	readonly wordCapacity: number;
	readonly uploadFirstWord: number;
	readonly uploadWordCount: number;
};

type DemoState = {
	readonly context: GPUCanvasContext;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly pipeline: GPURenderPipeline;
	readonly depthView: GPUTextureView;
	readonly vertexBuffer: GPUBuffer;
	readonly instanceBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly transformStorage: GPUBuffer;
	readonly cameraUniform: GPUBuffer;
	readonly bindTransforms: GPUBindGroup;
	readonly bindCamera: GPUBindGroup;
	readonly input: InputState;
	readonly orbitController: OrbitCameraController;
	readonly transformRefs: Uint32Array;
	readonly transformBytes: Uint8Array;
	readonly transformWords: Uint32Array;
	readonly transformFloats: Float32Array;
	readonly transformHalves: Float16ArrayLike | Uint16Array;
	readonly transformWordUploadFirst: number;
	readonly transformWordUploadCount: number;
	perSide: number;
	transformStride: number;
	snapshotColorView?: GPUTextureView;
	snapshotDepthView?: GPUTextureView;
	wasmTransformUploadBuffer?: ArrayBufferLike;
	wasmTransformUploadPtr?: number;
	wasmTransformUploadByteLength?: number;
	wasmTransformUploadView?: Uint8Array;
};

for (let i = 0; i < 256; i += 1) {
	const e = i - 127;
	if (e < -24) {
		F32_TO_F16_BASE[i] = 0x0000;
		F32_TO_F16_BASE[i | 0x100] = 0x8000;
		F32_TO_F16_SHIFT[i] = 24;
		F32_TO_F16_SHIFT[i | 0x100] = 24;
	} else if (e < -14) {
		const base = 0x0400 >> (-e - 14);
		const shift = -e - 1;
		F32_TO_F16_BASE[i] = base;
		F32_TO_F16_BASE[i | 0x100] = base | 0x8000;
		F32_TO_F16_SHIFT[i] = shift;
		F32_TO_F16_SHIFT[i | 0x100] = shift;
	} else if (e <= 15) {
		const base = (e + 15) << 10;
		F32_TO_F16_BASE[i] = base;
		F32_TO_F16_BASE[i | 0x100] = base | 0x8000;
		F32_TO_F16_SHIFT[i] = 13;
		F32_TO_F16_SHIFT[i | 0x100] = 13;
	} else if (e < 128) {
		F32_TO_F16_BASE[i] = 0x7c00;
		F32_TO_F16_BASE[i | 0x100] = 0xfc00;
		F32_TO_F16_SHIFT[i] = 24;
		F32_TO_F16_SHIFT[i | 0x100] = 24;
	} else {
		F32_TO_F16_BASE[i] = 0x7c00;
		F32_TO_F16_BASE[i | 0x100] = 0xfc00;
		F32_TO_F16_SHIFT[i] = 13;
		F32_TO_F16_SHIFT[i | 0x100] = 13;
	}
}

type WasmExports = {
	_start?: () => void;
	memory?: WebAssembly.Memory;
	create_wasm_demo_state: () => void;
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

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setUint32(
		offset,
		value,
		true,
	);
}

function entityUsesF32(entityIndex: number): boolean {
	switch (GLOBAL_TRANSFORM_PRECISION_MODE) {
		case "all-f32":
			return true;
		case "all-f16":
			return false;
		case "first-half-f32-second-half-f16":
			return entityIndex < Math.floor(ENTITY_COUNT / 2);
		case "even-id-f32-odd-id-f16":
			return (entityIndex & 1) === 0;
	}
}

function transformWordsForFormat(format: number): number {
	return format === GLOBAL_TRANSFORM_FORMAT_F16
		? TRANSFORM_WORDS_PER_ENTITY_F16
		: TRANSFORM_WORDS_PER_ENTITY_F32;
}

function createTransformLayout(): TransformLayout {
	const refs = new Uint32Array(ENTITY_COUNT * 2);
	let nextWord = 0;
	if (GLOBAL_TRANSFORM_PRECISION_MODE === "all-f32") {
		for (let i = 0; i < ENTITY_COUNT; i += 1) {
			const refBase = i * 2;
			refs[refBase] = GLOBAL_TRANSFORM_FORMAT_F32;
			refs[refBase + 1] = i * TRANSFORM_WORDS_PER_ENTITY_F32;
		}
		nextWord = ENTITY_COUNT * TRANSFORM_WORDS_PER_ENTITY_F32;
	} else {
		for (let i = 0; i < ENTITY_COUNT; i += 1) {
			const refBase = i * 2;
			refs[refBase] = GLOBAL_TRANSFORM_FORMAT_F16;
			refs[refBase + 1] = i * TRANSFORM_WORDS_PER_ENTITY_F16;
		}
		nextWord = ENTITY_COUNT * TRANSFORM_WORDS_PER_ENTITY_F16;
		if (GLOBAL_TRANSFORM_PRECISION_MODE !== "all-f16") {
			for (let i = 0; i < ENTITY_COUNT; i += 1) {
				if (entityUsesF32(i)) {
					const refBase = i * 2;
					refs[refBase] = GLOBAL_TRANSFORM_FORMAT_F32;
					refs[refBase + 1] = nextWord;
					nextWord += TRANSFORM_WORDS_PER_ENTITY_F32;
				}
			}
		}
	}
	let firstWord = Number.POSITIVE_INFINITY;
	let endWord = 0;
	for (let i = 0; i < ENTITY_COUNT; i += 1) {
		const refBase = i * 2;
		const wordOffset = refs[refBase + 1] ?? 0;
		const wordEnd = wordOffset + transformWordsForFormat(refs[refBase] ?? 0);
		firstWord = Math.min(firstWord, wordOffset);
		endWord = Math.max(endWord, wordEnd);
	}
	return {
		refs,
		wordCapacity: nextWord,
		uploadFirstWord: Number.isFinite(firstWord) ? firstWord : 0,
		uploadWordCount: Number.isFinite(firstWord) ? Math.max(endWord - firstWord, 0) : 0,
	};
}

function f32ToF16Bits(value: number): number {
	F16_SCRATCH_F32[0] = Math.fround(value);
	const bits = F16_SCRATCH_U32[0] ?? 0;
	const index = (bits >>> 23) & 0x1ff;
	return (F32_TO_F16_BASE[index] ?? 0) + ((bits & 0x007fffff) >>> (F32_TO_F16_SHIFT[index] ?? 24));
}

function writeHalf(halves: Float16ArrayLike | Uint16Array, index: number, value: number): void {
	if (Float16ArrayCtor !== undefined) {
		halves[index] = value;
	} else {
		halves[index] = f32ToF16Bits(value);
	}
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

function mat4RotationY(rad: number): Mat4 {
	const out = mat4Identity();
	const c = Math.cos(rad);
	const s = Math.sin(rad);
	out[0] = c;
	out[2] = -s;
	out[8] = s;
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

function cameraUniformBytes(yaw: number, pitch: number): Uint8Array {
	const viewRot = mat4Mul(
		mat4Mul(mat4RotationX(pitch), mat4RotationY(yaw)),
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

function instanceBytes(transformRefs: Uint32Array): Uint8Array {
	const bytes = new Uint8Array(ENTITY_COUNT * INSTANCE_STRIDE);
	for (let index = 0; index < ENTITY_COUNT; index += 1) {
			const [r, g, b] = instanceColorRgb(index);
			const base = index * INSTANCE_STRIDE;
			const refBase = index * 2;
			writeU32(bytes, base, transformRefs[refBase] ?? 0);
			writeU32(bytes, base + 4, transformRefs[refBase + 1] ?? 0);
			writeF32(bytes, base + 8, r);
			writeF32(bytes, base + 12, g);
			writeF32(bytes, base + 16, b);
	}
	return bytes;
}

function writeMassCubesFullTransformData(
	demoState: DemoState,
	perSide: number,
	waveTime: number,
): void {
	const refs = demoState.transformRefs;
	const words = demoState.transformWords;
	const floats = demoState.transformFloats;
	const halves = demoState.transformHalves;
	const uploadFirstWord = demoState.transformWordUploadFirst;
	const half = (perSide - 1) * 0.5;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let row = 0;
	let column = 0;
	while (localIndex < ENTITY_COUNT) {
		const rowCount = Math.min(perSide - column, ENTITY_COUNT - localIndex);
		let x = (column - half) * GRID_SPACING;
			const z = (row - half) * GRID_SPACING;
			let waveSin = Math.sin(localIndex * 0.09 + waveTime);
			let waveCos = Math.cos(localIndex * 0.09 + waveTime);
			for (let ix = 0; ix < rowCount; ix += 1) {
				const refBase = localIndex * 2;
				const format = refs[refBase] ?? 0;
				const wordOffset = (refs[refBase + 1] ?? 0) - uploadFirstWord;
				const y = waveSin * 0.12;
				if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
					const out = wordOffset * 2;
					writeHalf(halves, out, CUBE_SCALE);
					writeHalf(halves, out + 1, 0);
					writeHalf(halves, out + 2, 0);
					writeHalf(halves, out + 3, x);
					writeHalf(halves, out + 4, 0);
					writeHalf(halves, out + 5, CUBE_SCALE);
					writeHalf(halves, out + 6, 0);
					writeHalf(halves, out + 7, y);
					writeHalf(halves, out + 8, 0);
					writeHalf(halves, out + 9, 0);
					writeHalf(halves, out + 10, CUBE_SCALE);
					writeHalf(halves, out + 11, z);
				} else {
					floats[wordOffset] = CUBE_SCALE;
					words[wordOffset + 1] = 0;
					words[wordOffset + 2] = 0;
					floats[wordOffset + 3] = x;
					words[wordOffset + 4] = 0;
					floats[wordOffset + 5] = CUBE_SCALE;
					words[wordOffset + 6] = 0;
					floats[wordOffset + 7] = y;
					words[wordOffset + 8] = 0;
					words[wordOffset + 9] = 0;
					floats[wordOffset + 10] = CUBE_SCALE;
					floats[wordOffset + 11] = z;
				}

			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			localIndex += 1;
			x += GRID_SPACING;
		}
		row += 1;
		column = 0;
	}
}

function writeMassCubesYTransformData(demoState: DemoState, waveTime: number): void {
	const refs = demoState.transformRefs;
	const floats = demoState.transformFloats;
	const halves = demoState.transformHalves;
	const uploadFirstWord = demoState.transformWordUploadFirst;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let waveSin = Math.sin(waveTime);
	let waveCos = Math.cos(waveTime);
	while (localIndex < ENTITY_COUNT) {
		const refBase = localIndex * 2;
		const format = refs[refBase] ?? 0;
		const wordOffset = (refs[refBase + 1] ?? 0) - uploadFirstWord;
		const y = waveSin * 0.12;
		if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
			writeHalf(halves, wordOffset * 2 + 7, y);
		} else {
			floats[wordOffset + 7] = y;
		}
		const nextSin = waveSin * cosStep + waveCos * sinStep;
		waveCos = waveCos * cosStep - waveSin * sinStep;
		waveSin = nextSin;
		localIndex += 1;
	}
}

function writeWasmBytesToBuffer(
	queue: GPUQueue,
	gpuBuffer: GPUBuffer,
	memory: WebAssembly.Memory | undefined,
	ptr: number,
	byteLength: number,
	getCached: () => {
		buffer?: ArrayBufferLike;
		ptr?: number;
		byteLength?: number;
		view?: Uint8Array;
	},
	setCached: (
		buffer: ArrayBufferLike,
		ptr: number,
		byteLength: number,
		view: Uint8Array,
	) => void,
): void {
	if (memory === undefined) {
		throw new Error("WASM linear memory is not exported.");
	}
	if (ptr <= 0 || byteLength <= 0) {
		throw new Error(`Invalid WASM transform byte range: ${ptr}, ${byteLength}`);
	}
	const buffer = memory.buffer;
	const cached = getCached();
	let view = cached.view;
	if (
		view === undefined ||
		cached.buffer !== buffer ||
		cached.ptr !== ptr ||
		cached.byteLength !== byteLength
	) {
		view = new Uint8Array(buffer, ptr, byteLength);
		setCached(buffer, ptr, byteLength, view);
	}
	uploadGlobalTransformBytes(queue, gpuBuffer, view);
}

function writeTransformBytesFromWasmMemory(
	demoState: DemoState,
	memory: WebAssembly.Memory | undefined,
	ptr: number,
	byteLength: number,
): void {
	writeWasmBytesToBuffer(
		demoState.queue,
		demoState.transformStorage,
		memory,
		ptr,
		byteLength,
		() => ({
			buffer: demoState.wasmTransformUploadBuffer,
			ptr: demoState.wasmTransformUploadPtr,
			byteLength: demoState.wasmTransformUploadByteLength,
			view: demoState.wasmTransformUploadView,
		}),
		(buffer, cachedPtr, cachedByteLength, view) => {
			demoState.wasmTransformUploadBuffer = buffer;
			demoState.wasmTransformUploadPtr = cachedPtr;
			demoState.wasmTransformUploadByteLength = cachedByteLength;
			demoState.wasmTransformUploadView = view;
		},
	);
}

function shaderWgsl(): string {
	const prefix =
		`
struct CameraUniform {
  view_proj: mat4x4<f32>,
}

` +
		globalTransformWordsBindingDefault() +
		`
@group(1) @binding(0) var<uniform> camera: CameraUniform;
`;

	const suffix = `
struct VertexOut {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec3<f32>,
};

@vertex
fn vertexMain(
  @location(0) local_pos: vec3<f32>,
  @location(1) transform_ref: vec2<u32>,
  @location(2) color: vec3<f32>,
) -> VertexOut {
  let world_pos = rn_transform_point(
    rn_load_global_transform(transform_ref),
    local_pos,
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
	return prefix + globalTransformHelpersDefault() + suffix;
}

async function createDemoState(
	canvas: HTMLCanvasElement,
	renderFormat?: GPUTextureFormat,
): Promise<DemoState> {
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
	const targetFormat = renderFormat ?? format;

	const shader = device.createShaderModule({ code: shaderWgsl() });
	const transformLayout = createTransformLayout();
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
				globalTransformRefInstanceVertexBufferLayout(INSTANCE_STRIDE, {
					extraAttributes: [
						{ shaderLocation: 2, offset: 8, format: "float32x3" },
					],
				}),
			],
		},
		fragment: {
			module: shader,
			entryPoint: "fragmentMain",
			targets: [{ format: targetFormat }],
		},
		primitive: { topology: "triangle-list" },
		depthStencil: {
			format: "depth24plus",
			depthWriteEnabled: true,
			depthCompare: "less",
		},
	});

	const transformStorage = createGlobalTransformWordsBuffer(
		device,
		transformLayout.wordCapacity,
	);
	const cameraUniform = device.createBuffer({
		size: 256,
		usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
	});
	const orbitController = createOrbitCameraController(CAMERA_ELEVATION_RAD);
	queue.writeBuffer(
		cameraUniform,
		0,
		cameraUniformBytes(orbitController.yaw, orbitController.pitch),
	);

	const bindTransforms = globalTransformWordsBindGroup(
		device,
		pipeline,
		transformStorage,
	);
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
	queue.writeBuffer(instanceBuffer, 0, instanceBytes(transformLayout.refs));
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

	const transformBytes = new Uint8Array(transformLayout.uploadWordCount * 4);
	const transformWords = new Uint32Array(
		transformBytes.buffer,
		transformBytes.byteOffset,
		transformBytes.byteLength >>> 2,
	);
	const transformFloats = new Float32Array(
		transformBytes.buffer,
		transformBytes.byteOffset,
		transformBytes.byteLength >>> 2,
	);
	const transformHalves =
		Float16ArrayCtor !== undefined
			? new Float16ArrayCtor(
					transformBytes.buffer,
					transformBytes.byteOffset,
					transformBytes.byteLength >>> 1,
				)
			: new Uint16Array(
					transformBytes.buffer,
					transformBytes.byteOffset,
					transformBytes.byteLength >>> 1,
				);
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
		cameraUniform,
		bindTransforms,
		bindCamera,
		input: new InputState(),
		orbitController,
		transformRefs: transformLayout.refs,
		transformBytes,
		transformWords,
		transformFloats,
		transformHalves,
		transformWordUploadFirst: transformLayout.uploadFirstWord,
		transformWordUploadCount: transformLayout.uploadWordCount,
		perSide: gridSideLen(ENTITY_COUNT),
		transformStride: 0,
		snapshotColorView: undefined,
		snapshotDepthView: undefined,
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
	demoState: DemoState,
	label: string,
	getMemory: () => WebAssembly.Memory | undefined,
): WebAssembly.Imports {
	return {
		rhodonite_ecs_mass_cubes_host: {
			now_ms: () => performance.now(),
			entity_count: () => ENTITY_COUNT,
			initialize_demo_state: (perSide: number, transformStride: number) => {
				demoState.perSide = perSide;
				demoState.transformStride = transformStride;
			},
			write_initial_global_transforms: (perSide: number, waveTime: number) => {
				writeMassCubesFullTransformData(demoState, perSide, waveTime);
				uploadGlobalTransformBytes(
					demoState.queue,
					demoState.transformStorage,
					demoState.transformBytes,
					demoState.transformWordUploadFirst * 4,
				);
			},
			write_global_transform_y: (waveTime: number) => {
				writeMassCubesYTransformData(demoState, waveTime);
				uploadGlobalTransformBytes(
					demoState.queue,
					demoState.transformStorage,
					demoState.transformBytes,
					demoState.transformWordUploadFirst * 4,
				);
			},
			write_initial_global_transform_bytes: (ptr: number, byteLength: number) => {
				writeTransformBytesFromWasmMemory(demoState, getMemory(), ptr, byteLength);
			},
			write_global_transform_bytes: (ptr: number, byteLength: number) => {
				writeTransformBytesFromWasmMemory(demoState, getMemory(), ptr, byteLength);
			},
			render_demo_frame: (fps: number, cpuMs: number) => {
				demoState.input.beginFrame();
				updateOrbitCameraControllerFromInput(
					demoState.orbitController,
					demoState.input,
				);
				demoState.queue.writeBuffer(
					demoState.cameraUniform,
					0,
					cameraUniformBytes(
						demoState.orbitController.yaw,
						demoState.orbitController.pitch,
					),
				);
				const colorView =
					demoState.snapshotColorView ??
					demoState.context.getCurrentTexture().createView();
				const depthView = demoState.snapshotDepthView ?? demoState.depthView;
				const encoder = demoState.device.createCommandEncoder();
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
						view: depthView,
						depthClearValue: 1,
						depthLoadOp: "clear",
						depthStoreOp: "store",
					},
				});
				pass.setPipeline(demoState.pipeline);
				pass.setBindGroup(0, demoState.bindTransforms);
				pass.setBindGroup(1, demoState.bindCamera);
				pass.setIndexBuffer(demoState.indexBuffer, "uint16", 0, INDEX_U16_COUNT * 2);
				pass.setVertexBuffer(
					0,
					demoState.vertexBuffer,
					0,
					VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL,
				);
				pass.setVertexBuffer(
					1,
					demoState.instanceBuffer,
					0,
					ENTITY_COUNT * INSTANCE_STRIDE,
				);
				pass.drawIndexed(INDEX_U16_COUNT, ENTITY_COUNT);
				pass.end();
				demoState.queue.submit([encoder.finish()]);
				updatePerfOverlay(label, fps, cpuMs);
			},
		},
	};
}

async function instantiateWasm(
	demoState: DemoState,
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
		createHostImports(demoState, label, () => memory),
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
		void createDemoState(canvas)
			.then(async (demoState) => {
				installBrowserInputState(demoState.input, canvas);
				const wasm = await instantiateWasm(demoState, wasmUrl, label);
				wasm._start?.();
				wasm.create_wasm_demo_state();
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

export async function renderEcsMassCubesWasmSnapshot(
	wasmUrl: string,
	label: string,
): Promise<Uint8Array> {
	if (!navigator.gpu) {
		throw new Error("WebGPU is not supported in this browser.");
	}
	const canvas = document.createElement("canvas");
	canvas.width = CANVAS_WIDTH;
	canvas.height = CANVAS_HEIGHT;
	const demoState = await createDemoState(canvas, "rgba8unorm");
	const target = createRgba8ReadbackTarget(demoState.device, CANVAS_WIDTH, CANVAS_HEIGHT);
	try {
		const wasm = await instantiateWasm(demoState, wasmUrl, label);
		wasm._start?.();
		wasm.create_wasm_demo_state();
		demoState.snapshotColorView = target.view;
		demoState.snapshotDepthView = target.depthView;
		wasm.ecs_mass_cubes_wasm_render_tick();
		demoState.snapshotColorView = undefined;
		demoState.snapshotDepthView = undefined;
		return await readRgba8Texture(
			demoState.device,
			demoState.queue,
			target.texture,
			CANVAS_WIDTH,
			CANVAS_HEIGHT,
		);
	} finally {
		demoState.snapshotColorView = undefined;
		demoState.snapshotDepthView = undefined;
		destroyReadbackTarget(target);
	}
}
