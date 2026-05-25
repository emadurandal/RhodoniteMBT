// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonComponentTypeId,
	MoonEntityId,
	MoonGpuWriteCopy,
	MoonGpuWriteView,
	MoonSpawnBatchRow,
	MoonWorld,
	MoonWorldHistoryDeltaSummary,
	MoonWorldHistoryExport,
	MoonWorldHistoryExportComponentIdentity,
	MoonWorldHistoryExportComponentSnapshot,
	MoonWorldHistoryExportDelta,
	MoonWorldHistoryExportPayload,
	MoonWorldHistoryExportRecord,
	MoonWorldHistoryImportValidationDeltaReport,
	MoonWorldHistoryImportValidationRecordReport,
	MoonWorldHistoryImportValidationReport,
	MoonWorldHistoryRecordSummary,
	MoonWorldHistorySerializationComponentReport,
	MoonWorldHistorySerializationDeltaReport,
	MoonWorldHistorySerializationRecordReport,
	MoonWorldHistorySerializationReport,
	MoonWorldHistory,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	bytes_get_f32,
	bytes_put_f32,
	gpu_write_copy_byte_offset,
	gpu_write_copy_bytes,
	gpu_write_view_byte_offset,
	gpu_write_view_bytes,
	world_add_component,
	world_add_component_bytes,
	world_camera_blob_word_capacity,
	world_camera_component,
	world_camera_home_transform_component,
	world_camera_lens_component,
	world_child_of_component,
	world_component_by_stable_key,
	world_component_bytes_copy,
	world_component_cpu_stride,
	world_component_info,
	world_component_matches_identity,
	world_create_entity,
	world_destroy_entity,
	world_drain_global_transform_blob_write_views,
	world_drain_camera_blob_write_views,
	world_write_global_transform_blob_range_views,
	world_global_transform_component,
	world_global_transform_blob_word_capacity,
	world_has_component,
	world_is_alive,
	world_location,
	world_new,
	world_new_with_global_transform_f16,
	world_orbit_camera_controller_component,
	world_register_cpu_component,
	world_register_cpu_component_with_identity,
	world_remove_component,
	world_camera_gpu_row_copy,
	world_set_camera_matrices_col_major,
	world_set_child_of,
	world_set_component_bytes,
	world_get_global_transform_col_major,
	world_set_global_transform_col_major,
	world_set_global_transform_format,
	world_set_transform_trs,
	spawn_batch_row_entity,
	spawn_batch_row_write,
	spawn_batch_row_write_view,
	world_reserve_batch_capacity,
	world_spawn_batch,
	world_spawn_transform_global_batch_identity,
	world_transform_component,
	world_update_global_transforms_from_transforms,
	world_extract_global_transform_refs,
	world_write_global_transforms_dense_range_views,
	world_history_add_component,
	world_history_add_component_bytes,
	world_history_add_component_bytes_many,
	world_history_begin_guarded_transaction,
	world_history_begin_transaction,
	world_history_can_redo,
	world_history_can_undo,
	world_history_cancel_transaction,
	world_history_cancel_transaction_reverting,
	world_history_clear,
	world_history_commit_transaction,
	world_history_create_entities,
	world_history_create_entity,
	world_history_delta_summary_after_present,
	world_history_delta_summary_before_present,
	world_history_delta_summary_component,
	world_history_delta_summary_component_count,
	world_history_delta_summary_entity,
	world_history_delta_summary_kind,
	world_history_delta_summary_payload_bytes,
	world_history_destroy_entity,
	world_history_enabled,
	world_history_export_component_identity_builtin,
	world_history_export_component_identity_key,
	world_history_export_component_identity_local_component,
	world_history_export_component_identity_schema_hash,
	world_history_export_component_identity_schema_version,
	world_history_export_component_identity_new,
	world_history_export_component_snapshot_bytes,
	world_history_export_component_snapshot_component,
	world_history_export_component_snapshot_new,
	world_history_export_delta_after,
	world_history_export_delta_before,
	world_history_export_delta_component,
	world_history_export_delta_components,
	world_history_export_delta_entity,
	world_history_export_delta_kind,
	world_history_export_delta_new,
	world_history_export_format_version,
	world_history_export_new,
	world_history_export_payload_bytes,
	world_history_export_payload_global_transform_format,
	world_history_export_payload_new,
	world_history_export_record_count,
	world_history_export_record_delta_count,
	world_history_export_record_deltas,
	world_history_export_record_label,
	world_history_export_record_new,
	world_history_export_records,
	world_history_export_redo_stack,
	world_history_export_undo_stack,
	world_history_import_redo_stack,
	world_history_import_undo_stack,
	world_history_import_validation_delta_report_component,
	world_history_import_validation_delta_report_component_key,
	world_history_import_validation_delta_report_entity,
	world_history_import_validation_delta_report_index,
	world_history_import_validation_delta_report_kind,
	world_history_import_validation_delta_report_reason,
	world_history_import_validation_delta_report_valid,
	world_history_import_validation_record_report_delta_count,
	world_history_import_validation_record_report_deltas,
	world_history_import_validation_record_report_index,
	world_history_import_validation_record_report_label,
	world_history_import_validation_record_report_reason,
	world_history_import_validation_record_report_valid,
	world_history_import_validation_report_format_version,
	world_history_import_validation_report_reason,
	world_history_import_validation_report_record_count,
	world_history_import_validation_report_records,
	world_history_import_validation_report_valid,
	world_history_last_diagnostic,
	world_history_max_undo_bytes,
	world_history_max_undo_records,
	world_history_new,
	world_history_raw_mutation_guard_enabled,
	world_history_redo,
	world_history_redo_bytes,
	world_history_redo_label,
	world_history_redo_len,
	world_history_redo_serialization_report,
	world_history_redo_summary,
	world_history_remove_component,
	world_history_record_summary_delta_count,
	world_history_record_summary_deltas,
	world_history_record_summary_label,
	world_history_record_summary_payload_bytes,
	world_history_run_system_phase,
	world_history_serialization_component_report_component,
	world_history_serialization_component_report_reason,
	world_history_serialization_component_report_serializable,
	world_history_serialization_component_report_stable_key,
	world_history_serialization_delta_report_component,
	world_history_serialization_delta_report_component_count,
	world_history_serialization_delta_report_components,
	world_history_serialization_delta_report_entity,
	world_history_serialization_delta_report_kind,
	world_history_serialization_delta_report_payload_bytes,
	world_history_serialization_delta_report_reason,
	world_history_serialization_delta_report_serializable,
	world_history_serialization_record_report_delta_count,
	world_history_serialization_record_report_deltas,
	world_history_serialization_record_report_label,
	world_history_serialization_record_report_payload_bytes,
	world_history_serialization_record_report_reason,
	world_history_serialization_record_report_serializable,
	world_history_serialization_report_record_count,
	world_history_serialization_report_records,
	world_history_serialization_report_serializable,
	world_history_set_child_of,
	world_history_set_camera_matrices_col_major,
	world_history_set_component_bytes,
	world_history_set_component_bytes_many,
	world_history_set_enabled,
	world_history_set_global_transform_col_major,
	world_history_set_global_transform_format,
	world_history_set_max_undo_bytes,
	world_history_set_max_undo_records,
	world_history_set_raw_mutation_guard_enabled,
	world_history_spawn_batch,
	world_history_set_transform_trs,
	world_history_undo,
	world_history_undo_bytes,
	world_history_undo_label,
	world_history_undo_len,
	world_history_undo_serialization_report,
	world_history_undo_summary,
	world_history_validate_import_redo_stack,
	world_history_validate_import_undo_stack,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	ComponentTypeId,
	EntityId,
	type EntityLocation,
	RegisteredComponent,
} from "./types.ts";
import type { PhaseKey, SystemContext, SystemRunner } from "./system.ts";
import { ByteView, byteView, bytesInput, moonBool } from "./views.ts";

