import type {
	MoonComponentTypeId,
	MoonEntityId,
	MoonGpuField,
	MoonGpuLayout,
	MoonGpuResizeEvent,
	MoonRegisteredComponent,
} from "@moon/rhodonite_core/ecs/js_bridge";
import {
	component_type_id_index,
	component_type_id_new,
	entity_id_generation,
	entity_id_gpu_index,
	entity_id_index,
	entity_id_new,
	gpu_field_align,
	gpu_field_kind_name,
	gpu_field_name,
	gpu_field_offset,
	gpu_field_size,
	gpu_layout_align,
	gpu_layout_child_of,
	gpu_layout_empty,
	gpu_layout_fields,
	gpu_layout_global_transform,
	gpu_layout_global_transform_f16,
	gpu_layout_is_valid,
	gpu_layout_stride,
	gpu_layout_transform3d,
	gpu_resize_event_component,
	gpu_resize_event_needs_full_upload,
	gpu_resize_event_required_capacity,
	world_component_info_cpu_stride,
	world_component_info_kind,
	world_component_info_name,
} from "@moon/rhodonite_core/ecs/js_bridge";
import { moonBool } from "./views.ts";

export type ComponentKind = "CpuOnly" | "GpuVisible";
export type GpuFieldKind =
	| "F32"
	| "U32"
	| "Vec2F32"
	| "Vec3F32Packed"
	| "Vec3F32"
	| "Vec4F32"
	| "Vec4F16"
	| "Mat4x4F32";

export class EntityId {
	readonly inner: MoonEntityId;

	constructor(inner: MoonEntityId) {
		this.inner = inner;
	}

	static new(index: number, generation: number): EntityId {
		return new EntityId(entity_id_new(index, generation));
	}

	index(): number {
		return entity_id_index(this.inner);
	}

	generation(): number {
		return entity_id_generation(this.inner);
	}

	gpuIndex(): number {
		return entity_id_gpu_index(this.inner);
	}
}

export class ComponentTypeId {
	readonly inner: MoonComponentTypeId;

	constructor(inner: MoonComponentTypeId) {
		this.inner = inner;
	}

	static new(index: number): ComponentTypeId {
		return new ComponentTypeId(component_type_id_new(index));
	}

	index(): number {
		return component_type_id_index(this.inner);
	}
}

export type EntityLocation = {
	archetypeIndex: number;
	row: number;
};

export class GpuField {
	readonly inner: MoonGpuField;

	constructor(inner: MoonGpuField) {
		this.inner = inner;
	}

	name(): string {
		return gpu_field_name(this.inner);
	}

	kind(): GpuFieldKind {
		return gpu_field_kind_name(this.inner) as GpuFieldKind;
	}

	offset(): number {
		return gpu_field_offset(this.inner);
	}

	size(): number {
		return gpu_field_size(this.inner);
	}

	align(): number {
		return gpu_field_align(this.inner);
	}
}

export class GpuLayout {
	readonly inner: MoonGpuLayout;

	constructor(inner: MoonGpuLayout) {
		this.inner = inner;
	}

	static empty(stride: number): GpuLayout {
		return new GpuLayout(gpu_layout_empty(stride));
	}

	static transform3D(): GpuLayout {
		return new GpuLayout(gpu_layout_transform3d());
	}

	static globalTransform(): GpuLayout {
		return new GpuLayout(gpu_layout_global_transform());
	}

	static globalTransformF16(): GpuLayout {
		return new GpuLayout(gpu_layout_global_transform_f16());
	}

	static childOf(): GpuLayout {
		return new GpuLayout(gpu_layout_child_of());
	}

	stride(): number {
		return gpu_layout_stride(this.inner);
	}

	align(): number {
		return gpu_layout_align(this.inner);
	}

	isValid(): boolean {
		return moonBool(gpu_layout_is_valid(this.inner));
	}

	fields(): GpuField[] {
		return gpu_layout_fields(this.inner).map((field) => new GpuField(field));
	}
}

export class RegisteredComponent {
	readonly inner: MoonRegisteredComponent;

	constructor(inner: MoonRegisteredComponent) {
		this.inner = inner;
	}

	name(): string {
		return world_component_info_name(this.inner);
	}

	kind(): ComponentKind {
		return world_component_info_kind(this.inner) as ComponentKind;
	}

	cpuStride(): number {
		return world_component_info_cpu_stride(this.inner);
	}
}

export class GpuResizeEvent {
	readonly inner: MoonGpuResizeEvent;

	constructor(inner: MoonGpuResizeEvent) {
		this.inner = inner;
	}

	component(): ComponentTypeId {
		return new ComponentTypeId(gpu_resize_event_component(this.inner));
	}

	requiredCapacity(): number {
		return gpu_resize_event_required_capacity(this.inner);
	}

	needsFullUpload(): boolean {
		return moonBool(gpu_resize_event_needs_full_upload(this.inner));
	}
}
