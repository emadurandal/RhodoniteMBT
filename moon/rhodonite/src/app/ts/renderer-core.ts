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
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import type { Scene } from "./app-runtime.ts";
import {
	CubeMeshDesc,
	InstanceBufferHandle,
	MaterialHandle,
	MeshHandle,
	RENDERER_INSTANCE_STRIDE,
	RENDERABLE_COMPONENT_STRIDE,
	RenderableFlags,
	RenderTargetResources,
	StaticIndexedMeshDesc,
	UnlitMaterialDesc,
	cubeMeshDesc,
	renderableFlagsVisible,
	sceneRenderableComponent,
	type RendererDrawItem,
	type RendererInstanceBuffer,
	type RendererMaterial,
	type RendererMesh,
	type RendererPipelineEntry,
} from "./renderer-primitives.ts";

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