export type CpuComponentIdentity = {
	readonly stableKey: string;
	readonly schemaVersion?: string;
	readonly schemaHash?: string;
};

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
		return bytes instanceof Uint8Array ? new Uint8Array(bytes) : Uint8Array.from(bytes);
	}
}

export class World {
	readonly inner: MoonWorld;

	constructor(inner: MoonWorld) {
		this.inner = inner;
	}

	static new(): World {
		return new World(world_new());
	}

	static newWithGlobalTransformF16(): World {
		return new World(world_new_with_global_transform_f16());
	}

	createEntity(): EntityId {
		return new EntityId(world_create_entity(this.inner));
	}

	destroyEntity(entity: EntityId): boolean {
		return moonBool(world_destroy_entity(this.inner, entity.inner));
	}

	isAlive(entity: EntityId): boolean {
		return moonBool(world_is_alive(this.inner, entity.inner));
	}

	transformComponent(): ComponentTypeId {
		return new ComponentTypeId(world_transform_component(this.inner));
	}

	globalTransformComponent(): ComponentTypeId {
		return new ComponentTypeId(world_global_transform_component(this.inner));
	}

	childOfComponent(): ComponentTypeId {
		return new ComponentTypeId(world_child_of_component(this.inner));
	}

	cameraComponent(): ComponentTypeId {
		return new ComponentTypeId(world_camera_component(this.inner));
	}

	orbitCameraControllerComponent(): ComponentTypeId {
		return new ComponentTypeId(
			world_orbit_camera_controller_component(this.inner),
		);
	}

	cameraHomeTransformComponent(): ComponentTypeId {
		return new ComponentTypeId(
			world_camera_home_transform_component(this.inner),
		);
	}

	cameraLensComponent(): ComponentTypeId {
		return new ComponentTypeId(world_camera_lens_component(this.inner));
	}

	location(entity: EntityId): EntityLocation | null {
		const location = world_location(this.inner, entity.inner);
		return location === undefined || location === null
			? null
			: { archetypeIndex: location.archetype_index, row: location.row };
	}

	registerCpuComponent(name: string, cpuStride: number): ComponentTypeId {
		return new ComponentTypeId(
			world_register_cpu_component(this.inner, name, cpuStride),
		);
	}

	registerCpuComponentWithIdentity(
		name: string,
		cpuStride: number,
		identity: CpuComponentIdentity,
	): ComponentTypeId {
		return new ComponentTypeId(
			world_register_cpu_component_with_identity(
				this.inner,
				name,
				cpuStride,
				identity.stableKey,
				identity.schemaVersion,
				identity.schemaHash,
			),
		);
	}

	componentCpuStride(component: ComponentTypeId): number | null {
		return world_component_cpu_stride(this.inner, component.inner) ?? null;
	}

	componentInfo(component: ComponentTypeId): RegisteredComponent | null {
		const info = world_component_info(this.inner, component.inner);
		return info === undefined || info === null ? null : new RegisteredComponent(info);
	}

