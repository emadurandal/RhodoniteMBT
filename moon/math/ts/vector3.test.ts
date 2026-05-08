import { describe, expect, it } from "vitest";
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
	v3f_x,
	v3f_y,
	v3f_z,
	v3f_zero,
} from "@moon/math/js_bridge";

describe("Vector3F (MoonBit js_bridge)", () => {
	it("Vector3::new and x y z", () => {
		const v = v3f_new(1, 2, 3);
		expect(v3f_x(v)).toBeCloseTo(1);
		expect(v3f_y(v)).toBeCloseTo(2);
		expect(v3f_z(v)).toBeCloseTo(3);
	});

	it("Vector3::zero", () => {
		const z = v3f_zero();
		expect(v3f_x(z)).toBeCloseTo(0);
		expect(v3f_y(z)).toBeCloseTo(0);
		expect(v3f_z(z)).toBeCloseTo(0);
	});

	it("Vector3 add sub neg", () => {
		const a = v3f_new(10, 20, 30);
		const b = v3f_new(1, 2, 3);
		const sum = v3f_add(a, b);
		expect(v3f_x(sum)).toBeCloseTo(11);
		expect(v3f_y(sum)).toBeCloseTo(22);
		expect(v3f_z(sum)).toBeCloseTo(33);
		const diff = v3f_sub(a, b);
		expect(v3f_x(diff)).toBeCloseTo(9);
		expect(v3f_y(diff)).toBeCloseTo(18);
		expect(v3f_z(diff)).toBeCloseTo(27);
		const nb = v3f_neg(b);
		expect(v3f_x(nb)).toBeCloseTo(-1);
		expect(v3f_y(nb)).toBeCloseTo(-2);
		expect(v3f_z(nb)).toBeCloseTo(-3);
	});

	it("Vector3 Hadamard mul", () => {
		const a = v3f_new(2, 3, 4);
		const b = v3f_new(5, 6, 7);
		const h = v3f_mul(a, b);
		expect(v3f_x(h)).toBeCloseTo(10);
		expect(v3f_y(h)).toBeCloseTo(18);
		expect(v3f_z(h)).toBeCloseTo(28);
	});

	it("Vector3 scale div_scalar", () => {
		const v = v3f_new(6, 9, 12);
		const s = v3f_scale(v, 2);
		expect(v3f_x(s)).toBeCloseTo(12);
		expect(v3f_y(s)).toBeCloseTo(18);
		expect(v3f_z(s)).toBeCloseTo(24);
		const d = v3f_div_scalar(v, 3);
		expect(v3f_x(d)).toBeCloseTo(2);
		expect(v3f_y(d)).toBeCloseTo(3);
		expect(v3f_z(d)).toBeCloseTo(4);
	});

	it("Vector3 Eq", () => {
		expect(v3f_eq(v3f_new(1, 2, 3), v3f_new(1, 2, 3))).toBe(1);
		expect(v3f_eq(v3f_new(1, 2, 3), v3f_new(1, 2, 4))).toBe(0);
	});

	it("Vector3 Show", () => {
		expect(v3f_to_string(v3f_new(1, 2, 3))).toBe("Vector3::new(1, 2, 3)");
	});
});
