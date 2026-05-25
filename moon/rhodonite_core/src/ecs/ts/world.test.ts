// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from "vitest";
import {
	ComponentTypeId,
	GpuLayout,
	EntityId,
	PhaseKey,
	Query,
	RawQuery,
	System,
	SystemContext,
	SystemRunner,
	World,
	WorldHistory,
	getF32,
} from "./index.ts";

function f32Bytes(values: number[], stride = values.length * 4): Uint8Array {
	const bytes = new Uint8Array(stride);
	const view = new DataView(bytes.buffer);
	values.forEach((value, index) => view.setFloat32(index * 4, value, true));
	return bytes;
}

function identityMat4ColMajor(): number[] {
	return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
}

function translationMat4ColMajor(tx: number, ty: number, tz: number): number[] {
	return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, tx, ty, tz, 1];
}

function globalTransformFormatCode(refs: Uint8Array): number {
	return new DataView(refs.buffer, refs.byteOffset, refs.byteLength).getUint32(
		0,
		true,
	);
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
				expect(bytes.asUint8Array()).not.toBeNull();
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

	it("tracks query row writes through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TrackedPosition", 16);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);

		Query.new([cpu]).forEach(world, (row) => {
			expect(
				row.writeTracked(history, cpu, (bytes) => {
					bytes.setF32(0, 12);
				}),
			).toBe(true);
		});

		expect(history.undoLabel()).toBe("query_row_write");
		expect(
			getF32(world.componentBytesCopy(entity, cpu) ?? new Uint8Array(), 0),
		).toBeCloseTo(12);
		expect(history.undo(world)).toBe(true);
		expect(
			getF32(world.componentBytesCopy(entity, cpu) ?? new Uint8Array(), 0),
		).toBeCloseTo(1);
		expect(history.redo(world)).toBe(true);
		expect(
			getF32(world.componentBytesCopy(entity, cpu) ?? new Uint8Array(), 0),
		).toBeCloseTo(12);
	});

	it("tracks raw query row callback writes and delegates when history is disabled", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TrackedRawPosition", 16);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);

		RawQuery.new([cpu]).forEach(world, (row) => {
			expect(row.writeTracked(history, cpu, (bytes) => bytes.setF32(0, 4))).toBe(
				true,
			);
		});
		expect(history.undoLen()).toBe(1);
		expect(history.undo(world)).toBe(true);

		history.setMaxUndoRecords(0);
		RawQuery.new([cpu]).forEach(world, (row) => {
			expect(row.writeTracked(history, cpu, (bytes) => bytes.setF32(0, 8))).toBe(
				true,
			);
		});
		expect(history.lastDiagnostic()).toBe("recording_disabled");
		expect(history.undoLen()).toBe(0);
		expect(
			getF32(world.componentBytesCopy(entity, cpu) ?? new Uint8Array(), 0),
		).toBeCloseTo(8);
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

	it("tracks archetype column callback writes through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TrackedVelocity", 16);
		const e0 = world.createEntity();
		const e1 = world.createEntity();
		expect(world.addComponentBytes(e0, cpu, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpu, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);

		RawQuery.new([cpu]).forEachArchetype(world, (archetype) => {
			expect(
				archetype.writeColumnTracked(history, cpu, (column) => {
					column.setF32(0, 10);
				}),
			).toBe(true);
		});

		expect(history.undoLabel()).toBe("raw_query_archetype_write_column");
		expect(history.undoBytes()).toBe(32);
		expect(getF32(world.componentBytesCopy(e0, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(10);
		expect(getF32(world.componentBytesCopy(e1, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(2);
		expect(history.undo(world)).toBe(true);
		expect(getF32(world.componentBytesCopy(e0, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(1);
		expect(history.redo(world)).toBe(true);
		expect(getF32(world.componentBytesCopy(e0, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(10);

		history.setMaxUndoRecords(0);
		RawQuery.new([cpu]).forEachArchetype(world, (archetype) => {
			expect(
				archetype.writeColumnTracked(history, cpu, (column) => {
					column.setF32(16, 20);
				}),
			).toBe(true);
		});
		expect(history.lastDiagnostic()).toBe("recording_disabled");
		expect(history.undoLen()).toBe(0);
		expect(getF32(world.componentBytesCopy(e1, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(20);
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

	it("supports builtin transform/global transform upload helpers", () => {
		const world = World.new();
		const [entity] = world.spawnTransformGlobalBatchIdentity(1);
		expect(entity).toBeDefined();

		world.updateGlobalTransformsFromTransforms();
		expect(Array.from(world.getGlobalTransform(entity!) ?? [])).toEqual(
			identityMat4ColMajor(),
		);
		const writes = world.drainGlobalTransformBlobWriteViews();
		expect(writes.length).toBeGreaterThan(0);
		expect(writes[0]?.bytes().asUint8Array()).toBeInstanceOf(Uint8Array);
	});

	it("tracks builtin global transform matrices through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const entity = world.createEntity();

		expect(
			history.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(1, 2, 3),
			),
		).toBe(true);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			true,
		);
		let writes = world.drainGlobalTransformBlobWriteViews();
		expect(writes).toHaveLength(1);
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 12),
		).toBeCloseTo(1);

		expect(history.undo(world)).toBe(true);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			false,
		);
		expect(history.redo(world)).toBe(true);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			true,
		);
		writes = world.drainGlobalTransformBlobWriteViews();
		expect(writes.length).toBeGreaterThan(0);
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 12),
		).toBeCloseTo(1);

		expect(
			history.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(4, 5, 6),
			),
		).toBe(true);
		writes = world.drainGlobalTransformBlobWriteViews();
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 12),
		).toBeCloseTo(4);
		expect(history.undo(world)).toBe(true);
		writes = world.drainGlobalTransformBlobWriteViews();
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 12),
		).toBeCloseTo(1);
		expect(history.redo(world)).toBe(true);
		writes = world.drainGlobalTransformBlobWriteViews();
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 12),
		).toBeCloseTo(4);

		history.setMaxUndoRecords(0);
		expect(
			history.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(7, 8, 9),
			),
		).toBe(true);
		expect(history.lastDiagnostic()).toBe("recording_disabled");
		expect(history.undoLen()).toBe(0);
	});

	it("tracks builtin global transform format through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const entity = world.createEntity();

		expect(history.setGlobalTransformFormat(world, entity, 1)).toBe(true);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			true,
		);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		expect(history.undo(world)).toBe(true);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			false,
		);
		expect(history.redo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);

		expect(
			history.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(4, 5, 6),
			),
		).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		expect(history.setGlobalTransformFormat(world, entity, 0)).toBe(true);
		let writes = world.drainGlobalTransformBlobWriteViews();
		expect(writes[0]?.bytes().asUint8Array()?.byteLength).toBe(48);
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 12),
		).toBeCloseTo(4);
		expect(history.undo(world)).toBe(true);
		writes = world.drainGlobalTransformBlobWriteViews();
		expect(writes[0]?.bytes().asUint8Array()?.byteLength).toBe(24);
		expect(history.redo(world)).toBe(true);
		writes = world.drainGlobalTransformBlobWriteViews();
		expect(writes[0]?.bytes().asUint8Array()?.byteLength).toBe(48);
		expect(history.setGlobalTransformFormat(world, entity, 0)).toBe(true);
		expect(history.lastDiagnostic()).toBe("transaction_empty");
	});

	it("sets builtin ChildOf parent links", () => {
		const world = World.new();
		const parent = world.createEntity();
		const child = world.createEntity();

		expect(world.setChildOf(child, parent)).toBe(true);
		const bytes = world.componentBytesCopy(child, world.childOfComponent());
		expect(bytes).not.toBeNull();
		const view = new DataView(
			bytes?.buffer ?? new ArrayBuffer(0),
			bytes?.byteOffset ?? 0,
			bytes?.byteLength ?? 0,
		);
		expect(view.getUint32(0, true)).toBe(parent.index());
		expect(view.getUint32(4, true)).toBe(parent.generation());
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

	it("updates builtin camera matrices through the packed camera blob", () => {
		const world = World.new();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 50, 1.333, 1, 0),
		).toBe(true);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(true);
		expect(world.cameraBlobWordCapacity()).toBeGreaterThanOrEqual(72);

		const writes = world.drainCameraBlobWriteViews();
		expect(writes).toHaveLength(1);
		const row = writes[0]?.bytes().asUint8Array();
		expect(row).toBeInstanceOf(Uint8Array);
		expect(row?.byteLength).toBe(72 * 4);
		expect(getF32(row ?? new Uint8Array(), 0)).toBeCloseTo(1);
		expect(getF32(row ?? new Uint8Array(), 20)).toBeCloseTo(1);
	});

	it("tracks builtin camera matrices through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(
			history.setCameraMatrices(
				world,
				camera,
				identity,
				identity,
				0.1,
				50,
				1,
				1,
				0,
			),
		).toBe(true);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(true);
		let writes = world.drainCameraBlobWriteViews();
		expect(writes).toHaveLength(1);
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.1);

		expect(history.undo(world)).toBe(true);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(false);
		expect(history.redo(world)).toBe(true);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(true);
		writes = world.drainCameraBlobWriteViews();
		expect(writes.length).toBeGreaterThan(0);

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
		writes = world.drainCameraBlobWriteViews();
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.25);
		expect(history.undo(world)).toBe(true);
		writes = world.drainCameraBlobWriteViews();
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.1);
		expect(history.redo(world)).toBe(true);
		writes = world.drainCameraBlobWriteViews();
		expect(
			getF32(writes[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.25);
	});

	it("exposes builtin orbit camera component ids", () => {
		const world = World.new();

		expect(world.orbitCameraControllerComponent().index()).toBe(4);
		expect(world.cameraHomeTransformComponent().index()).toBe(5);
		expect(world.cameraLensComponent().index()).toBe(6);
	});

	it("runs TS systems with command-buffered component writes", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("TsSystemCpu", 4);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);

		const phase = PhaseKey.new("ts/update");
		const ctx = SystemContext.new(0.016, 7);
		const runner = SystemRunner.new();
		runner.addSystem(
			System.new("write-cpu", phase, [], [cpu], (systemWorld, systemCtx, commands) => {
				expect(systemWorld.isAlive(entity)).toBe(true);
				expect(systemCtx.deltaSeconds()).toBeCloseTo(0.016);
				expect(systemCtx.frameIndex()).toBe(7);
				expect(commands.isEmpty()).toBe(true);
				commands.setComponentBytes(entity, cpu, new Uint8Array([9, 0, 0, 0]));
				expect(commands.len()).toBe(1);
			}),
		);

		expect(runner.len()).toBe(1);
		expect(runner.runPhase(world, ctx, phase)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([9, 0, 0, 0]));
	});

	it("exposes structural TS systems and tracked system phases", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsTrackedSystemCpu", 4);
		const phase = PhaseKey.new("ts/tracked");
		const runner = SystemRunner.new();
		let createdIndex = -1;

		runner.addSystem(
			System.newWithStructuralWrite("spawn-cpu", phase, [], [cpu], (_world, _ctx, commands) => {
				const entity = commands.createEntity();
				createdIndex = entity.index();
				commands.addComponentBytes(entity, cpu, new Uint8Array([4, 0, 0, 0]));
			}),
		);

		expect(
			history.runSystemPhase(
				runner,
				world,
				SystemContext.new(0.016, 1),
				phase,
				"spawn from TS system",
			),
		).toBe(true);
		const createdEntity = EntityId.new(createdIndex, 0);
		const created = world.location(createdEntity);
		expect(created).not.toBeNull();
		expect(history.undo(world)).toBe(true);
		expect(world.isAlive(createdEntity)).toBe(false);
	});

	it("tracks TS system command-buffer writes through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsTrackedSystemWriteCpu", 4);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);

		const phase = PhaseKey.new("ts/tracked-write");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.new("tracked-write-cpu", phase, [], [cpu], (_world, _ctx, commands) => {
				commands.setComponentBytes(entity, cpu, new Uint8Array([6, 0, 0, 0]));
			}),
		);

		expect(
			history.runSystemPhase(
				runner,
				world,
				SystemContext.new(0.016, 2),
				phase,
				"tracked TS write",
			),
		).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([6, 0, 0, 0]),
		);
		expect(history.undoLabel()).toBe("tracked TS write");
		expect(history.undo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([1, 0, 0, 0]),
		);
		expect(history.redo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([6, 0, 0, 0]),
		);
	});

	it("applies TS command-buffer builtin blob writes in raw system phases", () => {
		const world = World.new();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();
		expect(world.setGlobalTransform(entity, identity)).toBe(true);
		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 10, 1, 1, 0),
		).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		const phase = PhaseKey.new("ts/raw-builtin-commands");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.new(
				"raw-builtin-commands",
				phase,
				[],
				[world.globalTransformComponent(), world.cameraComponent()],
				(_world, _ctx, commands) => {
					commands.setGlobalTransform(
						entity,
						translationMat4ColMajor(2, 3, 4),
					);
					commands.setGlobalTransformFormat(entity, 1);
					commands.setCameraMatrices(
						camera,
						identity,
						identity,
						0.25,
						50,
						1.5,
						0,
						2,
					);
				},
			),
		);

		expect(runner.runPhase(world, SystemContext.new(0.016, 3), phase)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		const cameraWrites = world.drainCameraBlobWriteViews();
		expect(
			getF32(cameraWrites[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.25);
	});

	it("tracks TS command-buffer builtin blob writes through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();
		expect(world.setGlobalTransform(entity, identity)).toBe(true);
		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 10, 1, 1, 0),
		).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		const phase = PhaseKey.new("ts/tracked-builtin-commands");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.new(
				"tracked-builtin-commands",
				phase,
				[],
				[world.globalTransformComponent(), world.cameraComponent()],
				(_world, _ctx, commands) => {
					commands.setGlobalTransform(
						entity,
						translationMat4ColMajor(5, 6, 7),
					);
					commands.setGlobalTransformFormat(entity, 1);
					commands.setCameraMatrices(
						camera,
						identity,
						identity,
						0.3,
						60,
						2,
						0,
						3,
					);
				},
			),
		);

		expect(
			history.runSystemPhase(
				runner,
				world,
				SystemContext.new(0.016, 4),
				phase,
				"tracked TS builtin commands",
			),
		).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		let cameraWrites = world.drainCameraBlobWriteViews();
		expect(
			getF32(cameraWrites[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.3);

		expect(history.undo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			0,
		);
		cameraWrites = world.drainCameraBlobWriteViews();
		expect(
			getF32(cameraWrites[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.1);
		expect(history.redo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
	});

	it("requires structural write for command-buffer builtin add paths", () => {
		const world = World.new();
		const entity = world.createEntity();
		const phase = PhaseKey.new("ts/builtin-command-structural");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.new(
				"builtin-command-missing-component",
				phase,
				[],
				[world.globalTransformComponent()],
				(_world, _ctx, commands) => {
					commands.setGlobalTransform(entity, identityMat4ColMajor());
				},
			),
		);

		expect(() =>
			runner.runPhase(world, SystemContext.new(0.016, 5), phase),
		).toThrow();
	});

	it("exposes payload-free undo and redo summaries", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistorySummaryCpu", 4);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);

		expect(history.beginTransaction("TS summary change")).toBe(true);
		expect(
			history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0])),
		).toBe(true);
		expect(history.commitTransaction()).toBe(true);
		expect(history.beginTransaction("TS summary destroy")).toBe(true);
		expect(history.destroyEntity(world, entity)).toBe(true);
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
		expect(summaries[0]?.deltas[0]?.entity?.index()).toBe(entity.index());
		expect(summaries[1]).toMatchObject({
			label: "TS summary change",
			deltaCount: 1,
			payloadBytes: 8,
		});
		expect(summaries[1]?.deltas[0]).toMatchObject({
			kind: "component_changed",
			componentCount: 0,
			payloadBytes: 8,
			beforePresent: true,
			afterPresent: true,
		});
		expect(summaries[1]?.deltas[0]?.entity?.index()).toBe(entity.index());
		expect(summaries[1]?.deltas[0]?.component?.index()).toBe(cpu.index());
		expect(history.lastDiagnostic()).toBe(diagnostic);
		expect(history.undoLen()).toBe(2);
		expect(history.redoLen()).toBe(0);

		expect(history.undo(world)).toBe(true);
		const redoSummaries = history.redoSummary();
		expect(redoSummaries).toHaveLength(1);
		expect(redoSummaries[0]?.label).toBe("TS summary destroy");
		expect(redoSummaries[0]?.deltas[0]?.kind).toBe("entity_destroyed");
	});

	it("reports history serialization eligibility without exposing payloads", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const stable = world.registerCpuComponentWithIdentity(
			"TsHistorySerializableStable",
			4,
			{
				stableKey: "com.example.TsHistorySerializableStable",
				schemaVersion: "1",
				schemaHash: "sha256:ts-history-serializable-stable",
			},
		);
		const legacy = world.registerCpuComponent("TsHistorySerializableLegacy", 4);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, stable, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			world.addComponentBytes(entity, legacy, new Uint8Array([2, 0, 0, 0])),
		).toBe(true);

		expect(history.beginTransaction("TS serialization eligibility")).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				entity,
				stable,
				new Uint8Array([3, 0, 0, 0]),
			),
		).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				entity,
				legacy,
				new Uint8Array([4, 0, 0, 0]),
			),
		).toBe(true);
		expect(history.commitTransaction()).toBe(true);

		const diagnostic = history.lastDiagnostic();
		const report = history.undoSerializationReport(world);
		expect(report.serializable).toBe(false);
		expect(report.recordCount).toBe(1);
		expect(report.records[0]).toMatchObject({
			label: "TS serialization eligibility",
			serializable: false,
			reason: "missing_stable_component_identity",
			deltaCount: 2,
			payloadBytes: 16,
		});
		expect(report.records[0]?.deltas[0]).toMatchObject({
			kind: "component_changed",
			serializable: true,
			reason: "none",
			payloadBytes: 8,
		});
		expect(report.records[0]?.deltas[0]?.components[0]).toMatchObject({
			serializable: true,
			reason: "none",
			stableKey: "com.example.TsHistorySerializableStable",
		});
		expect(report.records[0]?.deltas[1]).toMatchObject({
			kind: "component_changed",
			serializable: false,
			reason: "missing_stable_component_identity",
			payloadBytes: 8,
		});
		expect(report.records[0]?.deltas[1]?.components[0]).toMatchObject({
			serializable: false,
			reason: "missing_stable_component_identity",
			stableKey: null,
		});
		expect(report.records[0]?.deltas[1]?.component?.index()).toBe(legacy.index());
		expect(history.lastDiagnostic()).toBe(diagnostic);
		expect(history.undoLen()).toBe(1);
		expect(history.redoLen()).toBe(0);

		expect(history.undo(world)).toBe(true);
		const redoReport = history.redoSerializationReport(world);
		expect(redoReport.serializable).toBe(false);
		expect(redoReport.records[0]?.label).toBe("TS serialization eligibility");
	});

	it("audits direct WorldHistory mutation coverage", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryCoverageCpu", 4);
		const parent = world.createEntity();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(history.beginTransaction("TS coverage direct")).toBe(true);
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
		expect(history.commitTransaction()).toBe(true);
		expect(history.undoLabel()).toBe("TS coverage direct");
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([2, 0, 0, 0]),
		);
		expect(world.hasComponent(entity, world.transformComponent())).toBe(true);
		expect(world.hasComponent(entity, world.childOfComponent())).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		expect(history.undo(world)).toBe(true);
		expect(world.hasComponent(entity, cpu)).toBe(false);
		expect(world.hasComponent(entity, world.transformComponent())).toBe(false);
		expect(world.hasComponent(entity, world.childOfComponent())).toBe(false);
		expect(world.hasComponent(entity, world.globalTransformComponent())).toBe(
			false,
		);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(false);

		expect(history.redo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([2, 0, 0, 0]),
		);
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

	it("clears history when disabled", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryDisabled", 4);
		const entity = world.createEntity();

		history.setEnabled(false);
		expect(history.enabled()).toBe(false);
		expect(history.addComponentBytes(world, entity, cpu, new Uint8Array([9, 9, 9, 9]))).toBe(true);
		expect(world.hasComponent(entity, cpu)).toBe(true);
		expect(history.canUndo()).toBe(false);
	});

	it("limits WorldHistory undo records and exposes stack lengths", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryLimit", 4);
		const entity = world.createEntity();

		expect(history.lastDiagnostic()).toBe("none");
		expect(history.undo(world)).toBe(false);
		expect(history.lastDiagnostic()).toBe("empty_undo_stack");
		expect(history.maxUndoRecords()).toBe(100);
		expect(history.maxUndoBytes()).toBe(0);
		history.setMaxUndoRecords(2);
		expect(history.maxUndoRecords()).toBe(2);
		expect(history.undoLen()).toBe(0);
		expect(history.redoLen()).toBe(0);
		expect(history.undoBytes()).toBe(0);
		expect(history.redoBytes()).toBe(0);

		expect(
			world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([3, 0, 0, 0]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([4, 0, 0, 0]))).toBe(true);
		expect(history.undoLen()).toBe(2);
		expect(history.undoBytes()).toBe(16);
		expect(history.lastDiagnostic()).toBe("stack_trimmed_record_limit");

		expect(history.undo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(history.undoLen()).toBe(1);
		expect(history.redoLen()).toBe(1);
		expect(history.undoBytes()).toBe(8);
		expect(history.redoBytes()).toBe(8);
		expect(history.lastDiagnostic()).toBe("none");
		expect(history.undo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));
		expect(history.canUndo()).toBe(false);
	});

	it("limits WorldHistory retained payload bytes", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryByteLimit", 4);
		const entity = world.createEntity();

		history.setMaxUndoBytes(8);
		expect(history.maxUndoBytes()).toBe(8);
		expect(() => history.setMaxUndoBytes(-1)).toThrow();
		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([3, 0, 0, 0]))).toBe(true);
		expect(history.undoLen()).toBe(1);
		expect(history.undoBytes()).toBe(8);
		expect(history.lastDiagnostic()).toBe("stack_trimmed_byte_limit");
		expect(history.undo(world)).toBe(true);
		expect(history.redoBytes()).toBe(8);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));

		history.setMaxUndoBytes(4);
		expect(history.redoLen()).toBe(0);
		expect(history.lastDiagnostic()).toBe("stack_trimmed_byte_limit");
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([4, 0, 0, 0]))).toBe(true);
		expect(history.undoLen()).toBe(0);
		expect(history.undoBytes()).toBe(0);
		expect(history.lastDiagnostic()).toBe("record_dropped_byte_limit");
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([4, 0, 0, 0]));
	});

	it("exposes WorldHistory undo and redo labels", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryLabels", 4);
		const entity = world.createEntity();

		expect(history.undoLabel()).toBeNull();
		expect(history.redoLabel()).toBeNull();
		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(history.beginTransaction("Move Entity")).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(history.undoLabel()).toBeNull();
		expect(history.commitTransaction()).toBe(true);
		expect(history.undoLabel()).toBe("Move Entity");
		expect(history.redoLabel()).toBeNull();

		expect(history.beginTransaction("")).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([3, 0, 0, 0]))).toBe(true);
		expect(history.commitTransaction()).toBe(true);
		expect(history.undoLabel()).toBe("");
		expect(history.undo(world)).toBe(true);
		expect(history.undoLabel()).toBe("Move Entity");
		expect(history.redoLabel()).toBe("");
		history.clear();
		expect(history.undoLabel()).toBeNull();
		expect(history.redoLabel()).toBeNull();
	});

	it("treats zero max undo records as unrecorded tracked changes", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryZeroLimit", 4);
		const entity = world.createEntity();

		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(history.undoLen()).toBe(1);
		history.setMaxUndoRecords(0);
		expect(history.maxUndoRecords()).toBe(0);
		expect(history.undoLen()).toBe(0);
		expect(history.beginTransaction("no-records")).toBe(false);
		expect(history.setComponentBytes(world, entity, cpu, new Uint8Array([3, 0, 0, 0]))).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([3, 0, 0, 0]));
		expect(history.canUndo()).toBe(false);
	});

	it("guards raw World mutations during guarded WorldHistory transactions", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsHistoryRawGuard", 4);
		const entity = world.createEntity();

		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(history.rawMutationGuardEnabled()).toBe(false);
		history.setRawMutationGuardEnabled(true);
		expect(history.rawMutationGuardEnabled()).toBe(true);
		expect(history.beginGuardedTransaction(world, "guarded edit")).toBe(true);
		expect(() =>
			world.setComponentBytes(entity, cpu, new Uint8Array([9, 0, 0, 0])),
		).toThrow();
		expect(() =>
			world.spawnBatch([cpu], 1, (_index, _entity, row) => {
				row.write(cpu, (bytes) => bytes.setF32(0, 42));
			}),
		).toThrow();
		expect(() =>
			SystemRunner.new().runPhase(
				world,
				SystemContext.new(0.016, 1),
				PhaseKey.new("ts/raw-run-phase-guard"),
			),
		).toThrow();
		expect(
			history.setComponentBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0])),
		).toBe(true);
		expect(
			history.spawnBatch(world, [cpu], 1, (_index, _entity, row) => {
				row.write(cpu, (bytes) => bytes.setF32(0, 7));
			}),
		).toHaveLength(1);
		expect(history.commitTransaction()).toBe(true);
		expect(
			world.setComponentBytes(entity, cpu, new Uint8Array([3, 0, 0, 0])),
		).toBe(true);

		expect(history.beginGuardedTransaction(world, "guarded cancel")).toBe(true);
		expect(() => world.removeComponent(entity, cpu)).toThrow();
		expect(history.cancelTransaction()).toBe(true);
		expect(world.removeComponent(entity, cpu)).toBe(true);

		const queryWorld = World.new();
		const queryHistory = WorldHistory.new();
		const queryCpu = queryWorld.registerCpuComponent("TsHistoryRawGuardQuery", 4);
		const queryEntity = queryWorld.createEntity();
		expect(
			queryWorld.addComponentBytes(
				queryEntity,
				queryCpu,
				new Uint8Array([1, 0, 0, 0]),
			),
		).toBe(true);
		queryHistory.setRawMutationGuardEnabled(true);
		expect(
			queryHistory.beginGuardedTransaction(queryWorld, "guarded query"),
		).toBe(true);
		expect(() =>
			RawQuery.new([queryCpu]).forEachArchetype(queryWorld, (archetype) => {
				archetype.writeColumn(queryCpu);
			}),
		).toThrow();
		const trackedQueryWorld = World.new();
		const trackedQueryHistory = WorldHistory.new();
		const trackedQueryCpu = trackedQueryWorld.registerCpuComponent(
			"TsHistoryTrackedQuery",
			4,
		);
		const trackedQueryEntity = trackedQueryWorld.createEntity();
		expect(
			trackedQueryWorld.addComponentBytes(
				trackedQueryEntity,
				trackedQueryCpu,
				f32Bytes([1]),
			),
		).toBe(true);
		trackedQueryHistory.setRawMutationGuardEnabled(true);
		expect(
			trackedQueryHistory.beginGuardedTransaction(
				trackedQueryWorld,
				"guarded tracked query",
			),
		).toBe(true);
		Query.new([trackedQueryCpu]).forEach(trackedQueryWorld, (row) => {
			expect(
				row.writeTracked(
					trackedQueryHistory,
					trackedQueryCpu,
					(bytes) => bytes.setF32(0, 6),
				),
			).toBe(true);
		});
		expect(trackedQueryHistory.commitTransaction()).toBe(true);
		expect(trackedQueryHistory.undo(trackedQueryWorld)).toBe(true);
		expect(
			getF32(
				trackedQueryWorld.componentBytesCopy(
					trackedQueryEntity,
					trackedQueryCpu,
				) ?? new Uint8Array(),
				0,
			),
		).toBeCloseTo(1);

		const trackedColumnWorld = World.new();
		const trackedColumnHistory = WorldHistory.new();
		const trackedColumnCpu = trackedColumnWorld.registerCpuComponent(
			"TsHistoryTrackedColumn",
			4,
		);
		const trackedColumnEntity = trackedColumnWorld.createEntity();
		expect(
			trackedColumnWorld.addComponentBytes(
				trackedColumnEntity,
				trackedColumnCpu,
				f32Bytes([1]),
			),
		).toBe(true);
		trackedColumnHistory.setRawMutationGuardEnabled(true);
		expect(
			trackedColumnHistory.beginGuardedTransaction(
				trackedColumnWorld,
				"guarded tracked column",
			),
		).toBe(true);
		RawQuery.new([trackedColumnCpu]).forEachArchetype(
			trackedColumnWorld,
			(archetype) => {
				expect(
					archetype.writeColumnTracked(
						trackedColumnHistory,
						trackedColumnCpu,
						(bytes) => bytes.setF32(0, 5),
					),
				).toBe(true);
			},
		);
		expect(trackedColumnHistory.commitTransaction()).toBe(true);
		expect(trackedColumnHistory.undo(trackedColumnWorld)).toBe(true);
		expect(
			getF32(
				trackedColumnWorld.componentBytesCopy(
					trackedColumnEntity,
					trackedColumnCpu,
				) ?? new Uint8Array(),
				0,
			),
		).toBeCloseTo(1);

		const blobQueryWorld = World.new();
		const blobQueryHistory = WorldHistory.new();
		const blobQueryEntity = blobQueryWorld.createEntity();
		const blobQueryComponent = blobQueryWorld.globalTransformComponent();
		expect(
			blobQueryWorld.setGlobalTransform(blobQueryEntity, identityMat4ColMajor()),
		).toBe(true);
		blobQueryHistory.setRawMutationGuardEnabled(true);
		expect(
			blobQueryHistory.beginGuardedTransaction(
				blobQueryWorld,
				"guarded blob query",
			),
		).toBe(true);
		let sawBlobQuery = false;
		Query.new([blobQueryComponent]).forEach(blobQueryWorld, (row) => {
			expect(
				row.writeTracked(blobQueryHistory, blobQueryComponent, (bytes) => {
					sawBlobQuery = bytes.length > 0;
				}),
			).toBe(true);
		});
		expect(sawBlobQuery).toBe(true);
		expect(blobQueryHistory.commitTransaction()).toBe(true);
		expect(blobQueryHistory.lastDiagnostic()).toBe("transaction_empty");

		const blobColumnWorld = World.new();
		const blobColumnHistory = WorldHistory.new();
		const blobColumnEntity = blobColumnWorld.createEntity();
		const blobColumnComponent = blobColumnWorld.globalTransformComponent();
		expect(
			blobColumnWorld.setGlobalTransform(
				blobColumnEntity,
				identityMat4ColMajor(),
			),
		).toBe(true);
		blobColumnHistory.setRawMutationGuardEnabled(true);
		expect(
			blobColumnHistory.beginGuardedTransaction(
				blobColumnWorld,
				"guarded blob column",
			),
		).toBe(true);
		let sawBlobColumn = false;
		RawQuery.new([blobColumnComponent]).forEachArchetype(
			blobColumnWorld,
			(archetype) => {
				expect(
					archetype.writeColumnTracked(
						blobColumnHistory,
						blobColumnComponent,
						(bytes) => {
							sawBlobColumn = bytes.length > 0;
						},
					),
				).toBe(true);
			},
		);
		expect(sawBlobColumn).toBe(true);
		expect(blobColumnHistory.commitTransaction()).toBe(true);
		expect(blobColumnHistory.lastDiagnostic()).toBe("transaction_empty");
	});
});