	componentByStableKey(stableKey: string): ComponentTypeId | null {
		const component = world_component_by_stable_key(this.inner, stableKey);
		return component === undefined || component === null
			? null
			: new ComponentTypeId(component);
	}

	componentMatchesIdentity(
		component: ComponentTypeId,
		identity: CpuComponentIdentity,
	): boolean {
		return moonBool(
			world_component_matches_identity(
				this.inner,
				component.inner,
				identity.stableKey,
				identity.schemaVersion,
				identity.schemaHash,
			),
		);
	}

	hasComponent(entity: EntityId, component: ComponentTypeId): boolean {
		return moonBool(world_has_component(this.inner, entity.inner, component.inner));
	}

	addComponent(entity: EntityId, component: ComponentTypeId): boolean {
		return moonBool(world_add_component(this.inner, entity.inner, component.inner));
	}

	addComponentBytes(
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): boolean {
		return moonBool(
			world_add_component_bytes(
				this.inner,
				entity.inner,
				component.inner,
				bytesInput(bytes),
			),
		);
	}

	setComponentBytes(
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): boolean {
		return moonBool(
			world_set_component_bytes(
				this.inner,
				entity.inner,
				component.inner,
				bytesInput(bytes),
			),
		);
	}

	removeComponent(entity: EntityId, component: ComponentTypeId): boolean {
		return moonBool(world_remove_component(this.inner, entity.inner, component.inner));
	}

	componentBytesCopy(
		entity: EntityId,
		component: ComponentTypeId,
	): Uint8Array | null {
		const bytes = world_component_bytes_copy(this.inner, entity.inner, component.inner);
		if (bytes === undefined || bytes === null) {
			return null;
		}
		return bytes instanceof Uint8Array ? new Uint8Array(bytes) : Uint8Array.from(bytes);
	}

	drainGlobalTransformBlobWriteViews(): GpuWriteView[] {
		return world_drain_global_transform_blob_write_views(this.inner).map(
			(write) => new GpuWriteView(write),
		);
	}

	drainCameraBlobWriteViews(): GpuWriteView[] {
		return world_drain_camera_blob_write_views(this.inner).map(
			(write) => new GpuWriteView(write),
		);
	}

	cameraGpuRowCopy(entity: EntityId): Uint8Array | null {
		const bytes = world_camera_gpu_row_copy(this.inner, entity.inner);
		if (bytes === undefined || bytes === null) {
			return null;
		}
		return bytes instanceof Uint8Array ? new Uint8Array(bytes) : Uint8Array.from(bytes);
	}

	writeGlobalTransformBlobRangeViews(
		firstWord: number,
		wordCount: number,
		f: (bytes: ByteView) => void,
	): GpuWriteView[] {
		return world_write_global_transform_blob_range_views(
			this.inner,
			firstWord,
			wordCount,
			(bytes) => f(byteView(bytes)),
		).map((write) => new GpuWriteView(write));
	}

	setTransformTrs(
		entity: EntityId,
		px: number,
		py: number,
		pz: number,
		qx: number,
		qy: number,
		qz: number,
		qw: number,
		sx: number,
		sy: number,
		sz: number,
	): boolean {
		return moonBool(
			world_set_transform_trs(
				this.inner,
				entity.inner,
				px,
				py,
				pz,
				qx,
				qy,
				qz,
				qw,
				sx,
				sy,
				sz,
			),
		);
	}

	setChildOf(entity: EntityId, parent: EntityId): boolean {
		return moonBool(world_set_child_of(this.inner, entity.inner, parent.inner));
	}

	setGlobalTransform(entity: EntityId, matrixColMajor: ArrayLike<number>): boolean {
		return moonBool(
			world_set_global_transform_col_major(
				this.inner,
				entity.inner,
				Array.from(matrixColMajor),
			),
		);
	}

	getGlobalTransform(entity: EntityId): Float32Array | null {
		const data = world_get_global_transform_col_major(this.inner, entity.inner);
		if (data === undefined || data === null) {
			return null;
		}
		return data instanceof Float32Array
			? new Float32Array(data)
			: Float32Array.from(data);
	}

	setCameraMatrices(
		entity: EntityId,
		viewColMajor: ArrayLike<number>,
		projColMajor: ArrayLike<number>,
		near: number,
		far: number,
		aspect: number,
		projectionKind: number,
		flags: number,
	): boolean {
		return moonBool(
			world_set_camera_matrices_col_major(
				this.inner,
				entity.inner,
				Array.from(viewColMajor),
				Array.from(projColMajor),
				near,
				far,
				aspect,
				projectionKind,
				flags,
			),
		);
	}

	updateGlobalTransformsFromTransforms(): void {
		world_update_global_transforms_from_transforms(this.inner);
	}

	setGlobalTransformFormat(entity: EntityId, formatCode: 0 | 1): boolean {
		return moonBool(
			world_set_global_transform_format(this.inner, entity.inner, formatCode),
		);
	}

	globalTransformBlobWordCapacity(): number {
		return world_global_transform_blob_word_capacity(this.inner);
	}

	cameraBlobWordCapacity(): number {
		return world_camera_blob_word_capacity(this.inner);
	}

	extractGlobalTransformRefs(entities: EntityId[]): Uint8Array {
		const bytes = world_extract_global_transform_refs(
			this.inner,
			entities.map((entity) => entity.inner),
		);
		return bytes instanceof Uint8Array ? new Uint8Array(bytes) : Uint8Array.from(bytes);
	}

