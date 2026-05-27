// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type {
	MoonTransformPropagationReport,
	MoonWorld,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	transform_propagation_report_archetype_path_unavailable_count,
	transform_propagation_report_broken_ancestor_chain_count,
	transform_propagation_report_dirty_queue_count,
	transform_propagation_report_dirty_root_count,
	transform_propagation_report_fallback_to_full,
	transform_propagation_report_failure_count,
	transform_propagation_report_failure_reason,
	transform_propagation_report_global_transform_write_count,
	transform_propagation_report_hierarchy_index_rebuilt,
	transform_propagation_report_missing_global_transform_ref_count,
	transform_propagation_report_ok,
	transform_propagation_report_pending_upload_range_count,
	transform_propagation_report_skipped_dirty_entity_count,
	transform_propagation_report_used_dirty_path,
	transform_propagation_report_used_full_path,
	transform_propagation_report_visited_entity_count,
	world_add_component,
	world_add_component_bytes,
	world_camera_blob_word_capacity,
	world_camera_component,
	world_camera_gpu_row_copy,
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
	world_drain_camera_blob_write_views,
	world_drain_global_transform_blob_write_views,
	world_extract_global_transform_refs,
	world_get_global_transform_col_major,
	world_global_transform_blob_word_capacity,
	world_global_transform_component,
	world_has_component,
	world_is_alive,
	world_location,
	world_new,
	world_new_with_global_transform_f16,
	world_orbit_camera_controller_component,
	world_propagate_global_transforms_from_transforms_report,
	world_register_cpu_component,
	world_register_cpu_component_with_identity,
	world_remove_component,
	world_reserve_batch_capacity,
	world_set_camera_matrices_col_major,
	world_set_child_of,
	world_set_component_bytes,
	world_set_global_transform_col_major,
	world_set_global_transform_format,
	world_set_transform_trs,
	world_spawn_batch,
	world_spawn_transform_global_batch_identity,
	world_transform_component,
	world_update_global_transforms_from_transforms,
	world_write_global_transform_blob_range_views,
	world_write_global_transforms_dense_range_views,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	ComponentTypeId,
	EntityId,
	type EntityLocation,
	RegisteredComponent,
} from "./types.ts";
import { type ByteView, byteView, bytesInput, moonBool } from "./views.ts";
import { GpuWriteView, SpawnBatchRow } from "./world-primitives.ts";

export type CpuComponentIdentity = {
	readonly stableKey: string;
	readonly schemaVersion?: string;
	readonly schemaHash?: string;
};

export type TransformPropagationFailureReason =
	| "none"
	| "broken_ancestor_chain"
	| "missing_global_transform_ref"
	| "archetype_path_unavailable";

export class TransformPropagationReport {
	readonly inner: MoonTransformPropagationReport;

	constructor(inner: MoonTransformPropagationReport) {
		this.inner = inner;
	}

	ok(): boolean {
		return moonBool(transform_propagation_report_ok(this.inner));
	}

	usedDirtyPath(): boolean {
		return moonBool(transform_propagation_report_used_dirty_path(this.inner));
	}

	usedFullPath(): boolean {
		return moonBool(transform_propagation_report_used_full_path(this.inner));
	}

	fallbackToFull(): boolean {
		return moonBool(transform_propagation_report_fallback_to_full(this.inner));
	}

	dirtyQueueCount(): number {
		return transform_propagation_report_dirty_queue_count(this.inner);
	}

	dirtyRootCount(): number {
		return transform_propagation_report_dirty_root_count(this.inner);
	}

	skippedDirtyEntityCount(): number {
		return transform_propagation_report_skipped_dirty_entity_count(this.inner);
	}

	visitedEntityCount(): number {
		return transform_propagation_report_visited_entity_count(this.inner);
	}

	globalTransformWriteCount(): number {
		return transform_propagation_report_global_transform_write_count(this.inner);
	}

	hierarchyIndexRebuilt(): boolean {
		return moonBool(
			transform_propagation_report_hierarchy_index_rebuilt(this.inner),
		);
	}

	pendingUploadRangeCount(): number {
		return transform_propagation_report_pending_upload_range_count(this.inner);
	}

	failureReason(): TransformPropagationFailureReason {
		return transform_propagation_report_failure_reason(
			this.inner,
		) as TransformPropagationFailureReason;
	}

	failureCount(): number {
		return transform_propagation_report_failure_count(this.inner);
	}

	brokenAncestorChainCount(): number {
		return transform_propagation_report_broken_ancestor_chain_count(this.inner);
	}

	missingGlobalTransformRefCount(): number {
		return transform_propagation_report_missing_global_transform_ref_count(
			this.inner,
		);
	}

	archetypePathUnavailableCount(): number {
		return transform_propagation_report_archetype_path_unavailable_count(
			this.inner,
		);
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

	propagateGlobalTransformsFromTransformsReport(): TransformPropagationReport {
		return new TransformPropagationReport(
			world_propagate_global_transforms_from_transforms_report(this.inner),
		);
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
