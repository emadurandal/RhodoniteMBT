import { describe, expect, it } from "vitest";
import { Vector3F } from "./vector3.ts";

describe("Vector3F (MoonBit js_bridge wrapper)", () => {
	it("Vector3::new and x y z", () => {
		const v = Vector3F.new(1, 2, 3);
		expect(v.x()).toBeCloseTo(1);
		expect(v.y()).toBeCloseTo(2);
		expect(v.z()).toBeCloseTo(3);
	});

	it("Vector3::zero", () => {
		const z = Vector3F.zero();
		expect(z.x()).toBeCloseTo(0);
		expect(z.y()).toBeCloseTo(0);
		expect(z.z()).toBeCloseTo(0);
	});

	it("Vector3 data() shares reference with inner.data", () => {
		const v = Vector3F.new(1, 2, 3);
		const a = v.data();
		expect(a).toBe(v.inner.data);
		expect(a[0]).toBeCloseTo(1);
		expect(a[1]).toBeCloseTo(2);
		expect(a[2]).toBeCloseTo(3);
	});

	it("Vector3 add sub neg", () => {
		const a = Vector3F.new(10, 20, 30);
		const b = Vector3F.new(1, 2, 3);
		const sum = a.add(b);
		expect(sum.x()).toBeCloseTo(11);
		expect(sum.y()).toBeCloseTo(22);
		expect(sum.z()).toBeCloseTo(33);
		const diff = a.sub(b);
		expect(diff.x()).toBeCloseTo(9);
		expect(diff.y()).toBeCloseTo(18);
		expect(diff.z()).toBeCloseTo(27);
		const nb = b.neg();
		expect(nb.x()).toBeCloseTo(-1);
		expect(nb.y()).toBeCloseTo(-2);
		expect(nb.z()).toBeCloseTo(-3);
	});

	it("Vector3 Hadamard mul", () => {
		const a = Vector3F.new(2, 3, 4);
		const b = Vector3F.new(5, 6, 7);
		const h = a.mul(b);
		expect(h.x()).toBeCloseTo(10);
		expect(h.y()).toBeCloseTo(18);
		expect(h.z()).toBeCloseTo(28);
	});

	it("Vector3 scale div_scalar", () => {
		const v = Vector3F.new(6, 9, 12);
		const s = v.scale(2);
		expect(s.x()).toBeCloseTo(12);
		expect(s.y()).toBeCloseTo(18);
		expect(s.z()).toBeCloseTo(24);
		const d = v.divScalar(3);
		expect(d.x()).toBeCloseTo(2);
		expect(d.y()).toBeCloseTo(3);
		expect(d.z()).toBeCloseTo(4);
	});

	it("Vector3 Eq", () => {
		expect(Vector3F.new(1, 2, 3).eq(Vector3F.new(1, 2, 3))).toBe(true);
		expect(Vector3F.new(1, 2, 3).eq(Vector3F.new(1, 2, 4))).toBe(false);
	});

	it("Vector3 Show", () => {
		expect(Vector3F.new(1, 2, 3).toString()).toBe("Vector3::new(1, 2, 3)");
	});
});
