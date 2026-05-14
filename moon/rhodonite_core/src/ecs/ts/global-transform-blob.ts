import type { ByteView } from "./views.ts";
import type { GpuWriteView, World } from "./world.ts";

export type GlobalTransformGpuFormatCode = 0 | 1;
export type GlobalTransformWordCount = 6 | 12;

export type GlobalTransformDenseLayout = {
	readonly format: GlobalTransformGpuFormatCode;
	readonly wordsPerEntity: GlobalTransformWordCount;
};

export type GlobalTransformUploadRange = {
	readonly firstWord: number;
	readonly wordCount: number;
};

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

const GLOBAL_TRANSFORM_FORMAT_F32 = 0;
const GLOBAL_TRANSFORM_FORMAT_F16 = 1;
const F16_SCRATCH_F32 = new Float32Array(1);
const F16_SCRATCH_U32 = new Uint32Array(F16_SCRATCH_F32.buffer);
const F32_TO_F16_BASE = new Uint16Array(512);
const F32_TO_F16_SHIFT = new Uint8Array(512);
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

function f32ToF16Bits(value: number): number {
	F16_SCRATCH_F32[0] = Math.fround(value);
	const bits = F16_SCRATCH_U32[0] ?? 0;
	const index = (bits >>> 23) & 0x1ff;
	return (F32_TO_F16_BASE[index] ?? 0) + ((bits & 0x007fffff) >>> (F32_TO_F16_SHIFT[index] ?? 24));
}

export function globalTransformWordsForFormat(
	format: number,
): GlobalTransformWordCount {
	return format === GLOBAL_TRANSFORM_FORMAT_F16 ? 6 : 12;
}

export function detectDenseGlobalTransformLayout(
	refs: Uint32Array,
	count: number,
): GlobalTransformDenseLayout | null {
	if (refs.length < count * 2) {
		return null;
	}
	const format = refs[0];
	if (format !== GLOBAL_TRANSFORM_FORMAT_F32 && format !== GLOBAL_TRANSFORM_FORMAT_F16) {
		return null;
	}
	const wordsPerEntity = globalTransformWordsForFormat(format);
	for (let i = 0; i < count; i += 1) {
		const refBase = i * 2;
		if (refs[refBase] !== format || refs[refBase + 1] !== i * wordsPerEntity) {
			return null;
		}
	}
	return { format, wordsPerEntity };
}

export function computeGlobalTransformUploadRange(
	refs: Uint32Array,
	count: number,
	denseLayout: GlobalTransformDenseLayout | null = detectDenseGlobalTransformLayout(
		refs,
		count,
	),
): GlobalTransformUploadRange {
	if (denseLayout !== null) {
		return { firstWord: 0, wordCount: count * denseLayout.wordsPerEntity };
	}
	let firstWord = Number.POSITIVE_INFINITY;
	let endWord = 0;
	for (let i = 0; i < count; i += 1) {
		const refBase = i * 2;
		const format = refs[refBase] ?? GLOBAL_TRANSFORM_FORMAT_F32;
		const wordOffset = refs[refBase + 1] ?? 0;
		const wordCount = globalTransformWordsForFormat(format);
		firstWord = Math.min(firstWord, wordOffset);
		endWord = Math.max(endWord, wordOffset + wordCount);
	}
	if (!Number.isFinite(firstWord) || endWord <= firstWord) {
		return { firstWord: 0, wordCount: 0 };
	}
	return { firstWord, wordCount: endWord - firstWord };
}

export class GlobalTransformBlobWriter {
	readonly count: number;
	private readonly floats: Float32Array;
	private readonly halfBits: Uint16Array;
	private readonly halfFloats: Float16ArrayLike | null;
	private readonly refs: Uint32Array;
	private readonly firstWord: number;
	private readonly denseLayout: GlobalTransformDenseLayout | null;
	private format: GlobalTransformGpuFormatCode = GLOBAL_TRANSFORM_FORMAT_F32;
	private wordOffset = 0;
	setAffine3x4At: (
		index: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	) => void = (
		index,
		m00,
		m01,
		m02,
		m03,
		m10,
		m11,
		m12,
		m13,
		m20,
		m21,
		m22,
		m23,
	) =>
		this.setAffine3x4AtMixed(
			index,
			m00,
			m01,
			m02,
			m03,
			m10,
			m11,
			m12,
			m13,
			m20,
			m21,
			m22,
			m23,
		);
	setElementAt: (
		index: number,
		row: 0 | 1 | 2,
		column: 0 | 1 | 2 | 3,
		value: number,
	) => void = (index, row, column, value) =>
		this.setElementAtMixed(index, row, column, value);

