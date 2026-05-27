// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { ComponentTypeId, EntityId, World, WorldHistory } from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import type { Scene } from "./app-runtime.ts";

export const RENDERABLE_COMPONENT_STRIDE = 16;
export const RENDERER_INSTANCE_STRIDE = 24;
const RENDERABLE_COMPONENT_NAME = "RhodoniteRenderable";
const RENDERABLE_VISIBLE_BIT = 1;
const PRIMITIVE_POSITION3_VERTEX_STRIDE = 12;
const CUBE_VERTEX_COUNT = 8;
const CUBE_INDEX_COUNT = 36;

export type RendererMesh = {
	readonly vertexBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly vertexByteLength: number;
	readonly indexByteLength: number;
	readonly indexCount: number;
};

export type RendererMaterial = {
	readonly desc: UnlitMaterialDesc;
};

export type RendererInstanceBuffer = {
	readonly buffer: GPUBuffer;
	readonly byteCapacity: number;
};

export type RendererDrawItem = {
	readonly entity: EntityId;
	readonly meshIndex: number;
	readonly materialIndex: number;
};

export type RendererPipelineEntry = {
	readonly format: GPUTextureFormat;
	readonly pipeline: GPURenderPipeline;
};

export class RenderTargetResources {
	private readonly device: GPUDevice;
	private formatValue: GPUTextureFormat;
	private width = 0;
	private height = 0;
	private depthTexture: GPUTexture | null = null;
	private depthViewValue: GPUTextureView | null = null;

	constructor(
		device: GPUDevice,
		width: number,
		height: number,
		format: GPUTextureFormat,
	) {
		this.device = device;
		this.formatValue = format;
		this.resize(width, height, format);
	}

	static new(
		device: GPUDevice,
		width: number,
		height: number,
		format: GPUTextureFormat,
	): RenderTargetResources {
		return new RenderTargetResources(device, width, height, format);
	}

	active(): boolean {
		return this.width > 0 && this.height > 0 && this.depthViewValue !== null;
	}

	format(): GPUTextureFormat {
		return this.formatValue;
	}

	depthView(): GPUTextureView | null {
		return this.depthViewValue;
	}

	resize(width: number, height: number, format: GPUTextureFormat): void {
		this.releaseDepthResources();
		this.formatValue = format;
		this.width = width;
		this.height = height;
		if (width <= 0 || height <= 0) {
			this.width = 0;
			this.height = 0;
			return;
		}
		this.depthTexture = this.device.createTexture({
			size: [Math.max(width, 1), Math.max(height, 1)],
			format: "depth24plus",
			usage: globalThis.GPUTextureUsage?.RENDER_ATTACHMENT ?? 1,
		});
		this.depthViewValue = this.depthTexture.createView();
	}

	release(): void {
		this.releaseDepthResources();
	}

	private releaseDepthResources(): void {
		this.depthTexture?.destroy();
		this.depthTexture = null;
		this.depthViewValue = null;
	}
}

export class MeshHandle {
	private readonly indexValue: number;

	constructor(index: number) {
		this.indexValue = index;
	}

	index(): number {
		return this.indexValue;
	}
}

export class MaterialHandle {
	private readonly indexValue: number;

	constructor(index: number) {
		this.indexValue = index;
	}

	index(): number {
		return this.indexValue;
	}
}

export class InstanceBufferHandle {
	private readonly indexValue: number;

	constructor(index: number) {
		this.indexValue = index;
	}

	index(): number {
		return this.indexValue;
	}
}

export class StaticIndexedMeshDesc {
	private readonly verticesValue: Uint8Array;
	private readonly indicesU16Value: Uint8Array;
	private readonly indexCountValue: number;
	private readonly vertexLayoutValue: GPUVertexBufferLayout;

	constructor(
		vertices: Uint8Array,
		indicesU16: Uint8Array,
		indexCount: number,
		vertexLayout: GPUVertexBufferLayout,
	) {
		this.verticesValue = vertices;
		this.indicesU16Value = indicesU16;
		this.indexCountValue = indexCount;
		this.vertexLayoutValue = vertexLayout;
	}

	static new(
		vertices: Uint8Array,
		indicesU16: Uint8Array,
		indexCount: number,
		vertexLayout: GPUVertexBufferLayout,
	): StaticIndexedMeshDesc {
		return new StaticIndexedMeshDesc(
			vertices,
			indicesU16,
			indexCount,
			vertexLayout,
		);
	}

	vertices(): Uint8Array {
		return this.verticesValue;
	}