	writeGlobalTransformsDenseRangeViews(
		count: number,
		f: (
			bytes: ByteView,
			stride: number,
			firstEntityIndex: number,
			count: number,
		) => void,
	): GpuWriteView[] {
		return world_write_global_transforms_dense_range_views(
			this.inner,
			count,
			(bytes, stride, firstEntityIndex, rangeCount) =>
				f(byteView(bytes), stride, firstEntityIndex, rangeCount),
		).map((write) => new GpuWriteView(write));
	}

	spawnTransformGlobalBatchIdentity(count: number): EntityId[] {
		return world_spawn_transform_global_batch_identity(this.inner, count).map(
			(entity) => new EntityId(entity),
		);
	}

	reserveBatchCapacity(
		components: ComponentTypeId[],
		additionalRows: number,
	): boolean {
		return moonBool(
			world_reserve_batch_capacity(
				this.inner,
				components.map((component) => component.inner),
				additionalRows,
			),
		);
	}

	spawnBatch(
		components: ComponentTypeId[],
		count: number,
		f: (index: number, entity: EntityId, row: SpawnBatchRow) => void,
	): EntityId[] {
		return world_spawn_batch(
			this.inner,
			components.map((component) => component.inner),
			count,
			(index, entity, row) =>
				f(index, new EntityId(entity), new SpawnBatchRow(row)),
		).map((entity) => new EntityId(entity));
  }
}

export type HistoryDeltaKind =
	| "entity_created"
	| "entity_destroyed"
	| "component_added"
	| "component_removed"
	| "component_changed"
	| "global_transform_changed"
	| "camera_changed";

export type HistoryDeltaSummary = {
	readonly kind: HistoryDeltaKind;
	readonly entity: EntityId | null;
	readonly component: ComponentTypeId | null;
	readonly componentCount: number;
	readonly payloadBytes: number;
	readonly beforePresent: boolean;
	readonly afterPresent: boolean;
};

export type HistoryRecordSummary = {
	readonly label: string;
	readonly deltaCount: number;
	readonly payloadBytes: number;
	readonly deltas: HistoryDeltaSummary[];
};

export type HistorySerializationReason =
	| "none"
	| "unknown_component"
	| "missing_stable_component_identity";

export type HistorySerializationComponentReport = {
	readonly component: ComponentTypeId;
	readonly serializable: boolean;
	readonly reason: HistorySerializationReason;
	readonly stableKey: string | null;
};

export type HistorySerializationDeltaReport = {
	readonly kind: HistoryDeltaKind;
	readonly entity: EntityId | null;
	readonly component: ComponentTypeId | null;
	readonly componentCount: number;
	readonly serializable: boolean;
	readonly reason: HistorySerializationReason;
	readonly payloadBytes: number;
	readonly components: HistorySerializationComponentReport[];
};

export type HistorySerializationRecordReport = {
	readonly label: string;
	readonly serializable: boolean;
	readonly reason: HistorySerializationReason;
	readonly deltaCount: number;
	readonly payloadBytes: number;
	readonly deltas: HistorySerializationDeltaReport[];
};

export type HistorySerializationReport = {
	readonly serializable: boolean;
	readonly recordCount: number;
	readonly records: HistorySerializationRecordReport[];
};

export type HistoryImportValidationReason =
	| "none"
	| "transaction_open"
	| "applying"
	| "import_unsupported_format"
	| "import_invalid_archive"
	| "import_identity_mismatch"
	| "import_invalid_payload"
	| "import_validation_failed";

export type HistoryImportValidationDeltaReport = {
	readonly index: number;
	readonly kind: string;
	readonly entity: EntityId | null;
	readonly component: ComponentTypeId | null;
	readonly componentKey: string | null;
	readonly valid: boolean;
	readonly reason: HistoryImportValidationReason;
};

export type HistoryImportValidationRecordReport = {
	readonly index: number;
	readonly label: string;
	readonly valid: boolean;
	readonly reason: HistoryImportValidationReason;
	readonly deltaCount: number;
	readonly deltas: HistoryImportValidationDeltaReport[];
};

export type HistoryImportValidationReport = {
	readonly valid: boolean;
	readonly reason: HistoryImportValidationReason;
	readonly formatVersion: number;
	readonly recordCount: number;
	readonly records: HistoryImportValidationRecordReport[];
};

export type HistoryExportComponentIdentity = {
	readonly localComponent: ComponentTypeId;
	readonly key: string;
	readonly builtin: boolean;
	readonly schemaVersion: string | null;
	readonly schemaHash: string | null;
};

export type HistoryExportPayload = {
	readonly globalTransformFormat: number | null;
	readonly bytes: Uint8Array;
};

export type HistoryExportComponentSnapshot = {
	readonly component: HistoryExportComponentIdentity;
	readonly bytes: Uint8Array;
};

export type HistoryExportDelta = {
	readonly kind: HistoryDeltaKind;
	readonly entity: EntityId | null;
	readonly component: HistoryExportComponentIdentity | null;
	readonly before: HistoryExportPayload | null;
	readonly after: HistoryExportPayload | null;
	readonly components: HistoryExportComponentSnapshot[];
};

export type HistoryExportRecord = {
	readonly label: string;
	readonly deltaCount: number;
	readonly deltas: HistoryExportDelta[];
};

