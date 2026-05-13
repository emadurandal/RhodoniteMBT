import type {
	MoonBool,
	MoonByteBacking,
	MoonByteView,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	bytes_mut_view_get_f32,
	bytes_mut_view_put_f32,
	bytes_view_get_f32,
} from "@moon/rhodonite_core/ecs/js_bridge";

export function moonBool(value: MoonBool): boolean {
	return value === true || value === 1;
}

export function bytesInput(bytes: Uint8Array | ArrayLike<number>): Uint8Array | number[] {
	return bytes instanceof Uint8Array ? bytes : Array.from(bytes);
}

export class ByteView {
	readonly raw: MoonByteView;

	constructor(raw: MoonByteView) {
		this.raw = raw;
	}

	get buffer(): MoonByteBacking {
		return this.raw.buf;
	}

	get start(): number {
		return this.raw.start;
	}

	get end(): number {
		return this.raw.end;
	}

	get length(): number {
		return this.raw.end - this.raw.start;
	}

	get(index: number): number {
		this.checkIndex(index);
		return this.raw.buf[this.raw.start + index] ?? 0;
	}

	set(index: number, value: number): void {
		this.checkIndex(index);
		this.raw.buf[this.raw.start + index] = value & 0xff;
	}

	getF32(offset: number): number {
		if (this.raw.buf instanceof Uint8Array) {
			return bytes_view_get_f32(this.raw, offset);
		}
		return bytes_mut_view_get_f32(this.raw, offset);
	}

	setF32(offset: number, value: number): void {
		bytes_mut_view_put_f32(this.raw, offset, value);
	}

	/**
	 * Returns a zero-copy `Uint8Array` when the MoonBit backing storage is typed.
	 * CPU SoA columns may use a JS number array; use `toUint8ArrayCopy()` for that case.
	 */
	asUint8Array(): Uint8Array | null {
		if (!(this.raw.buf instanceof Uint8Array)) {
			return null;
		}
		return this.raw.buf.subarray(this.raw.start, this.raw.end);
	}

	toUint8ArrayCopy(): Uint8Array {
		const typed = this.asUint8Array();
		if (typed !== null) {
			return new Uint8Array(typed);
		}
		return Uint8Array.from(this.raw.buf.slice(this.raw.start, this.raw.end));
	}

	private checkIndex(index: number): void {
		if (index < 0 || index >= this.length) {
			throw new RangeError(`byte index ${index} outside view length ${this.length}`);
		}
	}
}

export function byteView(raw: MoonByteView): ByteView {
	return new ByteView(raw);
}