	indicesU16(): Uint8Array {
		return this.indicesU16Value;
	}

	indexCount(): number {
		return this.indexCountValue;
	}

	vertexLayout(): GPUVertexBufferLayout {
		return this.vertexLayoutValue;
	}
}

export function primitivePosition3VertexStride(): number {
	return PRIMITIVE_POSITION3_VERTEX_STRIDE;
}

export function primitivePosition3VertexLayout(): GPUVertexBufferLayout {
	return {
		arrayStride: PRIMITIVE_POSITION3_VERTEX_STRIDE,
		stepMode: "vertex",
		attributes: [{ shaderLocation: 0, offset: 0, format: "float32x3" }],
	};
}

export class CubeMeshDesc {
	private readonly halfExtentValue: number;

	constructor(halfExtent = 1) {
		this.halfExtentValue = halfExtent;
	}

	static new(halfExtent = 1): CubeMeshDesc {
		return new CubeMeshDesc(halfExtent);
	}

	halfExtent(): number {
		return this.halfExtentValue;
	}
}

export function cubePosition3VertexLayout(): GPUVertexBufferLayout {
	return primitivePosition3VertexLayout();
}

export function cubeVertexCount(): number {
	return CUBE_VERTEX_COUNT;
}

export function cubeIndexCount(): number {
	return CUBE_INDEX_COUNT;
}

export function cubeVertexPositionBytes(
	desc: CubeMeshDesc = CubeMeshDesc.new(),
): Uint8Array {
	const bytes = new Uint8Array(
		CUBE_VERTEX_COUNT * PRIMITIVE_POSITION3_VERTEX_STRIDE,
	);
	const view = new DataView(bytes.buffer);
	const halfExtent = desc.halfExtent();
	cubeLocalCorners().forEach(([x, y, z], vertexIndex) => {
		const base = vertexIndex * PRIMITIVE_POSITION3_VERTEX_STRIDE;
		view.setFloat32(base, x * halfExtent, true);
		view.setFloat32(base + 4, y * halfExtent, true);
		view.setFloat32(base + 8, z * halfExtent, true);
	});
	return bytes;
}

export function cubeIndexU16Bytes(): Uint8Array {
	const indices = [
		0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 0, 4, 7, 7, 3, 0, 1, 5, 6, 6, 2,
		1, 0, 1, 5, 5, 4, 0, 3, 2, 6, 6, 7, 3,
	];
	const bytes = new Uint8Array(CUBE_INDEX_COUNT * 2);
	const view = new DataView(bytes.buffer);
	indices.forEach((index, i) => view.setUint16(i * 2, index, true));
	return bytes;
}

export function cubeMeshDesc(
	desc: CubeMeshDesc = CubeMeshDesc.new(),
): StaticIndexedMeshDesc {
	return StaticIndexedMeshDesc.new(
		cubeVertexPositionBytes(desc),
		cubeIndexU16Bytes(),
		CUBE_INDEX_COUNT,
		cubePosition3VertexLayout(),
	);
}

export class RenderableFlags {
	private readonly bitsValue: number;

	constructor(bits: number) {
		this.bitsValue = bits >>> 0;
	}

	bits(): number {
		return this.bitsValue;
	}

	contains(flag: RenderableFlags): boolean {
		return (this.bitsValue & flag.bitsValue) === flag.bitsValue;
	}
}

export function renderableFlagsNone(): RenderableFlags {
	return new RenderableFlags(0);
}

export function renderableFlagsVisible(): RenderableFlags {
	return new RenderableFlags(RENDERABLE_VISIBLE_BIT);
}

export function renderableFlagsDefault(): RenderableFlags {
	return renderableFlagsVisible();
}

export class RenderableDesc {
	private readonly meshValue: MeshHandle;
	private readonly materialValue: MaterialHandle;
	private readonly flagsValue: RenderableFlags;

	constructor(
		mesh: MeshHandle,
		material: MaterialHandle,
		flags: RenderableFlags = renderableFlagsDefault(),
	) {
		this.meshValue = mesh;
		this.materialValue = material;
		this.flagsValue = flags;
	}

	static new(
		mesh: MeshHandle,
		material: MaterialHandle,
		flags: RenderableFlags = renderableFlagsDefault(),
	): RenderableDesc {
		return new RenderableDesc(mesh, material, flags);
	}

	mesh(): MeshHandle {
		return this.meshValue;
	}

	material(): MaterialHandle {
		return this.materialValue;
	}

	flags(): RenderableFlags {
		return this.flagsValue;
	}
}