export type HistoryExport = {
	readonly formatVersion: number;
	readonly recordCount: number;
	readonly records: HistoryExportRecord[];
};

function historyExportBytes(bytes: Uint8Array | number[]): Uint8Array {
	return bytes instanceof Uint8Array ? new Uint8Array(bytes) : Uint8Array.from(bytes);
}

function historySummaryEntity(
	entity:
		| ReturnType<typeof world_history_delta_summary_entity>
		| null
		| undefined,
): EntityId | null {
	return entity == null ? null : new EntityId(entity);
}

function historySummaryComponent(
	component:
		| ReturnType<typeof world_history_delta_summary_component>
		| null
		| undefined,
): ComponentTypeId | null {
	return component == null ? null : new ComponentTypeId(component);
}

function historyDeltaSummaryFromBridge(
	summary: MoonWorldHistoryDeltaSummary,
): HistoryDeltaSummary {
	return {
		kind: world_history_delta_summary_kind(summary) as HistoryDeltaKind,
		entity: historySummaryEntity(world_history_delta_summary_entity(summary)),
		component: historySummaryComponent(
			world_history_delta_summary_component(summary),
		),
		componentCount: world_history_delta_summary_component_count(summary),
		payloadBytes: world_history_delta_summary_payload_bytes(summary),
		beforePresent: moonBool(world_history_delta_summary_before_present(summary)),
		afterPresent: moonBool(world_history_delta_summary_after_present(summary)),
	};
}

function historyRecordSummaryFromBridge(
	summary: MoonWorldHistoryRecordSummary,
): HistoryRecordSummary {
	return {
		label: world_history_record_summary_label(summary),
		deltaCount: world_history_record_summary_delta_count(summary),
		payloadBytes: world_history_record_summary_payload_bytes(summary),
		deltas: world_history_record_summary_deltas(summary).map((delta) =>
			historyDeltaSummaryFromBridge(delta),
		),
	};
}

function historySerializationComponentReportFromBridge(
	report: MoonWorldHistorySerializationComponentReport,
): HistorySerializationComponentReport {
	return {
		component: new ComponentTypeId(
			world_history_serialization_component_report_component(report),
		),
		serializable: moonBool(
			world_history_serialization_component_report_serializable(report),
		),
		reason: world_history_serialization_component_report_reason(
			report,
		) as HistorySerializationReason,
		stableKey:
			world_history_serialization_component_report_stable_key(report) ?? null,
	};
}

function historySerializationDeltaReportFromBridge(
	report: MoonWorldHistorySerializationDeltaReport,
): HistorySerializationDeltaReport {
	return {
		kind: world_history_serialization_delta_report_kind(
			report,
		) as HistoryDeltaKind,
		entity: historySummaryEntity(
			world_history_serialization_delta_report_entity(report),
		),
		component: historySummaryComponent(
			world_history_serialization_delta_report_component(report),
		),
		componentCount:
			world_history_serialization_delta_report_component_count(report),
		serializable: moonBool(
			world_history_serialization_delta_report_serializable(report),
		),
		reason: world_history_serialization_delta_report_reason(
			report,
		) as HistorySerializationReason,
		payloadBytes: world_history_serialization_delta_report_payload_bytes(report),
		components: world_history_serialization_delta_report_components(report).map(
			(component) => historySerializationComponentReportFromBridge(component),
		),
	};
}

function historySerializationRecordReportFromBridge(
	report: MoonWorldHistorySerializationRecordReport,
): HistorySerializationRecordReport {
	return {
		label: world_history_serialization_record_report_label(report),
		serializable: moonBool(
			world_history_serialization_record_report_serializable(report),
		),
		reason: world_history_serialization_record_report_reason(
			report,
		) as HistorySerializationReason,
		deltaCount: world_history_serialization_record_report_delta_count(report),
		payloadBytes: world_history_serialization_record_report_payload_bytes(report),
		deltas: world_history_serialization_record_report_deltas(report).map(
			(delta) => historySerializationDeltaReportFromBridge(delta),
		),
	};
}

function historySerializationReportFromBridge(
	report: MoonWorldHistorySerializationReport,
): HistorySerializationReport {
	return {
		serializable: moonBool(
			world_history_serialization_report_serializable(report),
		),
		recordCount: world_history_serialization_report_record_count(report),
		records: world_history_serialization_report_records(report).map((record) =>
			historySerializationRecordReportFromBridge(record),
		),
	};
}

function historyImportValidationDeltaReportFromBridge(
	report: MoonWorldHistoryImportValidationDeltaReport,
): HistoryImportValidationDeltaReport {
	return {
		index: world_history_import_validation_delta_report_index(report),
		kind: world_history_import_validation_delta_report_kind(report),
		entity: historySummaryEntity(
			world_history_import_validation_delta_report_entity(report),
		),
		component: historySummaryComponent(
			world_history_import_validation_delta_report_component(report),
		),
		componentKey:
			world_history_import_validation_delta_report_component_key(report) ??
			null,
		valid: moonBool(world_history_import_validation_delta_report_valid(report)),
		reason: world_history_import_validation_delta_report_reason(
			report,
		) as HistoryImportValidationReason,
	};
}

