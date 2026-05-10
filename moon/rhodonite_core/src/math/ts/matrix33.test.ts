import { describe, expect, it } from "vitest";
import { Matrix3F } from "./matrix33.ts";
import { Vector3F } from "./vector3.ts";

describe("Matrix3F (MoonBit js_bridge wrapper)", () => {
	it("identity mulVec", () => {
		const id = Matrix3F.identity();
		const v = Vector3F.new(2, 3, 4);
		const o = id.mulVec(v);
		expect(o.x()).toBeCloseTo(2);
		expect(o.y()).toBeCloseTo(3);
		expect(o.z()).toBeCloseTo(4);
	});

	it("matMul diagonal scales", () => {
		const s = Matrix3F.newColMajor(2, 0, 0, 0, 2, 0, 0, 0, 2);
		const t = Matrix3F.newColMajor(3, 0, 0, 0, 3, 0, 0, 0, 3);
		const p = s.matMul(t);
		expect(p.at(0, 0)).toBeCloseTo(6);
		expect(p.at(1, 1)).toBeCloseTo(6);
		expect(p.at(2, 2)).toBeCloseTo(6);
	});

	it("transpose twice", () => {
		const m = Matrix3F.newColMajor(1, 2, 3, 4, 5, 6, 7, 8, 9);
		expect(m.transpose().transpose().eq(m)).toBe(true);
	});

	it("Hadamard mul", () => {
		const a = Matrix3F.newColMajor(2, 3, 4, 1, 1, 1, 0, 0, 0);
		const b = Matrix3F.newColMajor(5, 6, 7, 2, 2, 2, 1, 1, 1);
		const h = a.mul(b);
		expect(h.at(0, 0)).toBeCloseTo(10);
		expect(h.at(1, 0)).toBeCloseTo(18);
		expect(h.at(2, 0)).toBeCloseTo(28);
	});

	it("det and inverse", () => {
		const m = Matrix3F.newColMajor(1, 0, 0, 0, 2, 0, 0, 0, 4);
		expect(m.det()).toBeCloseTo(8);
		const inv = m.inverse();
		expect(inv).not.toBeNull();
		expect(inv!.matMul(m).eq(Matrix3F.identity())).toBe(true);
	});

	it("singular inverse returns null", () => {
		const m = Matrix3F.newColMajor(1, 2, 3, 4, 5, 6, 7, 8, 9);
		expect(m.det()).toBeCloseTo(0);
		expect(m.inverse()).toBeNull();
	});

	it("toString", () => {
		expect(Matrix3F.identity().toString()).toBe(
			"Matrix3::new_col_major(1, 0, 0, 0, 1, 0, 0, 0, 1)",
		);
	});
});
