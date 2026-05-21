// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
	type EntityId,
	World,
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import {
	MaterialHandle,
	MeshHandle,
	Renderer,
	RenderableDesc,
	RenderableFlags,
	Scene,
	UnlitMaterialDesc,
	addRenderable,
	registerRenderableComponent,
	renderableComponentBytes,
	renderableComponentStride,
	renderableFlagsDefault,
	renderableFlagsNone,
	renderableFlagsVisible,
	setRenderable,
} from "./index.ts";

type FakeBuffer = GPUBuffer & {
	readonly id: number;
	readonly descriptor: GPUBufferDescriptor;
	destroyed: boolean;
};

type FakeTexture = GPUTexture & {
	readonly descriptor: GPUTextureDescriptor;
	readonly view: GPUTextureView;
	destroyed: boolean;
};

type FakeWrite = {
	readonly buffer: FakeBuffer;
	readonly offset: number;
	readonly bytes: Uint8Array;
};

type FakeRenderPassCall = {
	readonly name: string;
	readonly args: readonly unknown[];
};

class FakeQueue {
	readonly writes: FakeWrite[] = [];
	readonly submissions: GPUCommandBuffer[][] = [];

	writeBuffer(
		buffer: GPUBuffer,
		bufferOffset: GPUSize64,
		data: AllowSharedBufferSource | ArrayBufferView,
		dataOffset = 0,
		size?: GPUSize64,
	): void {
		const bytes = data instanceof ArrayBuffer
			? new Uint8Array(data)
			: new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
		const copy = bytes.slice(
			dataOffset,
			size === undefined ? undefined : dataOffset + size,
		);
		this.writes.push({
			buffer: buffer as FakeBuffer,
			offset: Number(bufferOffset),
			bytes: copy,
		});
	}

	submit(commandBuffers: Iterable<GPUCommandBuffer>): void {
		this.submissions.push(Array.from(commandBuffers));
	}
}

class FakeRenderPass {
	readonly calls: FakeRenderPassCall[] = [];

	setPipeline(pipeline: GPURenderPipeline): void {
		this.record("setPipeline", pipeline);
	}

	setBindGroup(index: number, bindGroup: GPUBindGroup): void {
		this.record("setBindGroup", index, bindGroup);
	}

	setIndexBuffer(
		buffer: GPUBuffer,
		indexFormat: GPUIndexFormat,
		offset?: GPUSize64,
		size?: GPUSize64,
	): void {
		this.record("setIndexBuffer", buffer, indexFormat, offset, size);
	}

	setVertexBuffer(
		slot: GPUIndex32,
		buffer: GPUBuffer | null,
		offset?: GPUSize64,
		size?: GPUSize64,
	): void {
		this.record("setVertexBuffer", slot, buffer, offset, size);
	}

	drawIndexed(
		indexCount: GPUSize32,
		instanceCount?: GPUSize32,
		firstIndex?: GPUSize32,
		baseVertex?: GPUSignedOffset32,
		firstInstance?: GPUSize32,
	): void {
		this.record(
			"drawIndexed",
			indexCount,
			instanceCount,
			firstIndex,
			baseVertex,
			firstInstance,
		);
	}

	end(): void {
		this.record("end");
	}

	private record(name: string, ...args: unknown[]): void {
		this.calls.push({ name, args });
	}
}

class FakeCommandEncoder {
	readonly pass = new FakeRenderPass();
	renderPassDescriptor: GPURenderPassDescriptor | null = null;

	beginRenderPass(descriptor: GPURenderPassDescriptor): GPURenderPassEncoder {
		this.renderPassDescriptor = descriptor;
		return this.pass as unknown as GPURenderPassEncoder;
	}

	finish(): GPUCommandBuffer {
		return { encoder: this } as unknown as GPUCommandBuffer;
	}
}

class FakeDevice {
	readonly buffers: FakeBuffer[] = [];
	readonly textures: FakeTexture[] = [];
	readonly bindGroups: GPUBindGroup[] = [];
	readonly encoders: FakeCommandEncoder[] = [];
	readonly queue = new FakeQueue();
	private nextBufferId = 1;

	createShaderModule(descriptor: GPUShaderModuleDescriptor): GPUShaderModule {
		return { descriptor } as unknown as GPUShaderModule;
	}

	createRenderPipeline(descriptor: GPURenderPipelineDescriptor): GPURenderPipeline {
		return {
			descriptor,
			getBindGroupLayout: (index: number) => ({ index }),
		} as unknown as GPURenderPipeline;
	}

	createTexture(descriptor: GPUTextureDescriptor): GPUTexture {
		const texture = {
			descriptor,
			view: { texture: descriptor } as unknown as GPUTextureView,
			destroyed: false,
			createView() {
				return this.view;
			},
			destroy() {
				this.destroyed = true;
			},
		} as FakeTexture;
		this.textures.push(texture);
		return texture;
	}