function historyImportValidationRecordReportFromBridge(
	report: MoonWorldHistoryImportValidationRecordReport,
): HistoryImportValidationRecordReport {
	return {
		index: world_history_import_validation_record_report_index(report),
		label: world_history_import_validation_record_report_label(report),
		valid: moonBool(world_history_import_validation_record_report_valid(report)),
		reason: world_history_import_validation_record_report_reason(
			report,
		) as HistoryImportValidationReason,
		deltaCount: world_history_import_validation_record_report_delta_count(report),
		deltas: world_history_import_validation_record_report_deltas(report).map(
			(delta) => historyImportValidationDeltaReportFromBridge(delta),
		),
	};
}

function historyImportValidationReportFromBridge(
	report: MoonWorldHistoryImportValidationReport,
): HistoryImportValidationReport {
	return {
		valid: moonBool(world_history_import_validation_report_valid(report)),
		reason: world_history_import_validation_report_reason(
			report,
		) as HistoryImportValidationReason,
		formatVersion: world_history_import_validation_report_format_version(report),
		recordCount: world_history_import_validation_report_record_count(report),
		records: world_history_import_validation_report_records(report).map(
			(record) => historyImportValidationRecordReportFromBridge(record),
		),
	};
}

function historyExportComponentIdentityFromBridge(
	identity: MoonWorldHistoryExportComponentIdentity,
): HistoryExportComponentIdentity {
	return {
		localComponent: new ComponentTypeId(
			world_history_export_component_identity_local_component(identity),
		),
		key: world_history_export_component_identity_key(identity),
		builtin: moonBool(world_history_export_component_identity_builtin(identity)),
		schemaVersion:
			world_history_export_component_identity_schema_version(identity) ?? null,
		schemaHash:
			world_history_export_component_identity_schema_hash(identity) ?? null,
	};
}

function historyExportPayloadFromBridge(
	payload: MoonWorldHistoryExportPayload,
): HistoryExportPayload {
	return {
		globalTransformFormat:
			world_history_export_payload_global_transform_format(payload) ?? null,
		bytes: historyExportBytes(world_history_export_payload_bytes(payload)),
	};
}

function historyExportComponentSnapshotFromBridge(
	snapshot: MoonWorldHistoryExportComponentSnapshot,
): HistoryExportComponentSnapshot {
	return {
		component: historyExportComponentIdentityFromBridge(
			world_history_export_component_snapshot_component(snapshot),
		),
		bytes: historyExportBytes(
			world_history_export_component_snapshot_bytes(snapshot),
		),
	};
}

function historyExportDeltaFromBridge(
	delta: MoonWorldHistoryExportDelta,
): HistoryExportDelta {
	const component = world_history_export_delta_component(delta);
	const before = world_history_export_delta_before(delta);
	const after = world_history_export_delta_after(delta);
	return {
		kind: world_history_export_delta_kind(delta) as HistoryDeltaKind,
		entity: historySummaryEntity(world_history_export_delta_entity(delta)),
		component:
			component == null
				? null
				: historyExportComponentIdentityFromBridge(component),
		before: before == null ? null : historyExportPayloadFromBridge(before),
		after: after == null ? null : historyExportPayloadFromBridge(after),
		components: world_history_export_delta_components(delta).map((snapshot) =>
			historyExportComponentSnapshotFromBridge(snapshot),
		),
	};
}

function historyExportRecordFromBridge(
	record: MoonWorldHistoryExportRecord,
): HistoryExportRecord {
	return {
		label: world_history_export_record_label(record),
		deltaCount: world_history_export_record_delta_count(record),
		deltas: world_history_export_record_deltas(record).map((delta) =>
			historyExportDeltaFromBridge(delta),
		),
	};
}

function historyExportFromBridge(exported: MoonWorldHistoryExport): HistoryExport {
	return {
		formatVersion: world_history_export_format_version(exported),
		recordCount: world_history_export_record_count(exported),
		records: world_history_export_records(exported).map((record) =>
			historyExportRecordFromBridge(record),
		),
	};
}

function historyEntityToBridge(entity: EntityId | null): MoonEntityId | undefined {
	if (entity == null) {
		return undefined;
	}
	const value = entity as EntityId & { inner?: MoonEntityId };
	if (value.inner != null) {
		return value.inner;
	}
	return entity as unknown as MoonEntityId;
}

function historyComponentToBridge(
	component: ComponentTypeId,
): MoonComponentTypeId {
	const value = component as ComponentTypeId & { inner?: MoonComponentTypeId };
	if (value.inner != null) {
		return value.inner;
	}
	return component as unknown as MoonComponentTypeId;
}

function historyExportInputBytes(bytes: Uint8Array): Uint8Array {
	if (bytes instanceof Uint8Array) {
		return new Uint8Array(bytes);
	}
	if (Array.isArray(bytes)) {
		return Uint8Array.from(bytes);
	}
	const value = bytes as unknown as Record<string, number>;
	return Uint8Array.from(
		Object.keys(value)
			.filter((key) => /^\d+$/.test(key))
			.sort((a, b) => Number(a) - Number(b))
			.map((key) => value[key] ?? 0),
	);
}

function historyExportComponentIdentityToBridge(
	identity: HistoryExportComponentIdentity | null,
): MoonWorldHistoryExportComponentIdentity | undefined {
	if (identity == null) {
		return undefined;
	}
	return world_history_export_component_identity_new(
		historyComponentToBridge(identity.localComponent),
		identity.key,
		identity.builtin,
		identity.schemaVersion ?? undefined,
		identity.schemaHash ?? undefined,
	);
}

