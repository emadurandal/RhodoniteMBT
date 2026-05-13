/** Generated MoonBit js_bridge bindings (`moon build --target js --release`). */
declare module "@moon/rhodonite_core/math/js_bridge" {
	export type MoonVecF = { data: number[] };
	export type MoonBool = boolean | 0 | 1;

	export function v3f_new(x: number, y: number, z: number): MoonVecF;
	export function v3f_zero(): MoonVecF;
	export function v3f_x(v: MoonVecF): number;
	export function v3f_y(v: MoonVecF): number;
	export function v3f_z(v: MoonVecF): number;
	/** Same `number[]` as the vector's internal `FixedArray` (no copy). */
	export function v3f_data(v: MoonVecF): number[];
	export function v3f_add(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v3f_sub(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v3f_neg(v: MoonVecF): MoonVecF;
	export function v3f_mul(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v3f_scale(v: MoonVecF, s: number): MoonVecF;
	export function v3f_div_scalar(v: MoonVecF, s: number): MoonVecF;
	export function v3f_eq(a: MoonVecF, b: MoonVecF): MoonBool;
	export function v3f_to_string(v: MoonVecF): string;

	export function v4f_new(
		x: number,
		y: number,
		z: number,
		w: number,
	): MoonVecF;
	export function v4f_zero(): MoonVecF;
	export function v4f_x(v: MoonVecF): number;
	export function v4f_y(v: MoonVecF): number;
	export function v4f_z(v: MoonVecF): number;
	export function v4f_w(v: MoonVecF): number;
	/** Same `number[]` as the vector's internal `FixedArray` (no copy). */
	export function v4f_data(v: MoonVecF): number[];
	export function v4f_add(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v4f_sub(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v4f_neg(v: MoonVecF): MoonVecF;
	export function v4f_mul(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v4f_scale(v: MoonVecF, s: number): MoonVecF;
	export function v4f_div_scalar(v: MoonVecF, s: number): MoonVecF;
	export function v4f_eq(a: MoonVecF, b: MoonVecF): MoonBool;
	export function v4f_to_string(v: MoonVecF): string;

	export type MoonMat3F = { data: number[] };
	export type MoonMat4F = { data: number[] };

	export function m3f_new_col_major(
		m00: number,
		m10: number,
		m20: number,
		m01: number,
		m11: number,
		m21: number,
		m02: number,
		m12: number,
		m22: number,
	): MoonMat3F;
	export function m3f_zero(): MoonMat3F;
	export function m3f_identity(): MoonMat3F;
	/** Same `number[]` as internal column-major storage (no copy). */
	export function m3f_data(m: MoonMat3F): number[];
	export function m3f_at(m: MoonMat3F, row: number, col: number): number;
	export function m3f_transpose(m: MoonMat3F): MoonMat3F;
	export function m3f_mat_mul(a: MoonMat3F, b: MoonMat3F): MoonMat3F;
	export function m3f_mul_vec(m: MoonMat3F, v: MoonVecF): MoonVecF;
	export function m3f_scale(m: MoonMat3F, s: number): MoonMat3F;
	export function m3f_div_scalar(m: MoonMat3F, s: number): MoonMat3F;
	export function m3f_det(m: MoonMat3F): number;
	/** `Some` value or `undefined` when singular. */
	export function m3f_inverse(m: MoonMat3F): MoonMat3F | undefined;
	export function m3f_add(a: MoonMat3F, b: MoonMat3F): MoonMat3F;
	export function m3f_sub(a: MoonMat3F, b: MoonMat3F): MoonMat3F;
	export function m3f_neg(m: MoonMat3F): MoonMat3F;
	export function m3f_mul(a: MoonMat3F, b: MoonMat3F): MoonMat3F;
	export function m3f_eq(a: MoonMat3F, b: MoonMat3F): MoonBool;
	export function m3f_to_string(m: MoonMat3F): string;

	export function m4f_new_col_major(
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
	): MoonMat4F;
	export function m4f_zero(): MoonMat4F;
	export function m4f_identity(): MoonMat4F;
	export function m4f_rotation_x(angle: number): MoonMat4F;
	export function m4f_rotation_y(angle: number): MoonMat4F;
	export function m4f_rotation_z(angle: number): MoonMat4F;
	export function m4f_translation(tx: number, ty: number, tz: number): MoonMat4F;
	export function m4f_ortho(
		left: number,
		right: number,
		bottom: number,
		top: number,
		near: number,
		far: number,
	): MoonMat4F;
	export function m4f_data(m: MoonMat4F): number[];
	export function m4f_at(m: MoonMat4F, row: number, col: number): number;
	export function m4f_transpose(m: MoonMat4F): MoonMat4F;
	export function m4f_mat_mul(a: MoonMat4F, b: MoonMat4F): MoonMat4F;
	export function m4f_mul_vec4(m: MoonMat4F, v: MoonVecF): MoonVecF;
	export function m4f_transform_point(m: MoonMat4F, p: MoonVecF): MoonVecF;
	export function m4f_scale(m: MoonMat4F, s: number): MoonMat4F;
	export function m4f_div_scalar(m: MoonMat4F, s: number): MoonMat4F;
	export function m4f_det(m: MoonMat4F): number;
	export function m4f_inverse(m: MoonMat4F): MoonMat4F | undefined;
	export function m4f_add(a: MoonMat4F, b: MoonMat4F): MoonMat4F;
	export function m4f_sub(a: MoonMat4F, b: MoonMat4F): MoonMat4F;
	export function m4f_neg(m: MoonMat4F): MoonMat4F;
	export function m4f_mul(a: MoonMat4F, b: MoonMat4F): MoonMat4F;
	export function m4f_eq(a: MoonMat4F, b: MoonMat4F): MoonBool;
	export function m4f_to_string(m: MoonMat4F): string;
}
