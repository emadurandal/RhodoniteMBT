// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonGpuWriteCopy,
	MoonGpuWriteView,
	MoonSpawnBatchRow,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	gpu_write_copy_byte_offset,
	gpu_write_copy_bytes,
	gpu_write_view_byte_offset,
	gpu_write_view_bytes,
	spawn_batch_row_entity,
	spawn_batch_row_write,
	spawn_batch_row_write_view,
} from "@moon/rhodonite_core/ecs/js_bridge";
import { ComponentTypeId, EntityId } from "./types.ts";
import { type ByteView, byteView } from "./views.ts";

export class SpawnBatchRow {
	readonly inner: MoonSpawnBatchRow;

	constructor(inner: MoonSpawnBatchRow) {
		this.inner = inner;
	}

	entity(): EntityId {
		return new EntityId(spawn_batch_row_entity(this.inner));
	}

	writeView(component: ComponentTypeId): ByteView {
		return byteView(spawn_batch_row_write_view(this.inner, component.inner));
	}

	write(component: ComponentTypeId, f: (bytes: ByteView) => void): void {
		spawn_batch_row_write(this.inner, component.inner, (bytes) =>
			f(byteView(bytes)),
		);
	}
}

export class GpuWriteView {
	readonly inner: MoonGpuWriteView;

	constructor(inner: MoonGpuWriteView) {
		this.inner = inner;
	}

	byteOffset(): number {
		return gpu_write_view_byte_offset(this.inner);
	}

	bytes(): ByteView {
		return byteView(gpu_write_view_bytes(this.inner));
	}
}

export class GpuWriteCopy {
	readonly inner: MoonGpuWriteCopy;

	constructor(inner: MoonGpuWriteCopy) {
		this.inner = inner;
	}

	byteOffset(): number {
		return gpu_write_copy_byte_offset(this.inner);
	}

	bytes(): Uint8Array {
		const bytes = gpu_write_copy_bytes(this.inner);
		return bytes instanceof Uint8Array
			? new Uint8Array(bytes)
			: Uint8Array.from(bytes);
	}
}
