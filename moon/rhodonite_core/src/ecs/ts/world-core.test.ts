// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	ComponentTypeId,
	EntityId,
	GpuLayout,
	PhaseKey,
	Query,
	RawQuery,
	System,
	SystemContext,
	SystemRunner,
	World,
	WorldHistory,
	decodeHistoryExportJson,
	describe,
	encodeHistoryExportJson,
	expect,
	f32Bytes,
	getF32,
	globalTransformFormatCode,
	identityMat4ColMajor,
	it,
	translationMat4ColMajor,
} from "./test-support/world-test-support.ts";

describe("ECS TypeScript wrapper: core", () => {
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


	it("registers metadata and keeps GPU layout helpers available", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("TsCPU", 16);
		const layout = GpuLayout.empty(16);

		expect(layout.isValid()).toBe(true);
		expect(layout.stride()).toBe(16);
		expect(world.componentCpuStride(cpu)).toBe(16);

		const info = world.componentInfo(cpu);
		expect(info?.name()).toBe("TsCPU");
		expect(info?.cpuStride()).toBe(16);
		expect(info?.stableKey()).toBeNull();
		expect(info?.schemaVersion()).toBeNull();
		expect(info?.schemaHash()).toBeNull();
		expect(
			world.componentMatchesIdentity(cpu, {
				stableKey: "com.example.TsCPU",
			}),
		).toBe(false);
	});


	it("registers stable component identity metadata", () => {
		const world = World.new();
		const cpu = world.registerCpuComponentWithIdentity("TsStableCPU", 8, {
			stableKey: "com.example.TsStableCPU",
			schemaVersion: "3",
			schemaHash: "sha256:ts-stable",
		});

		const info = world.componentInfo(cpu);
		expect(info?.name()).toBe("TsStableCPU");
		expect(info?.cpuStride()).toBe(8);
		expect(info?.stableKey()).toBe("com.example.TsStableCPU");
		expect(info?.schemaVersion()).toBe("3");
		expect(info?.schemaHash()).toBe("sha256:ts-stable");
		expect(world.componentByStableKey("com.example.TsStableCPU")?.index()).toBe(
			cpu.index(),
		);
		expect(world.componentByStableKey("com.example.MissingTsStable")).toBeNull();
		expect(world.componentByStableKey("TsStableCPU")).toBeNull();
		expect(
			world.componentMatchesIdentity(cpu, {
				stableKey: "com.example.TsStableCPU",
			}),
		).toBe(true);
		expect(
			world.componentMatchesIdentity(cpu, {
				stableKey: "com.example.TsStableCPU",
				schemaVersion: "3",
				schemaHash: "sha256:ts-stable",
			}),
		).toBe(true);
		expect(
			world.componentMatchesIdentity(cpu, {
				stableKey: "com.example.TsStableCPU",
				schemaVersion: "4",
			}),
		).toBe(false);
		expect(
			world.componentMatchesIdentity(cpu, {
				stableKey: "com.example.TsStableCPU",
				schemaHash: "sha256:mismatch",
			}),
		).toBe(false);
		expect(
			world.componentMatchesIdentity(ComponentTypeId.new(9999), {
				stableKey: "com.example.TsStableCPU",
			}),
		).toBe(false);
		expect(world.addComponentBytes(world.createEntity(), cpu, new Uint8Array(8))).toBe(
			true,
		);
	});


	it("rejects duplicate stable component identity keys", () => {
		const world = World.new();
		world.registerCpuComponentWithIdentity("TsStableA", 4, {
			stableKey: "com.example.DuplicateTsStable",
		});
		expect(() =>
			world.registerCpuComponentWithIdentity("TsStableB", 4, {
				stableKey: "com.example.DuplicateTsStable",
			}),
		).toThrow();
	});


	it("batch-spawns arbitrary CPU components", () => {
		const world = World.new();
		const cpuA = world.registerCpuComponent("SpawnBatchTsCpuA", 16);
		const cpuB = world.registerCpuComponent("SpawnBatchTsCpuB", 16);
		expect(world.reserveBatchCapacity([cpuB, cpuA], 2)).toBe(true);

		const entities = world.spawnBatch([cpuB, cpuA], 2, (index, entity, row) => {
			expect(row.entity().index()).toBe(entity.index());
			row.write(cpuA, (bytes) => bytes.setF32(0, index + 1));
			row.write(cpuB, (bytes) => bytes.setF32(0, index + 10));
		});

		expect(entities).toHaveLength(2);
		expect(
			getF32(world.componentBytesCopy(entities[1], cpuA) ?? new Uint8Array(), 0),
		).toBeCloseTo(2);
		expect(
			getF32(world.componentBytesCopy(entities[1], cpuB) ?? new Uint8Array(), 0),
		).toBeCloseTo(11);
	});

	it("reports transform propagation diagnostics without draining uploads", () => {
		const world = World.new();
		const parent = world.createEntity();
		const child = world.createEntity();

		expect(
			world.setTransformTrs(parent, 10, 0, 0, 0, 0, 0, 1, 1, 1, 1),
		).toBe(true);
		expect(world.setTransformTrs(child, 5, 0, 0, 0, 0, 0, 1, 1, 1, 1)).toBe(
			true,
		);
		expect(world.setChildOf(child, parent)).toBe(true);
		expect(world.setGlobalTransform(parent, identityMat4ColMajor())).toBe(true);
		expect(world.setGlobalTransform(child, identityMat4ColMajor())).toBe(true);
		world.updateGlobalTransformsFromTransforms();
		world.drainGlobalTransformBlobWriteViews();

		expect(
			world.setTransformTrs(parent, 20, 0, 0, 0, 0, 0, 1, 1, 1, 1),
		).toBe(true);
		const report = world.propagateGlobalTransformsFromTransformsReport();
		expect(report.ok()).toBe(true);
		expect(report.usedDirtyPath()).toBe(true);
		expect(report.usedFullPath()).toBe(false);
		expect(report.fallbackToFull()).toBe(false);
		expect(report.dirtyQueueCount()).toBe(1);
		expect(report.dirtyRootCount()).toBe(1);
		expect(report.skippedDirtyEntityCount()).toBe(0);
		expect(report.visitedEntityCount()).toBe(2);
		expect(report.globalTransformWriteCount()).toBe(2);
		expect(report.pendingUploadRangeCount()).toBe(1);
		expect(world.getGlobalTransform(child)?.[12]).toBeCloseTo(25);
		expect(world.drainGlobalTransformBlobWriteViews()).toHaveLength(1);
	});

});
