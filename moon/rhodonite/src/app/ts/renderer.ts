// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	cameraHelpersDefault,
	cameraWordsBindGroup,
	cameraWordsBindingDefault,
	createCameraWordsBuffer,
	createGlobalTransformWordsBuffer,
	drainAndUploadCameraWrites,
	drainAndUploadGlobalTransformWrites,
	globalTransformHelpersDefault,
	globalTransformRefInstanceVertexBufferLayout,
	globalTransformWordsBindGroup,
	globalTransformWordsBindingDefault,
	Query,
	type ComponentTypeId,
	type EntityId,
	type World,
	type WorldHistory,
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import type { Scene } from "./app-runtime.ts";

const RENDERABLE_COMPONENT_STRIDE = 16;
const RENDERER_INSTANCE_STRIDE = 24;
const RENDERABLE_COMPONENT_NAME = "RhodoniteRenderable";
const RENDERABLE_VISIBLE_BIT = 1;
const PRIMITIVE_POSITION3_VERTEX_STRIDE = 12;
const CUBE_VERTEX_COUNT = 8;
const CUBE_INDEX_COUNT = 36;

type RendererMesh = {
	readonly vertexBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly vertexByteLength: number;
	readonly indexByteLength: number;
	readonly indexCount: number;
};

type RendererMaterial = {
	readonly desc: UnlitMaterialDesc;
};

type RendererInstanceBuffer = {
	readonly buffer: GPUBuffer;
	readonly byteCapacity: number;
};

type RendererDrawItem = {
	readonly entity: EntityId;
	readonly meshIndex: number;
	readonly materialIndex: number;
};