	constructor(
		bytes: ByteView,
		options: {
			readonly refs: Uint32Array;
			readonly count: number;
			readonly firstWord: number;
			readonly denseLayout?: GlobalTransformDenseLayout | null;
		},
	) {
		const view = bytes.asUint8Array();
		if (view === null || (view.byteOffset & 3) !== 0) {
			throw new Error("GlobalTransform blob must be backed by aligned Uint8Array storage.");
		}
		this.floats = new Float32Array(view.buffer, view.byteOffset, view.byteLength >>> 2);
		this.halfBits = new Uint16Array(view.buffer, view.byteOffset, view.byteLength >>> 1);
		this.halfFloats =
			Float16ArrayCtor === undefined
				? null
				: new Float16ArrayCtor(
						view.buffer,
						view.byteOffset,
						view.byteLength >>> 1,
					);
		this.refs = options.refs;
		this.count = options.count;
		this.firstWord = options.firstWord;
		this.denseLayout =
			options.denseLayout === undefined
				? detectDenseGlobalTransformLayout(options.refs, options.count)
				: options.denseLayout;
		if (this.denseLayout?.format === GLOBAL_TRANSFORM_FORMAT_F32) {
			this.setAffine3x4At = this.setAffine3x4AtDenseF32;
			this.setElementAt = this.setElementAtDenseF32;
		} else if (this.denseLayout?.format === GLOBAL_TRANSFORM_FORMAT_F16) {
			if (this.halfFloats !== null) {
				this.setAffine3x4At = this.setAffine3x4AtDenseF16Float;
				this.setElementAt = this.setElementAtDenseF16Float;
			} else {
				this.setAffine3x4At = this.setAffine3x4AtDenseF16Bits;
				this.setElementAt = this.setElementAtDenseF16Bits;
			}
		}
	}

	moveTo(index: number): this {
		if (index < 0 || index >= this.count) {
			throw new RangeError(`GlobalTransform index ${index} outside count ${this.count}`);
		}
		if (this.denseLayout !== null) {
			this.format = this.denseLayout.format;
			this.wordOffset = index * this.denseLayout.wordsPerEntity - this.firstWord;
			return this;
		}
		const refBase = index * 2;
		const format = this.refs[refBase] ?? GLOBAL_TRANSFORM_FORMAT_F32;
		this.format =
			format === GLOBAL_TRANSFORM_FORMAT_F16
				? GLOBAL_TRANSFORM_FORMAT_F16
				: GLOBAL_TRANSFORM_FORMAT_F32;
		this.wordOffset = (this.refs[refBase + 1] ?? 0) - this.firstWord;
		return this;
	}

