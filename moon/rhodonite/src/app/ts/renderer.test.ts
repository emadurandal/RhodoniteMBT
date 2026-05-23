// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
	ComponentTypeId,
	type EntityId,
	World,
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import {
	FakeDevice,
	installFakeWebGpuConstants,
} from "../test-utils/fake-webgpu.ts";
import {
	CubeMeshDesc,
	InstanceBufferHandle,
	MaterialHandle,
	MeshHandle,
	Renderer,
	RenderableDesc,
	RenderableFlags,
	Scene,
	UnlitMaterialDesc,
	addRenderable,
	cubeIndexCount,
	cubeIndexU16Bytes,
	cubeMeshDesc,
	cubeVertexCount,
	cubeVertexPositionBytes,
	renderableComponentBytes,
	renderableComponentStride,
	renderableFlagsDefault,
	renderableFlagsNone,
	renderableFlagsVisible,
	setRenderable,
} from "./index.ts";

function renderableBytes(
	mesh: number,
	material: number,
	flags = renderableFlagsDefault(),
): Uint8Array {
	return renderableComponentBytes(
		RenderableDesc.new(new MeshHandle(mesh), new MaterialHandle(material), flags),
	);
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

function findComponentByName(world: World, name: string): ComponentTypeId | null {
	for (let index = 0; index < 64; index += 1) {
		const id = ComponentTypeId.new(index);
		if (world.componentInfo(id)?.name() === name) {
			return id;
		}
	}
	return null;
}

describe("Renderer TypeScript renderable API", () => {
	beforeEach(() => {
		installFakeWebGpuConstants();
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

	it("builds shared-corner cube mesh descriptors", () => {
		const desc = cubeMeshDesc(CubeMeshDesc.new(0.5));
		const vertices = desc.vertices();
		const indices = desc.indicesU16();

		expect(cubeVertexCount()).toBe(8);
		expect(cubeIndexCount()).toBe(36);
		expect(vertices.byteLength).toBe(8 * 12);
		expect(indices.byteLength).toBe(36 * 2);
		expect(f32At(vertices, 0)).toBe(-0.5);
		expect(f32At(vertices, 4)).toBe(-0.5);
		expect(f32At(vertices, 8)).toBe(-0.5);
		expect(f32At(vertices, 84)).toBe(-0.5);
		expect(f32At(vertices, 88)).toBe(0.5);
		expect(f32At(vertices, 92)).toBe(0.5);
		expect(Array.from(indices.slice(0, 6))).toEqual([0, 0, 1, 0, 2, 0]);
		expect(Array.from(indices.slice(70, 72))).toEqual([3, 0]);
		expect(cubeVertexPositionBytes(CubeMeshDesc.new(0.5))).toEqual(vertices);
		expect(cubeIndexU16Bytes()).toEqual(indices);
	});

	it("registers a renderable CPU component and writes add/set rows", () => {
		const world = World.new();
		const scene = new Scene<World, EntityId>("renderable", world);
		const entity = world.createEntity();

		expect(
			addRenderable(
				scene,
				entity,
				RenderableDesc.new(new MeshHandle(1), new MaterialHandle(2)),
			),
		).toBe(true);
		const renderable = findComponentByName(world, "RhodoniteRenderable");
		expect(renderable).not.toBeNull();
		expect(world.componentCpuStride(renderable!)).toBe(
			renderableComponentStride(),
		);
		expect(world.componentBytesCopy(entity, renderable!)).toEqual(
			renderableBytes(1, 2),
		);

		expect(
			setRenderable(
				scene,
				entity,
				RenderableDesc.new(
					new MeshHandle(3),
					new MaterialHandle(4),
					renderableFlagsNone(),
				),
			),
		).toBe(true);
		expect(world.componentBytesCopy(entity, renderable!)).toEqual(
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

	it("registers cube meshes through the descriptor path", () => {
		const { device, renderer } = testRenderer();
		const mesh = renderer.registerCubeMesh(CubeMeshDesc.new(0.5));

		expect(mesh.index()).toBe(0);
		expect(device.queue.writes.map((write) => write.bytes.byteLength)).toEqual([
			96, 72,
		]);
	});

	it("skips prepared instanced draws when handles or instance counts are invalid", () => {
		const { device, renderer } = testRenderer();
		const mesh = renderer.registerStaticIndexedMesh(
			new Uint8Array([1, 2, 3, 4, 5, 6]),
			new Uint8Array([0, 0, 1, 0, 2, 0]),
			3,
		);
		const instances = renderer.registerStaticInstanceBuffer(new Uint8Array(24));
		const colorView = { kind: "color" } as unknown as GPUTextureView;

		renderer.renderPreparedInstancedMesh(new MeshHandle(99), instances, 1, colorView);
		renderer.renderPreparedInstancedMesh(mesh, new InstanceBufferHandle(99), 1, colorView);
		renderer.renderPreparedInstancedMesh(mesh, instances, 0, colorView);
		renderer.renderPreparedInstancedMesh(mesh, instances, 2, colorView);

		expect(device.encoders).toHaveLength(0);
		expect(device.queue.submissions).toHaveLength(0);
	});

	it("skips prepared instanced draws when depth resources are inactive", () => {
		const { device, renderer } = testRenderer();
		const mesh = renderer.registerStaticIndexedMesh(
			new Uint8Array([1, 2, 3, 4, 5, 6]),
			new Uint8Array([0, 0, 1, 0, 2, 0]),
			3,
		);
		const instances = renderer.registerStaticInstanceBuffer(new Uint8Array(24));
		const colorView = { kind: "color" } as unknown as GPUTextureView;

		renderer.resizeSurfaceResources(0, 32);
		renderer.renderPreparedInstancedMesh(mesh, instances, 1, colorView);

		expect(device.textures[0]?.destroyed).toBe(true);
		expect(device.encoders).toHaveLength(0);
		expect(device.queue.submissions).toHaveLength(0);
	});

	it("guards static instance buffer updates by handle and capacity", () => {
		const { device, renderer } = testRenderer();
		const instances = renderer.registerStaticInstanceBuffer(new Uint8Array(24));

		expect(renderer.updateStaticInstanceBuffer(new InstanceBufferHandle(99), new Uint8Array(4))).toBe(
			false,
		);
		expect(renderer.updateStaticInstanceBuffer(instances, new Uint8Array(48))).toBe(
			false,
		);
		expect(device.queue.writes).toHaveLength(1);

		expect(renderer.updateStaticInstanceBuffer(instances, new Uint8Array(24))).toBe(
			true,
		);
		expect(device.queue.writes).toHaveLength(2);
		expect(device.queue.writes[1]?.buffer).toBe(device.buffers[0]);
		expect(device.queue.writes[1]?.bytes.byteLength).toBe(24);
	});

	it("skips renderables that lack GlobalTransform", () => {
		const { device, renderer } = testRenderer();
		const world = World.new();
		const scene = new Scene<World, EntityId>("render-test", world);
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();
		const mesh = renderer.registerStaticIndexedMesh(
			new Uint8Array([1, 2, 3, 4, 5, 6]),
			new Uint8Array([0, 0, 1, 0, 2, 0]),
			3,
		);
		const material = renderer.registerUnlitMaterial(
			UnlitMaterialDesc.new(0.25, 0.5, 0.75),
		);
		const colorView = { kind: "color" } as unknown as GPUTextureView;

		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 100, 1, 1, 0),
		).toBe(true);
		expect(
			addRenderable(
				scene,
				entity,
				RenderableDesc.new(mesh, material),
			),
		).toBe(true);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			false,
		);

		renderer.renderSceneRenderables(scene, colorView);

		const drawCalls = device.encoders[0]?.pass.calls.filter(
			(call) => call.name === "drawIndexed",
		);
		expect(drawCalls).toEqual([]);
	});

	it("extracts visible renderables into one draw call per entity", () => {
		const { device, renderer } = testRenderer();
		const world = World.new();
		const scene = new Scene<World, EntityId>("render-test", world);
		const [entity] = world.spawnTransformGlobalBatchIdentity(1);
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();
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
				scene,
				entity!,
				RenderableDesc.new(mesh, material),
			),
		).toBe(true);

		renderer.renderSceneRenderables(scene, colorView);

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
