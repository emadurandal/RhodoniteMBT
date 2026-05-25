// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

export { describe, expect, it } from "vitest";
export {
	ComponentTypeId,
	EntityId,
	GpuLayout,
	PhaseKey,
	Query,
	RawQuery,
	System,
	SystemContext,
	SystemRunner,
	World,
	WorldHistory,
	decodeHistoryExportJson,
	encodeHistoryExportJson,
	getF32,
} from "../index.ts";

export function f32Bytes(
	values: number[],
	stride = values.length * 4,
): Uint8Array {
	const bytes = new Uint8Array(stride);
	const view = new DataView(bytes.buffer);
	values.forEach((value, index) => view.setFloat32(index * 4, value, true));
	return bytes;
}

export function identityMat4ColMajor(): number[] {
	return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
}

export function translationMat4ColMajor(
	tx: number,
	ty: number,
	tz: number,
): number[] {
	return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, tx, ty, tz, 1];
}

export function globalTransformFormatCode(refs: Uint8Array): number {
	return new DataView(refs.buffer, refs.byteOffset, refs.byteLength).getUint32(
		0,
		true,
	);
}