	setAffine3x4(
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void {
		if (this.format === GLOBAL_TRANSFORM_FORMAT_F16) {
			this.writeF16Scalar(0, m00);
			this.writeF16Scalar(1, m01);
			this.writeF16Scalar(2, m02);
			this.writeF16Scalar(3, m03);
			this.writeF16Scalar(4, m10);
			this.writeF16Scalar(5, m11);
			this.writeF16Scalar(6, m12);
			this.writeF16Scalar(7, m13);
			this.writeF16Scalar(8, m20);
			this.writeF16Scalar(9, m21);
			this.writeF16Scalar(10, m22);
			this.writeF16Scalar(11, m23);
			return;
		}
		const out = this.wordOffset;
		this.floats[out] = m00;
		this.floats[out + 1] = m01;
		this.floats[out + 2] = m02;
		this.floats[out + 3] = m03;
		this.floats[out + 4] = m10;
		this.floats[out + 5] = m11;
		this.floats[out + 6] = m12;
		this.floats[out + 7] = m13;
		this.floats[out + 8] = m20;
		this.floats[out + 9] = m21;
		this.floats[out + 10] = m22;
		this.floats[out + 11] = m23;
	}

	private setAffine3x4AtMixed(
		index: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void {
		const refBase = index * 2;
		const format = this.refs[refBase] ?? GLOBAL_TRANSFORM_FORMAT_F32;
		const wordOffset = (this.refs[refBase + 1] ?? 0) - this.firstWord;
		if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
			if (this.halfFloats !== null) {
				this.writeF16FloatAffine3x4(wordOffset * 2, m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23);
			} else {
				this.writeF16BitsAffine3x4(wordOffset * 2, m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23);
			}
			return;
		}
		this.writeF32Affine3x4(wordOffset, m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23);
	}

	private setAffine3x4AtDenseF32 = (
		index: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void => {
		this.writeF32Affine3x4(
			index * 12 - this.firstWord,
			m00,
			m01,
			m02,
			m03,
			m10,
			m11,
			m12,
			m13,
			m20,
			m21,
			m22,
			m23,
		);
	};

	private setAffine3x4AtDenseF16Float = (
		index: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void => {
		this.writeF16FloatAffine3x4(
			(index * 6 - this.firstWord) * 2,
			m00,
			m01,
			m02,
			m03,
			m10,
			m11,
			m12,
			m13,
			m20,
			m21,
			m22,
			m23,
		);
	};

	private setAffine3x4AtDenseF16Bits = (
		index: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void => {
		this.writeF16BitsAffine3x4(
			(index * 6 - this.firstWord) * 2,
			m00,
			m01,
			m02,
			m03,
			m10,
			m11,
			m12,
			m13,
			m20,
			m21,
			m22,
			m23,
		);
	}

	setElement(row: 0 | 1 | 2, column: 0 | 1 | 2 | 3, value: number): void {
		const scalarIndex = row * 4 + column;
		if (this.format === GLOBAL_TRANSFORM_FORMAT_F16) {
			this.writeF16Scalar(scalarIndex, value);
			return;
		}
		this.floats[this.wordOffset + scalarIndex] = value;
	}

	elementSetter(
		row: 0 | 1 | 2,
		column: 0 | 1 | 2 | 3,
	): (index: number, value: number) => void {
		const scalarIndex = row * 4 + column;
		if (this.denseLayout?.format === GLOBAL_TRANSFORM_FORMAT_F32) {
			return (index, value) => {
				this.floats[index * 12 - this.firstWord + scalarIndex] = value;
			};
		}
		if (this.denseLayout?.format === GLOBAL_TRANSFORM_FORMAT_F16) {
			if (this.halfFloats !== null) {
				const halfFloats = this.halfFloats;
				const firstWord = this.firstWord;
				return (index, value) => {
					halfFloats[(index * 6 - firstWord) * 2 + scalarIndex] = value;
				};
			}
			const halfBits = this.halfBits;
			const firstWord = this.firstWord;
			return (index, value) => {
				halfBits[(index * 6 - firstWord) * 2 + scalarIndex] = f32ToF16Bits(value);
			};
		}
		const refs = this.refs;
		const floats = this.floats;
		return (index, value) => {
			const refBase = index * 2;
			const format = refs[refBase] ?? GLOBAL_TRANSFORM_FORMAT_F32;
			const wordOffset = (refs[refBase + 1] ?? 0) - this.firstWord;
			if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
				this.writeF16ScalarAt(wordOffset * 2 + scalarIndex, value);
				return;
			}
			floats[wordOffset + scalarIndex] = value;
		};
	}

	private setElementAtMixed(
		index: number,
		row: 0 | 1 | 2,
		column: 0 | 1 | 2 | 3,
		value: number,
	): void {
		const scalarIndex = row * 4 + column;
		const refBase = index * 2;
		const format = this.refs[refBase] ?? GLOBAL_TRANSFORM_FORMAT_F32;
		const wordOffset = (this.refs[refBase + 1] ?? 0) - this.firstWord;
		if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
			this.writeF16ScalarAt(wordOffset * 2 + scalarIndex, value);
			return;
		}
		this.floats[wordOffset + scalarIndex] = value;
	}

	private setElementAtDenseF32 = (
		index: number,
		row: 0 | 1 | 2,
		column: 0 | 1 | 2 | 3,
		value: number,
	): void => {
		this.floats[index * 12 - this.firstWord + row * 4 + column] = value;
	};

	private setElementAtDenseF16Float = (
		index: number,
		row: 0 | 1 | 2,
		column: 0 | 1 | 2 | 3,
		value: number,
	): void => {
		this.halfFloats![(index * 6 - this.firstWord) * 2 + row * 4 + column] = value;
	};

	private setElementAtDenseF16Bits = (
		index: number,
		row: 0 | 1 | 2,
		column: 0 | 1 | 2 | 3,
		value: number,
	): void => {
		this.halfBits[(index * 6 - this.firstWord) * 2 + row * 4 + column] = f32ToF16Bits(value);
	};

	private writeF16Scalar(scalarIndex: number, value: number): void {
		const offset = this.wordOffset * 2 + scalarIndex;
		this.writeF16ScalarAt(offset, value);
	}

	private writeF16ScalarAt(offset: number, value: number): void {
		if (this.halfFloats !== null) {
			this.halfFloats[offset] = value;
			return;
		}
		this.halfBits[offset] = f32ToF16Bits(value);
	}

	private writeF32Affine3x4(
		out: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void {
		this.floats[out] = m00;
		this.floats[out + 1] = m01;
		this.floats[out + 2] = m02;
		this.floats[out + 3] = m03;
		this.floats[out + 4] = m10;
		this.floats[out + 5] = m11;
		this.floats[out + 6] = m12;
		this.floats[out + 7] = m13;
		this.floats[out + 8] = m20;
		this.floats[out + 9] = m21;
		this.floats[out + 10] = m22;
		this.floats[out + 11] = m23;
	}

	private writeF16FloatAffine3x4(
		out: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void {
		const halfFloats = this.halfFloats!;
		halfFloats[out] = m00;
		halfFloats[out + 1] = m01;
		halfFloats[out + 2] = m02;
		halfFloats[out + 3] = m03;
		halfFloats[out + 4] = m10;
		halfFloats[out + 5] = m11;
		halfFloats[out + 6] = m12;
		halfFloats[out + 7] = m13;
		halfFloats[out + 8] = m20;
		halfFloats[out + 9] = m21;
		halfFloats[out + 10] = m22;
		halfFloats[out + 11] = m23;
	}

	private writeF16BitsAffine3x4(
		out: number,
		m00: number,
		m01: number,
		m02: number,
		m03: number,
		m10: number,
		m11: number,
		m12: number,
		m13: number,
		m20: number,
		m21: number,
		m22: number,
		m23: number,
	): void {
		this.halfBits[out] = f32ToF16Bits(m00);
		this.halfBits[out + 1] = f32ToF16Bits(m01);
		this.halfBits[out + 2] = f32ToF16Bits(m02);
		this.halfBits[out + 3] = f32ToF16Bits(m03);
		this.halfBits[out + 4] = f32ToF16Bits(m10);
		this.halfBits[out + 5] = f32ToF16Bits(m11);
		this.halfBits[out + 6] = f32ToF16Bits(m12);
		this.halfBits[out + 7] = f32ToF16Bits(m13);
		this.halfBits[out + 8] = f32ToF16Bits(m20);
		this.halfBits[out + 9] = f32ToF16Bits(m21);
		this.halfBits[out + 10] = f32ToF16Bits(m22);
		this.halfBits[out + 11] = f32ToF16Bits(m23);
	}
}

export function writeGlobalTransformBlobByRefs(
	bytes: ByteView,
	options: {
		readonly refs: Uint32Array;
		readonly count: number;
		readonly firstWord: number;
		readonly denseLayout?: GlobalTransformDenseLayout | null;
		readonly write: (writer: GlobalTransformBlobWriter) => void;
	},
): void {
	const writer = new GlobalTransformBlobWriter(bytes, options);
	options.write(writer);
}

export function writeGlobalTransformBlobRangeByRefs(
	world: Pick<World, "writeGlobalTransformBlobRangeViews">,
	options: {
		readonly refs: Uint32Array;
		readonly count: number;
		readonly range?: GlobalTransformUploadRange;
		readonly denseLayout?: GlobalTransformDenseLayout | null;
		readonly write: (writer: GlobalTransformBlobWriter) => void;
	},
): GpuWriteView[] {
	const denseLayout =
		options.denseLayout === undefined
			? detectDenseGlobalTransformLayout(options.refs, options.count)
			: options.denseLayout;
	const range =
		options.range ??
		computeGlobalTransformUploadRange(options.refs, options.count, denseLayout);
	return world.writeGlobalTransformBlobRangeViews(
		range.firstWord,
		range.wordCount,
		(bytes) =>
			writeGlobalTransformBlobByRefs(bytes, {
				refs: options.refs,
				count: options.count,
				firstWord: range.firstWord,
				denseLayout,
				write: options.write,
			}),
	);
}
