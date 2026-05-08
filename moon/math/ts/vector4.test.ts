import { describe, expect, it } from "vitest";
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

describe("Vector4F (MoonBit js_bridge)", () => {
	it("Vector4::new and x y z w", () => {
		const v = v4f_new(1, 2, 3, 4);
		expect(v4f_x(v)).toBeCloseTo(1);
		expect(v4f_y(v)).toBeCloseTo(2);
		expect(v4f_z(v)).toBeCloseTo(3);
		expect(v4f_w(v)).toBeCloseTo(4);
	});

	it("Vector4::zero", () => {
		const z = v4f_zero();
		expect(v4f_x(z)).toBeCloseTo(0);
		expect(v4f_y(z)).toBeCloseTo(0);
		expect(v4f_z(z)).toBeCloseTo(0);
		expect(v4f_w(z)).toBeCloseTo(0);
	});

	it("Vector4 add sub neg", () => {
		const a = v4f_new(10, 20, 30, 40);
		const b = v4f_new(1, 2, 3, 4);
		const sum = v4f_add(a, b);
		expect(v4f_x(sum)).toBeCloseTo(11);
		expect(v4f_y(sum)).toBeCloseTo(22);
		expect(v4f_z(sum)).toBeCloseTo(33);
		expect(v4f_w(sum)).toBeCloseTo(44);
		const diff = v4f_sub(a, b);
		expect(v4f_x(diff)).toBeCloseTo(9);
		expect(v4f_y(diff)).toBeCloseTo(18);
		expect(v4f_z(diff)).toBeCloseTo(27);
		expect(v4f_w(diff)).toBeCloseTo(36);
		const nb = v4f_neg(b);
		expect(v4f_x(nb)).toBeCloseTo(-1);
		expect(v4f_y(nb)).toBeCloseTo(-2);
		expect(v4f_z(nb)).toBeCloseTo(-3);
		expect(v4f_w(nb)).toBeCloseTo(-4);
	});

	it("Vector4 Hadamard mul", () => {
		const a = v4f_new(2, 3, 4, 5);
		const b = v4f_new(6, 7, 8, 9);
		const h = v4f_mul(a, b);
		expect(v4f_x(h)).toBeCloseTo(12);
		expect(v4f_y(h)).toBeCloseTo(21);
		expect(v4f_z(h)).toBeCloseTo(32);
		expect(v4f_w(h)).toBeCloseTo(45);
	});

	it("Vector4 scale div_scalar", () => {
		const v = v4f_new(8, 12, 16, 20);
		const s = v4f_scale(v, 2);
		expect(v4f_x(s)).toBeCloseTo(16);
		expect(v4f_y(s)).toBeCloseTo(24);
		expect(v4f_z(s)).toBeCloseTo(32);
		expect(v4f_w(s)).toBeCloseTo(40);
		const d = v4f_div_scalar(v, 4);
		expect(v4f_x(d)).toBeCloseTo(2);
		expect(v4f_y(d)).toBeCloseTo(3);
		expect(v4f_z(d)).toBeCloseTo(4);
		expect(v4f_w(d)).toBeCloseTo(5);
	});

	it("Vector4 Eq", () => {
		expect(v4f_eq(v4f_new(1, 2, 3, 4), v4f_new(1, 2, 3, 4))).toBe(1);
		expect(v4f_eq(v4f_new(1, 2, 3, 4), v4f_new(1, 2, 3, 5))).toBe(0);
	});

	it("Vector4 Show", () => {
		expect(v4f_to_string(v4f_new(1, 2, 3, 4))).toBe(
			"Vector4::new(1, 2, 3, 4)",
		);
	});
});
