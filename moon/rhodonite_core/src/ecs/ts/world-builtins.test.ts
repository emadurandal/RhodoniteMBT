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

describe("ECS TypeScript wrapper: builtins", () => {
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

});
