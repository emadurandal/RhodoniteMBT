import "./style.css";
import {
	World,
	type ByteView,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";

const ENTITY_COUNT = 800_000;
const USE_FP16_GLOBAL_TRANSFORM = true;
const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;
const VERTEX_STRIDE_LOCAL = 12;
const INSTANCE_STRIDE = 24;
const VERTS_PER_CUBE = 8;
const INDEX_U16_COUNT = 36;
const CAMERA_ELEVATION_RAD = 0.42;
const GRID_SPACING = 0.14;
const CUBE_SCALE = 0.055;
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

type Mat4 = Float32Array;
type DenseTransformLayout = {
	readonly format: 0 | 1;
	readonly wordsPerEntity: 6 | 12;
};

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
	readonly transformRefs: Uint32Array;
	readonly transformWordCapacity: number;
	readonly transformWordUploadCount: number;
	readonly denseTransformLayout: DenseTransformLayout | null;
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

function f32ToF16Bits(value: number): number {
	F16_SCRATCH_F32[0] = Math.fround(value);
	const bits = F16_SCRATCH_U32[0] ?? 0;
	const index = (bits >>> 23) & 0x1ff;
	return (F32_TO_F16_BASE[index] ?? 0) + ((bits & 0x007fffff) >>> (F32_TO_F16_SHIFT[index] ?? 24));
}

function packF16x2(x: number, y: number): number {
	return f32ToF16Bits(x) | (f32ToF16Bits(y) << 16);
}

function detectDenseTransformLayout(refs: Uint32Array): DenseTransformLayout | null {
	if (refs.length < ENTITY_COUNT * 2) {
		return null;
	}
	const format = refs[0];
	if (format !== 0 && format !== 1) {
		return null;
	}
	const wordsPerEntity = format === 1 ? 6 : 12;
	for (let i = 0; i < ENTITY_COUNT; i += 1) {
		const refBase = i * 2;
		if (refs[refBase] !== format || refs[refBase + 1] !== i * wordsPerEntity) {
			return null;
		}
	}
	return { format, wordsPerEntity };
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

function instanceBytes(entities: ReturnType<World["spawnTransformGlobalBatchIdentity"]>, refs: Uint8Array): Uint8Array {
	const bytes = new Uint8Array(entities.length * INSTANCE_STRIDE);
	entities.forEach((entity, i) => {
		const index = entity.index();
		const [r, g, b] = instanceColorRgb(index);
		const base = i * INSTANCE_STRIDE;
		bytes.set(refs.subarray(i * 8, i * 8 + 8), base);
		writeF32(bytes, base + 8, r);
		writeF32(bytes, base + 12, g);
		writeF32(bytes, base + 16, b);
	});
	return bytes;
}

function uploadGlobalTransformWrites(
	queue: GPUQueue,
	buffer: GPUBuffer,
	writes: ReturnType<World["drainGpuWriteViews"]>,
): void {
	for (const write of writes) {
		const bytes = write.bytes();
		const backing = bytes.buffer;
		if (backing instanceof Uint8Array) {
			queue.writeBuffer(buffer, write.byteOffset(), backing, bytes.start, bytes.length);
		} else {
			queue.writeBuffer(buffer, write.byteOffset(), bytes.toUint8ArrayCopy());
		}
	}
}

function writeMassCubesTransformBlob(
	bytes: ByteView,
	refs: Uint32Array,
	denseLayout: DenseTransformLayout | null,
	perSide: number,
	t: number,
	fullRows: boolean,
): void {
	const view = bytes.asUint8Array();
	if (view === null || (view.byteOffset & 3) !== 0) {
		throw new Error("GlobalTransform blob must be backed by aligned Uint8Array storage.");
	}
	const waveTime = t * 1.8;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	if (denseLayout !== null && !fullRows) {
		if (denseLayout.format === 1) {
			if (Float16ArrayCtor !== undefined) {
				const halfFloats = new Float16ArrayCtor(
					view.buffer,
					view.byteOffset,
					view.byteLength >>> 1,
				);
				let i = 0;
				let waveSin = Math.sin(waveTime);
				let waveCos = Math.cos(waveTime);
				while (i < ENTITY_COUNT) {
					halfFloats[i * 12 + 7] = waveSin * 0.12;
					const nextSin = waveSin * cosStep + waveCos * sinStep;
					waveCos = waveCos * cosStep - waveSin * sinStep;
					waveSin = nextSin;
					i += 1;
				}
				return;
			}
			const halfRows = new Uint16Array(view.buffer, view.byteOffset, view.byteLength >>> 1);
			let i = 0;
			let waveSin = Math.sin(waveTime);
			let waveCos = Math.cos(waveTime);
			while (i < ENTITY_COUNT) {
				halfRows[i * 12 + 7] = f32ToF16Bits(waveSin * 0.12);
				const nextSin = waveSin * cosStep + waveCos * sinStep;
				waveCos = waveCos * cosStep - waveSin * sinStep;
				waveSin = nextSin;
				i += 1;
			}
			return;
		}
		const floats = new Float32Array(view.buffer, view.byteOffset, view.byteLength >>> 2);
		let i = 0;
		let waveSin = Math.sin(waveTime);
		let waveCos = Math.cos(waveTime);
		while (i < ENTITY_COUNT) {
			floats[i * 12 + 7] = waveSin * 0.12;
			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			i += 1;
		}
		return;
	}
	if (denseLayout !== null && fullRows) {
		const half = (perSide - 1) * 0.5;
		if (denseLayout.format === 1) {
			if (Float16ArrayCtor !== undefined) {
				const halfFloats = new Float16ArrayCtor(
					view.buffer,
					view.byteOffset,
					view.byteLength >>> 1,
				);
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
						const out = localIndex * 12;
						halfFloats[out] = CUBE_SCALE;
						halfFloats[out + 1] = 0;
						halfFloats[out + 2] = 0;
						halfFloats[out + 3] = x;
						halfFloats[out + 4] = 0;
						halfFloats[out + 5] = CUBE_SCALE;
						halfFloats[out + 6] = 0;
						halfFloats[out + 7] = waveSin * 0.12;
						halfFloats[out + 8] = 0;
						halfFloats[out + 9] = 0;
						halfFloats[out + 10] = CUBE_SCALE;
						halfFloats[out + 11] = z;
						const nextSin = waveSin * cosStep + waveCos * sinStep;
						waveCos = waveCos * cosStep - waveSin * sinStep;
						waveSin = nextSin;
						localIndex += 1;
						x += GRID_SPACING;
					}
					row += 1;
					column = 0;
				}
				return;
			}
			const halfRows = new Uint16Array(view.buffer, view.byteOffset, view.byteLength >>> 1);
			const zeroH = f32ToF16Bits(0);
			const scaleH = f32ToF16Bits(CUBE_SCALE);
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
					const out = localIndex * 12;
					halfRows[out] = scaleH;
					halfRows[out + 1] = zeroH;
					halfRows[out + 2] = zeroH;
					halfRows[out + 3] = f32ToF16Bits(x);
					halfRows[out + 4] = zeroH;
					halfRows[out + 5] = scaleH;
					halfRows[out + 6] = zeroH;
					halfRows[out + 7] = f32ToF16Bits(waveSin * 0.12);
					halfRows[out + 8] = zeroH;
					halfRows[out + 9] = zeroH;
					halfRows[out + 10] = scaleH;
					halfRows[out + 11] = f32ToF16Bits(z);
					const nextSin = waveSin * cosStep + waveCos * sinStep;
					waveCos = waveCos * cosStep - waveSin * sinStep;
					waveSin = nextSin;
					localIndex += 1;
					x += GRID_SPACING;
				}
				row += 1;
				column = 0;
			}
			return;
		}
		const floats = new Float32Array(view.buffer, view.byteOffset, view.byteLength >>> 2);
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
				const out = localIndex * 12;
				floats[out] = CUBE_SCALE;
				floats[out + 1] = 0;
				floats[out + 2] = 0;
				floats[out + 3] = x;
				floats[out + 4] = 0;
				floats[out + 5] = CUBE_SCALE;
				floats[out + 6] = 0;
				floats[out + 7] = waveSin * 0.12;
				floats[out + 8] = 0;
				floats[out + 9] = 0;
				floats[out + 10] = CUBE_SCALE;
				floats[out + 11] = z;
				const nextSin = waveSin * cosStep + waveCos * sinStep;
				waveCos = waveCos * cosStep - waveSin * sinStep;
				waveSin = nextSin;
				localIndex += 1;
				x += GRID_SPACING;
			}
			row += 1;
			column = 0;
		}
		return;
	}
	const words = new Uint32Array(view.buffer, view.byteOffset, view.byteLength >>> 2);
	const floats = new Float32Array(view.buffer, view.byteOffset, view.byteLength >>> 2);
	if (!fullRows) {
		let i = 0;
		let waveSin = Math.sin(waveTime);
		let waveCos = Math.cos(waveTime);
		while (i < ENTITY_COUNT) {
			const refBase = i * 2;
			const format = refs[refBase] ?? 0;
			const wordOffset = refs[refBase + 1] ?? 0;
			const y = waveSin * 0.12;
			if (format === 1) {
				words[wordOffset + 3] = packF16x2(0, y);
			} else {
				floats[wordOffset + 7] = y;
			}
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
	while (localIndex < ENTITY_COUNT) {
		const rowCount = Math.min(perSide - column, ENTITY_COUNT - localIndex);
		let x = (column - half) * GRID_SPACING;
		const z = (row - half) * GRID_SPACING;
		let waveSin = Math.sin(localIndex * 0.09 + waveTime);
		let waveCos = Math.cos(localIndex * 0.09 + waveTime);
		for (let ix = 0; ix < rowCount; ix += 1) {
			const refBase = localIndex * 2;
			const format = refs[refBase] ?? 0;
			const wordOffset = refs[refBase + 1] ?? 0;
			const y = waveSin * 0.12;
			if (format === 1) {
				words[wordOffset] = packF16x2(CUBE_SCALE, 0);
				words[wordOffset + 1] = packF16x2(0, x);
				words[wordOffset + 2] = packF16x2(0, CUBE_SCALE);
				words[wordOffset + 3] = packF16x2(0, y);
				words[wordOffset + 4] = packF16x2(0, 0);
				words[wordOffset + 5] = packF16x2(CUBE_SCALE, z);
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

function uploadInitialGlobalTransforms(renderer: Renderer): void {
	uploadGlobalTransformWrites(
		renderer.queue,
		renderer.transformStorage,
		renderer.world.writeGlobalTransformBlobRangeViews(
			0,
			renderer.transformWordUploadCount,
			(bytes) =>
				writeMassCubesTransformBlob(
					bytes,
					renderer.transformRefs,
					renderer.denseTransformLayout,
					renderer.perSide,
					0,
					true,
				),
		),
	);
}

function updateAndDrainGlobalTransforms(renderer: Renderer, t: number): void {
	uploadGlobalTransformWrites(
		renderer.queue,
		renderer.transformStorage,
		renderer.world.writeGlobalTransformBlobRangeViews(
			0,
			renderer.transformWordUploadCount,
			(bytes) =>
				writeMassCubesTransformBlob(
					bytes,
					renderer.transformRefs,
					renderer.denseTransformLayout,
					renderer.perSide,
					t,
					false,
				),
		),
	);
}

function shaderWgsl(): string {
	return `
struct CameraUniform {
  view_proj: mat4x4<f32>,
}

@group(0) @binding(0) var<storage, read> transform_words: array<u32>;
@group(1) @binding(0) var<uniform> camera: CameraUniform;

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
  let format = transform_ref.x;
  let word_offset = transform_ref.y;
  var row0: vec4<f32>;
  var row1: vec4<f32>;
  var row2: vec4<f32>;
  if (format == 1u) {
    let r0xy = unpack2x16float(transform_words[word_offset + 0u]);
    let r0zw = unpack2x16float(transform_words[word_offset + 1u]);
    let r1xy = unpack2x16float(transform_words[word_offset + 2u]);
    let r1zw = unpack2x16float(transform_words[word_offset + 3u]);
    let r2xy = unpack2x16float(transform_words[word_offset + 4u]);
    let r2zw = unpack2x16float(transform_words[word_offset + 5u]);
    row0 = vec4<f32>(r0xy.x, r0xy.y, r0zw.x, r0zw.y);
    row1 = vec4<f32>(r1xy.x, r1xy.y, r1zw.x, r1zw.y);
    row2 = vec4<f32>(r2xy.x, r2xy.y, r2zw.x, r2zw.y);
  } else {
    row0 = vec4<f32>(
      bitcast<f32>(transform_words[word_offset + 0u]),
      bitcast<f32>(transform_words[word_offset + 1u]),
      bitcast<f32>(transform_words[word_offset + 2u]),
      bitcast<f32>(transform_words[word_offset + 3u]),
    );
    row1 = vec4<f32>(
      bitcast<f32>(transform_words[word_offset + 4u]),
      bitcast<f32>(transform_words[word_offset + 5u]),
      bitcast<f32>(transform_words[word_offset + 6u]),
      bitcast<f32>(transform_words[word_offset + 7u]),
    );
    row2 = vec4<f32>(
      bitcast<f32>(transform_words[word_offset + 8u]),
      bitcast<f32>(transform_words[word_offset + 9u]),
      bitcast<f32>(transform_words[word_offset + 10u]),
      bitcast<f32>(transform_words[word_offset + 11u]),
    );
  }
  let local_h = vec4<f32>(local_pos, 1.0);
  let world_pos = vec4<f32>(
    dot(row0, local_h),
    dot(row1, local_h),
    dot(row2, local_h),
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

	const shader = device.createShaderModule({
		code: shaderWgsl(),
	});
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
					attributes: [
						{ shaderLocation: 1, offset: 0, format: "uint32x2" },
						{ shaderLocation: 2, offset: 8, format: "float32x3" },
					],
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

	const world = USE_FP16_GLOBAL_TRANSFORM
		? World.newWithGlobalTransformF16()
		: World.new();
	const perSide = gridSideLen(ENTITY_COUNT);
	const entities = world.spawnTransformGlobalBatchIdentity(ENTITY_COUNT);
	const transformRefsBytes = world.extractGlobalTransformRefs(entities);
	const transformRefs = new Uint32Array(
		transformRefsBytes.buffer,
		transformRefsBytes.byteOffset,
		transformRefsBytes.byteLength >>> 2,
	);
	const denseTransformLayout = detectDenseTransformLayout(transformRefs);
	const transformWordCapacity = world.globalTransformBlobWordCapacity();
	const transformWordUploadCount =
		denseTransformLayout?.wordsPerEntity === undefined
			? transformWordCapacity
			: ENTITY_COUNT * denseTransformLayout.wordsPerEntity;
	const transformStorage = device.createBuffer({
		size: Math.max(transformWordCapacity * 4, 4),
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
	const instanceData = instanceBytes(entities, transformRefsBytes);
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
		transformRefs,
		transformWordCapacity,
		transformWordUploadCount,
		denseTransformLayout,
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
