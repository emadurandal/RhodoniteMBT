import { describe, expect, it } from "vitest";
import { vec4f, vec4fZero } from "./vector4.ts";

describe("Vector4F (MoonBit js_bridge wrapper)", () => {
	it("Vector4::new and x y z w", () => {
		const v = vec4f(1, 2, 3, 4);
		expect(v.x()).toBeCloseTo(1);
		expect(v.y()).toBeCloseTo(2);
		expect(v.z()).toBeCloseTo(3);
		expect(v.w()).toBeCloseTo(4);
	});

	it("Vector4::zero", () => {
		const z = vec4fZero();
		expect(z.x()).toBeCloseTo(0);
		expect(z.y()).toBeCloseTo(0);
		expect(z.z()).toBeCloseTo(0);
		expect(z.w()).toBeCloseTo(0);
	});

	it("Vector4 add sub neg", () => {
		const a = vec4f(10, 20, 30, 40);
		const b = vec4f(1, 2, 3, 4);
		const sum = a.add(b);
		expect(sum.x()).toBeCloseTo(11);
		expect(sum.y()).toBeCloseTo(22);
		expect(sum.z()).toBeCloseTo(33);
		expect(sum.w()).toBeCloseTo(44);
		const diff = a.sub(b);
		expect(diff.x()).toBeCloseTo(9);
		expect(diff.y()).toBeCloseTo(18);
		expect(diff.z()).toBeCloseTo(27);
		expect(diff.w()).toBeCloseTo(36);
		const nb = b.neg();
		expect(nb.x()).toBeCloseTo(-1);
		expect(nb.y()).toBeCloseTo(-2);
		expect(nb.z()).toBeCloseTo(-3);
		expect(nb.w()).toBeCloseTo(-4);
	});

	it("Vector4 Hadamard mul", () => {
		const a = vec4f(2, 3, 4, 5);
		const b = vec4f(6, 7, 8, 9);
		const h = a.mul(b);
		expect(h.x()).toBeCloseTo(12);
		expect(h.y()).toBeCloseTo(21);
		expect(h.z()).toBeCloseTo(32);
		expect(h.w()).toBeCloseTo(45);
	});

	it("Vector4 scale div_scalar", () => {
		const v = vec4f(8, 12, 16, 20);
		const s = v.scale(2);
		expect(s.x()).toBeCloseTo(16);
		expect(s.y()).toBeCloseTo(24);
		expect(s.z()).toBeCloseTo(32);
		expect(s.w()).toBeCloseTo(40);
		const d = v.divScalar(4);
		expect(d.x()).toBeCloseTo(2);
		expect(d.y()).toBeCloseTo(3);
		expect(d.z()).toBeCloseTo(4);
		expect(d.w()).toBeCloseTo(5);
	});

	it("Vector4 Eq", () => {
		expect(vec4f(1, 2, 3, 4).eq(vec4f(1, 2, 3, 4))).toBe(true);
		expect(vec4f(1, 2, 3, 4).eq(vec4f(1, 2, 3, 5))).toBe(false);
	});

	it("Vector4 Show", () => {
		expect(vec4f(1, 2, 3, 4).toString()).toBe(
			"Vector4::new(1, 2, 3, 4)",
		);
	});
});