type RendererPipelineEntry = {
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

function sceneRenderableComponent(scene: Scene<World, EntityId>): ComponentTypeId {
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

export class Renderer {
	private readonly device: GPUDevice;
	private readonly queue: GPUQueue;
	private readonly transformLayout: GPUBindGroupLayout;
	private readonly cameraLayout: GPUBindGroupLayout;
	private readonly pipelineLayout: GPUPipelineLayout;
	private readonly vertexLayout: GPUVertexBufferLayout;
	private readonly pipelineEntries: RendererPipelineEntry[] = [];
	private readonly meshes: RendererMesh[] = [];
	private readonly materials: RendererMaterial[] = [];
	private readonly instanceBuffers: RendererInstanceBuffer[] = [];
	private transformStorage: GPUBuffer | null = null;
	private cameraStorage: GPUBuffer | null = null;
	private bindTransforms: GPUBindGroup | null = null;
	private bindCamera: GPUBindGroup | null = null;
	private renderableInstanceBuffer: GPUBuffer | null = null;
	private renderableInstanceByteCapacity = 0;
	private transformWordCapacity = 0;
	private cameraWordCapacity = 0;

	constructor(
		device: GPUDevice,
		queue: GPUQueue,
		vertexLayout: GPUVertexBufferLayout,
	) {
		this.device = device;
		this.queue = queue;
		this.vertexLayout = vertexLayout;
		this.transformLayout = createRendererStorageBindGroupLayout(device);
		this.cameraLayout = createRendererStorageBindGroupLayout(device);
		this.pipelineLayout = device.createPipelineLayout({
			bindGroupLayouts: [this.transformLayout, this.cameraLayout],
		});
	}

	static new(
		device: GPUDevice,
		queue: GPUQueue,
		vertexLayout: GPUVertexBufferLayout,
	): Renderer {
		return new Renderer(device, queue, vertexLayout);
	}

	registerStaticIndexedMesh(
		vertices: Uint8Array,
		indicesU16: Uint8Array,
		indexCount: number,
	): MeshHandle {
		const vertexBuffer = this.device.createBuffer({
			size: Math.max(vertices.byteLength, 4),
			usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
		});
		this.queue.writeBuffer(vertexBuffer, 0, vertices);
		const indexBuffer = this.device.createBuffer({
			size: Math.max(indicesU16.byteLength, 4),
			usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
		});
		this.queue.writeBuffer(indexBuffer, 0, indicesU16);
		const index = this.meshes.length;
		this.meshes.push({
			vertexBuffer,
			indexBuffer,
			vertexByteLength: vertices.byteLength,
			indexByteLength: indicesU16.byteLength,
			indexCount,
		});
		return new MeshHandle(index);
	}

	registerStaticIndexedMeshDesc(desc: StaticIndexedMeshDesc): MeshHandle {
		return this.registerStaticIndexedMesh(
			desc.vertices(),
			desc.indicesU16(),
			desc.indexCount(),
		);
	}

	registerCubeMesh(desc: CubeMeshDesc = CubeMeshDesc.new()): MeshHandle {
		return this.registerStaticIndexedMeshDesc(cubeMeshDesc(desc));
	}

	registerUnlitMaterial(desc: UnlitMaterialDesc): MaterialHandle {
		const index = this.materials.length;
		this.materials.push({ desc });
		return new MaterialHandle(index);
	}

	registerStaticInstanceBuffer(instanceBytes: Uint8Array): InstanceBufferHandle {
		const buffer = this.device.createBuffer({
			size: Math.max(instanceBytes.byteLength, 4),
			usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
		});
		this.queue.writeBuffer(buffer, 0, instanceBytes);
		const index = this.instanceBuffers.length;
		this.instanceBuffers.push({
			buffer,
			byteCapacity: instanceBytes.byteLength,
		});
		return new InstanceBufferHandle(index);
	}

	updateStaticInstanceBuffer(
		handle: InstanceBufferHandle,
		instanceBytes: Uint8Array,
	): boolean {
		const entry = this.instanceBuffers[handle.index()];
		if (entry === undefined || instanceBytes.byteLength > entry.byteCapacity) {
			return false;
		}
		this.queue.writeBuffer(entry.buffer, 0, instanceBytes);
		return true;
	}

	uploadGlobalTransformWrites(
		world: World,
		writes: ReturnType<World["drainGlobalTransformBlobWriteViews"]>,
	): void {
		this.ensureSceneBuffers(world);
		if (this.transformStorage !== null) {
			for (const write of writes) {
				const bytes = write.bytes();
				const view = bytes.asUint8Array();
				this.queue.writeBuffer(
					this.transformStorage,
					write.byteOffset(),
					view ?? bytes.toUint8ArrayCopy(),
				);
			}
		}
	}

	ensureStorageBuffers(options: {
		readonly transformWords: number;
		readonly cameraWords: number;
	}): void {
		this.ensureStorageBufferCapacities(
			options.transformWords,
			options.cameraWords,
		);
	}

	uploadGlobalTransformBytes(bytes: Uint8Array, byteOffset = 0): void {
		if (this.transformStorage !== null) {
			this.queue.writeBuffer(this.transformStorage, byteOffset, bytes);
		}
	}

	uploadCameraBytes(bytes: Uint8Array, byteOffset = 0): void {
		if (this.cameraStorage !== null) {
			this.queue.writeBuffer(this.cameraStorage, byteOffset, bytes);
		}
	}

	renderSceneRenderables(
		scene: Scene<World, EntityId>,
		target: RenderTargetResources,
		colorView: GPUTextureView,
	): void {
		const depthView = target.depthView();
		if (depthView === null) {
			return;
		}
		const pipeline = this.pipelineForFormat(target.format());
		const world = scene.world();
		this.ensureSceneBuffers(world);
		const items = this.extractDrawItems(world, sceneRenderableComponent(scene));
		const instanceBuffer =
			items.length > 0 ? this.writeRenderableInstances(world, items) : null;
		if (this.transformStorage !== null) {
			drainAndUploadGlobalTransformWrites(
				this.queue,
				this.transformStorage,
				world,
			);
		}
		if (this.cameraStorage !== null) {
			drainAndUploadCameraWrites(this.queue, this.cameraStorage, world);
		}
		const encoder = this.device.createCommandEncoder();
		const pass = encoder.beginRenderPass({
			colorAttachments: [
				{
					view: colorView,
					clearValue: { r: 0.03, g: 0.04, b: 0.09, a: 1 },
					loadOp: "clear",
					storeOp: "store",
				},
			],
			depthStencilAttachment: {
				view: depthView,
				depthClearValue: 1,
				depthLoadOp: "clear",
				depthStoreOp: "store",
			},
		});
		pass.setPipeline(pipeline);
		if (this.bindTransforms !== null) {
			pass.setBindGroup(0, this.bindTransforms);
		}
		if (this.bindCamera !== null) {
			pass.setBindGroup(1, this.bindCamera);
		}
		if (instanceBuffer !== null) {
			pass.setVertexBuffer(1, instanceBuffer, 0, items.length * RENDERER_INSTANCE_STRIDE);
			for (let i = 0; i < items.length; i += 1) {
				const mesh = this.meshes[items[i]!.meshIndex]!;
				pass.setIndexBuffer(mesh.indexBuffer, "uint16", 0, mesh.indexByteLength);
				pass.setVertexBuffer(0, mesh.vertexBuffer, 0, mesh.vertexByteLength);
				pass.drawIndexed(mesh.indexCount, 1, 0, 0, i);
			}
		}
		pass.end();
		this.queue.submit([encoder.finish()]);
	}

	renderInstancedMesh(
		scene: Scene<World, EntityId>,
		mesh: MeshHandle,
		instances: InstanceBufferHandle,
		instanceCount: number,
		target: RenderTargetResources,
		colorView: GPUTextureView,
	): void {
		const meshEntry = this.meshes[mesh.index()];
		const instanceEntry = this.instanceBuffers[instances.index()];
		const instanceByteLength = instanceCount * RENDERER_INSTANCE_STRIDE;
		const depthView = target.depthView();
		if (
			depthView === null ||
			instanceCount <= 0 ||
			meshEntry === undefined ||
			instanceEntry === undefined ||
			instanceByteLength > instanceEntry.byteCapacity
		) {
			return;
		}
		const world = scene.world();
		this.ensureSceneBuffers(world);
		if (this.transformStorage !== null) {
			drainAndUploadGlobalTransformWrites(
				this.queue,
				this.transformStorage,
				world,
			);
		}
		if (this.cameraStorage !== null) {
			drainAndUploadCameraWrites(this.queue, this.cameraStorage, world);
		}
		this.drawInstancedMesh(
			meshEntry,
			instanceEntry,
			instanceCount,
			target,
			colorView,
		);
	}

	renderPreparedInstancedMesh(
		mesh: MeshHandle,
		instances: InstanceBufferHandle,
		instanceCount: number,
		target: RenderTargetResources,
		colorView: GPUTextureView,
	): void {
		const meshEntry = this.meshes[mesh.index()];
		const instanceEntry = this.instanceBuffers[instances.index()];
		const instanceByteLength = instanceCount * RENDERER_INSTANCE_STRIDE;
		const depthView = target.depthView();
		if (
			depthView === null ||
			instanceCount <= 0 ||
			meshEntry === undefined ||
			instanceEntry === undefined ||
			instanceByteLength > instanceEntry.byteCapacity
		) {
			return;
		}
		this.drawInstancedMesh(
			meshEntry,
			instanceEntry,
			instanceCount,
			target,
			colorView,
		);
	}

	release(): void {
		for (const mesh of this.meshes) {
			mesh.vertexBuffer.destroy();
			mesh.indexBuffer.destroy();
		}
		for (const entry of this.instanceBuffers) {
			entry.buffer.destroy();
		}
		this.transformStorage?.destroy();
		this.cameraStorage?.destroy();
		this.renderableInstanceBuffer?.destroy();
		this.transformStorage = null;
		this.cameraStorage = null;
		this.renderableInstanceBuffer = null;
	}

	private ensureSceneBuffers(world: World): void {
		this.ensureStorageBufferCapacities(
			world.globalTransformBlobWordCapacity(),
			world.cameraBlobWordCapacity(),
		);
	}

	private ensureStorageBufferCapacities(
		transformCapacity: number,
		cameraCapacity: number,
	): void {
		if (
			this.transformStorage === null ||
			transformCapacity > this.transformWordCapacity
		) {
			this.transformStorage?.destroy();
			this.transformStorage = createGlobalTransformWordsBuffer(
				this.device,
				transformCapacity,
			);
			this.transformWordCapacity = transformCapacity;
			this.bindTransforms = globalTransformWordsBindGroup(
				this.device,
				this.transformLayout,
				this.transformStorage,
			);
		}
		if (this.cameraStorage === null || cameraCapacity > this.cameraWordCapacity) {
			this.cameraStorage?.destroy();
			this.cameraStorage = createCameraWordsBuffer(this.device, cameraCapacity);
			this.cameraWordCapacity = cameraCapacity;
			this.bindCamera = cameraWordsBindGroup(
				this.device,
				this.cameraLayout,
				this.cameraStorage,
			);
		}
	}

	private drawInstancedMesh(
		meshEntry: RendererMesh,
		instanceEntry: RendererInstanceBuffer,
		instanceCount: number,
		target: RenderTargetResources,
		colorView: GPUTextureView,
	): void {
		const depthView = target.depthView();
		if (depthView === null) {
			return;
		}
		const pipeline = this.pipelineForFormat(target.format());
		const instanceByteLength = instanceCount * RENDERER_INSTANCE_STRIDE;
		const encoder = this.device.createCommandEncoder();
		const pass = encoder.beginRenderPass({
			colorAttachments: [
				{
					view: colorView,
					clearValue: { r: 0.03, g: 0.04, b: 0.09, a: 1 },
					loadOp: "clear",
					storeOp: "store",
				},
			],
			depthStencilAttachment: {
				view: depthView,
				depthClearValue: 1,
				depthLoadOp: "clear",
				depthStoreOp: "store",
			},
		});
		pass.setPipeline(pipeline);
		if (this.bindTransforms !== null) {
			pass.setBindGroup(0, this.bindTransforms);
		}
		if (this.bindCamera !== null) {
			pass.setBindGroup(1, this.bindCamera);
		}
		pass.setIndexBuffer(meshEntry.indexBuffer, "uint16", 0, meshEntry.indexByteLength);
		pass.setVertexBuffer(0, meshEntry.vertexBuffer, 0, meshEntry.vertexByteLength);
		pass.setVertexBuffer(1, instanceEntry.buffer, 0, instanceByteLength);
		pass.drawIndexed(meshEntry.indexCount, instanceCount);
		pass.end();
		this.queue.submit([encoder.finish()]);
	}

	private extractDrawItems(
		world: World,
		renderable: ComponentTypeId,
	): RendererDrawItem[] {
		const items: RendererDrawItem[] = [];
		Query.new([renderable, world.globalTransformComponent()]).forEach(
			world,
			(row) => {
				row.read(renderable, (bytes) => {
					if (bytes.length < RENDERABLE_COMPONENT_STRIDE) {
						return;
					}
					const payload = bytes.asUint8Array() ?? bytes.toUint8ArrayCopy();
					const view = new DataView(
						payload.buffer,
						payload.byteOffset,
						payload.byteLength,
					);
					const flags = new RenderableFlags(view.getUint32(8, true));
					if (!flags.contains(renderableFlagsVisible())) {
						return;
					}
					const meshIndex = view.getUint32(0, true);
					const materialIndex = view.getUint32(4, true);
					if (
						this.meshes[meshIndex] !== undefined &&
						this.materials[materialIndex] !== undefined
					) {
						items.push({
							entity: row.entity(),
							meshIndex,
							materialIndex,
						});
					}
				});
			},
		);
		return items;
	}

	private writeRenderableInstances(
		world: World,
		items: RendererDrawItem[],
	): GPUBuffer | null {
		const instanceBytes = buildRendererInstanceBytes(world, items, this.materials);
		const buffer = this.ensureInstanceBuffer(instanceBytes.byteLength);
		if (buffer === null) {
			return null;
		}
		this.queue.writeBuffer(buffer, 0, instanceBytes);
		return buffer;
	}

	private ensureInstanceBuffer(byteLength: number): GPUBuffer | null {
		if (byteLength <= 0) {
			return null;
		}
		if (
			this.renderableInstanceBuffer === null ||
			byteLength > this.renderableInstanceByteCapacity
		) {
			this.renderableInstanceBuffer?.destroy();
			this.renderableInstanceBuffer = this.device.createBuffer({
				size: Math.max(byteLength, 4),
				usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
			});
			this.renderableInstanceByteCapacity = byteLength;
		}
		return this.renderableInstanceBuffer;
	}

	private pipelineForFormat(format: GPUTextureFormat): GPURenderPipeline {
		const existing = this.pipelineEntries.find((entry) => entry.format === format);
		if (existing !== undefined) {
			return existing.pipeline;
		}
		const pipeline = createRenderableUnlitPipeline(
			this.device,
			this.pipelineLayout,
			format,
			this.vertexLayout,
		);
		this.pipelineEntries.push({ format, pipeline });
		return pipeline;
	}
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

function createRenderableUnlitPipeline(
	device: GPUDevice,
	pipelineLayout: GPUPipelineLayout,
	format: GPUTextureFormat,
	vertexLayout: GPUVertexBufferLayout,
): GPURenderPipeline {
	const shader = device.createShaderModule({ code: renderableUnlitWgsl() });
	return device.createRenderPipeline({
		layout: pipelineLayout,
		vertex: {
			module: shader,
			entryPoint: "vertexMain",
			buffers: [vertexLayout, renderableInstanceVertexBufferLayout()],
		},
		fragment: {
			module: shader,
			entryPoint: "fragmentMain",
			targets: [{ format }],
		},
		primitive: { topology: "triangle-list" },
		depthStencil: {
			format: "depth24plus",
			depthWriteEnabled: true,
			depthCompare: "less",
		},
	});
}

function createRendererStorageBindGroupLayout(
	device: GPUDevice,
): GPUBindGroupLayout {
	return device.createBindGroupLayout({
		entries: [
			{
				binding: 0,
				visibility: globalThis.GPUShaderStage?.VERTEX ?? 1,
				buffer: { type: "read-only-storage" },
			},
		],
	});
}

function renderableInstanceVertexBufferLayout(): GPUVertexBufferLayout {
	return globalTransformRefInstanceVertexBufferLayout(RENDERER_INSTANCE_STRIDE, {
		shaderLocation: 1,
		offset: 0,
		extraAttributes: [{ shaderLocation: 2, offset: 8, format: "float32x3" }],
	});
}

function renderableUnlitWgsl(): string {
	return (
		globalTransformWordsBindingDefault() +
		cameraWordsBindingDefault() +
		globalTransformHelpersDefault() +
		cameraHelpersDefault() +
		`
struct VertexOut {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec3<f32>,
};

@vertex
fn vertexMain(
  @location(0) local_pos: vec3<f32>,
  @location(1) transform_ref: vec2<u32>,
  @location(2) color: vec3<f32>,
) -> VertexOut {
  let world_pos = rn_transform_point(
    rn_load_global_transform(transform_ref),
    local_pos,
  );
  let camera = rn_load_camera(0u);
  var o: VertexOut;
  o.position = camera.view_proj * world_pos;
  o.color = color;
  return o;
}

@fragment
fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  return vec4<f32>(color, 1.0);
}
`
	);
}

function buildRendererInstanceBytes(
	world: World,
	items: readonly RendererDrawItem[],
	materials: readonly RendererMaterial[],
): Uint8Array {
	const bytes = new Uint8Array(items.length * RENDERER_INSTANCE_STRIDE);
	const refs = world.extractGlobalTransformRefs(items.map((item) => item.entity));
	const view = new DataView(bytes.buffer);
	for (let i = 0; i < items.length; i += 1) {
		const base = i * RENDERER_INSTANCE_STRIDE;
		bytes.set(refs.subarray(i * 8, i * 8 + 8), base);
		const material = materials[items[i]!.materialIndex]!.desc;
		view.setFloat32(base + 8, material.baseColorR(), true);
		view.setFloat32(base + 12, material.baseColorG(), true);
		view.setFloat32(base + 16, material.baseColorB(), true);
	}
	return bytes;
}
