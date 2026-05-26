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
