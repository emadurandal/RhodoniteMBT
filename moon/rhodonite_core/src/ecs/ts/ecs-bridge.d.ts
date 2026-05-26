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
	export type MoonCommandBuffer = object;
	export type MoonQuery = object;
	export type MoonRawQuery = object;
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
	export function world_history_record_summary_label(
		summary: MoonWorldHistoryRecordSummary,
	): string;
	export function world_history_record_summary_delta_count(
		summary: MoonWorldHistoryRecordSummary,
	): number;
	export function world_history_record_summary_payload_bytes(
		summary: MoonWorldHistoryRecordSummary,
	): number;
	export function world_history_record_summary_deltas(
		summary: MoonWorldHistoryRecordSummary,
	): MoonWorldHistoryDeltaSummary[];
	export function world_history_delta_summary_kind(
		summary: MoonWorldHistoryDeltaSummary,
	): string;
	export function world_history_delta_summary_entity(
		summary: MoonWorldHistoryDeltaSummary,
	): MoonEntityId | undefined;
	export function world_history_delta_summary_component(
		summary: MoonWorldHistoryDeltaSummary,
	): MoonComponentTypeId | undefined;
	export function world_history_delta_summary_component_count(
		summary: MoonWorldHistoryDeltaSummary,
	): number;
	export function world_history_delta_summary_payload_bytes(
		summary: MoonWorldHistoryDeltaSummary,
	): number;
	export function world_history_delta_summary_before_present(
		summary: MoonWorldHistoryDeltaSummary,
	): MoonBool;
	export function world_history_delta_summary_after_present(
		summary: MoonWorldHistoryDeltaSummary,
	): MoonBool;
	export function world_history_last_diagnostic(
		history: MoonWorldHistory,
	): string;
	export function world_history_undo_label(
		history: MoonWorldHistory,
	): string | undefined;
	export function world_history_redo_label(
		history: MoonWorldHistory,
	): string | undefined;
	export function world_history_begin_transaction(
		history: MoonWorldHistory,
		label: string,
	): MoonBool;
	export function world_history_begin_guarded_transaction(
		history: MoonWorldHistory,
		world: MoonWorld,
		label: string,
	): MoonBool;
	export function world_history_commit_transaction(
		history: MoonWorldHistory,
	): MoonBool;
	export function world_history_cancel_transaction(
		history: MoonWorldHistory,
	): MoonBool;
	export function world_history_cancel_transaction_preserving_diagnostic(
		history: MoonWorldHistory,
	): MoonBool;
	export function world_history_cancel_transaction_reverting(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonBool;
	export function world_history_can_undo(history: MoonWorldHistory): MoonBool;
	export function world_history_can_redo(history: MoonWorldHistory): MoonBool;
	export function world_history_undo(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonBool;
	export function world_history_redo(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonBool;
	export function world_history_create_entity(
		history: MoonWorldHistory,
		world: MoonWorld,
	): MoonEntityId;
	export function world_history_create_entities(
		history: MoonWorldHistory,
		world: MoonWorld,
		count: number,
	): MoonEntityId[];
	export function world_history_spawn_batch(
		history: MoonWorldHistory,
		world: MoonWorld,
		components: MoonComponentTypeId[],
		count: number,
		f: (index: number, entity: MoonEntityId, row: MoonSpawnBatchRow) => void,
	): MoonEntityId[];
	export function world_history_destroy_entity(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
	): MoonBool;
	export function world_history_add_component(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): MoonBool;
	export function world_history_add_component_bytes(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
		bytes: Uint8Array | number[],
	): MoonBool;
	export function world_history_add_component_bytes_many(
		history: MoonWorldHistory,
		world: MoonWorld,
		component: MoonComponentTypeId,
		entities: MoonEntityId[],
		bytesList: Array<Uint8Array | number[]>,
	): MoonBool;
	export function world_history_set_component_bytes(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
		bytes: Uint8Array | number[],
	): MoonBool;
	export function world_history_set_component_bytes_many(
		history: MoonWorldHistory,
		world: MoonWorld,
		component: MoonComponentTypeId,
		entities: MoonEntityId[],
		bytesList: Array<Uint8Array | number[]>,
	): MoonBool;
	export function world_history_remove_component(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): MoonBool;
	export function world_history_set_transform_trs(
		history: MoonWorldHistory,
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
	export function world_history_set_child_of(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		parent: MoonEntityId,
	): MoonBool;
	export function world_history_set_global_transform_col_major(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		matrixColMajor: number[],
	): MoonBool;
	export function world_history_set_global_transform_format(
		history: MoonWorldHistory,
		world: MoonWorld,
		entity: MoonEntityId,
		formatCode: number,
	): MoonBool;
	export function world_history_set_camera_matrices_col_major(
		history: MoonWorldHistory,
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
	export function spawn_batch_row_entity(row: MoonSpawnBatchRow): MoonEntityId;
	export function spawn_batch_row_write_view(
		row: MoonSpawnBatchRow,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function spawn_batch_row_write(
		row: MoonSpawnBatchRow,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): void;

	export function query_new(required: MoonComponentTypeId[]): MoonQuery;
	export function raw_query_new(required: MoonComponentTypeId[]): MoonRawQuery;
	export function query_required_components(query: MoonQuery): MoonComponentTypeId[];
	export function query_for_each(
		query: MoonQuery,
		world: MoonWorld,
		f: (row: MoonQueryRow) => void,
	): void;
	export function raw_query_for_each(
		query: MoonRawQuery,
		world: MoonWorld,
		f: (row: MoonRawQueryRow) => void,
	): void;
	export function query_prepare(query: MoonQuery, world: MoonWorld): MoonPreparedQuery;
	export function raw_query_prepare(
		query: MoonRawQuery,
		world: MoonWorld,
	): MoonRawPreparedQuery;
	export function raw_query_for_each_archetype(
		query: MoonRawQuery,
		world: MoonWorld,
		f: (archetype: MoonRawQueryArchetype) => void,
	): void;
	export function raw_prepared_query_for_each_archetype(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
		f: (archetype: MoonRawQueryArchetype) => void,
	): void;
	export function prepared_query_for_each(
		query: MoonPreparedQuery,
		world: MoonWorld,
		f: (row: MoonQueryRow) => void,
	): void;
	export function raw_prepared_query_for_each(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
		f: (row: MoonRawQueryRow) => void,
	): void;
	export function query_row_entity(row: MoonQueryRow): MoonEntityId;
	export function raw_query_row_entity(row: MoonRawQueryRow): MoonEntityId;
	export function query_row_has(
		row: MoonQueryRow,
		component: MoonComponentTypeId,
	): MoonBool;
	export function raw_query_row_has(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonBool;
	export function query_row_read(
		row: MoonQueryRow,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): void;
	export function query_row_write(
		row: MoonQueryRow,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): void;
	export function query_row_write_tracked(
		row: MoonQueryRow,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_row_read_view(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_row_write_view(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_row_write_tracked(
		row: MoonRawQueryRow,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_archetype_length(
		archetype: MoonRawQueryArchetype,
	): number;
	export function raw_query_archetype_entity(
		archetype: MoonRawQueryArchetype,
		row: number,
	): MoonEntityId;
	export function raw_query_archetype_has(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): MoonBool;
	export function raw_query_archetype_component_stride(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): number;
	export function raw_query_archetype_read_column(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_archetype_write_column(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_archetype_write_column_tracked(
		archetype: MoonRawQueryArchetype,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_archetype_write_column_rows_tracked(
		archetype: MoonRawQueryArchetype,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		rows: number[],
		f: (row: number, bytes: MoonByteView) => void,
	): MoonBool;

	export function phase_key_new(name: string): MoonPhaseKey;
	export function phase_key_name(phase: MoonPhaseKey): string;
	export function system_context_new(
		deltaSeconds: number,
		frameIndex: number,
	): MoonSystemContext;
	export function system_context_delta_seconds(ctx: MoonSystemContext): number;
	export function system_context_frame_index(ctx: MoonSystemContext): number;

	export function command_buffer_len(commands: MoonCommandBuffer): number;
	export function command_buffer_is_empty(commands: MoonCommandBuffer): MoonBool;
	export function command_buffer_create_entity(
		commands: MoonCommandBuffer,
	): MoonEntityId;
	export function command_buffer_destroy_entity(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
	): void;
	export function command_buffer_add_component(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): void;
	export function command_buffer_add_component_bytes(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
		bytes: Uint8Array | number[],
	): void;
	export function command_buffer_set_component_bytes(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
		bytes: Uint8Array | number[],
	): void;
	export function command_buffer_set_global_transform_col_major(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		matrixColMajor: number[],
	): void;
	export function command_buffer_set_global_transform_format(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		formatCode: number,
	): void;
	export function command_buffer_set_camera_matrices_col_major(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		viewColMajor: number[],
		projColMajor: number[],
		near: number,
		far: number,
		aspect: number,
		projectionKind: number,
		flags: number,
	): void;
	export function command_buffer_remove_component(
		commands: MoonCommandBuffer,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): void;

	export function system_new(
		name: string,
		phase: MoonPhaseKey,
		reads: MoonComponentTypeId[],
		writes: MoonComponentTypeId[],
		run: (
			world: MoonWorld,
			ctx: MoonSystemContext,
			commands: MoonCommandBuffer,
		) => void,
	): MoonSystem;
	export function system_new_with_structural_write(
		name: string,
		phase: MoonPhaseKey,
		reads: MoonComponentTypeId[],
		writes: MoonComponentTypeId[],
		run: (
			world: MoonWorld,
			ctx: MoonSystemContext,
			commands: MoonCommandBuffer,
		) => void,
	): MoonSystem;
	export function system_name(system: MoonSystem): string;
	export function system_phase(system: MoonSystem): MoonPhaseKey;
	export function system_reads(system: MoonSystem): MoonComponentTypeId[];
	export function system_writes(system: MoonSystem): MoonComponentTypeId[];
	export function system_structural_write(system: MoonSystem): MoonBool;
	export function system_conflicts_with(
		system: MoonSystem,
		other: MoonSystem,
	): MoonBool;
	export function transform_propagation_system(
		world: MoonWorld,
		phase: MoonPhaseKey,
	): MoonSystem;
	export function orbit_camera_transform_command_system(
		world: MoonWorld,
		phase: MoonPhaseKey,
		orbitComponent: MoonComponentTypeId,
		homeComponent: MoonComponentTypeId,
	): MoonSystem;
	export function camera_blob_sync_command_system(
		world: MoonWorld,
		phase: MoonPhaseKey,
		lensComponent: MoonComponentTypeId,
	): MoonSystem;
	export function orbit_camera_blob_sync_command_system(
		world: MoonWorld,
		phase: MoonPhaseKey,
		orbitComponent: MoonComponentTypeId,
		lensComponent: MoonComponentTypeId,
	): MoonSystem;

	export function system_runner_new(): MoonSystemRunner;
	export function system_runner_len(runner: MoonSystemRunner): number;
	export function system_runner_add_system(
		runner: MoonSystemRunner,
		system: MoonSystem,
	): void;
	export function system_runner_has_parallel_access_conflicts(
		runner: MoonSystemRunner,
	): MoonBool;
	export function system_runner_plan_phase(
		runner: MoonSystemRunner,
		phase: MoonPhaseKey,
	): MoonSystemPhasePlan;
	export function system_phase_plan_phase(
		plan: MoonSystemPhasePlan,
	): MoonPhaseKey;
	export function system_phase_plan_system_count(
		plan: MoonSystemPhasePlan,
	): number;
	export function system_phase_plan_batches(
		plan: MoonSystemPhasePlan,
	): MoonSystemPlanBatch[];
	export function system_plan_batch_index(batch: MoonSystemPlanBatch): number;
	export function system_plan_batch_systems(
		batch: MoonSystemPlanBatch,
	): MoonSystemPlanSystem[];
	export function system_plan_system_runner_index(
		system: MoonSystemPlanSystem,
	): number;
	export function system_plan_system_batch_index(
		system: MoonSystemPlanSystem,
	): number;
	export function system_plan_system_name(system: MoonSystemPlanSystem): string;
	export function system_plan_system_phase(
		system: MoonSystemPlanSystem,
	): MoonPhaseKey;
	export function system_plan_system_reads(
		system: MoonSystemPlanSystem,
	): MoonComponentTypeId[];
	export function system_plan_system_writes(
		system: MoonSystemPlanSystem,
	): MoonComponentTypeId[];
	export function system_plan_system_structural_write(
		system: MoonSystemPlanSystem,
	): MoonBool;
	export function system_runner_run_phase(
		runner: MoonSystemRunner,
		world: MoonWorld,
		ctx: MoonSystemContext,
		phase: MoonPhaseKey,
	): MoonBool;
	export function world_history_run_system_phase(
		history: MoonWorldHistory,
		runner: MoonSystemRunner,
		world: MoonWorld,
		ctx: MoonSystemContext,
		phase: MoonPhaseKey,
		label: string,
	): MoonBool;

	export function gpu_layout_empty(stride: number): MoonGpuLayout;
	export function gpu_layout_transform3d(): MoonGpuLayout;
	export function gpu_layout_global_transform(): MoonGpuLayout;
	export function gpu_layout_global_transform_f16(): MoonGpuLayout;
	export function gpu_layout_child_of(): MoonGpuLayout;
	export function gpu_layout_camera(): MoonGpuLayout;
	export function gpu_layout_stride(layout: MoonGpuLayout): number;
	export function gpu_layout_align(layout: MoonGpuLayout): number;
	export function gpu_layout_is_valid(layout: MoonGpuLayout): MoonBool;
	export function gpu_layout_fields(layout: MoonGpuLayout): MoonGpuField[];
	export function gpu_field_name(field: MoonGpuField): string;
	export function gpu_field_kind_name(field: MoonGpuField): string;
	export function gpu_field_offset(field: MoonGpuField): number;
	export function gpu_field_size(field: MoonGpuField): number;
	export function gpu_field_align(field: MoonGpuField): number;

	export function gpu_write_view_byte_offset(write: MoonGpuWriteView): number;
	export function gpu_write_view_bytes(write: MoonGpuWriteView): MoonByteView;
	export function gpu_write_copy_byte_offset(write: MoonGpuWriteCopy): number;
	export function gpu_write_copy_bytes(write: MoonGpuWriteCopy): Uint8Array | number[];

	export function bytes_get_f32(bytes: Uint8Array | number[], offset: number): number;
	export function bytes_put_f32(
		bytes: Uint8Array | number[],
		offset: number,
		value: number,
	): void;
	export function bytes_view_get_f32(view: MoonByteView, offset: number): number;
	export function bytes_mut_view_get_f32(view: MoonByteView, offset: number): number;
	export function bytes_mut_view_put_f32(
		view: MoonByteView,
		offset: number,
		value: number,
	): void;
}
