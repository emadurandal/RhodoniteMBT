import { describe, expect, it } from "vitest";
import { GpuLayout, Query, RawQuery, World, getF32, putF32 } from "./index.ts";

function f32Bytes(values: number[], stride = values.length * 4): Uint8Array {
	const bytes = new Uint8Array(stride);
	const view = new DataView(bytes.buffer);
	values.forEach((value, index) => view.setFloat32(index * 4, value, true));
	return bytes;
}

describe("ECS TypeScript wrapper", () => {
	it("creates entities and invalidates stale handles", () => {
		const world = World.new();
		const e0 = world.createEntity();
		const e1 = world.createEntity();

		expect(world.isAlive(e0)).toBe(true);
		expect(world.isAlive(e1)).toBe(true);
		expect(world.destroyEntity(e0)).toBe(true);
		expect(world.isAlive(e0)).toBe(false);

		const e2 = world.createEntity();
		expect(e2.index()).toBe(e0.index());
		expect(e2.generation()).toBe(e0.generation() + 1);
		expect(e2.gpuIndex()).toBe(e2.index());
	});

	it("registers metadata and GPU layouts", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("TsCPU", 16);
		const gpuLayout = GpuLayout.empty(16);
		const gpu = world.registerGpuComponent("TsGPU", gpuLayout);

		expect(gpuLayout.isValid()).toBe(true);
		expect(gpuLayout.stride()).toBe(16);
		expect(world.componentCpuStride(cpu)).toBe(16);
		expect(world.componentCpuStride(gpu)).toBe(0);

		const info = world.componentInfo(gpu);
		expect(info?.name()).toBe("TsGPU");
		expect(info?.kind()).toBe("GpuVisible");
		expect(world.componentGpuLayout(gpu)?.stride()).toBe(16);
	});

	it("queries CPU component rows without copying the backing storage", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("Position", 16);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, f32Bytes([1, 2, 3, 0], 16))).toBe(
			true,
		);

		const query = Query.new([cpu]);
		let visited = 0;
		query.forEach(world, (row) => {
			visited += 1;
			expect(row.entity().index()).toBe(entity.index());
			row.write(cpu, (bytes) => {
				expect(bytes.length).toBe(16);
				expect(bytes.asUint8Array()).toBeNull();
				expect(bytes.getF32(0)).toBeCloseTo(1);
				bytes.setF32(0, 9);
				bytes.set(12, 7);
			});
		});

		expect(visited).toBe(1);
		const copy = world.componentBytesCopy(entity, cpu);
		expect(copy).not.toBeNull();
		expect(getF32(copy ?? new Uint8Array(), 0)).toBeCloseTo(9);
		expect(copy?.[12]).toBe(7);
	});

	it("returns borrowed GPU write views for immediate upload", () => {
		const world = World.new();
		const gpu = world.registerGpuComponent("GpuMaterial", GpuLayout.empty(16));
		const entity = world.createEntity();
		const bytes = new Uint8Array(16);
		putF32(bytes, 0, 12.5);

		expect(world.addComponentBytes(entity, gpu, bytes)).toBe(true);
		expect(world.drainResizeEvents().length).toBeGreaterThan(0);

		const writes = world.drainGpuWriteViews(gpu);
		expect(writes).toHaveLength(1);
		expect(writes[0]?.byteOffset()).toBe(entity.index() * 16);
		const view = writes[0]?.bytes();
		expect(view?.length).toBe(16);
		const typed = view?.asUint8Array();
		expect(typed).toBeInstanceOf(Uint8Array);
		expect(typed?.byteLength).toBe(16);
		expect(view?.getF32(0)).toBeCloseTo(12.5);
	});

	it("exposes archetype column views for hot CPU loops", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("Velocity", 16);
		const e0 = world.createEntity();
		const e1 = world.createEntity();
		expect(world.addComponentBytes(e0, cpu, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpu, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);

		RawQuery.new([cpu]).forEachArchetype(world, (archetype) => {
			expect(archetype.length()).toBe(2);
			expect(archetype.componentStride(cpu)).toBe(16);
			const column = archetype.writeColumn(cpu);
			expect(column.length).toBe(32);
			column.setF32(0, 10);
			column.setF32(16, 20);
		});

		const e0Bytes = world.componentBytesCopy(e0, cpu);
		const e1Bytes = world.componentBytesCopy(e1, cpu);
		expect(getF32(e0Bytes ?? new Uint8Array(), 0)).toBeCloseTo(10);
		expect(getF32(e1Bytes ?? new Uint8Array(), 0)).toBeCloseTo(20);
	});

	it("reuses prepared row query plans", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("PreparedTsCpu", 16);
		const prepared = Query.new([cpu]).prepare(world);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, f32Bytes([4, 0, 0, 0], 16))).toBe(
			true,
		);

		let sum = 0;
		prepared.forEach(world, (row) => {
			row.read(cpu, (bytes) => {
				sum += bytes.getF32(0);
			});
		});

		expect(sum).toBeCloseTo(4);
	});

	it("batch-spawns arbitrary CPU and GPU components", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("SpawnBatchTsCpu", 16);
		const gpu = world.registerGpuComponent("SpawnBatchTsGpu", GpuLayout.empty(16));

		const entities = world.spawnBatch([gpu, cpu], 2, (index, entity, row) => {
			expect(row.entity().index()).toBe(entity.index());
			row.write(cpu, (bytes) => bytes.setF32(0, index + 1));
			row.write(gpu, (bytes) => bytes.setF32(0, index + 10));
		});

		expect(entities).toHaveLength(2);
		expect(world.componentBytesCopy(entities[0], cpu)?.[0]).not.toBeUndefined();
		expect(
			getF32(world.componentBytesCopy(entities[1], cpu) ?? new Uint8Array(), 0),
		).toBeCloseTo(2);
		const writes = world.drainGpuWriteViews(gpu);
		expect(writes).toHaveLength(1);
		expect(writes[0]?.bytes().getF32(0)).toBeCloseTo(10);
		expect(writes[0]?.bytes().getF32(16)).toBeCloseTo(11);
	});

	it("supports builtin transform/global transform upload helpers", () => {
		const world = World.new();
		const [entity] = world.spawnTransformGlobalBatchIdentity(1);
		expect(entity).toBeDefined();
		const globalTransform = world.globalTransformComponent();

		world.updateGlobalTransformsFromTransforms();
		const writes = world.drainGpuWriteViews(globalTransform);
		expect(writes.length).toBeGreaterThan(0);
		expect(writes[0]?.bytes().asUint8Array()).toBeInstanceOf(Uint8Array);
	});

	it("keeps transform archetype columns appendable after JS global-transform fast path", () => {
		const world = World.new();
		const first = world.spawnTransformGlobalBatchIdentity(1);
		expect(first).toHaveLength(1);

		world.updateGlobalTransformsFromTransforms();

		const second = world.spawnTransformGlobalBatchIdentity(1);
		expect(second).toHaveLength(1);
		expect(world.isAlive(second[0])).toBe(true);
	});
});
