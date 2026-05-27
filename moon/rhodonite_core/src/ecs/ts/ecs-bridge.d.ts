// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

/** Generated MoonBit ECS js_bridge bindings (`moon build --target js --release`). */
declare module "@moon/rhodonite_core/ecs/js_bridge" {
	export type MoonBool = boolean | 0 | 1;
	export type MoonByteBacking = Uint8Array | number[];
	export type MoonByteView = { buf: MoonByteBacking; start: number; end: number };

	export type MoonEntityId = { index: number; generation: number };
	export type MoonComponentTypeId = { index: number };
	export type MoonEntityLocation = { archetype_index: number; row: number };
	export type MoonWorld = object;
	export type MoonWorldHistory = object;
	export type MoonWorldHistoryRecordSummary = object;
	export type MoonWorldHistoryDeltaSummary = object;
	export type MoonWorldHistorySerializationReport = object;
	export type MoonWorldHistorySerializationRecordReport = object;
	export type MoonWorldHistorySerializationDeltaReport = object;
	export type MoonWorldHistorySerializationComponentReport = object;
	export type MoonWorldHistoryImportValidationReport = object;
	export type MoonWorldHistoryImportValidationRecordReport = object;
	export type MoonWorldHistoryImportValidationDeltaReport = object;
	export type MoonWorldHistoryExport = object;
	export type MoonWorldHistoryExportRecord = object;
	export type MoonWorldHistoryExportDelta = object;
	export type MoonWorldHistoryExportComponentIdentity = object;
	export type MoonWorldHistoryExportPayload = object;
	export type MoonWorldHistoryExportComponentSnapshot = object;
	export type MoonPhaseKey = object;
	export type MoonSystemContext = object;
	export type MoonSystem = object;
	export type MoonSystemRunner = object;
	export type MoonSystemPhasePlan = object;
	export type MoonSystemPlanBatch = object;
	export type MoonSystemPlanSystem = object;
	export type MoonSystemRunReport = object;
	export type MoonSystemRunBatchReport = object;
	export type MoonSystemRunSystemReport = object;
	export type MoonTransformPropagationReport = object;
	export type MoonCommandBufferCommandFailure = object;
	export type MoonCommandBuffer = object;
	export type MoonQuery = object;
	export type MoonRawQuery = object;
	export type MoonQueryCache = object;
	export type MoonRawQueryCache = object;
	export type MoonQueryPlan = object;
	export type MoonQueryPlanArchetype = object;
	export type MoonPreparedQuery = object;
	export type MoonRawPreparedQuery = object;
	export type MoonQueryRow = object;
	export type MoonRawQueryRow = object;
	export type MoonRawQueryArchetype = object;
	export type MoonSpawnBatchRow = object;
	export type MoonRegisteredComponent = object;
	export type MoonGpuLayout = { fields: MoonGpuField[]; stride: number; align: number };
	export type MoonGpuField = {
		name: string;
		kind: unknown;
		offset: number;
		size: number;
		align: number;
	};
	export type MoonGpuWriteView = { byte_offset: number; bytes: MoonByteView };
	export type MoonGpuWriteCopy = { byte_offset: number; bytes: Uint8Array | number[] };

	export function entity_id_new(index: number, generation: number): MoonEntityId;
	export function entity_id_index(entity: MoonEntityId): number;
	export function entity_id_generation(entity: MoonEntityId): number;
	export function entity_id_gpu_index(entity: MoonEntityId): number;
	export function component_type_id_new(index: number): MoonComponentTypeId;
	export function component_type_id_index(component: MoonComponentTypeId): number;

