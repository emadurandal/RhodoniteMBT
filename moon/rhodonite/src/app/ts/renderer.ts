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
	type ComponentTypeId,
	type EntityId,
	type World,
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import type { Scene } from "./app-runtime.ts";

const RENDERABLE_COMPONENT_STRIDE = 16;
const RENDERER_INSTANCE_STRIDE = 24;
const RENDERABLE_COMPONENT_NAME = "RhodoniteRenderable";
const RENDERABLE_VISIBLE_BIT = 1;

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

export class RenderableComponent {
	private readonly idValue: ComponentTypeId;
	private readonly entitiesValue = new Map<string, EntityId>();

	constructor(id: ComponentTypeId) {
		this.idValue = id;
	}

	id(): ComponentTypeId {
		return this.idValue;
	}

	track(entity: EntityId): void {
		this.entitiesValue.set(entityKey(entity), entity);
	}

	entities(): EntityId[] {
		return Array.from(this.entitiesValue.values());
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

export function registerRenderableComponent(world: World): RenderableComponent {
	return new RenderableComponent(
		world.registerCpuComponent(
			RENDERABLE_COMPONENT_NAME,
			RENDERABLE_COMPONENT_STRIDE,
		),
	);
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
	world: World,
	entity: EntityId,
	component: RenderableComponent,
	desc: RenderableDesc,
): boolean {
	const added = world.addComponentBytes(
		entity,
		component.id(),
		renderableComponentBytes(desc),
	);
	if (added) {
		component.track(entity);
	}
	return added;
}

export function setRenderable(
	world: World,
	entity: EntityId,
	component: RenderableComponent,
	desc: RenderableDesc,
): boolean {
	const bytes = renderableComponentBytes(desc);
	const changed = world.hasComponent(entity, component.id())
		? world.setComponentBytes(entity, component.id(), bytes)
		: world.addComponentBytes(entity, component.id(), bytes);
	if (changed) {
		component.track(entity);
	}
	return changed;
}

export class Renderer {
	private readonly device: GPUDevice;
	private readonly queue: GPUQueue;
	private readonly pipeline: GPURenderPipeline;
	private depthTexture: GPUTexture | null = null;
	private depthView: GPUTextureView | null = null;
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
		format: GPUTextureFormat,
		width: number,
		height: number,
		vertexLayout: GPUVertexBufferLayout,
	) {
		this.device = device;
		this.queue = queue;
		this.pipeline = createRenderableUnlitPipeline(
			device,
			format,
			vertexLayout,
		);
		this.resizeSurfaceResources(width, height);
	}

	static new(
		device: GPUDevice,
		queue: GPUQueue,
		format: GPUTextureFormat,
		width: number,
		height: number,
		vertexLayout: GPUVertexBufferLayout,
	): Renderer {
		return new Renderer(device, queue, format, width, height, vertexLayout);
	}

	resizeSurfaceResources(width: number, height: number): void {
		this.depthTexture?.destroy();
		this.depthTexture = null;
		this.depthView = null;
		if (width <= 0 || height <= 0) {
			return;
		}
		this.depthTexture = this.device.createTexture({
			size: [Math.max(width, 1), Math.max(height, 1)],
			format: "depth24plus",
			usage: GPUTextureUsage.RENDER_ATTACHMENT,
		});
		this.depthView = this.depthTexture.createView();
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

	renderSceneRenderables(
		scene: Scene<World, EntityId>,
		renderable: RenderableComponent,
		colorView: GPUTextureView,
	): void {
		if (this.depthView === null) {
			return;
		}
		const world = scene.world();
		this.ensureSceneBuffers(world);
		const items = this.extractDrawItems(world, renderable);
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
				view: this.depthView,
				depthClearValue: 1,
				depthLoadOp: "clear",
				depthStoreOp: "store",
			},
		});
		pass.setPipeline(this.pipeline);
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
		colorView: GPUTextureView,
	): void {
		const meshEntry = this.meshes[mesh.index()];
		const instanceEntry = this.instanceBuffers[instances.index()];
		const instanceByteLength = instanceCount * RENDERER_INSTANCE_STRIDE;
		if (
			this.depthView === null ||
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
				view: this.depthView,
				depthClearValue: 1,
				depthLoadOp: "clear",
				depthStoreOp: "store",
			},
		});
		pass.setPipeline(this.pipeline);
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
		this.depthTexture?.destroy();
		this.transformStorage = null;
		this.cameraStorage = null;
		this.renderableInstanceBuffer = null;
		this.depthTexture = null;
		this.depthView = null;
	}

	private ensureSceneBuffers(world: World): void {
		const transformCapacity = world.globalTransformBlobWordCapacity();
		if (
			this.transformStorage === null ||
			transformCapacity > this.transformWordCapacity
		) {
			this.transformStorage?.destroy();
			this.transformStorage = createGlobalTransformWordsBuffer(
				this.device,
				world,
			);
			this.transformWordCapacity = transformCapacity;
			this.bindTransforms = globalTransformWordsBindGroup(
				this.device,
				this.pipeline,
				this.transformStorage,
			);
		}
		const cameraCapacity = world.cameraBlobWordCapacity();
		if (this.cameraStorage === null || cameraCapacity > this.cameraWordCapacity) {
			this.cameraStorage?.destroy();
			this.cameraStorage = createCameraWordsBuffer(this.device, world);
			this.cameraWordCapacity = cameraCapacity;
			this.bindCamera = cameraWordsBindGroup(
				this.device,
				this.pipeline,
				this.cameraStorage,
			);
		}
	}

	private extractDrawItems(
		world: World,
		renderable: RenderableComponent,
	): RendererDrawItem[] {
		const items: RendererDrawItem[] = [];
		for (const entity of renderable.entities()) {
			if (!world.isAlive(entity) || !world.hasComponent(entity, renderable.id())) {
				continue;
			}
			const bytes = world.componentBytesCopy(entity, renderable.id());
			if (bytes === null || bytes.byteLength < RENDERABLE_COMPONENT_STRIDE) {
				continue;
			}
			const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
			const meshIndex = view.getUint32(0, true);
			const materialIndex = view.getUint32(4, true);
			const flags = view.getUint32(8, true);
			if (
				(flags & RENDERABLE_VISIBLE_BIT) !== 0 &&
				this.meshes[meshIndex] !== undefined &&
				this.materials[materialIndex] !== undefined
			) {
				items.push({ entity, meshIndex, materialIndex });
			}
		}
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
}

function entityKey(entity: EntityId): string {
	return `${entity.index()}:${entity.generation()}`;
}

function createRenderableUnlitPipeline(
	device: GPUDevice,
	format: GPUTextureFormat,
	vertexLayout: GPUVertexBufferLayout,
): GPURenderPipeline {
	const shader = device.createShaderModule({ code: renderableUnlitWgsl() });
	return device.createRenderPipeline({
		layout: "auto",
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
