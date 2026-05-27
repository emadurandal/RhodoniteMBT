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
	getGpuWriteF32,
	globalTransformFormatCode,
	identityMat4ColMajor,
	it,
	translationMat4ColMajor,
} from "./test-support/world-test-support.ts";

describe("ECS TypeScript wrapper: system", () => {
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

	it("runs TS direct systems without command buffers", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("TsDirectSystemCpu", 4);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);

		const phase = PhaseKey.new("ts/direct");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.newDirect("direct-write-cpu", phase, [], [cpu], (systemWorld, systemCtx) => {
				expect(systemCtx.frameIndex()).toBe(9);
				expect(
					systemWorld.setComponentBytes(entity, cpu, new Uint8Array([7, 0, 0, 0])),
				).toBe(true);
			}),
		);

		expect(runner.runPhase(world, SystemContext.new(0.016, 9), phase)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([7, 0, 0, 0]));
	});

	it("reports TS direct systems as empty command reports", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("TsDirectReportCpu", 4);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);

		const phase = PhaseKey.new("ts/direct-report");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.newDirect("direct-report", phase, [], [cpu], (systemWorld) => {
				expect(
					systemWorld.setComponentBytes(entity, cpu, new Uint8Array([8, 0, 0, 0])),
				).toBe(true);
			}),
		);

		const report = runner.runPhaseReport(world, SystemContext.new(0.016, 1), phase);
		expect(report.ok()).toBe(true);
		expect(report.systemCount()).toBe(1);
		expect(report.queuedCommandCount()).toBe(0);
		expect(report.appliedCommandCount()).toBe(0);
		expect(report.failedCommandCount()).toBe(0);
		const system = report.batches()[0].systems()[0];
		expect(system.name()).toBe("direct-report");
		expect(system.queuedCommandCount()).toBe(0);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([8, 0, 0, 0]));
	});

	it("reports TS system command-buffer execution results", () => {
		const world = World.new();
		const cpu = world.registerCpuComponent("TsSystemReportCpu", 4);
		const entity = world.createEntity();
		expect(world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		const missing = EntityId.new(entity.index() + 100, 0);
		const phase = PhaseKey.new("ts/report");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.newWithStructuralWrite("report-failure", phase, [], [cpu], (_world, _ctx, commands) => {
				commands.setComponentBytes(entity, cpu, new Uint8Array([2, 0, 0, 0]));
				commands.destroyEntity(missing);
			}),
		);

		const report = runner.runPhaseReport(world, SystemContext.new(0.016, 1), phase);
		expect(report.ok()).toBe(false);
		expect(report.phase().name()).toBe("ts/report");
		expect(report.batchCount()).toBe(1);
		expect(report.systemCount()).toBe(1);
		expect(report.queuedCommandCount()).toBe(2);
		expect(report.appliedCommandCount()).toBe(1);
		expect(report.failedCommandCount()).toBe(1);
		const batch = report.batches()[0];
		expect(batch.ok()).toBe(false);
		expect(batch.index()).toBe(0);
		const system = batch.systems()[0];
		expect(system.runnerIndex()).toBe(0);
		expect(system.batchIndex()).toBe(0);
		expect(system.name()).toBe("report-failure");
		expect(system.queuedCommandCount()).toBe(2);
		expect(system.appliedCommandCount()).toBe(1);
		expect(system.failedCommandCount()).toBe(1);
		const failure = system.failures()[0];
		expect(failure.commandIndex()).toBe(1);
		expect(failure.commandKind()).toBe("destroy_entity");
		expect(failure.reason()).toBe("apply_failed");
		expect(failure.entity().index()).toBe(missing.index());
		expect(failure.component().index()).toBe(-1);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(new Uint8Array([2, 0, 0, 0]));
	});

	it("plans TS system phases without executing callbacks", () => {
		const world = World.new();
		const a = world.registerCpuComponent("TsSystemPlanA", 4);
		const b = world.registerCpuComponent("TsSystemPlanB", 4);
		const phase = PhaseKey.new("ts/plan");
		const otherPhase = PhaseKey.new("ts/plan-other");
		const runner = SystemRunner.new();
		let executed = false;

		runner.addSystem(System.new("read-a", phase, [a], [], () => {
			executed = true;
		}));
		runner.addSystem(System.new("write-b", phase, [], [b], () => {
			executed = true;
		}));
		runner.addSystem(System.new("write-a", phase, [], [a], () => {
			executed = true;
		}));
		runner.addSystem(System.new("other", otherPhase, [], [], () => {
			executed = true;
		}));

		const empty = runner.planPhase(PhaseKey.new("ts/missing"));
		expect(empty.phase().name()).toBe("ts/missing");
		expect(empty.systemCount()).toBe(0);
		expect(empty.batchCount()).toBe(0);
		expect(empty.batches()).toEqual([]);

		const plan = runner.planPhase(phase);
		expect(executed).toBe(false);
		expect(plan.phase().name()).toBe("ts/plan");
		expect(plan.systemCount()).toBe(3);
		expect(plan.batchCount()).toBe(2);
		const batches = plan.batches();
		expect(batches[0].index()).toBe(0);
		expect(batches[1].index()).toBe(1);
		const firstBatch = batches[0].systems();
		expect(firstBatch.map((system) => system.name())).toEqual([
			"read-a",
			"write-b",
		]);
		expect(firstBatch[0].runnerIndex()).toBe(0);
		expect(firstBatch[0].batchIndex()).toBe(0);
		expect(firstBatch[0].phase().name()).toBe("ts/plan");
		expect(firstBatch[0].reads().map((component) => component.index())).toEqual([
			a.index(),
		]);
		expect(firstBatch[0].writes()).toEqual([]);
		expect(firstBatch[0].structuralWrite()).toBe(false);
		expect(firstBatch[1].runnerIndex()).toBe(1);
		expect(firstBatch[1].writes().map((component) => component.index())).toEqual([
			b.index(),
		]);
		const secondBatch = batches[1].systems();
		expect(secondBatch).toHaveLength(1);
		expect(secondBatch[0].name()).toBe("write-a");
		expect(secondBatch[0].runnerIndex()).toBe(2);
	});

	it("plans structural TS systems as separate batches", () => {
		const phase = PhaseKey.new("ts/plan-structural");
		const runner = SystemRunner.new();
		runner.addSystem(System.new("before", phase, [], [], () => {}));
		runner.addSystem(
			System.newWithStructuralWrite("structural", phase, [], [], () => {}),
		);
		runner.addSystem(System.new("after", phase, [], [], () => {}));

		const batches = runner.planPhase(phase).batches();
		expect(batches).toHaveLength(3);
		expect(batches.map((batch) => batch.systems()[0].name())).toEqual([
			"before",
			"structural",
			"after",
		]);
		expect(batches[1].systems()[0].structuralWrite()).toBe(true);
	});

	it("refreshes cached TS phase plans after adding systems", () => {
		const phase = PhaseKey.new("ts/plan-cache");
		const runner = SystemRunner.new();
		runner.addSystem(System.new("first", phase, [], [], () => {}));

		const before = runner.planPhase(phase);
		expect(before.systemCount()).toBe(1);
		expect(before.batches()[0].systems()[0].name()).toBe("first");

		runner.addSystem(System.new("second", phase, [], [], () => {}));
		const after = runner.planPhase(phase);
		expect(after.systemCount()).toBe(2);
		expect(after.batches()[0].systems().map((system) => system.name())).toEqual([
			"first",
			"second",
		]);
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


	it("keeps successful TS command-buffer deltas when a later command fails", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsTrackedSystemPartialCpu", 4);
		const entity = world.createEntity();
		const missing = EntityId.new(entity.index() + 100, 0);
		expect(
			world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);

		const phase = PhaseKey.new("ts/tracked-partial-failure");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.newWithStructuralWrite(
				"tracked-partial-failure",
				phase,
				[],
				[cpu],
				(_world, _ctx, commands) => {
					commands.setComponentBytes(entity, cpu, new Uint8Array([9, 0, 0, 0]));
					commands.destroyEntity(missing);
				},
			),
		);

		expect(
			history.runSystemPhase(
				runner,
				world,
				SystemContext.new(0.016, 3),
				phase,
				"tracked TS partial failure",
			),
		).toBe(false);
		expect(history.undoLen()).toBe(1);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([9, 0, 0, 0]),
		);
		expect(history.undo(world)).toBe(true);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([1, 0, 0, 0]),
		);
	});

	it("reports tracked TS system phase command failures", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsTrackedSystemReportCpu", 4);
		const entity = world.createEntity();
		const missing = EntityId.new(entity.index() + 100, 0);
		expect(
			world.addComponentBytes(entity, cpu, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		const phase = PhaseKey.new("ts/tracked-report");
		const runner = SystemRunner.new();
		runner.addSystem(
			System.newWithStructuralWrite(
				"tracked-report-failure",
				phase,
				[],
				[cpu],
				(_world, _ctx, commands) => {
					commands.setComponentBytes(entity, cpu, new Uint8Array([2, 0, 0, 0]));
					commands.destroyEntity(missing);
				},
			),
		);

		const report = history.runSystemPhaseReport(
			runner,
			world,
			SystemContext.new(0.016, 1),
			phase,
			"tracked report failure",
		);
		expect(report.ok()).toBe(false);
		expect(report.failedCommandCount()).toBe(1);
		expect(report.batches()[0].systems()[0].failures()[0].commandKind()).toBe("destroy_entity");
		expect(report.batches()[0].systems()[0].failures()[0].reason()).toBe("apply_failed");
		expect(history.lastDiagnostic()).toBe("operation_failed");
		expect(history.undoLen()).toBe(1);
		expect(world.componentBytesCopy(entity, cpu)).toEqual(
			new Uint8Array([2, 0, 0, 0]),
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
		expect(getGpuWriteF32(cameraWrites[0], 268)).toBeCloseTo(0.25);
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
		expect(getGpuWriteF32(cameraWrites[0], 268)).toBeCloseTo(0.3);

		expect(history.undo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			0,
		);
		cameraWrites = world.drainCameraBlobWriteViews();
		expect(getGpuWriteF32(cameraWrites[0], 268)).toBeCloseTo(0.1);
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

});
