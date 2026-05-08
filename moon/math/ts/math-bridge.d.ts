/** Generated MoonBit js_bridge bindings (`moon build --target js --release`). */
declare module "@moon/math/js_bridge" {
	export type MoonVecF = { data: number[] };

	export function v3f_new(x: number, y: number, z: number): MoonVecF;
	export function v3f_zero(): MoonVecF;
	export function v3f_x(v: MoonVecF): number;
	export function v3f_y(v: MoonVecF): number;
	export function v3f_z(v: MoonVecF): number;
	/** ベクトル内部の `FixedArray` と同一の `number[]`（コピーなし）。 */
	export function v3f_data(v: MoonVecF): number[];
	export function v3f_add(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v3f_sub(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v3f_neg(v: MoonVecF): MoonVecF;
	export function v3f_mul(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v3f_scale(v: MoonVecF, s: number): MoonVecF;
	export function v3f_div_scalar(v: MoonVecF, s: number): MoonVecF;
	/** MoonBit `Bool` は JS では `0 | 1`。 */
	export function v3f_eq(a: MoonVecF, b: MoonVecF): 0 | 1;
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
	/** ベクトル内部の `FixedArray` と同一の `number[]`（コピーなし）。 */
	export function v4f_data(v: MoonVecF): number[];
	export function v4f_add(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v4f_sub(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v4f_neg(v: MoonVecF): MoonVecF;
	export function v4f_mul(a: MoonVecF, b: MoonVecF): MoonVecF;
	export function v4f_scale(v: MoonVecF, s: number): MoonVecF;
	export function v4f_div_scalar(v: MoonVecF, s: number): MoonVecF;
	/** MoonBit `Bool` は JS では `0 | 1`。 */
	export function v4f_eq(a: MoonVecF, b: MoonVecF): 0 | 1;
	export function v4f_to_string(v: MoonVecF): string;
}