	createBuffer(descriptor: GPUBufferDescriptor): GPUBuffer {
		const buffer = {
			id: this.nextBufferId,
			descriptor,
			destroyed: false,
			destroy() {
				this.destroyed = true;
			},
		} as FakeBuffer;
		this.nextBufferId += 1;
		this.buffers.push(buffer);
		return buffer;
	}

	createBindGroup(descriptor: GPUBindGroupDescriptor): GPUBindGroup {
		const bindGroup = { descriptor } as unknown as GPUBindGroup;
		this.bindGroups.push(bindGroup);
		return bindGroup;
	}

	createCommandEncoder(): GPUCommandEncoder {
		const encoder = new FakeCommandEncoder();
		this.encoders.push(encoder);
		return encoder as unknown as GPUCommandEncoder;
	}
}

function renderableBytes(
	mesh: number,
	material: number,
	flags = renderableFlagsDefault(),
): Uint8Array {
	return renderableComponentBytes(
		RenderableDesc.new(new MeshHandle(mesh), new MaterialHandle(material), flags),
	);
}

function installWebGpuConstants(): void {
	vi.stubGlobal("GPUBufferUsage", {
		VERTEX: 1,
		COPY_DST: 2,
		INDEX: 4,
		STORAGE: 8,
	});
	vi.stubGlobal("GPUTextureUsage", {
		RENDER_ATTACHMENT: 1,
	});
}

function testRenderer(device = new FakeDevice()): {
	readonly device: FakeDevice;
	readonly renderer: Renderer;
} {
	return {
		device,
		renderer: Renderer.new(
			device as unknown as GPUDevice,
			device.queue as unknown as GPUQueue,
			"rgba8unorm",
			64,
			32,
			{
				arrayStride: 12,
				attributes: [{ shaderLocation: 0, offset: 0, format: "float32x3" }],
			},
		),
	};
}

function identityMat4ColMajor(): number[] {
	return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
}

function f32At(bytes: Uint8Array, offset: number): number {
	return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getFloat32(
		offset,
		true,
	);
}

