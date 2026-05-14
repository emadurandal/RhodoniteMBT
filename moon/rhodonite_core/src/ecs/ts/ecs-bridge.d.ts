/** Generated MoonBit ECS js_bridge bindings (`moon build --target js --release`). */
declare module "@moon/rhodonite_core/ecs/js_bridge" {
	export type MoonBool = boolean | 0 | 1;
	export type MoonByteBacking = Uint8Array | number[];
	export type MoonByteView = { buf: MoonByteBacking; start: number; end: number };

	export type MoonEntityId = { index: number; generation: number };
	export type MoonComponentTypeId = { index: number };
	export type MoonEntityLocation = { archetype_index: number; row: number };
	export type MoonWorld = object;
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
	export type MoonGpuResizeEvent = {
		component: MoonComponentTypeId;
		required_capacity: number;
		needs_full_upload: MoonBool;
	};

	export function entity_id_new(index: number, generation: number): MoonEntityId;
	export function entity_id_index(entity: MoonEntityId): number;
	export function entity_id_generation(entity: MoonEntityId): number;
	export function entity_id_gpu_index(entity: MoonEntityId): number;
	export function component_type_id_new(index: number): MoonComponentTypeId;
	export function component_type_id_index(component: MoonComponentTypeId): number;

	export function world_new(): MoonWorld;
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
	export function world_register_cpu_component(
		world: MoonWorld,
		name: string,
		cpuStride: number,
	): MoonComponentTypeId;
	export function world_register_gpu_component(
		world: MoonWorld,
		name: string,
		gpuLayout: MoonGpuLayout,
	): MoonComponentTypeId;
	export function world_component_cpu_stride(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): number | undefined;
	export function world_component_gpu_layout(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): MoonGpuLayout | undefined;
	export function world_component_info(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): MoonRegisteredComponent | undefined;
	export function world_component_info_kind(info: MoonRegisteredComponent): string;
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
	export function world_clear_gpu_component(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): MoonBool;
	export function world_component_bytes_copy(
		world: MoonWorld,
		entity: MoonEntityId,
		component: MoonComponentTypeId,
	): Uint8Array | number[] | undefined;
	export function world_drain_gpu_write_views(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): MoonGpuWriteView[];
	export function world_drain_gpu_writes_copy(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): MoonGpuWriteCopy[];
	export function world_drain_resize_events(world: MoonWorld): MoonGpuResizeEvent[];
	export function world_gpu_component_active_indices(
		world: MoonWorld,
		component: MoonComponentTypeId,
	): number[];
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
	export function world_update_global_transforms_from_transforms(
		world: MoonWorld,
	): void;
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
	export function world_spawn_batch(
		world: MoonWorld,
		components: MoonComponentTypeId[],
		count: number,
		f: (index: number, entity: MoonEntityId, row: MoonSpawnBatchRow) => void,
	): MoonEntityId[];
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

	export function gpu_layout_empty(stride: number): MoonGpuLayout;
	export function gpu_layout_transform3d(): MoonGpuLayout;
	export function gpu_layout_global_transform(): MoonGpuLayout;
	export function gpu_layout_child_of(): MoonGpuLayout;
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
	export function gpu_resize_event_component(
		event: MoonGpuResizeEvent,
	): MoonComponentTypeId;
	export function gpu_resize_event_required_capacity(
		event: MoonGpuResizeEvent,
	): number;
	export function gpu_resize_event_needs_full_upload(
		event: MoonGpuResizeEvent,
	): MoonBool;

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
