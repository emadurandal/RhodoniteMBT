import type {
	MoonGpuWriteCopy,
	MoonGpuWriteView,
	MoonSpawnBatchRow,
	MoonWorld,
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
	world_child_of_component,
	world_component_bytes_copy,
	world_component_cpu_stride,
	world_component_info,
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
	world_register_cpu_component,
	world_remove_component,
	world_set_component_bytes,
	world_set_global_transform_format,
	world_set_transform_trs,
	spawn_batch_row_entity,
	spawn_batch_row_write,
	spawn_batch_row_write_view,
	world_spawn_batch,
	world_spawn_transform_global_batch_identity,
	world_transform_component,
	world_update_global_transforms_from_transforms,
	world_extract_global_transform_refs,
	world_write_global_transforms_dense_range_views,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	ComponentTypeId,
	EntityId,
	type EntityLocation,
	RegisteredComponent,
} from "./types.ts";
import { ByteView, byteView, bytesInput, moonBool } from "./views.ts";

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

	componentCpuStride(component: ComponentTypeId): number | null {
		return world_component_cpu_stride(this.inner, component.inner) ?? null;
	}

	componentInfo(component: ComponentTypeId): RegisteredComponent | null {
		const info = world_component_info(this.inner, component.inner);
		return info === undefined || info === null ? null : new RegisteredComponent(info);
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
