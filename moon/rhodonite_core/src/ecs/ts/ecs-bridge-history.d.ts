// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

/** Generated MoonBit ECS js_bridge bindings (`moon build --target js --release`). */
declare module "@moon/rhodonite_core/ecs/js_bridge" {
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
	export function query_new_with_excluded(
		required: MoonComponentTypeId[],
		excluded: MoonComponentTypeId[],
	): MoonQuery;
	export function raw_query_new(required: MoonComponentTypeId[]): MoonRawQuery;
	export function raw_query_new_with_excluded(
		required: MoonComponentTypeId[],
		excluded: MoonComponentTypeId[],
	): MoonRawQuery;
	export function query_cache_new(required: MoonComponentTypeId[]): MoonQueryCache;
	export function query_cache_new_with_excluded(
		required: MoonComponentTypeId[],
		excluded: MoonComponentTypeId[],
	): MoonQueryCache;
	export function raw_query_cache_new(
		required: MoonComponentTypeId[],
	): MoonRawQueryCache;
	export function raw_query_cache_new_with_excluded(
		required: MoonComponentTypeId[],
		excluded: MoonComponentTypeId[],
	): MoonRawQueryCache;
	export function query_required_components(query: MoonQuery): MoonComponentTypeId[];
	export function query_excluded_components(query: MoonQuery): MoonComponentTypeId[];
	export function query_component_index(
		query: MoonQuery,
		component: MoonComponentTypeId,
	): number;
	export function query_cache_required_components(
		cache: MoonQueryCache,
	): MoonComponentTypeId[];
	export function query_cache_excluded_components(
		cache: MoonQueryCache,
	): MoonComponentTypeId[];
	export function query_cache_component_index(
		cache: MoonQueryCache,
		component: MoonComponentTypeId,
	): number;
	export function raw_query_required_components(
		query: MoonRawQuery,
	): MoonComponentTypeId[];
	export function raw_query_excluded_components(
		query: MoonRawQuery,
	): MoonComponentTypeId[];
	export function raw_query_cache_required_components(
		cache: MoonRawQueryCache,
	): MoonComponentTypeId[];
	export function raw_query_cache_excluded_components(
		cache: MoonRawQueryCache,
	): MoonComponentTypeId[];
	export function raw_query_component_index(
		query: MoonRawQuery,
		component: MoonComponentTypeId,
	): number;
	export function raw_query_cache_component_index(
		cache: MoonRawQueryCache,
		component: MoonComponentTypeId,
	): number;
	export function query_for_each(
		query: MoonQuery,
		world: MoonWorld,
		f: (row: MoonQueryRow) => void,
	): void;
	export function query_for_each_read_at(
		query: MoonQuery,
		world: MoonWorld,
		index: number,
		f: (entity: MoonEntityId, bytes: MoonByteView) => void,
	): void;
	export function query_cache_for_each(
		cache: MoonQueryCache,
		world: MoonWorld,
		f: (row: MoonQueryRow) => void,
	): void;
	export function query_cache_for_each_read_at(
		cache: MoonQueryCache,
		world: MoonWorld,
		index: number,
		f: (entity: MoonEntityId, bytes: MoonByteView) => void,
	): void;
	export function raw_query_for_each(
		query: MoonRawQuery,
		world: MoonWorld,
		f: (row: MoonRawQueryRow) => void,
	): void;
	export function raw_query_for_each_read_view_at(
		query: MoonRawQuery,
		world: MoonWorld,
		index: number,
		f: (entity: MoonEntityId, bytes: MoonByteView) => void,
	): void;
	export function raw_query_cache_for_each(
		cache: MoonRawQueryCache,
		world: MoonWorld,
		f: (row: MoonRawQueryRow) => void,
	): void;
	export function raw_query_cache_for_each_read_view_at(
		cache: MoonRawQueryCache,
		world: MoonWorld,
		index: number,
		f: (entity: MoonEntityId, bytes: MoonByteView) => void,
	): void;
	export function query_prepare(query: MoonQuery, world: MoonWorld): MoonPreparedQuery;
	export function query_plan(query: MoonQuery, world: MoonWorld): MoonQueryPlan;
	export function query_cache_plan(
		cache: MoonQueryCache,
		world: MoonWorld,
	): MoonQueryPlan;
	export function query_cache_refresh(cache: MoonQueryCache, world: MoonWorld): void;
	export function raw_query_prepare(
		query: MoonRawQuery,
		world: MoonWorld,
	): MoonRawPreparedQuery;
	export function raw_query_plan(query: MoonRawQuery, world: MoonWorld): MoonQueryPlan;
	export function raw_query_cache_plan(
		cache: MoonRawQueryCache,
		world: MoonWorld,
	): MoonQueryPlan;
	export function raw_query_cache_refresh(
		cache: MoonRawQueryCache,
		world: MoonWorld,
	): void;
	export function raw_query_for_each_archetype(
		query: MoonRawQuery,
		world: MoonWorld,
		f: (archetype: MoonRawQueryArchetype) => void,
	): void;
	export function raw_query_cache_for_each_archetype(
		cache: MoonRawQueryCache,
		world: MoonWorld,
		f: (archetype: MoonRawQueryArchetype) => void,
	): void;
	export function raw_prepared_query_for_each_archetype(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
		f: (archetype: MoonRawQueryArchetype) => void,
	): void;
	export function raw_prepared_query_plan(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
	): MoonQueryPlan;
	export function raw_prepared_query_is_stale(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
	): MoonBool;
	export function raw_prepared_query_refresh(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
	): MoonRawPreparedQuery;
	export function prepared_query_for_each(
		query: MoonPreparedQuery,
		world: MoonWorld,
		f: (row: MoonQueryRow) => void,
	): void;
	export function prepared_query_for_each_read_at(
		query: MoonPreparedQuery,
		world: MoonWorld,
		index: number,
		f: (entity: MoonEntityId, bytes: MoonByteView) => void,
	): void;
	export function prepared_query_plan(
		query: MoonPreparedQuery,
		world: MoonWorld,
	): MoonQueryPlan;
	export function prepared_query_is_stale(
		query: MoonPreparedQuery,
		world: MoonWorld,
	): MoonBool;
	export function prepared_query_refresh(
		query: MoonPreparedQuery,
		world: MoonWorld,
	): MoonPreparedQuery;
	export function raw_prepared_query_for_each(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
		f: (row: MoonRawQueryRow) => void,
	): void;
	export function raw_prepared_query_for_each_read_view_at(
		query: MoonRawPreparedQuery,
		world: MoonWorld,
		index: number,
		f: (entity: MoonEntityId, bytes: MoonByteView) => void,
	): void;
	export function query_plan_required_components(
		plan: MoonQueryPlan,
	): MoonComponentTypeId[];
	export function query_plan_excluded_components(
		plan: MoonQueryPlan,
	): MoonComponentTypeId[];
	export function query_plan_archetype_version(plan: MoonQueryPlan): number;
	export function query_plan_candidate_archetype_count(
		plan: MoonQueryPlan,
	): number;
	export function query_plan_matched_archetype_count(
		plan: MoonQueryPlan,
	): number;
	export function query_plan_matched_row_count(plan: MoonQueryPlan): number;
	export function query_plan_stale(plan: MoonQueryPlan): MoonBool;
	export function query_plan_archetypes(
		plan: MoonQueryPlan,
	): MoonQueryPlanArchetype[];
	export function query_plan_archetype_index(
		archetype: MoonQueryPlanArchetype,
	): number;
	export function query_plan_archetype_row_count(
		archetype: MoonQueryPlanArchetype,
	): number;
	export function query_row_entity(row: MoonQueryRow): MoonEntityId;
	export function raw_query_row_entity(row: MoonRawQueryRow): MoonEntityId;
	export function query_row_has(
		row: MoonQueryRow,
		component: MoonComponentTypeId,
	): MoonBool;
	export function query_row_has_at(row: MoonQueryRow, index: number): MoonBool;
	export function raw_query_row_has(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonBool;
	export function raw_query_row_has_at(
		row: MoonRawQueryRow,
		index: number,
	): MoonBool;
	export function query_row_read(
		row: MoonQueryRow,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): void;
	export function query_row_read_at(
		row: MoonQueryRow,
		index: number,
		f: (bytes: MoonByteView) => void,
	): void;
	export function query_row_write(
		row: MoonQueryRow,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): void;
	export function query_row_write_at(
		row: MoonQueryRow,
		index: number,
		f: (bytes: MoonByteView) => void,
	): void;
	export function query_row_write_tracked(
		row: MoonQueryRow,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function query_row_write_tracked_at(
		row: MoonQueryRow,
		history: MoonWorldHistory,
		index: number,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_row_read_view(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_row_read_view_at(
		row: MoonRawQueryRow,
		index: number,
	): MoonByteView;
	export function raw_query_row_write_view(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_row_write_view_at(
		row: MoonRawQueryRow,
		index: number,
	): MoonByteView;
	export function raw_query_row_write_tracked(
		row: MoonRawQueryRow,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_row_write_tracked_at(
		row: MoonRawQueryRow,
		history: MoonWorldHistory,
		index: number,
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
	export function raw_query_archetype_has_at(
		archetype: MoonRawQueryArchetype,
		index: number,
	): MoonBool;
	export function raw_query_archetype_component_stride(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): number;
	export function raw_query_archetype_component_stride_at(
		archetype: MoonRawQueryArchetype,
		index: number,
	): number;
	export function raw_query_archetype_read_column(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_archetype_read_column_at(
		archetype: MoonRawQueryArchetype,
		index: number,
	): MoonByteView;
	export function raw_query_archetype_read_column_range(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
		rowStart: number,
		rowCount: number,
	): MoonByteView;
	export function raw_query_archetype_read_column_range_at(
		archetype: MoonRawQueryArchetype,
		index: number,
		rowStart: number,
		rowCount: number,
	): MoonByteView;
	export function raw_query_archetype_write_column(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_archetype_write_column_at(
		archetype: MoonRawQueryArchetype,
		index: number,
	): MoonByteView;
	export function raw_query_archetype_write_column_range(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
		rowStart: number,
		rowCount: number,
	): MoonByteView;
	export function raw_query_archetype_write_column_range_at(
		archetype: MoonRawQueryArchetype,
		index: number,
		rowStart: number,
		rowCount: number,
	): MoonByteView;
	export function raw_query_archetype_for_each_column_chunk(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
		rowsPerChunk: number,
		f: (rowStart: number, rowCount: number, bytes: MoonByteView) => void,
	): void;
	export function raw_query_archetype_for_each_column_chunk_at(
		archetype: MoonRawQueryArchetype,
		index: number,
		rowsPerChunk: number,
		f: (rowStart: number, rowCount: number, bytes: MoonByteView) => void,
	): void;
	export function raw_query_archetype_for_each_column_chunk_span(
		archetype: MoonRawQueryArchetype,
		component: MoonComponentTypeId,
		rowsPerChunk: number,
		f: (
			rowStart: number,
			rowCount: number,
			column: MoonByteView,
			byteStart: number,
			byteCount: number,
			stride: number,
		) => void,
	): void;
	export function raw_query_archetype_for_each_column_chunk_span_at(
		archetype: MoonRawQueryArchetype,
		index: number,
		rowsPerChunk: number,
		f: (
			rowStart: number,
			rowCount: number,
			column: MoonByteView,
			byteStart: number,
			byteCount: number,
			stride: number,
		) => void,
	): void;
	export function raw_query_archetype_write_column_tracked(
		archetype: MoonRawQueryArchetype,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_archetype_write_column_tracked_at(
		archetype: MoonRawQueryArchetype,
		history: MoonWorldHistory,
		index: number,
		f: (bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_archetype_write_column_rows_tracked(
		archetype: MoonRawQueryArchetype,
		history: MoonWorldHistory,
		component: MoonComponentTypeId,
		rows: number[],
		f: (row: number, bytes: MoonByteView) => void,
	): MoonBool;
	export function raw_query_archetype_write_column_rows_tracked_at(
		archetype: MoonRawQueryArchetype,
		history: MoonWorldHistory,
		index: number,
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
	export function system_new_direct(
		name: string,
		phase: MoonPhaseKey,
		reads: MoonComponentTypeId[],
		writes: MoonComponentTypeId[],
		run: (world: MoonWorld, ctx: MoonSystemContext) => void,
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
	export function system_runner_run_phase_report(
		runner: MoonSystemRunner,
		world: MoonWorld,
		ctx: MoonSystemContext,
		phase: MoonPhaseKey,
	): MoonSystemRunReport;
	export function world_history_run_system_phase(
		history: MoonWorldHistory,
		runner: MoonSystemRunner,
		world: MoonWorld,
		ctx: MoonSystemContext,
		phase: MoonPhaseKey,
		label: string,
	): MoonBool;
	export function world_history_run_system_phase_report(
		history: MoonWorldHistory,
		runner: MoonSystemRunner,
		world: MoonWorld,
		ctx: MoonSystemContext,
		phase: MoonPhaseKey,
		label: string,
	): MoonSystemRunReport;
	export function system_run_report_phase(
		report: MoonSystemRunReport,
	): MoonPhaseKey;
	export function system_run_report_ok(report: MoonSystemRunReport): MoonBool;
	export function system_run_report_batch_count(
		report: MoonSystemRunReport,
	): number;
	export function system_run_report_system_count(
		report: MoonSystemRunReport,
	): number;
	export function system_run_report_queued_command_count(
		report: MoonSystemRunReport,
	): number;
	export function system_run_report_applied_command_count(
		report: MoonSystemRunReport,
	): number;
	export function system_run_report_failed_command_count(
		report: MoonSystemRunReport,
	): number;
	export function system_run_report_batches(
		report: MoonSystemRunReport,
	): MoonSystemRunBatchReport[];
	export function system_run_batch_report_index(
		report: MoonSystemRunBatchReport,
	): number;
	export function system_run_batch_report_ok(
		report: MoonSystemRunBatchReport,
	): MoonBool;
	export function system_run_batch_report_system_count(
		report: MoonSystemRunBatchReport,
	): number;
	export function system_run_batch_report_queued_command_count(
		report: MoonSystemRunBatchReport,
	): number;
	export function system_run_batch_report_applied_command_count(
		report: MoonSystemRunBatchReport,
	): number;
	export function system_run_batch_report_failed_command_count(
		report: MoonSystemRunBatchReport,
	): number;
	export function system_run_batch_report_systems(
		report: MoonSystemRunBatchReport,
	): MoonSystemRunSystemReport[];
	export function system_run_system_report_runner_index(
		report: MoonSystemRunSystemReport,
	): number;
	export function system_run_system_report_batch_index(
		report: MoonSystemRunSystemReport,
	): number;
	export function system_run_system_report_name(
		report: MoonSystemRunSystemReport,
	): string;
	export function system_run_system_report_queued_command_count(
		report: MoonSystemRunSystemReport,
	): number;
	export function system_run_system_report_applied_command_count(
		report: MoonSystemRunSystemReport,
	): number;
	export function system_run_system_report_failed_command_count(
		report: MoonSystemRunSystemReport,
	): number;
	export function system_run_system_report_failures(
		report: MoonSystemRunSystemReport,
	): MoonCommandBufferCommandFailure[];
	export function command_buffer_command_failure_command_index(
		failure: MoonCommandBufferCommandFailure,
	): number;
	export function command_buffer_command_failure_command_kind(
		failure: MoonCommandBufferCommandFailure,
	): string;
	export function command_buffer_command_failure_reason(
		failure: MoonCommandBufferCommandFailure,
	): string;
	export function command_buffer_command_failure_entity(
		failure: MoonCommandBufferCommandFailure,
	): MoonEntityId;
	export function command_buffer_command_failure_component(
		failure: MoonCommandBufferCommandFailure,
	): MoonComponentTypeId;

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
