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
import type { HistoryDiagnosticReason } from "./world-history-types.ts";

function expectLastDiagnostic(
	history: WorldHistory,
	expected: HistoryDiagnosticReason,
): void {
	const diagnostic: HistoryDiagnosticReason = history.lastDiagnostic();
	expect(diagnostic).toBe(expected);
}

describe("ECS TypeScript wrapper: history", () => {
	it("exposes payload-free undo and redo summaries", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistorySummaryCpu", 4);
		const removable = world.registerCpuComponent("TsHistorySummaryRemovable", 4);
		const changedEntity = world.createEntity();
		const addEntity = world.createEntity();
		const removeEntity = world.createEntity();
		const globalEntity = world.createEntity();
		const cameraEntity = world.createEntity();
		const identity = identityMat4ColMajor();
		expect(
			world.addComponentBytes(changedEntity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			world.addComponentBytes(
				removeEntity,
				removable,
				new Uint8Array([7, 0, 0, 0]),
			),
		).toBe(true);
		expect(
			world.setGlobalTransform(
				globalEntity,
				translationMat4ColMajor(1, 2, 3),
			),
		).toBe(true);
		expect(
			world.setCameraMatrices(cameraEntity, identity, identity, 0.1, 50, 1, 1, 0),
		).toBe(true);

		expect(history.beginTransaction("TS summary mixed")).toBe(true);
		const created = history.createEntity(world);
		expect(
			history.addComponentBytes(
				world,
				addEntity,
				cpu,
				new Uint8Array([8, 0, 0, 0]),
			),
		).toBe(true);
		expect(history.removeComponent(world, removeEntity, removable)).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				changedEntity,
				cpu,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		expect(
			history.setGlobalTransform(
				world,
				globalEntity,
				translationMat4ColMajor(4, 5, 6),
			),
		).toBe(true);
		expect(
			history.setCameraMatrices(
				world,
				cameraEntity,
				identity,
				identity,
				0.25,
				100,
				1.5,
				0,
				2,
			),
		).toBe(true);
		expect(history.commitTransaction()).toBe(true);
		expect(history.beginTransaction("TS summary destroy")).toBe(true);
		expect(history.destroyEntity(world, changedEntity)).toBe(true);
		expect(history.commitTransaction()).toBe(true);

		const diagnostic = history.lastDiagnostic();
		const summaries = history.undoSummary();
		expect(summaries).toHaveLength(2);
		expect(summaries[0]).toMatchObject({
			label: "TS summary destroy",
			deltaCount: 1,
			payloadBytes: 4,
		});
		expect(summaries[0]?.deltas[0]).toMatchObject({
			kind: "entity_destroyed",
			component: null,
			componentCount: 1,
			payloadBytes: 4,
			beforePresent: true,
			afterPresent: false,
		});
		expect(summaries[0]?.deltas[0]?.entity?.index()).toBe(
			changedEntity.index(),
		);
		expect(summaries[1]).toMatchObject({
			label: "TS summary mixed",
			deltaCount: 6,
			payloadBytes: 688,
		});
		expect(summaries[1]?.deltas.map((delta) => delta.kind)).toEqual([
			"entity_created",
			"component_added",
			"component_removed",
			"component_changed",
			"global_transform_changed",
			"camera_changed",
		]);
		expect(summaries[1]?.deltas[0]).toMatchObject({
			kind: "entity_created",
			component: null,
			componentCount: 0,
			payloadBytes: 0,
			beforePresent: false,
			afterPresent: true,
		});
		expect(summaries[1]?.deltas[0]?.entity?.index()).toBe(created.index());
		expect(summaries[1]?.deltas[1]).toMatchObject({
			kind: "component_added",
			componentCount: 0,
			payloadBytes: 4,
			beforePresent: false,
			afterPresent: true,
		});
		expect(summaries[1]?.deltas[1]?.entity?.index()).toBe(addEntity.index());
		expect(summaries[1]?.deltas[1]?.component?.index()).toBe(cpu.index());
		expect(summaries[1]?.deltas[2]).toMatchObject({
			kind: "component_removed",
			componentCount: 0,
			payloadBytes: 4,
			beforePresent: true,
			afterPresent: false,
		});
		expect(summaries[1]?.deltas[2]?.entity?.index()).toBe(removeEntity.index());
		expect(summaries[1]?.deltas[2]?.component?.index()).toBe(
			removable.index(),
		);
		expect(summaries[1]?.deltas[3]).toMatchObject({
			kind: "component_changed",
			componentCount: 0,
			payloadBytes: 8,
			beforePresent: true,
			afterPresent: true,
		});
		expect(summaries[1]?.deltas[3]?.entity?.index()).toBe(
			changedEntity.index(),
		);
		expect(summaries[1]?.deltas[3]?.component?.index()).toBe(cpu.index());
		expect(summaries[1]?.deltas[4]).toMatchObject({
			kind: "global_transform_changed",
			component: null,
			componentCount: 0,
			payloadBytes: 96,
			beforePresent: true,
			afterPresent: true,
		});
		expect(summaries[1]?.deltas[4]?.entity?.index()).toBe(globalEntity.index());
		expect(summaries[1]?.deltas[5]).toMatchObject({
			kind: "camera_changed",
			component: null,
			componentCount: 0,
			payloadBytes: 576,
			beforePresent: true,
			afterPresent: true,
		});
		expect(summaries[1]?.deltas[5]?.entity?.index()).toBe(cameraEntity.index());
		for (const summary of summaries) {
			for (const delta of summary.deltas) {
				expect("bytes" in (delta as unknown as Record<string, unknown>)).toBe(
					false,
				);
				expect("before" in (delta as unknown as Record<string, unknown>)).toBe(
					false,
				);
				expect("after" in (delta as unknown as Record<string, unknown>)).toBe(
					false,
				);
			}
		}
		expect(history.lastDiagnostic()).toBe(diagnostic);
		expect(history.undoLen()).toBe(2);
		expect(history.redoLen()).toBe(0);

		expect(history.undo(world)).toBe(true);
		expect(history.undo(world)).toBe(true);
		const redoSummaries = history.redoSummary();
		expect(redoSummaries).toHaveLength(2);
		expect(redoSummaries[0]?.label).toBe("TS summary mixed");
		expect(redoSummaries[0]?.deltas.map((delta) => delta.kind)).toEqual([
			"entity_created",
			"component_added",
			"component_removed",
			"component_changed",
			"global_transform_changed",
			"camera_changed",
		]);
		expect(redoSummaries[0]?.payloadBytes).toBe(summaries[1]?.payloadBytes);
		expect(redoSummaries[1]?.label).toBe("TS summary destroy");
		expect(redoSummaries[1]?.deltas[0]?.kind).toBe("entity_destroyed");
		expect(redoSummaries[1]?.payloadBytes).toBe(summaries[0]?.payloadBytes);
		expect(history.undoLen()).toBe(0);
		expect(history.redoLen()).toBe(2);
	});


	it("audits direct WorldHistory mutation coverage", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryCoverageCpu", 4);
		const marker = world.registerCpuComponent("TsHistoryCoverageMarker", 4);
		const removable = world.registerCpuComponent("TsHistoryCoverageRemovable", 4);
		const parent = world.createEntity();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const bulkAdd0 = world.createEntity();
		const bulkAdd1 = world.createEntity();
		const bulkSet0 = world.createEntity();
		const bulkSet1 = world.createEntity();
		const removeEntity = world.createEntity();
		const victim = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(world.addComponentBytes(bulkSet0, cpu, new Uint8Array([10, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(bulkSet1, cpu, new Uint8Array([11, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(removeEntity, removable, new Uint8Array([90, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(victim, cpu, new Uint8Array([99, 0, 0, 0]))).toBe(true);
		expect(history.beginTransaction("TS coverage direct")).toBe(true);
		const created = history.createEntity(world);
		const createdMany = history.createEntities(world, 2);
		const spawned = history.spawnBatch(world, [marker, cpu], 2, (index, _entity, row) => {
			row.write(marker, (bytes) => bytes.setF32(0, index + 30));
			row.write(cpu, (bytes) => bytes.setF32(0, index + 40));
		});
		expect(history.addComponent(world, parent, marker)).toBe(true);
		expect(
			history.addComponentBytes(world, entity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0])),
		).toBe(true);
		expect(
			history.setTransformTrs(world, entity, 4, 5, 6, 0, 0, 0, 1, 1, 1, 1),
		).toBe(true);
		expect(history.setChildOf(world, entity, parent)).toBe(true);
		expect(
			history.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(1, 2, 3),
			),
		).toBe(true);
		expect(history.setGlobalTransformFormat(world, entity, 1)).toBe(true);
		expect(
			history.setCameraMatrices(
				world,
				camera,
				identity,
				identity,
				0.25,
				100,
				1.5,
				0,
				2,
			),
		).toBe(true);
		expect(
			history.addComponentBytesMany(
				world,
				marker,
				[bulkAdd0, bulkAdd1],
				[new Uint8Array([50, 0, 0, 0]), new Uint8Array([51, 0, 0, 0])],
			),
		).toBe(true);
		expect(
			history.setComponentBytesMany(
				world,
				cpu,
				[bulkSet0, bulkSet1],
				[new Uint8Array([12, 0, 0, 0]), new Uint8Array([13, 0, 0, 0])],
			),
		).toBe(true);
		expect(history.removeComponent(world, removeEntity, removable)).toBe(true);
		expect(history.destroyEntity(world, victim)).toBe(true);
		expect(history.commitTransaction()).toBe(true);
		expect(history.undoLabel()).toBe("TS coverage direct");
		expect(world.isAlive(created)).toBe(true);
		expect(createdMany).toHaveLength(2);
		expect(spawned).toHaveLength(2);
		expect(world.hasComponent(parent, marker)).toBe(true);
		expect(world.componentBytesCopy(spawned[0], marker)).toEqual(f32Bytes([30]));
		expect(world.componentBytesCopy(spawned[1], cpu)).toEqual(f32Bytes([41]));
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([2, 0, 0, 0]),
		);
		expect(world.componentBytesCopy(bulkAdd0, marker)).toEqual(new Uint8Array([50, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkAdd1, marker)).toEqual(new Uint8Array([51, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkSet0, cpu)).toEqual(new Uint8Array([12, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkSet1, cpu)).toEqual(new Uint8Array([13, 0, 0, 0]));
		expect(world.hasComponent(removeEntity, removable)).toBe(false);
		expect(world.isAlive(victim)).toBe(false);
		expect(world.hasComponent(entity, world.transformComponent())).toBe(true);
		expect(world.hasComponent(entity, world.childOfComponent())).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		expect(history.undo(world)).toBe(true);
		expect(world.isAlive(created)).toBe(false);
		expect(world.isAlive(createdMany[0])).toBe(false);
		expect(world.isAlive(createdMany[1])).toBe(false);
		expect(world.isAlive(spawned[0])).toBe(false);
		expect(world.isAlive(spawned[1])).toBe(false);
		expect(world.hasComponent(parent, marker)).toBe(false);
		expect(world.hasComponent(entity, cpu)).toBe(false);
		expect(world.hasComponent(entity, world.transformComponent())).toBe(false);
		expect(world.hasComponent(entity, world.childOfComponent())).toBe(false);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			false,
		);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(false);
		expect(world.hasComponent(bulkAdd0, marker)).toBe(false);
		expect(world.hasComponent(bulkAdd1, marker)).toBe(false);
		expect(world.componentBytesCopy(bulkSet0, cpu)).toEqual(new Uint8Array([10, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkSet1, cpu)).toEqual(new Uint8Array([11, 0, 0, 0]));
		expect(world.componentBytesCopy(removeEntity, removable)).toEqual(new Uint8Array([90, 0, 0, 0]));
		expect(world.isAlive(victim)).toBe(true);
		expect(world.componentBytesCopy(victim, cpu)).toEqual(new Uint8Array([99, 0, 0, 0]));

		expect(history.redo(world)).toBe(true);
		expect(world.isAlive(created)).toBe(true);
		expect(world.isAlive(createdMany[0])).toBe(true);
		expect(world.isAlive(createdMany[1])).toBe(true);
		expect(world.hasComponent(parent, marker)).toBe(true);
		expect(world.isAlive(spawned[0])).toBe(true);
		expect(world.isAlive(spawned[1])).toBe(true);
		expect(world.componentBytesCopy(spawned[0], marker)).toEqual(f32Bytes([30]));
		expect(world.componentBytesCopy(spawned[1], cpu)).toEqual(f32Bytes([41]));
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([2, 0, 0, 0]),
		);
		expect(world.componentBytesCopy(bulkAdd0, marker)).toEqual(new Uint8Array([50, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkAdd1, marker)).toEqual(new Uint8Array([51, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkSet0, cpu)).toEqual(new Uint8Array([12, 0, 0, 0]));
		expect(world.componentBytesCopy(bulkSet1, cpu)).toEqual(new Uint8Array([13, 0, 0, 0]));
		expect(world.hasComponent(removeEntity, removable)).toBe(false);
		expect(world.isAlive(victim)).toBe(false);
		const childBytes = world.componentBytesCopy(entity, world.childOfComponent());
		expect(childBytes).not.toBeNull();
		const childView = new DataView(
			childBytes?.buffer ?? new ArrayBuffer(0),
			childBytes?.byteOffset ?? 0,
			childBytes?.byteLength ?? 0,
		);
		expect(childView.getUint32(0, true)).toBe(parent.index());
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		const cameraWrites = world.drainCameraBlobWriteViews();
		expect(
			getF32(cameraWrites[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.25);
	});


	it("round-trips compound history invariants through TypeScript wrapper", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryInvariantCpu", 4);
		const bulk = world.registerCpuComponent("TsHistoryInvariantBulk", 4);
		const bulk0 = world.createEntity();
		const bulk1 = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(world.addComponentBytes(bulk0, bulk, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(bulk1, bulk, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(history.beginTransaction("TS history invariant compound")).toBe(true);
		const parent = history.createEntity(world);
		const entity = history.createEntity(world);
		const camera = history.createEntity(world);
		expect(history.addComponentBytes(world, entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(
			history.setComponentBytesMany(
				world,
				bulk,
				[bulk0, bulk1],
				[new Uint8Array([3, 0, 0, 0]), new Uint8Array([4, 0, 0, 0])],
			),
		).toBe(true);
		expect(history.setTransformTrs(world, entity, 4, 5, 6, 0, 0, 0, 1, 1, 1, 1)).toBe(true);
		expect(history.setChildOf(world, entity, parent)).toBe(true);
		expect(history.setGlobalTransform(world, entity, translationMat4ColMajor(1, 2, 3))).toBe(true);
		expect(history.setGlobalTransformFormat(world, entity, 1)).toBe(true);
		expect(history.setCameraMatrices(world, camera, identity, identity, 0.25, 100, 1.5, 0, 2)).toBe(true);
		expect(history.commitTransaction()).toBe(true);
		expect(history.undoLen()).toBe(1);
		expect(history.redoLen()).toBe(0);

		expect(history.undo(world)).toBe(true);
		expect(history.undoLen()).toBe(0);
		expect(history.redoLen()).toBe(1);
		expect(world.isAlive(parent)).toBe(false);
		expect(world.isAlive(entity)).toBe(false);
		expect(world.isAlive(camera)).toBe(false);
		expect(world.componentBytesCopy(bulk0, bulk)).toEqual(new Uint8Array([1, 0, 0, 0]));
		expect(world.componentBytesCopy(bulk1, bulk)).toEqual(new Uint8Array([2, 0, 0, 0]));

		expect(history.redo(world)).toBe(true);
		expect(history.undoLen()).toBe(1);
		expect(history.redoLen()).toBe(0);
		expect(world.isAlive(parent)).toBe(true);
		expect(world.isAlive(entity)).toBe(true);
		expect(world.isAlive(camera)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));
		expect(world.componentBytesCopy(bulk0, bulk)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(world.componentBytesCopy(bulk1, bulk)).toEqual(new Uint8Array([4, 0, 0, 0]));
		const childBytes = world.componentBytesCopy(entity, world.childOfComponent());
		expect(childBytes).not.toBeNull();
		const childView = new DataView(
			childBytes?.buffer ?? new ArrayBuffer(0),
			childBytes?.byteOffset ?? 0,
			childBytes?.byteLength ?? 0,
		);
		expect(childView.getUint32(0, true)).toBe(parent.index());
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(1);
		const global = world.getGlobalTransform(entity);
		expect(global).not.toBeNull();
		expect(global?.[12]).toBeCloseTo(1);
		expect(global?.[13]).toBeCloseTo(2);
		expect(global?.[14]).toBeCloseTo(3);
		const cameraRow = world.cameraGpuRowCopy(camera);
		expect(cameraRow).not.toBeNull();
		expect(getF32(cameraRow ?? new Uint8Array(), 268)).toBeCloseTo(0.25);
		expect(getF32(cameraRow ?? new Uint8Array(), 276)).toBeCloseTo(1.5);
		expect(getF32(cameraRow ?? new Uint8Array(), 284)).toBeCloseTo(2);
	});


	it("tracks undo and redo through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryCpu", 4);
		const entity = history.createEntity(world);

		expect(world.isAlive(entity)).toBe(true);
		expect(history.addComponentBytes(world, entity, cpu, new Uint8Array([1, 2, 3, 4]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([5, 6, 7, 8]))).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([5, 6, 7, 8]));

		expect(history.undo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([1, 2, 3, 4]));
		expect(history.redo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([5, 6, 7, 8]));

		expect(history.destroyEntity(world, entity)).toBe(true);
		expect(world.isAlive(entity)).toBe(false);
		expect(history.undo(world)).toBe(true);
		expect(world.isAlive(entity)).toBe(true);
		expect(entity.generation()).toBe(0);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([5, 6, 7, 8]));
	});


	it("tracks batch entity creation and component adds through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryBatchAuthoringCpu", 4);
		const entities = history.createEntities(world, 2);

		expect(entities).toHaveLength(2);
		expect(world.isAlive(entities[0])).toBe(true);
		expect(world.isAlive(entities[1])).toBe(true);
		expect(
			history.addComponentBytesMany(
				world,
				cpu,
				entities,
				[new Uint8Array([1, 0, 0, 0]), new Uint8Array([2, 0, 0, 0])],
			),
		).toBe(true);
		expect(history.undoLabel()).toBe("add_component_bytes_many");
		expect(world.componentBytesCopy(entities[0], cpu)).toEqual(new Uint8Array([1, 0, 0, 0]));
		expect(world.componentBytesCopy(entities[1], cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));

		expect(history.undo(world)).toBe(true);
		expect(world.hasComponent(entities[0], cpu)).toBe(false);
		expect(world.hasComponent(entities[1], cpu)).toBe(false);
		expect(history.undo(world)).toBe(true);
		expect(world.isAlive(entities[0])).toBe(false);
		expect(world.isAlive(entities[1])).toBe(false);

		expect(history.redo(world)).toBe(true);
		expect(world.isAlive(entities[0])).toBe(true);
		expect(world.isAlive(entities[1])).toBe(true);
		expect(history.redo(world)).toBe(true);
		expect(world.componentBytesCopy(entities[0], cpu)).toEqual(new Uint8Array([1, 0, 0, 0]));
		expect(world.componentBytesCopy(entities[1], cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));
	});


	it("tracks spawnBatch rows through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpuA = world.registerCpuComponent("TsHistorySpawnBatchA", 4);
		const cpuB = world.registerCpuComponent("TsHistorySpawnBatchB", 4);

		const entities = history.spawnBatch(world, [cpuB, cpuA], 2, (index, entity, row) => {
			expect(row.entity().index()).toBe(entity.index());
			row.write(cpuA, (bytes) => bytes.setF32(0, index + 1));
			row.write(cpuB, (bytes) => bytes.setF32(0, index + 10));
		});

		expect(entities).toHaveLength(2);
		expect(history.undoLabel()).toBe("spawn_batch");
		expect(getF32(world.componentBytesCopy(entities[1], cpuA) ?? new Uint8Array(), 0)).toBeCloseTo(2);
		expect(getF32(world.componentBytesCopy(entities[1], cpuB) ?? new Uint8Array(), 0)).toBeCloseTo(11);
		expect(history.undo(world)).toBe(true);
		expect(world.isAlive(entities[0])).toBe(false);
		expect(world.isAlive(entities[1])).toBe(false);
		expect(history.redo(world)).toBe(true);
		expect(getF32(world.componentBytesCopy(entities[1], cpuA) ?? new Uint8Array(), 0)).toBeCloseTo(2);
		expect(getF32(world.componentBytesCopy(entities[1], cpuB) ?? new Uint8Array(), 0)).toBeCloseTo(11);

		expect(() =>
			history.spawnBatch(world, [cpuA, cpuA], 1, () => {
				// Duplicate components follow raw World.spawnBatch and abort.
			}),
		).toThrow();
	});


	it("tracks bulk component byte changes through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryBulkCpu", 4);
		const e0 = world.createEntity();
		const e1 = world.createEntity();
		const missing = world.createEntity();

		expect(world.addComponentBytes(e0, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(e1, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(
			history.setComponentBytesMany(
				world,
				cpu,
				[e0, e1],
				[new Uint8Array([3, 0, 0, 0]), new Uint8Array([4, 0, 0, 0])],
			),
		).toBe(true);
		expect(history.undoLabel()).toBe("set_component_bytes_many");
		expect(world.componentBytesCopy(e0, cpu)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(world.componentBytesCopy(e1, cpu)).toEqual(new Uint8Array([4, 0, 0, 0]));
		expect(history.undo(world)).toBe(true);
		expect(world.componentBytesCopy(e0, cpu)).toEqual(new Uint8Array([1, 0, 0, 0]));
		expect(world.componentBytesCopy(e1, cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));
		expect(history.redo(world)).toBe(true);
		expect(world.componentBytesCopy(e0, cpu)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(world.componentBytesCopy(e1, cpu)).toEqual(new Uint8Array([4, 0, 0, 0]));

		expect(
			history.setComponentBytesMany(
				world,
				cpu,
				[e0, missing],
				[new Uint8Array([5, 0, 0, 0]), new Uint8Array([6, 0, 0, 0])],
			),
		).toBe(false);
		expect(world.componentBytesCopy(e0, cpu)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(world.componentBytesCopy(missing, cpu)).toBeNull();
		expect(
			history.setComponentBytesMany(
				world,
				cpu,
				[e0, e0],
				[new Uint8Array([7, 0, 0, 0]), new Uint8Array([8, 0, 0, 0])],
			),
		).toBe(false);
		expect(history.lastDiagnostic()).toBe("operation_failed");
		expect(world.componentBytesCopy(e0, cpu)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(() =>
			history.setComponentBytesMany(
				world,
				cpu,
				[e0],
				[new Uint8Array([7, 0, 0, 0]), new Uint8Array([8, 0, 0, 0])],
			),
		).toThrow();
	});


	it("rejects invalid bulk component adds through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryBulkAddInvalidCpu", 4);
		const e0 = world.createEntity();
		const e1 = world.createEntity();

		expect(world.addComponentBytes(e1, cpu, new Uint8Array([9, 0, 0, 0]))).toBe(true);
		expect(
			history.addComponentBytesMany(
				world,
				cpu,
				[e0, e1],
				[new Uint8Array([1, 0, 0, 0]), new Uint8Array([2, 0, 0, 0])],
			),
		).toBe(false);
		expect(history.lastDiagnostic()).toBe("operation_failed");
		expect(history.undoLen()).toBe(0);
		expect(world.hasComponent(e0, cpu)).toBe(false);
		expect(world.componentBytesCopy(e1, cpu)).toEqual(new Uint8Array([9, 0, 0, 0]));

		expect(
			history.addComponentBytesMany(
				world,
				cpu,
				[e0, e0],
				[new Uint8Array([1, 0, 0, 0]), new Uint8Array([2, 0, 0, 0])],
			),
		).toBe(false);
		expect(world.hasComponent(e0, cpu)).toBe(false);
		expect(() =>
			history.addComponentBytesMany(
				world,
				cpu,
				[e0],
				[new Uint8Array([1, 0, 0, 0]), new Uint8Array([2, 0, 0, 0])],
			),
		).toThrow();
	});


});
