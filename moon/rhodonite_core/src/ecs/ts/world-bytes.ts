// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { bytes_get_f32, bytes_put_f32 } from "@moon/rhodonite_core/ecs/js_bridge";

export function getF32(bytes: Uint8Array | number[], offset: number): number {
	return bytes_get_f32(bytes, offset);
}

export function putF32(
	bytes: Uint8Array | number[],
	offset: number,
	value: number,
): void {
	bytes_put_f32(bytes, offset, value);
}
