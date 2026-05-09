import type { MoonVecF } from "@moon/math/js_bridge";
import {
	v3f_add,
	v3f_div_scalar,
	v3f_eq,
	v3f_mul,
	v3f_neg,
	v3f_new,
	v3f_scale,
	v3f_sub,
	v3f_to_string,
	v3f_data,
	v3f_x,
	v3f_y,
	v3f_z,
	v3f_zero,
} from "@moon/math/js_bridge";

export class Vector3F {
	readonly inner: MoonVecF;

	constructor(inner: MoonVecF) {
		this.inner = inner;
	}

	static new(x: number, y: number, z: number): Vector3F {
		return new Vector3F(v3f_new(x, y, z));
	}

	static zero(): Vector3F {
		return new Vector3F(v3f_zero());
	}

	x(): number {
		return v3f_x(this.inner);
	}

	y(): number {
		return v3f_y(this.inner);
	}

	z(): number {
		return v3f_z(this.inner);
	}

	/** 内部ストレージと同一の配列（コピーなし）。 */
	data(): number[] {
		return v3f_data(this.inner);
	}

	add(other: Vector3F): Vector3F {
		return new Vector3F(v3f_add(this.inner, other.inner));
	}

	sub(other: Vector3F): Vector3F {
		return new Vector3F(v3f_sub(this.inner, other.inner));
	}

	neg(): Vector3F {
		return new Vector3F(v3f_neg(this.inner));
	}

	mul(other: Vector3F): Vector3F {
		return new Vector3F(v3f_mul(this.inner, other.inner));
	}

	scale(s: number): Vector3F {
		return new Vector3F(v3f_scale(this.inner, s));
	}

	divScalar(s: number): Vector3F {
		return new Vector3F(v3f_div_scalar(this.inner, s));
	}

	eq(other: Vector3F): boolean {
		return v3f_eq(this.inner, other.inner) === 1;
	}

	toString(): string {
		return v3f_to_string(this.inner);
	}
}