function historyExportPayloadToBridge(
	payload: HistoryExportPayload | null,
): MoonWorldHistoryExportPayload | undefined {
	if (payload == null) {
		return undefined;
	}
	return world_history_export_payload_new(
		payload.globalTransformFormat ?? undefined,
		historyExportInputBytes(payload.bytes),
	);
}

function historyExportComponentSnapshotToBridge(
	snapshot: HistoryExportComponentSnapshot,
): MoonWorldHistoryExportComponentSnapshot {
	return world_history_export_component_snapshot_new(
		world_history_export_component_identity_new(
			historyComponentToBridge(snapshot.component.localComponent),
			snapshot.component.key,
			snapshot.component.builtin,
			snapshot.component.schemaVersion ?? undefined,
			snapshot.component.schemaHash ?? undefined,
		),
		historyExportInputBytes(snapshot.bytes),
	);
}

function historyExportDeltaToBridge(
	delta: HistoryExportDelta,
): MoonWorldHistoryExportDelta {
	return world_history_export_delta_new(
		delta.kind,
		historyEntityToBridge(delta.entity),
		historyExportComponentIdentityToBridge(delta.component),
		historyExportPayloadToBridge(delta.before),
		historyExportPayloadToBridge(delta.after),
		delta.components.map((snapshot) =>
			historyExportComponentSnapshotToBridge(snapshot),
		),
	);
}

function historyExportRecordToBridge(
	record: HistoryExportRecord,
): MoonWorldHistoryExportRecord {
	return world_history_export_record_new(
		record.label,
		record.deltaCount,
		record.deltas.map((delta) => historyExportDeltaToBridge(delta)),
	);
}

function historyExportToBridge(exported: HistoryExport): MoonWorldHistoryExport {
	return world_history_export_new(
		exported.formatVersion,
		exported.recordCount,
		exported.records.map((record) => historyExportRecordToBridge(record)),
	);
}

export class WorldHistory {
	readonly inner: MoonWorldHistory;

	constructor(inner: MoonWorldHistory) {
		this.inner = inner;
	}

	static new(): WorldHistory {
		return new WorldHistory(world_history_new());
	}

	enabled(): boolean {
		return moonBool(world_history_enabled(this.inner));
	}

	setEnabled(enabled: boolean): void {
		world_history_set_enabled(this.inner, enabled);
	}

	rawMutationGuardEnabled(): boolean {
		return moonBool(world_history_raw_mutation_guard_enabled(this.inner));
	}

	setRawMutationGuardEnabled(enabled: boolean): void {
		world_history_set_raw_mutation_guard_enabled(this.inner, enabled);
	}

	maxUndoRecords(): number {
		return world_history_max_undo_records(this.inner);
	}

	maxUndoBytes(): number {
		return world_history_max_undo_bytes(this.inner);
	}

	setMaxUndoRecords(limit: number): void {
		world_history_set_max_undo_records(this.inner, limit);
	}

	setMaxUndoBytes(limit: number): void {
		world_history_set_max_undo_bytes(this.inner, limit);
	}

	clear(): void {
		world_history_clear(this.inner);
	}

	undoLen(): number {
		return world_history_undo_len(this.inner);
	}

	redoLen(): number {
		return world_history_redo_len(this.inner);
	}

	undoBytes(): number {
		return world_history_undo_bytes(this.inner);
	}

	redoBytes(): number {
		return world_history_redo_bytes(this.inner);
	}

	undoSummary(): HistoryRecordSummary[] {
		return world_history_undo_summary(this.inner).map((summary) =>
			historyRecordSummaryFromBridge(summary),
		);
	}

	redoSummary(): HistoryRecordSummary[] {
		return world_history_redo_summary(this.inner).map((summary) =>
			historyRecordSummaryFromBridge(summary),
		);
	}

	undoSerializationReport(world: World): HistorySerializationReport {
		return historySerializationReportFromBridge(
			world_history_undo_serialization_report(this.inner, world.inner),
		);
	}

	redoSerializationReport(world: World): HistorySerializationReport {
		return historySerializationReportFromBridge(
			world_history_redo_serialization_report(this.inner, world.inner),
		);
	}

	exportUndoStack(world: World): HistoryExport | null {
		const exported = world_history_export_undo_stack(this.inner, world.inner);
		return exported == null ? null : historyExportFromBridge(exported);
	}

	exportRedoStack(world: World): HistoryExport | null {
		const exported = world_history_export_redo_stack(this.inner, world.inner);
		return exported == null ? null : historyExportFromBridge(exported);
	}

