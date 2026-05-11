import { describe, expect, it } from "vitest";
import { Matrix44F } from "./matrix44.ts";
import { Vector3F } from "./vector3.ts";
import { Vector4F } from "./vector4.ts";

describe("Matrix44F (MoonBit js_bridge wrapper)", () => {
	it("identity mulVec4", () => {
		const id = Matrix44F.identity();
		const v = Vector4F.new(2, 3, 4, 5);
		const o = id.mulVec4(v);
		expect(o.x()).toBeCloseTo(2);
		expect(o.y()).toBeCloseTo(3);
		expect(o.z()).toBeCloseTo(4);
		expect(o.w()).toBeCloseTo(5);
	});

	it("matMul diagonal", () => {
		const s = Matrix44F.newColMajor(
			2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2,
		);
		const t = Matrix44F.newColMajor(
			3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3,
		);
		const p = s.matMul(t);
		expect(p.at(0, 0)).toBeCloseTo(6);
		expect(p.at(1, 1)).toBeCloseTo(6);
		expect(p.at(2, 2)).toBeCloseTo(6);
		expect(p.at(3, 3)).toBeCloseTo(6);
	});

	it("transpose col_major_1_to_16", () => {
		const m = Matrix44F.newColMajor(
			1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
		);
		const t = Matrix44F.newColMajor(
			1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16,
		);
		expect(m.transpose().eq(t)).toBe(true);
	});

	it("transformPoint translation", () => {
		const m = Matrix44F.newColMajor(
			1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 30, 1,
		);
		const p = Vector3F.new(1, 2, 3);
		const q = m.transformPoint(p);
		expect(q.x()).toBeCloseTo(11);
		expect(q.y()).toBeCloseTo(22);
		expect(q.z()).toBeCloseTo(33);
	});

	it("det and inverse", () => {
		const m = Matrix44F.newColMajor(
			2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2,
		);
		expect(m.det()).toBeCloseTo(16);
		const inv = m.inverse();
		expect(inv).not.toBeNull();
		expect(inv!.matMul(m).eq(Matrix44F.identity())).toBe(true);
	});

	it("singular inverse returns null", () => {
		const m = Matrix44F.newColMajor(
			1, 2, 3, 4, 2, 4, 6, 8, 3, 6, 9, 12, 4, 8, 12, 16,
		);
		expect(m.det()).toBeCloseTo(0);
		expect(m.inverse()).toBeNull();
	});

	it("toString", () => {
		expect(Matrix44F.identity().toString()).toBe(
			"Matrix44::new_col_major(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)",
		);
	});
});
