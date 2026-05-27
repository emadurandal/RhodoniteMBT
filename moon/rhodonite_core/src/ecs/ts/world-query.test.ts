// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	ComponentTypeId,
	EntityId,
	GpuLayout,
	PhaseKey,
	Query,
	QueryCache,
	RawQuery,
	RawQueryCache,
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

describe("ECS TypeScript wrapper: query", () => {
	it("queries CPU component rows without copying the backing storage", () => {
		const world = World.new();
		const cpu = world.registerComponent("Position", 16);
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
		const cpu = world.registerComponent("TrackedPosition", 16);
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
		const cpu = world.registerComponent("TrackedRawPosition", 16);
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
		const cpu = world.registerComponent("Velocity", 16);
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
		const cpu = world.registerComponent("TrackedVelocity", 16);
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


	it("tracks explicit archetype column rows through WorldHistory", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerComponent("TrackedVelocityRows", 16);
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
				archetype.writeColumnRowsTracked(history, cpu, [1], (_row, bytes) => {
					bytes.setF32(0, 20);
				}),
			).toBe(true);
		});

		expect(history.undoLabel()).toBe("raw_query_archetype_write_column_rows");
		expect(history.undoBytes()).toBe(32);
		expect(getF32(world.componentBytesCopy(e0, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(1);
		expect(getF32(world.componentBytesCopy(e1, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(20);
		expect(history.undo(world)).toBe(true);
		expect(getF32(world.componentBytesCopy(e1, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(2);
		expect(history.redo(world)).toBe(true);
		expect(getF32(world.componentBytesCopy(e1, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(20);
	});


	it("accepts empty explicit archetype column rows", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerComponent("TrackedVelocityRowsEmpty", 16);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);

		RawQuery.new([cpu]).forEachArchetype(world, (archetype) => {
			expect(
				archetype.writeColumnRowsTracked(history, cpu, [], (_row, bytes) => {
					bytes.setF32(0, 20);
				}),
			).toBe(true);
		});

		expect(history.undoLen()).toBe(0);
		expect(history.lastDiagnostic()).toBe("transaction_empty");
		expect(getF32(world.componentBytesCopy(entity, cpu) ?? new Uint8Array(), 0)).toBeCloseTo(1);
	});


	it("reuses prepared row query plans", () => {
		const world = World.new();
		const cpu = world.registerComponent("PreparedTsCpu", 16);
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

	it("exposes query plan diagnostics", () => {
		const world = World.new();
		const cpuA = world.registerComponent("PlanTsA", 16);
		const cpuB = world.registerComponent("PlanTsB", 16);
		const both = world.createEntity();
		const onlyA = world.createEntity();
		expect(world.addComponentBytes(both, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(both, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(onlyA, cpuA, f32Bytes([3, 0, 0, 0], 16))).toBe(
			true,
		);

		const plan = Query.new([cpuA, cpuB]).plan(world);
		expect(plan.requiredComponents().map((component) => component.index())).toEqual([
			cpuA.index(),
			cpuB.index(),
		]);
		expect(plan.candidateArchetypeCount()).toBe(1);
		expect(plan.matchedArchetypeCount()).toBe(1);
		expect(plan.matchedRowCount()).toBe(1);
		expect(plan.stale()).toBe(false);
		expect(plan.archetypes()).toHaveLength(1);
		expect(plan.archetypes()[0]?.rowCount()).toBe(1);

		const rawPlan = RawQuery.new([cpuA]).plan(world);
		expect(rawPlan.candidateArchetypeCount()).toBe(2);
		expect(rawPlan.matchedArchetypeCount()).toBe(2);
		expect(rawPlan.matchedRowCount()).toBe(2);
	});

	it("reports stale prepared query plan diagnostics", () => {
		const world = World.new();
		const cpuA = world.registerComponent("PreparedPlanTsA", 16);
		const cpuB = world.registerComponent("PreparedPlanTsB", 16);
		const prepared = Query.new([cpuA, cpuB]).prepare(world);
		expect(prepared.plan(world).stale()).toBe(false);

		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(entity, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);

		const stalePlan = prepared.plan(world);
		expect(stalePlan.stale()).toBe(true);
		expect(stalePlan.candidateArchetypeCount()).toBe(1);
		expect(stalePlan.matchedArchetypeCount()).toBe(1);
		expect(stalePlan.matchedRowCount()).toBe(1);
		expect(stalePlan.archetypes()[0]?.rowCount()).toBe(1);

		const rawPrepared = RawQuery.new([cpuA, cpuB]).prepare(world);
		expect(rawPrepared.plan(world).stale()).toBe(false);
	});

	it("refreshes stale prepared query plans", () => {
		const world = World.new();
		const cpuA = world.registerComponent("RefreshPlanTsA", 16);
		const cpuB = world.registerComponent("RefreshPlanTsB", 16);
		const prepared = Query.new([cpuA, cpuB]).prepare(world);
		expect(prepared.isStale(world)).toBe(false);

		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(entity, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(prepared.isStale(world)).toBe(true);
		expect(prepared.plan(world).stale()).toBe(true);

		const refreshed = prepared.refresh(world);
		expect(refreshed.isStale(world)).toBe(false);
		expect(refreshed.plan(world).stale()).toBe(false);
		expect(refreshed.plan(world).matchedRowCount()).toBe(1);

		let sum = 0;
		refreshed.forEach(world, (row) => {
			row.read(cpuA, (bytes) => {
				sum += bytes.getF32(0);
			});
		});
		expect(sum).toBeCloseTo(1);
	});

	it("refreshes stale raw prepared query plans", () => {
		const world = World.new();
		const cpuA = world.registerComponent("RawRefreshPlanTsA", 16);
		const cpuB = world.registerComponent("RawRefreshPlanTsB", 16);
		const prepared = RawQuery.new([cpuA, cpuB]).prepare(world);
		expect(prepared.isStale(world)).toBe(false);

		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpuA, f32Bytes([3, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(entity, cpuB, f32Bytes([4, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(prepared.isStale(world)).toBe(true);

		const refreshed = prepared.refresh(world);
		expect(refreshed.isStale(world)).toBe(false);
		expect(refreshed.plan(world).matchedRowCount()).toBe(1);
		let rows = 0;
		refreshed.forEachArchetype(world, (archetype) => {
			rows += archetype.length();
		});
		expect(rows).toBe(1);
	});

	it("reuses and refreshes query cache row plans", () => {
		const world = World.new();
		const cpuA = world.registerComponent("QueryCacheTsA", 16);
		const cpuB = world.registerComponent("QueryCacheTsB", 16);
		const cache = QueryCache.new([cpuA, cpuB]);
		expect(cache.requiredComponents().map((component) => component.index())).toEqual([
			cpuA.index(),
			cpuB.index(),
		]);

		const e0 = world.createEntity();
		expect(world.addComponentBytes(e0, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e0, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);
		let sum = 0;
		cache.forEach(world, (row) => {
			row.read(cpuA, (bytes) => {
				sum += bytes.getF32(0);
			});
		});
		expect(sum).toBeCloseTo(1);
		expect(cache.plan(world).stale()).toBe(false);

		const cpuC = world.registerComponent("QueryCacheTsC", 16);
		const e1 = world.createEntity();
		expect(world.addComponentBytes(e1, cpuA, f32Bytes([3, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuB, f32Bytes([4, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuC, f32Bytes([5, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(cache.plan(world).stale()).toBe(true);
		cache.refresh(world);
		expect(cache.plan(world).stale()).toBe(false);
		expect(cache.plan(world).matchedRowCount()).toBe(2);
	});

	it("filters query rows with excluded components", () => {
		const world = World.new();
		const cpuA = world.registerComponent("QueryWithoutTsA", 16);
		const cpuB = world.registerComponent("QueryWithoutTsB", 16);
		const cpuC = world.registerComponent("QueryWithoutTsC", 16);
		const query = Query.newWithExcluded([cpuA, cpuB], [cpuC]);
		expect(query.excludedComponents().map((component) => component.index())).toEqual([
			cpuC.index(),
		]);

		const e0 = world.createEntity();
		expect(world.addComponentBytes(e0, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e0, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);
		const e1 = world.createEntity();
		expect(world.addComponentBytes(e1, cpuA, f32Bytes([3, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuB, f32Bytes([4, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuC, f32Bytes([5, 0, 0, 0], 16))).toBe(
			true,
		);

		const plan = query.plan(world);
		expect(plan.excludedComponents().map((component) => component.index())).toEqual([
			cpuC.index(),
		]);
		expect(plan.candidateArchetypeCount()).toBe(2);
		expect(plan.matchedRowCount()).toBe(1);
		let rows = 0;
		query.forEach(world, (row) => {
			rows += 1;
			expect(row.entity().index()).toBe(e0.index());
			expect(row.has(cpuC)).toBe(false);
		});
		expect(rows).toBe(1);
		expect(() => query.componentIndex(cpuC)).toThrow();
	});

	it("reuses and refreshes raw query cache archetype plans", () => {
		const world = World.new();
		const cpuA = world.registerComponent("RawQueryCacheTsA", 16);
		const cpuB = world.registerComponent("RawQueryCacheTsB", 16);
		const cache = RawQueryCache.new([cpuA, cpuB]);
		const e0 = world.createEntity();
		expect(world.addComponentBytes(e0, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e0, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);
		cache.refresh(world);
		expect(cache.plan(world).matchedRowCount()).toBe(1);

		const cpuC = world.registerComponent("RawQueryCacheTsC", 16);
		const e1 = world.createEntity();
		expect(world.addComponentBytes(e1, cpuA, f32Bytes([3, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuB, f32Bytes([4, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuC, f32Bytes([5, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(cache.plan(world).stale()).toBe(true);
		let rows = 0;
		cache.forEachArchetype(world, (archetype) => {
			rows += archetype.length();
		});
		expect(rows).toBe(2);
		expect(cache.plan(world).stale()).toBe(false);
	});

	it("filters raw query archetypes with excluded components", () => {
		const world = World.new();
		const cpuA = world.registerComponent("RawQueryWithoutTsA", 16);
		const cpuB = world.registerComponent("RawQueryWithoutTsB", 16);
		const cpuC = world.registerComponent("RawQueryWithoutTsC", 16);
		const cache = RawQueryCache.newWithExcluded([cpuA, cpuB], [cpuC]);
		expect(cache.excludedComponents().map((component) => component.index())).toEqual([
			cpuC.index(),
		]);

		const e0 = world.createEntity();
		expect(world.addComponentBytes(e0, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e0, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);
		const e1 = world.createEntity();
		expect(world.addComponentBytes(e1, cpuA, f32Bytes([3, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuB, f32Bytes([4, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(e1, cpuC, f32Bytes([5, 0, 0, 0], 16))).toBe(
			true,
		);

		let rows = 0;
		cache.forEachArchetype(world, (archetype) => {
			rows += archetype.length();
		});
		expect(rows).toBe(1);
		expect(cache.plan(world).matchedRowCount()).toBe(1);
	});

	it("uses pre-resolved query component indexes", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpuA = world.registerComponent("QueryIndexTsA", 16);
		const cpuB = world.registerComponent("QueryIndexTsB", 16);
		const query = Query.new([cpuA, cpuB]);
		const cache = QueryCache.new([cpuA, cpuB]);
		expect(query.componentIndex(cpuA)).toBe(0);
		expect(query.componentIndex(cpuB)).toBe(1);
		expect(cache.componentIndex(cpuB)).toBe(1);

		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(entity, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);

		let fastReadB = 0;
		query.forEachReadAt(world, 1, (seenEntity, bytes) => {
			expect(seenEntity.index()).toBe(entity.index());
			fastReadB = bytes.getF32(0);
		});
		expect(fastReadB).toBeCloseTo(2);
		query.prepare(world).forEachReadAt(world, 0, (seenEntity, bytes) => {
			expect(seenEntity.index()).toBe(entity.index());
			expect(bytes.getF32(0)).toBeCloseTo(1);
		});
		cache.refresh(world);
		let cachedFastReadB = 0;
		cache.forEachReadAt(world, 1, (seenEntity, bytes) => {
			expect(seenEntity.index()).toBe(entity.index());
			cachedFastReadB = bytes.getF32(0);
		});
		expect(cachedFastReadB).toBeCloseTo(2);

		let readA = 0;
		query.forEach(world, (row) => {
			expect(row.hasAt(0)).toBe(true);
			row.readAt(0, (bytes) => {
				readA = bytes.getF32(0);
			});
			row.writeAt(1, (bytes) => bytes.setF32(0, 7));
			expect(row.writeTrackedAt(history, 0, (bytes) => bytes.setF32(0, 5))).toBe(
				true,
			);
		});
		expect(readA).toBeCloseTo(1);
		expect(getF32(world.componentBytesCopy(entity, cpuA) ?? new Uint8Array(), 0)).toBeCloseTo(5);
		expect(getF32(world.componentBytesCopy(entity, cpuB) ?? new Uint8Array(), 0)).toBeCloseTo(7);
		expect(() => query.forEachReadAt(world, -1, () => {})).toThrow();
		expect(() => query.componentIndex(world.registerComponent("QueryIndexTsC", 16))).toThrow();
	});

	it("uses pre-resolved raw query component indexes", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpuA = world.registerComponent("RawQueryIndexTsA", 16);
		const cpuB = world.registerComponent("RawQueryIndexTsB", 16);
		const raw = RawQuery.new([cpuA, cpuB]);
		const cache = RawQueryCache.new([cpuA, cpuB]);
		expect(raw.componentIndex(cpuA)).toBe(0);
		expect(raw.componentIndex(cpuB)).toBe(1);
		expect(cache.componentIndex(cpuB)).toBe(1);

		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpuA, f32Bytes([1, 0, 0, 0], 16))).toBe(
			true,
		);
		expect(world.addComponentBytes(entity, cpuB, f32Bytes([2, 0, 0, 0], 16))).toBe(
			true,
		);

		raw.forEachReadViewAt(world, 1, (seenEntity, bytes) => {
			expect(seenEntity.index()).toBe(entity.index());
			expect(bytes.getF32(0)).toBeCloseTo(2);
		});
		raw.prepare(world).forEachReadViewAt(world, 0, (seenEntity, bytes) => {
			expect(seenEntity.index()).toBe(entity.index());
			expect(bytes.getF32(0)).toBeCloseTo(1);
		});
		cache.refresh(world);
		cache.forEachReadViewAt(world, 1, (seenEntity, bytes) => {
			expect(seenEntity.index()).toBe(entity.index());
			expect(bytes.getF32(0)).toBeCloseTo(2);
		});

		raw.forEach(world, (row) => {
			expect(row.hasAt(0)).toBe(true);
			expect(row.readViewAt(0).getF32(0)).toBeCloseTo(1);
			row.writeViewAt(1).setF32(0, 3);
			expect(row.writeTrackedAt(history, 0, (bytes) => bytes.setF32(0, 4))).toBe(
				true,
			);
		});
		raw.forEachArchetype(world, (archetype) => {
			expect(archetype.hasAt(1)).toBe(true);
			expect(archetype.componentStrideAt(1)).toBe(16);
			expect(archetype.readColumnAt(1).getF32(0)).toBeCloseTo(3);
			archetype.writeColumnAt(1).setF32(0, 6);
			expect(
				archetype.writeColumnTrackedAt(history, 0, (bytes) => bytes.setF32(0, 8)),
			).toBe(true);
			expect(
				archetype.writeColumnRowsTrackedAt(history, 0, [0], (_row, bytes) =>
					bytes.setF32(0, 9),
				),
			).toBe(true);
			expect(() => archetype.readColumnAt(-1)).toThrow();
		});
		expect(getF32(world.componentBytesCopy(entity, cpuA) ?? new Uint8Array(), 0)).toBeCloseTo(9);
		expect(getF32(world.componentBytesCopy(entity, cpuB) ?? new Uint8Array(), 0)).toBeCloseTo(6);
	});

});
