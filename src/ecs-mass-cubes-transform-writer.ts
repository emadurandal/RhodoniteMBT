import type { ByteView } from "../moon/rhodonite_core/src/ecs/ts/index.ts";

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
const F16_SCRATCH_F32 = new Float32Array(1);
const F16_SCRATCH_U32 = new Uint32Array(F16_SCRATCH_F32.buffer);
const F32_TO_F16_BASE = new Uint16Array(512);
const F32_TO_F16_SHIFT = new Uint8Array(512);

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

export function f32ToF16Bits(value: number): number {
	F16_SCRATCH_F32[0] = Math.fround(value);
	const bits = F16_SCRATCH_U32[0] ?? 0;
	const index = (bits >>> 23) & 0x1ff;
	return (F32_TO_F16_BASE[index] ?? 0) + ((bits & 0x007fffff) >>> (F32_TO_F16_SHIFT[index] ?? 24));
}

export function writeHalf(
	halves: Float16ArrayLike | Uint16Array,
	index: number,
	value: number,
): void {
	if (Float16ArrayCtor !== undefined) {
		halves[index] = value;
	} else {
		halves[index] = f32ToF16Bits(value);
	}
}

export function createMassCubesHalfArray(bytes: Uint8Array): Float16ArrayLike | Uint16Array {
	if (Float16ArrayCtor !== undefined) {
		return new Float16ArrayCtor(bytes.buffer, bytes.byteOffset, bytes.byteLength >>> 1);
	}
	return new Uint16Array(bytes.buffer, bytes.byteOffset, bytes.byteLength >>> 1);
}

export function writeMassCubesDenseYTransformWaveToArrays(
	floats: Float32Array,
	halves: Float16ArrayLike | Uint16Array,
	count: number,
	firstWord: number,
	wordsPerEntity: number,
	formatCode: number,
	waveTime: number,
): void {
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let waveSin = Math.sin(waveTime);
	let waveCos = Math.cos(waveTime);
	if (formatCode === 1) {
		const halfStride = wordsPerEntity * 2;
		let halfIndex = (3 - firstWord) * 2 + 1;
		if (Float16ArrayCtor !== undefined) {
			for (let i = 0; i < count; i += 1) {
				halves[halfIndex] = waveSin * 0.12;
				const nextSin = waveSin * cosStep + waveCos * sinStep;
				waveCos = waveCos * cosStep - waveSin * sinStep;
				waveSin = nextSin;
				halfIndex += halfStride;
			}
			return;
		}
		for (let i = 0; i < count; i += 1) {
			halves[halfIndex] = f32ToF16Bits(waveSin * 0.12);
			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			halfIndex += halfStride;
		}
		return;
	}
	let wordIndex = 7 - firstWord;
	for (let i = 0; i < count; i += 1) {
		floats[wordIndex] = Math.fround(waveSin * 0.12);
		const nextSin = waveSin * cosStep + waveCos * sinStep;
		waveCos = waveCos * cosStep - waveSin * sinStep;
		waveSin = nextSin;
		wordIndex += wordsPerEntity;
	}
}

export function writeMassCubesDenseYTransformWaveToByteView(
	bytes: ByteView,
	count: number,
	firstWord: number,
	wordsPerEntity: number,
	formatCode: number,
	waveTime: number,
): void {
	const src = bytes.asUint8Array();
	if (src === null) {
		throw new Error("MassCubes dense transform writer requires typed byte storage.");
	}
	writeMassCubesDenseYTransformWaveToArrays(
		new Float32Array(src.buffer, src.byteOffset, src.byteLength >>> 2),
		createMassCubesHalfArray(src),
		count,
		firstWord,
		wordsPerEntity,
		formatCode,
		waveTime,
	);
}