	export function world_new(): MoonWorld;
	export function world_new_with_global_transform_f16(): MoonWorld;
	export function world_create_entity(world: MoonWorld): MoonEntityId;
	export function world_destroy_entity(world: MoonWorld, entity: MoonEntityId): MoonBool;
	export function world_is_alive(world: MoonWorld, entity: MoonEntityId): MoonBool;
	export function world_location(
		world: MoonWorld,
		entity: MoonEntityId,
	): MoonEntityLocation | undefined;
	export function world_transform_component(world: MoonWorld): MoonComponentTypeId;
	export function world_global_transform_component(
		world: MoonWorld,
	): MoonComponentTypeId;
	export function world_child_of_component(world: MoonWorld): MoonComponentTypeId;
	export function world_camera_component(world: MoonWorld): MoonComponentTypeId;
	export function world_orbit_camera_controller_component(
		world: MoonWorld,
	): MoonComponentTypeId;
	export function world_camera_home_transform_component(
		world: MoonWorld,
	): MoonComponentTypeId;
	export function world_camera_lens_component(world: MoonWorld): MoonComponentTypeId;
	export function world_register_cpu_component(
		world: MoonWorld,
		name: string,
		cpuStride: number,
	): MoonComponentTypeId;
	export function world_register_cpu_component_with_identity(
		world: MoonWorld,
		name: string,
		cpuStride: number,
		stableKey: string,
		schemaVersion: string | undefined,
		schemaHash: string | undefined,
	): MoonComponentTypeId;
	export function world_component_cpu_stride(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): number | undefined;
	export function world_component_info(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): MoonRegisteredComponent | undefined;
	export function world_component_by_stable_key(
		world: MoonWorld,
		stableKey: string,
	): MoonComponentTypeId | undefined;
	export function world_component_matches_identity(
		world: MoonWorld,
		component: MoonComponentTypeId,
		stableKey: string,
		schemaVersion: string | undefined,
		schemaHash: string | undefined,
	): MoonBool;
	export function world_component_info_name(info: MoonRegisteredComponent): string;
	export function world_component_info_cpu_stride(info: MoonRegisteredComponent): number;
	export function world_component_info_stable_key(
		info: MoonRegisteredComponent,
	): string | undefined;
	export function world_component_info_schema_version(
		info: MoonRegisteredComponent,
	): string | undefined;
	export function world_component_info_schema_hash(
		info: MoonRegisteredComponent,
	): string | undefined;
	export function world_has_component(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): MoonBool;
	export function world_add_component(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): MoonBool;
	export function world_add_component_bytes(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
		bytes: Uint8Array | number[],
	): MoonBool;
	export function world_set_component_bytes(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
		bytes: Uint8Array | number[],
	): MoonBool;
	export function world_remove_component(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): MoonBool;
	export function world_component_bytes_copy(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): Uint8Array | number[] | undefined;
	export function world_drain_global_transform_blob_write_views(
		world: MoonWorld,
	): MoonGpuWriteView[];
	export function world_write_global_transform_blob_range_views(
		world: MoonWorld,
		firstWord: number,
		wordCount: number,
		f: (bytes: MoonByteView) => void,
	): MoonGpuWriteView[];
	export function world_set_transform_trs(
		world: MoonWorld,
		entity: MoonEntityId,
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
	): MoonBool;
	export function world_set_child_of(
		world: MoonWorld,
		entity: MoonEntityId,
		parent: MoonEntityId,
	): MoonBool;
	export function world_set_global_transform_col_major(
		world: MoonWorld,
		entity: MoonEntityId,
		matrixColMajor: number[],
	): MoonBool;
	export function world_get_global_transform_col_major(
		world: MoonWorld,
		entity: MoonEntityId,
	): number[] | undefined;
	export function world_set_camera_matrices_col_major(
		world: MoonWorld,
		entity: MoonEntityId,
		viewColMajor: number[],
		projColMajor: number[],
		near: number,
		far: number,
		aspect: number,
		projectionKind: number,
		flags: number,
	): MoonBool;
	export function world_camera_gpu_row_copy(
		world: MoonWorld,
		entity: MoonEntityId,
	): Uint8Array | number[] | undefined;
	export function world_update_global_transforms_from_transforms(
		world: MoonWorld,
	): void;
	export function world_propagate_global_transforms_from_transforms_report(
		world: MoonWorld,
	): MoonTransformPropagationReport;
	export function transform_propagation_report_ok(
		report: MoonTransformPropagationReport,
	): MoonBool;
	export function transform_propagation_report_used_dirty_path(
		report: MoonTransformPropagationReport,
	): MoonBool;
	export function transform_propagation_report_used_full_path(
		report: MoonTransformPropagationReport,
	): MoonBool;
	export function transform_propagation_report_fallback_to_full(
		report: MoonTransformPropagationReport,
	): MoonBool;
	export function transform_propagation_report_dirty_queue_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_dirty_root_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_skipped_dirty_entity_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_visited_entity_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_global_transform_write_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_hierarchy_index_rebuilt(
		report: MoonTransformPropagationReport,
	): MoonBool;
	export function transform_propagation_report_pending_upload_range_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_failure_reason(
		report: MoonTransformPropagationReport,
	): string;
	export function transform_propagation_report_failure_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_broken_ancestor_chain_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_missing_global_transform_ref_count(
		report: MoonTransformPropagationReport,
	): number;
	export function transform_propagation_report_archetype_path_unavailable_count(
		report: MoonTransformPropagationReport,
	): number;
	export function world_set_global_transform_format(
		world: MoonWorld,
		entity: MoonEntityId,
		formatCode: number,
	): MoonBool;
	export function world_global_transform_blob_word_capacity(
		world: MoonWorld,
	): number;
	export function world_drain_camera_blob_write_views(
		world: MoonWorld,
	): MoonGpuWriteView[];
	export function world_camera_blob_word_capacity(world: MoonWorld): number;
	export function world_extract_global_transform_refs(
		world: MoonWorld,
		entities: MoonEntityId[],
	): Uint8Array | number[];
	export function world_write_global_transforms_dense_range_views(
		world: MoonWorld,
		count: number,
		f: (
			bytes: MoonByteView,
			stride: number,
			firstEntityIndex: number,
			count: number,
		) => void,
	): MoonGpuWriteView[];
	export function world_spawn_transform_global_batch_identity(
		world: MoonWorld,
		count: number,
	): MoonEntityId[];
	export function world_reserve_batch_capacity(
		world: MoonWorld,
		components: MoonComponentTypeId[],
		additionalRows: number,
	): MoonBool;
	export function world_spawn_batch(
		world: MoonWorld,
		components: MoonComponentTypeId[],
		count: number,
		f: (index: number, entity: MoonEntityId, row: MoonSpawnBatchRow) => void,
	): MoonEntityId[];
	export function world_history_new(): MoonWorldHistory;
	export function world_history_enabled(history: MoonWorldHistory): MoonBool;
	export function world_history_set_enabled(
		history: MoonWorldHistory,
		enabled: boolean,
	): void;
	export function world_history_raw_mutation_guard_enabled(
		history: MoonWorldHistory,
	): MoonBool;
	export function world_history_set_raw_mutation_guard_enabled(
		history: MoonWorldHistory,
		enabled: boolean,
	): void;
	export function world_history_max_undo_records(
		history: MoonWorldHistory,
	): number;
	export function world_history_max_undo_bytes(
		history: MoonWorldHistory,
	): number;
	export function world_history_set_max_undo_records(
		history: MoonWorldHistory,
		limit: number,
	): void;
	export function world_history_set_max_undo_bytes(
		history: MoonWorldHistory,
		limit: number,
	): void;
	export function world_history_clear(history: MoonWorldHistory): void;
	export function world_history_undo_len(history: MoonWorldHistory): number;
	export function world_history_redo_len(history: MoonWorldHistory): number;
	export function world_history_undo_bytes(history: MoonWorldHistory): number;
	export function world_history_redo_bytes(history: MoonWorldHistory): number;
	export function world_history_undo_summary(
		history: MoonWorldHistory,
	): MoonWorldHistoryRecordSummary[];
	export function world_history_redo_summary(
		history: MoonWorldHistory,
	): MoonWorldHistoryRecordSummary[];
	export function world_history_undo_serialization_report(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonWorldHistorySerializationReport;
	export function world_history_redo_serialization_report(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonWorldHistorySerializationReport;
	export function world_history_export_undo_stack(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonWorldHistoryExport | undefined;
	export function world_history_export_redo_stack(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonWorldHistoryExport | undefined;
	export function world_history_import_undo_stack(
		history: MoonWorldHistory,
		world: MoonWorld,
		exported: MoonWorldHistoryExport,
	): MoonBool;
	export function world_history_import_redo_stack(
		history: MoonWorldHistory,
		world: MoonWorld,
		exported: MoonWorldHistoryExport,
	): MoonBool;
	export function world_history_validate_import_undo_stack(
		history: MoonWorldHistory,
		world: MoonWorld,
		exported: MoonWorldHistoryExport,
	): MoonWorldHistoryImportValidationReport;
	export function world_history_validate_import_redo_stack(
		history: MoonWorldHistory,
		world: MoonWorld,
		exported: MoonWorldHistoryExport,
	): MoonWorldHistoryImportValidationReport;
	export function world_history_import_validation_report_valid(
		report: MoonWorldHistoryImportValidationReport,
	): MoonBool;
	export function world_history_import_validation_report_reason(
		report: MoonWorldHistoryImportValidationReport,
	): string;
	export function world_history_import_validation_report_format_version(
		report: MoonWorldHistoryImportValidationReport,
	): number;
	export function world_history_import_validation_report_record_count(
		report: MoonWorldHistoryImportValidationReport,
	): number;
	export function world_history_import_validation_report_records(
		report: MoonWorldHistoryImportValidationReport,
	): MoonWorldHistoryImportValidationRecordReport[];
	export function world_history_import_validation_record_report_index(
		report: MoonWorldHistoryImportValidationRecordReport,
	): number;
	export function world_history_import_validation_record_report_label(
		report: MoonWorldHistoryImportValidationRecordReport,
	): string;
	export function world_history_import_validation_record_report_valid(
		report: MoonWorldHistoryImportValidationRecordReport,
	): MoonBool;
	export function world_history_import_validation_record_report_reason(
		report: MoonWorldHistoryImportValidationRecordReport,
	): string;
	export function world_history_import_validation_record_report_delta_count(
		report: MoonWorldHistoryImportValidationRecordReport,
	): number;
	export function world_history_import_validation_record_report_deltas(
		report: MoonWorldHistoryImportValidationRecordReport,
	): MoonWorldHistoryImportValidationDeltaReport[];
	export function world_history_import_validation_delta_report_index(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): number;
	export function world_history_import_validation_delta_report_kind(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): string;
	export function world_history_import_validation_delta_report_entity(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): MoonEntityId | undefined;
	export function world_history_import_validation_delta_report_component(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): MoonComponentTypeId | undefined;
	export function world_history_import_validation_delta_report_component_key(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): string | undefined;
	export function world_history_import_validation_delta_report_valid(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): MoonBool;
	export function world_history_import_validation_delta_report_reason(
		report: MoonWorldHistoryImportValidationDeltaReport,
	): string;
	export function world_history_serialization_report_serializable(
		report: MoonWorldHistorySerializationReport,
	): MoonBool;
	export function world_history_serialization_report_record_count(
		report: MoonWorldHistorySerializationReport,
	): number;
	export function world_history_serialization_report_records(
		report: MoonWorldHistorySerializationReport,
	): MoonWorldHistorySerializationRecordReport[];
	export function world_history_serialization_record_report_label(
		report: MoonWorldHistorySerializationRecordReport,
	): string;
	export function world_history_serialization_record_report_serializable(
		report: MoonWorldHistorySerializationRecordReport,
	): MoonBool;
	export function world_history_serialization_record_report_reason(
		report: MoonWorldHistorySerializationRecordReport,
	): string;
	export function world_history_serialization_record_report_delta_count(
		report: MoonWorldHistorySerializationRecordReport,
	): number;
	export function world_history_serialization_record_report_payload_bytes(
		report: MoonWorldHistorySerializationRecordReport,
	): number;
	export function world_history_serialization_record_report_deltas(
		report: MoonWorldHistorySerializationRecordReport,
	): MoonWorldHistorySerializationDeltaReport[];
	export function world_history_serialization_delta_report_kind(
		report: MoonWorldHistorySerializationDeltaReport,
	): string;
	export function world_history_serialization_delta_report_entity(
		report: MoonWorldHistorySerializationDeltaReport,
	): MoonEntityId | undefined;
	export function world_history_serialization_delta_report_component(
		report: MoonWorldHistorySerializationDeltaReport,
	): MoonComponentTypeId | undefined;
	export function world_history_serialization_delta_report_component_count(
		report: MoonWorldHistorySerializationDeltaReport,
	): number;
	export function world_history_serialization_delta_report_serializable(
		report: MoonWorldHistorySerializationDeltaReport,
	): MoonBool;
	export function world_history_serialization_delta_report_reason(
		report: MoonWorldHistorySerializationDeltaReport,
	): string;
	export function world_history_serialization_delta_report_payload_bytes(
		report: MoonWorldHistorySerializationDeltaReport,
	): number;
	export function world_history_serialization_delta_report_components(
		report: MoonWorldHistorySerializationDeltaReport,
	): MoonWorldHistorySerializationComponentReport[];
	export function world_history_serialization_component_report_component(
		report: MoonWorldHistorySerializationComponentReport,
	): MoonComponentTypeId;
	export function world_history_serialization_component_report_serializable(
		report: MoonWorldHistorySerializationComponentReport,
	): MoonBool;
	export function world_history_serialization_component_report_reason(
		report: MoonWorldHistorySerializationComponentReport,
	): string;
	export function world_history_serialization_component_report_stable_key(
		report: MoonWorldHistorySerializationComponentReport,
	): string | undefined;
	export function world_history_export_format_version(
		exported: MoonWorldHistoryExport,
	): number;
	export function world_history_export_record_count(
		exported: MoonWorldHistoryExport,
	): number;
	export function world_history_export_records(
		exported: MoonWorldHistoryExport,
	): MoonWorldHistoryExportRecord[];
	export function world_history_export_record_label(
		record: MoonWorldHistoryExportRecord,
	): string;
	export function world_history_export_record_delta_count(
		record: MoonWorldHistoryExportRecord,
	): number;
	export function world_history_export_record_deltas(
		record: MoonWorldHistoryExportRecord,
	): MoonWorldHistoryExportDelta[];
	export function world_history_export_delta_kind(
		delta: MoonWorldHistoryExportDelta,
	): string;
	export function world_history_export_delta_entity(
		delta: MoonWorldHistoryExportDelta,
	): MoonEntityId | undefined;
	export function world_history_export_delta_component(
		delta: MoonWorldHistoryExportDelta,
	): MoonWorldHistoryExportComponentIdentity | undefined;
	export function world_history_export_delta_before(
		delta: MoonWorldHistoryExportDelta,
	): MoonWorldHistoryExportPayload | undefined;
	export function world_history_export_delta_after(
		delta: MoonWorldHistoryExportDelta,
	): MoonWorldHistoryExportPayload | undefined;
	export function world_history_export_delta_components(
		delta: MoonWorldHistoryExportDelta,
	): MoonWorldHistoryExportComponentSnapshot[];
	export function world_history_export_component_identity_local_component(
		identity: MoonWorldHistoryExportComponentIdentity,
	): MoonComponentTypeId;
	export function world_history_export_component_identity_key(
		identity: MoonWorldHistoryExportComponentIdentity,
	): string;
	export function world_history_export_component_identity_builtin(
		identity: MoonWorldHistoryExportComponentIdentity,
	): MoonBool;
	export function world_history_export_component_identity_schema_version(
		identity: MoonWorldHistoryExportComponentIdentity,
	): string | undefined;
	export function world_history_export_component_identity_schema_hash(
		identity: MoonWorldHistoryExportComponentIdentity,
	): string | undefined;
	export function world_history_export_payload_global_transform_format(
		payload: MoonWorldHistoryExportPayload,
	): number | undefined;
	export function world_history_export_payload_bytes(
		payload: MoonWorldHistoryExportPayload,
	): MoonByteBacking;
	export function world_history_export_component_snapshot_component(
		snapshot: MoonWorldHistoryExportComponentSnapshot,
	): MoonWorldHistoryExportComponentIdentity;
	export function world_history_export_component_snapshot_bytes(
		snapshot: MoonWorldHistoryExportComponentSnapshot,
	): MoonByteBacking;
	export function world_history_export_component_identity_new(
		localComponent: MoonComponentTypeId,
		key: string,
		builtin: boolean,
		schemaVersion: string | undefined,
		schemaHash: string | undefined,
	): MoonWorldHistoryExportComponentIdentity;
	export function world_history_export_payload_new(
		globalTransformFormat: number | undefined,
		bytes: Uint8Array | number[],
	): MoonWorldHistoryExportPayload;
	export function world_history_export_component_snapshot_new(
		component: MoonWorldHistoryExportComponentIdentity,
		bytes: Uint8Array | number[],
	): MoonWorldHistoryExportComponentSnapshot;
	export function world_history_export_delta_new(
		kind: string,
		entity: MoonEntityId | undefined,
		component: MoonWorldHistoryExportComponentIdentity | undefined,
		before: MoonWorldHistoryExportPayload | undefined,
		after: MoonWorldHistoryExportPayload | undefined,
		components: MoonWorldHistoryExportComponentSnapshot[],
	): MoonWorldHistoryExportDelta;
	export function world_history_export_record_new(
		label: string,
		deltaCount: number,
		deltas: MoonWorldHistoryExportDelta[],
	): MoonWorldHistoryExportRecord;
	export function world_history_export_new(
		formatVersion: number,
		recordCount: number,
		records: MoonWorldHistoryExportRecord[],
	): MoonWorldHistoryExport;
}