	importUndoStack(world: World, archive: HistoryExport): boolean {
		return moonBool(
			world_history_import_undo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	importRedoStack(world: World, archive: HistoryExport): boolean {
		return moonBool(
			world_history_import_redo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	validateImportUndoStack(
		world: World,
		archive: HistoryExport,
	): HistoryImportValidationReport {
		return historyImportValidationReportFromBridge(
			world_history_validate_import_undo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	validateImportRedoStack(
		world: World,
		archive: HistoryExport,
	): HistoryImportValidationReport {
		return historyImportValidationReportFromBridge(
			world_history_validate_import_redo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	lastDiagnostic(): string {
		return world_history_last_diagnostic(this.inner);
	}

	undoLabel(): string | null {
		return world_history_undo_label(this.inner) ?? null;
	}

	redoLabel(): string | null {
		return world_history_redo_label(this.inner) ?? null;
	}

	beginTransaction(label: string): boolean {
		return moonBool(world_history_begin_transaction(this.inner, label));
	}

	beginGuardedTransaction(world: World, label: string): boolean {
		return moonBool(
			world_history_begin_guarded_transaction(this.inner, world.inner, label),
		);
	}

	commitTransaction(): boolean {
		return moonBool(world_history_commit_transaction(this.inner));
	}

	cancelTransaction(): boolean {
		return moonBool(world_history_cancel_transaction(this.inner));
	}

	cancelTransactionReverting(world: World): boolean {
		return moonBool(
			world_history_cancel_transaction_reverting(this.inner, world.inner),
		);
	}

	canUndo(): boolean {
		return moonBool(world_history_can_undo(this.inner));
	}

	canRedo(): boolean {
		return moonBool(world_history_can_redo(this.inner));
	}

	undo(world: World): boolean {
		return moonBool(world_history_undo(this.inner, world.inner));
	}

	redo(world: World): boolean {
		return moonBool(world_history_redo(this.inner, world.inner));
	}

	createEntity(world: World): EntityId {
		return new EntityId(world_history_create_entity(this.inner, world.inner));
	}

	createEntities(world: World, count: number): EntityId[] {
		return world_history_create_entities(this.inner, world.inner, count).map(
			(entity) => new EntityId(entity),
		);
	}

	spawnBatch(
		world: World,
		components: ComponentTypeId[],
		count: number,
		f: (index: number, entity: EntityId, row: SpawnBatchRow) => void,
	): EntityId[] {
		return world_history_spawn_batch(
			this.inner,
			world.inner,
			components.map((component) => component.inner),
			count,
			(index, entity, row) =>
				f(index, new EntityId(entity), new SpawnBatchRow(row)),
		).map((entity) => new EntityId(entity));
	}

	destroyEntity(world: World, entity: EntityId): boolean {
		return moonBool(
			world_history_destroy_entity(this.inner, world.inner, entity.inner),
		);
	}

	addComponent(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
	): boolean {
		return moonBool(
			world_history_add_component(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
			),
		);
	}

	addComponentBytes(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): boolean {
		return moonBool(
			world_history_add_component_bytes(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
				bytesInput(bytes),
			),
		);
	}

	addComponentBytesMany(
		world: World,
		component: ComponentTypeId,
		entities: EntityId[],
		bytesList: Array<Uint8Array | ArrayLike<number>>,
	): boolean {
		return moonBool(
			world_history_add_component_bytes_many(
				this.inner,
				world.inner,
				component.inner,
				entities.map((entity) => entity.inner),
				bytesList.map((bytes) => bytesInput(bytes)),
			),
		);
	}

	setComponentBytes(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): boolean {
		return moonBool(
			world_history_set_component_bytes(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
				bytesInput(bytes),
			),
		);
	}

	setComponentBytesMany(
		world: World,
		component: ComponentTypeId,
		entities: EntityId[],
		bytesList: Array<Uint8Array | ArrayLike<number>>,
	): boolean {
		return moonBool(
			world_history_set_component_bytes_many(
				this.inner,
				world.inner,
				component.inner,
				entities.map((entity) => entity.inner),
				bytesList.map((bytes) => bytesInput(bytes)),
			),
		);
	}

	removeComponent(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
	): boolean {
		return moonBool(
			world_history_remove_component(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
			),
		);
	}

	setTransformTrs(
		world: World,
		entity: EntityId,
		px: number,
		py: number,
		pz: number,
		qx: number,
		qy: number,
		qz: number,
		qw: number,
		sx: number,
		sy: number,
		sz: number,
	): boolean {
		return moonBool(
			world_history_set_transform_trs(
				this.inner,
				world.inner,
				entity.inner,
				px,
				py,
				pz,
				qx,
				qy,
				qz,
				qw,
				sx,
				sy,
				sz,
			),
		);
	}

	setChildOf(world: World, entity: EntityId, parent: EntityId): boolean {
		return moonBool(
			world_history_set_child_of(
				this.inner,
				world.inner,
				entity.inner,
				parent.inner,
			),
		);
	}

	setGlobalTransform(
		world: World,
		entity: EntityId,
		matrixColMajor: ArrayLike<number>,
	): boolean {
		return moonBool(
			world_history_set_global_transform_col_major(
				this.inner,
				world.inner,
				entity.inner,
				Array.from(matrixColMajor),
			),
		);
	}

	setGlobalTransformFormat(
		world: World,
		entity: EntityId,
		formatCode: 0 | 1,
	): boolean {
		return moonBool(
			world_history_set_global_transform_format(
				this.inner,
				world.inner,
				entity.inner,
				formatCode,
			),
		);
	}

	setCameraMatrices(
		world: World,
		entity: EntityId,
		viewColMajor: ArrayLike<number>,
		projColMajor: ArrayLike<number>,
		near: number,
		far: number,
		aspect: number,
		projectionKind: number,
		flags: number,
	): boolean {
		return moonBool(
			world_history_set_camera_matrices_col_major(
				this.inner,
				world.inner,
				entity.inner,
				Array.from(viewColMajor),
				Array.from(projColMajor),
				near,
				far,
				aspect,
				projectionKind,
				flags,
			),
		);
	}

	runSystemPhase(
		runner: SystemRunner,
		world: World,
		ctx: SystemContext,
		phase: PhaseKey,
		label: string,
	): boolean {
		return moonBool(
			world_history_run_system_phase(
				this.inner,
				runner.inner,
				world.inner,
				ctx.inner,
				phase.inner,
				label,
			),
		);
	}
}

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
