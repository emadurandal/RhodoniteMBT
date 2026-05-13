import type { MoonMat4F } from "@moon/rhodonite_core/math/js_bridge";
import {
	m4f_add,
	m4f_at,
	m4f_data,
	m4f_det,
	m4f_div_scalar,
	m4f_eq,
	m4f_identity,
	m4f_inverse,
	m4f_mat_mul,
	m4f_mul,
	m4f_mul_vec4,
	m4f_neg,
	m4f_new_col_major,
	m4f_ortho,
	m4f_rotation_x,
	m4f_rotation_y,
	m4f_rotation_z,
	m4f_scale,
	m4f_sub,
	m4f_to_string,
	m4f_translation,
	m4f_transform_point,
	m4f_transpose,
	m4f_zero,
} from "@moon/rhodonite_core/math/js_bridge";
import { Vector3F } from "./vector3.ts";
import { Vector4F } from "./vector4.ts";

export class Matrix44F {
	readonly inner: MoonMat4F;

	constructor(inner: MoonMat4F) {
		this.inner = inner;
	}

	static newColMajor(
		m00: number,
		m10: number,
		m20: number,
		m30: number,
		m01: number,
		m11: number,
		m21: number,
		m31: number,
		m02: number,
		m12: number,
		m22: number,
		m32: number,
		m03: number,
		m13: number,
		m23: number,
		m33: number,
	): Matrix44F {
		return new Matrix44F(
			m4f_new_col_major(
				m00,
				m10,
				m20,
				m30,
				m01,
				m11,
				m21,
				m31,
				m02,
				m12,
				m22,
				m32,
				m03,
				m13,
				m23,
				m33,
			),
		);
	}

	static zero(): Matrix44F {
		return new Matrix44F(m4f_zero());
	}

	static identity(): Matrix44F {
		return new Matrix44F(m4f_identity());
	}

	/** Radians, right-handed, +X axis (column-major [`Matrix44F`]). */
	static rotationX(angle: number): Matrix44F {
		return new Matrix44F(m4f_rotation_x(angle));
	}

	/** Radians, right-handed, +Y axis (column-major [`Matrix44F`]). */
	static rotationY(angle: number): Matrix44F {
		return new Matrix44F(m4f_rotation_y(angle));
	}

	/** Radians, right-handed, +Z axis (column-major [`Matrix44F`]). */
	static rotationZ(angle: number): Matrix44F {
		return new Matrix44F(m4f_rotation_z(angle));
	}

	static translation(tx: number, ty: number, tz: number): Matrix44F {
		return new Matrix44F(m4f_translation(tx, ty, tz));
	}

	/**
	 * Orthographic projection (WebGPU-style depth in z ∈ [0, 1]);
	 * `near` / `far` are depths along negative Z (same contract as MoonBit [`Matrix44::ortho`]).
	 */
	static ortho(
		left: number,
		right: number,
		bottom: number,
		top: number,
		near: number,
		far: number,
	): Matrix44F {
		return new Matrix44F(m4f_ortho(left, right, bottom, top, near, far));
	}

	at(row: number, col: number): number {
		return m4f_at(this.inner, row, col);
	}

	data(): number[] {
		return m4f_data(this.inner);
	}

	transpose(): Matrix44F {
		return new Matrix44F(m4f_transpose(this.inner));
	}

	matMul(other: Matrix44F): Matrix44F {
		return new Matrix44F(m4f_mat_mul(this.inner, other.inner));
	}

	mulVec4(v: Vector4F): Vector4F {
		return new Vector4F(m4f_mul_vec4(this.inner, v.inner));
	}

	transformPoint(p: Vector3F): Vector3F {
		return new Vector3F(m4f_transform_point(this.inner, p.inner));
	}

	scale(s: number): Matrix44F {
		return new Matrix44F(m4f_scale(this.inner, s));
	}

	divScalar(s: number): Matrix44F {
		return new Matrix44F(m4f_div_scalar(this.inner, s));
	}

	det(): number {
		return m4f_det(this.inner);
	}

	inverse(): Matrix44F | null {
		const r = m4f_inverse(this.inner);
		if (r === undefined || r === null) {
			return null;
		}
		return new Matrix44F(r);
	}

	add(other: Matrix44F): Matrix44F {
		return new Matrix44F(m4f_add(this.inner, other.inner));
	}

	sub(other: Matrix44F): Matrix44F {
		return new Matrix44F(m4f_sub(this.inner, other.inner));
	}

	neg(): Matrix44F {
		return new Matrix44F(m4f_neg(this.inner));
	}

	mul(other: Matrix44F): Matrix44F {
		return new Matrix44F(m4f_mul(this.inner, other.inner));
	}

	eq(other: Matrix44F): boolean {
		const result = m4f_eq(this.inner, other.inner);
		return result === true || result === 1;
	}

	toString(): string {
		return m4f_to_string(this.inner);
	}
}
