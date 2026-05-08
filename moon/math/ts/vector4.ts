import type { MoonVecF } from "@moon/math/js_bridge";
import {
	v4f_add,
	v4f_div_scalar,
	v4f_eq,
	v4f_mul,
	v4f_neg,
	v4f_new,
	v4f_scale,
	v4f_sub,
	v4f_to_string,
	v4f_w,
	v4f_x,
	v4f_y,
	v4f_z,
	v4f_zero,
} from "@moon/math/js_bridge";

export class Vector4F {
	readonly inner: MoonVecF;

	constructor(inner: MoonVecF) {
		this.inner = inner;
	}

	static of(x: number, y: number, z: number, w: number): Vector4F {
		return new Vector4F(v4f_new(x, y, z, w));
	}

	static zero(): Vector4F {
		return new Vector4F(v4f_zero());
	}

	x(): number {
		return v4f_x(this.inner);
	}

	y(): number {
		return v4f_y(this.inner);
	}

	z(): number {
		return v4f_z(this.inner);
	}

	w(): number {
		return v4f_w(this.inner);
	}

	add(other: Vector4F): Vector4F {
		return new Vector4F(v4f_add(this.inner, other.inner));
	}

	sub(other: Vector4F): Vector4F {
		return new Vector4F(v4f_sub(this.inner, other.inner));
	}

	neg(): Vector4F {
		return new Vector4F(v4f_neg(this.inner));
	}

	mul(other: Vector4F): Vector4F {
		return new Vector4F(v4f_mul(this.inner, other.inner));
	}

	scale(s: number): Vector4F {
		return new Vector4F(v4f_scale(this.inner, s));
	}

	divScalar(s: number): Vector4F {
		return new Vector4F(v4f_div_scalar(this.inner, s));
	}

	eq(other: Vector4F): boolean {
		return v4f_eq(this.inner, other.inner) === 1;
	}

	toString(): string {
		return v4f_to_string(this.inner);
	}
}

export function vec4f(x: number, y: number, z: number, w: number): Vector4F {
	return Vector4F.of(x, y, z, w);
}

export function vec4fZero(): Vector4F {
	return Vector4F.zero();
}