export class UnlitMaterialDesc {
	private readonly baseColorRValue: number;
	private readonly baseColorGValue: number;
	private readonly baseColorBValue: number;
	private readonly alphaValue: number;
	private readonly flagsValue: number;

	constructor(
		baseColorR: number,
		baseColorG: number,
		baseColorB: number,
		alpha = 1,
		flags = 0,
	) {
		this.baseColorRValue = baseColorR;
		this.baseColorGValue = baseColorG;
		this.baseColorBValue = baseColorB;
		this.alphaValue = alpha;
		this.flagsValue = flags >>> 0;
	}

	static new(
		baseColorR: number,
		baseColorG: number,
		baseColorB: number,
		alpha = 1,
		flags = 0,
	): UnlitMaterialDesc {
		return new UnlitMaterialDesc(
			baseColorR,
			baseColorG,
			baseColorB,
			alpha,
			flags,
		);
	}

	baseColorR(): number {
		return this.baseColorRValue;
	}

	baseColorG(): number {
		return this.baseColorGValue;
	}

	baseColorB(): number {
		return this.baseColorBValue;
	}

	alpha(): number {
		return this.alphaValue;
	}

	flags(): number {
		return this.flagsValue;
	}
}

export function renderableComponentStride(): number {
	return RENDERABLE_COMPONENT_STRIDE;
}

type SceneRenderableRegistration = {
	readonly world: World;
	readonly id: ComponentTypeId;
};

const sceneRenderableComponents = new WeakMap<
	Scene<World, EntityId>,
	SceneRenderableRegistration
>();

export function sceneRenderableComponent(scene: Scene<World, EntityId>): ComponentTypeId {
	const world = scene.world();
	const existing = sceneRenderableComponents.get(scene);
	if (existing !== undefined && existing.world === world) {
		return existing.id;
	}
	const id = world.registerCpuComponent(
		RENDERABLE_COMPONENT_NAME,
		RENDERABLE_COMPONENT_STRIDE,
	);
	sceneRenderableComponents.set(scene, { world, id });
	return id;
}

export function renderableComponentBytes(desc: RenderableDesc): Uint8Array {
	const bytes = new Uint8Array(RENDERABLE_COMPONENT_STRIDE);
	const view = new DataView(bytes.buffer);
	view.setUint32(0, desc.mesh().index() >>> 0, true);
	view.setUint32(4, desc.material().index() >>> 0, true);
	view.setUint32(8, desc.flags().bits(), true);
	view.setUint32(12, 0, true);
	return bytes;
}

export function addRenderable(
	scene: Scene<World, EntityId>,
	entity: EntityId,
	desc: RenderableDesc,
): boolean {
	return scene.world().addComponentBytes(
		entity,
		sceneRenderableComponent(scene),
		renderableComponentBytes(desc),
	);
}

export function setRenderable(
	scene: Scene<World, EntityId>,
	entity: EntityId,
	desc: RenderableDesc,
): boolean {
	const world = scene.world();
	const component = sceneRenderableComponent(scene);
	const bytes = renderableComponentBytes(desc);
	return world.hasComponent(entity, component)
		? world.setComponentBytes(entity, component, bytes)
		: world.addComponentBytes(entity, component, bytes);
}

export function addRenderableTracked(
	history: WorldHistory,
	scene: Scene<World, EntityId>,
	entity: EntityId,
	desc: RenderableDesc,
): boolean {
	return history.addComponentBytes(
		scene.world(),
		entity,
		sceneRenderableComponent(scene),
		renderableComponentBytes(desc),
	);
}

export function setRenderableTracked(
	history: WorldHistory,
	scene: Scene<World, EntityId>,
	entity: EntityId,
	desc: RenderableDesc,
): boolean {
	const world = scene.world();
	const component = sceneRenderableComponent(scene);
	const bytes = renderableComponentBytes(desc);
	return world.hasComponent(entity, component)
		? history.setComponentBytes(world, entity, component, bytes)
		: history.addComponentBytes(world, entity, component, bytes);
}

export function removeRenderableTracked(
	history: WorldHistory,
	scene: Scene<World, EntityId>,
	entity: EntityId,
): boolean {
	return history.removeComponent(
		scene.world(),
		entity,
		sceneRenderableComponent(scene),
	);
}


function cubeLocalCorners(): [number, number, number][] {
	return [
		[-1, -1, -1],
		[1, -1, -1],
		[1, 1, -1],
		[-1, 1, -1],
		[-1, -1, 1],
		[1, -1, 1],
		[1, 1, 1],
		[-1, 1, 1],
	];
}
