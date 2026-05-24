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
	export type MoonPhaseKey = object;
	export type MoonSystemContext = object;
	export type MoonSystem = object;
	export type MoonSystemRunner = object;
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
	export function world_component_cpu_stride(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): number | undefined;
	export function world_component_info(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): MoonRegisteredComponent | undefined;
	export function world_component_info_name(info: MoonRegisteredComponent): string;
	export function world_component_info_cpu_stride(info: MoonRegisteredComponent): number;
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
	export function world_history_set_max_undo_records(
		history: MoonWorldHistory,
		limit: number,
	): void;
	export function world_history_clear(history: MoonWorldHistory): void;
	export function world_history_undo_len(history: MoonWorldHistory): number;
	export function world_history_redo_len(history: MoonWorldHistory): number;
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
	export function raw_query_row_read_view(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonByteView;
	export function raw_query_row_write_view(
		row: MoonRawQueryRow,
		component: MoonComponentTypeId,
	): MoonByteView;
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

	export function system_runner_new(): MoonSystemRunner;
	export function system_runner_len(runner: MoonSystemRunner): number;
	export function system_runner_add_system(
		runner: MoonSystemRunner,
		system: MoonSystem,
	): void;
	export function system_runner_has_parallel_access_conflicts(
		runner: MoonSystemRunner,
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
