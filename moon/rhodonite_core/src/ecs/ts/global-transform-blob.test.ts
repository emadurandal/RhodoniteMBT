import { describe, expect, it } from "vitest";
import {
	GlobalTransformBlobWriter,
	computeGlobalTransformUploadRange,
	detectDenseGlobalTransformLayout,
	detectGlobalTransformRuns,
	writeGlobalTransformBlobByRefs,
} from "./global-transform-blob.ts";
import { ByteView } from "./views.ts";

function byteView(bytes: Uint8Array): ByteView {
	return new ByteView({ buf: bytes, start: 0, end: bytes.byteLength });
}

describe("GlobalTransform blob helpers", () => {
	it("detects dense refs and computes upload ranges", () => {
		const refs = new Uint32Array([1, 0, 1, 6, 1, 12]);
		const dense = detectDenseGlobalTransformLayout(refs, 3);
		expect(dense).toEqual({ format: 1, wordsPerEntity: 6 });
		expect(computeGlobalTransformUploadRange(refs, 3, dense)).toEqual({
			firstWord: 0,
			wordCount: 18,
		});
	});

	it("writes fp32 and fp16 affine rows through one writer", () => {
		const bytes = new Uint8Array(18 * 4);
		const refs = new Uint32Array([0, 0, 1, 12]);
		writeGlobalTransformBlobByRefs(byteView(bytes), {
			refs,
			count: 2,
			firstWord: 0,
			denseLayout: null,
			write: (writer) => {
				writer.setAffine3x4At(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
				writer.setAffine3x4At(1, 1, 0, 0, 2, 0, 1, 0, 3, 0, 0, 1, 4);
			},
		});

		expect(Array.from(new Float32Array(bytes.buffer, 0, 12))).toEqual([
			1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
		]);
		expect(Array.from(new Uint16Array(bytes.buffer, 12 * 4, 12))).toEqual([
			0x3c00, 0, 0, 0x4000, 0, 0x3c00, 0, 0x4200, 0, 0, 0x3c00, 0x4400,
		]);
	});

	it("updates a single affine element for either precision", () => {
		const bytes = new Uint8Array(18 * 4);
		const refs = new Uint32Array([0, 0, 1, 12]);
		const writer = new GlobalTransformBlobWriter(byteView(bytes), {
			refs,
			count: 2,
			firstWord: 0,
			denseLayout: null,
		});

		writer.setElementAt(0, 1, 3, 2);
		writer.setElementAt(1, 1, 3, 2);

		expect(new Float32Array(bytes.buffer, 0, 12)[7]).toBe(2);
		expect(new Uint16Array(bytes.buffer, 12 * 4, 12)[7]).toBe(0x4000);
	});

	it("creates a reusable affine element setter", () => {
		const bytes = new Uint8Array(18 * 4);
		const refs = new Uint32Array([1, 0, 1, 6, 1, 12]);
		const writer = new GlobalTransformBlobWriter(byteView(bytes), {
			refs,
			count: 3,
			firstWord: 0,
			denseLayout: { format: 1, wordsPerEntity: 6 },
		});

		const setY = writer.elementSetter(1, 3);
		setY(0, 1);
		setY(1, 2);
		setY(2, 4);

		expect(new Uint16Array(bytes.buffer)[7]).toBe(0x3c00);
		expect(new Uint16Array(bytes.buffer)[19]).toBe(0x4000);
		expect(new Uint16Array(bytes.buffer)[31]).toBe(0x4400);
	});

	it("uses contiguous mixed precision runs for scalar setters", () => {
		const bytes = new Uint8Array(36 * 4);
		const refs = new Uint32Array([0, 0, 0, 12, 1, 24, 1, 30]);
		expect(detectGlobalTransformRuns(refs, 4)).toEqual([
			{ firstIndex: 0, endIndex: 2, format: 0, firstWord: 0, wordsPerEntity: 12 },
			{ firstIndex: 2, endIndex: 4, format: 1, firstWord: 24, wordsPerEntity: 6 },
		]);
		const writer = new GlobalTransformBlobWriter(byteView(bytes), {
			refs,
			count: 4,
			firstWord: 0,
			denseLayout: null,
		});

		const setY = writer.elementSetter(1, 3);
		setY(0, 1);
		setY(1, 2);
		setY(2, 4);
		setY(3, 8);

		const floats = new Float32Array(bytes.buffer);
		const halves = new Uint16Array(bytes.buffer);
		expect(floats[7]).toBe(1);
		expect(floats[19]).toBe(2);
		expect(halves[24 * 2 + 7]).toBe(0x4400);
		expect(halves[30 * 2 + 7]).toBe(0x4800);
	});
});
