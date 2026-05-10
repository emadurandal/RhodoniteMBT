import type { MoonMat3F } from "@moon/rhodonite_core/math/js_bridge";
import {
	m3f_add,
	m3f_at,
	m3f_data,
	m3f_det,
	m3f_div_scalar,
	m3f_eq,
	m3f_identity,
	m3f_inverse,
	m3f_mat_mul,
	m3f_mul,
	m3f_mul_vec,
	m3f_neg,
	m3f_new_col_major,
	m3f_scale,
	m3f_sub,
	m3f_to_string,
	m3f_transpose,
	m3f_zero,
} from "@moon/rhodonite_core/math/js_bridge";
import { Vector3F } from "./vector3.ts";

export class Matrix3F {
	readonly inner: MoonMat3F;

	constructor(inner: MoonMat3F) {
		this.inner = inner;
	}

	/** Column-major component order (see MoonBit `Matrix3::new_col_major`). */
	static newColMajor(
		m00: number,
		m10: number,
		m20: number,
		m01: number,
		m11: number,
		m21: number,
		m02: number,
		m12: number,
		m22: number,
	): Matrix3F {
		return new Matrix3F(
			m3f_new_col_major(m00, m10, m20, m01, m11, m21, m02, m12, m22),
		);
	}

	static zero(): Matrix3F {
		return new Matrix3F(m3f_zero());
	}

	static identity(): Matrix3F {
		return new Matrix3F(m3f_identity());
	}

	at(row: number, col: number): number {
		return m3f_at(this.inner, row, col);
	}

	/** Same array as internal storage (no copy). */
	data(): number[] {
		return m3f_data(this.inner);
	}

	transpose(): Matrix3F {
		return new Matrix3F(m3f_transpose(this.inner));
	}

	matMul(other: Matrix3F): Matrix3F {
		return new Matrix3F(m3f_mat_mul(this.inner, other.inner));
	}

	mulVec(v: Vector3F): Vector3F {
		return new Vector3F(m3f_mul_vec(this.inner, v.inner));
	}

	scale(s: number): Matrix3F {
		return new Matrix3F(m3f_scale(this.inner, s));
	}

	divScalar(s: number): Matrix3F {
		return new Matrix3F(m3f_div_scalar(this.inner, s));
	}

	det(): number {
		return m3f_det(this.inner);
	}

	/** `null` when singular (MoonBit `None` → `undefined` in JS). */
	inverse(): Matrix3F | null {
		const r = m3f_inverse(this.inner);
		if (r === undefined || r === null) {
			return null;
		}
		return new Matrix3F(r);
	}

	add(other: Matrix3F): Matrix3F {
		return new Matrix3F(m3f_add(this.inner, other.inner));
	}

	sub(other: Matrix3F): Matrix3F {
		return new Matrix3F(m3f_sub(this.inner, other.inner));
	}

	neg(): Matrix3F {
		return new Matrix3F(m3f_neg(this.inner));
	}

	/** Hadamard (component-wise) product. */
	mul(other: Matrix3F): Matrix3F {
		return new Matrix3F(m3f_mul(this.inner, other.inner));
	}

	eq(other: Matrix3F): boolean {
		return m3f_eq(this.inner, other.inner) === 1;
	}

	toString(): string {
		return m3f_to_string(this.inner);
	}
}