describe("Renderer TypeScript renderable API", () => {
	beforeEach(() => {
		installWebGpuConstants();
	});

	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it("packs renderable component rows in the ECS CPU layout", () => {
		const bytes = renderableBytes(
			0x01020304,
			0x05060708,
			new RenderableFlags(0x0a0b0c0d),
		);

		expect(bytes.byteLength).toBe(renderableComponentStride());
		expect(Array.from(bytes)).toEqual([
			0x04, 0x03, 0x02, 0x01, 0x08, 0x07, 0x06, 0x05, 0x0d, 0x0c, 0x0b, 0x0a,
			0, 0, 0, 0,
		]);
	});

	it("keeps renderable flags unsigned and composable", () => {
		const visible = renderableFlagsVisible();
		const allBits = new RenderableFlags(-1);

		expect(renderableFlagsNone().bits()).toBe(0);
		expect(visible.bits()).toBe(1);
		expect(renderableFlagsDefault().contains(visible)).toBe(true);
		expect(renderableFlagsNone().contains(visible)).toBe(false);
		expect(allBits.bits()).toBe(0xffffffff);
		expect(allBits.contains(visible)).toBe(true);
	});

	it("exposes mesh, material, and material descriptor accessors", () => {
		const mesh = new MeshHandle(7);
		const material = new MaterialHandle(9);
		const desc = RenderableDesc.new(mesh, material);
		const unlit = UnlitMaterialDesc.new(0.25, 0.5, 0.75, undefined, -1);

		expect(desc.mesh()).toBe(mesh);
		expect(desc.material()).toBe(material);
		expect(desc.flags().contains(renderableFlagsVisible())).toBe(true);
		expect(unlit.baseColorR()).toBeCloseTo(0.25);
		expect(unlit.baseColorG()).toBeCloseTo(0.5);
		expect(unlit.baseColorB()).toBeCloseTo(0.75);
		expect(unlit.alpha()).toBe(1);
		expect(unlit.flags()).toBe(0xffffffff);
	});

	it("registers a renderable CPU component and writes add/set rows", () => {
		const world = World.new();
		const renderable = registerRenderableComponent(world);
		const entity = world.createEntity();

		expect(world.componentCpuStride(renderable.id())).toBe(
			renderableComponentStride(),
		);
		expect(world.componentInfo(renderable.id())?.name()).toBe(
			"RhodoniteRenderable",
		);

		expect(
			addRenderable(
				world,
				entity,
				renderable,
				RenderableDesc.new(new MeshHandle(1), new MaterialHandle(2)),
			),
		).toBe(true);
		expect(renderable.entities()).toEqual([entity]);
		expect(world.componentBytesCopy(entity, renderable.id())).toEqual(
			renderableBytes(1, 2),
		);

		expect(
			setRenderable(
				world,
				entity,
				renderable,
				RenderableDesc.new(
					new MeshHandle(3),
					new MaterialHandle(4),
					renderableFlagsNone(),
				),
			),
		).toBe(true);
		expect(renderable.entities()).toEqual([entity]);
		expect(world.componentBytesCopy(entity, renderable.id())).toEqual(
			renderableBytes(3, 4, renderableFlagsNone()),
		);
	});

	it("records prepared instanced draw calls through WebGPU resources", () => {
		const { device, renderer } = testRenderer();
		const mesh = renderer.registerStaticIndexedMesh(
			new Uint8Array([1, 2, 3, 4, 5, 6]),
			new Uint8Array([0, 0, 1, 0, 2, 0]),
			3,
		);
		const instances = renderer.registerStaticInstanceBuffer(new Uint8Array(48));
		const colorView = { kind: "color" } as unknown as GPUTextureView;

		renderer.ensureStorageBuffers({ transformWords: 16, cameraWords: 72 });
		renderer.uploadGlobalTransformBytes(new Uint8Array([9, 8, 7, 6]), 4);
		renderer.uploadCameraBytes(new Uint8Array([5, 4, 3, 2]), 8);
		renderer.renderPreparedInstancedMesh(mesh, instances, 2, colorView);

		expect(device.bindGroups).toHaveLength(2);
		expect(device.queue.writes.map((write) => write.bytes.byteLength)).toEqual([
			6, 6, 48, 4, 4,
		]);
		expect(device.queue.submissions).toHaveLength(1);
		const calls = device.encoders[0]?.pass.calls ?? [];
		expect(calls.map((call) => call.name)).toEqual([
			"setPipeline",
			"setBindGroup",
			"setBindGroup",
			"setIndexBuffer",
			"setVertexBuffer",
			"setVertexBuffer",
			"drawIndexed",
			"end",
		]);
		expect(calls.find((call) => call.name === "drawIndexed")?.args).toEqual([
			3,
			2,
			undefined,
			undefined,
			undefined,
		]);
		expect(
			calls
				.filter((call) => call.name === "setVertexBuffer")
				.map((call) => call.args.slice(0, 4)),
		).toEqual([
			[0, device.buffers[0], 0, 6],
			[1, device.buffers[2], 0, 48],
		]);
	});

	it("extracts visible renderables into one draw call per entity", () => {
		const { device, renderer } = testRenderer();
		const world = World.new();
		const scene = new Scene<World, EntityId>("render-test", world);
		const [entity] = world.spawnTransformGlobalBatchIdentity(1);
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();
		const renderable = registerRenderableComponent(world);
		const mesh = renderer.registerStaticIndexedMesh(
			new Uint8Array([1, 2, 3, 4, 5, 6]),
			new Uint8Array([0, 0, 1, 0, 2, 0]),
			3,
		);
		const material = renderer.registerUnlitMaterial(
			UnlitMaterialDesc.new(0.25, 0.5, 0.75),
		);
		const colorView = { kind: "color" } as unknown as GPUTextureView;

		expect(entity).toBeDefined();
		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 100, 1, 1, 0),
		).toBe(true);
		expect(
			addRenderable(
				world,
				entity!,
				renderable,
				RenderableDesc.new(mesh, material),
			),
		).toBe(true);

		renderer.renderSceneRenderables(scene, renderable, colorView);

		expect(device.queue.submissions).toHaveLength(1);
		const instanceWrite = device.queue.writes.find(
			(write) => write.bytes.byteLength === 24,
		);
		expect(instanceWrite).toBeDefined();
		expect(f32At(instanceWrite?.bytes ?? new Uint8Array(), 8)).toBeCloseTo(0.25);
		expect(f32At(instanceWrite?.bytes ?? new Uint8Array(), 12)).toBeCloseTo(0.5);
		expect(f32At(instanceWrite?.bytes ?? new Uint8Array(), 16)).toBeCloseTo(0.75);
		const drawCalls = device.encoders[0]?.pass.calls.filter(
			(call) => call.name === "drawIndexed",
		);
		expect(drawCalls).toEqual([
			{
				name: "drawIndexed",
				args: [3, 1, 0, 0, 0],
			},
		]);
	});

	it("releases owned GPU resources", () => {
		const { device, renderer } = testRenderer();
		renderer.registerStaticIndexedMesh(
			new Uint8Array([1, 2]),
			new Uint8Array([0, 0]),
			1,
		);
		renderer.registerStaticInstanceBuffer(new Uint8Array(24));
		renderer.ensureStorageBuffers({ transformWords: 16, cameraWords: 72 });
		renderer.release();

		expect(device.buffers.every((buffer) => buffer.destroyed)).toBe(true);
		expect(device.textures.every((texture) => texture.destroyed)).toBe(true);
	});
});
