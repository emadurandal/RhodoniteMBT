// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	Query,
	RawQuery,
	World,
	WorldHistory,
	describe,
	expect,
	f32Bytes,
	getF32,
	globalTransformFormatCode,
	identityMat4ColMajor,
	it,
	translationMat4ColMajor,
} from "./test-support/world-test-support.ts";

function expectBytes(
	world: World,
	entity: ReturnType<World["createEntity"]>,
	component: ReturnType<World["registerCpuComponent"]>,
	expected: Uint8Array,
): void {
	expect(world.componentBytesCopy(entity, component)).toEqual(expected);
}

function expectF32(
	world: World,
	entity: ReturnType<World["createEntity"]>,
	component: ReturnType<World["registerCpuComponent"]>,
	expected: number,
): void {
	expect(getF32(world.componentBytesCopy(entity, component) ?? new Uint8Array(), 0)).toBeCloseTo(
		expected,
	);
}

function expectStacks(
	history: WorldHistory,
	undoLen: number,
	redoLen: number,
): void {
	expect(history.undoLen()).toBe(undoLen);
	expect(history.redoLen()).toBe(redoLen);
}

describe("ECS TypeScript wrapper: history invariants", () => {
	it("round-trips compound tracked operations through the public wrapper", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsInvariantCompoundCpu", 4);
		const bulk = world.registerCpuComponent("TsInvariantCompoundBulk", 4);
		const bulk0 = world.createEntity();
		const bulk1 = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(world.addComponentBytes(bulk0, bulk, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(bulk1, bulk, new Uint8Array([2, 0, 0, 0]))).toBe(true);
		expect(history.beginTransaction("TS invariant compound")).toBe(true);
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
		expect(history.setCameraMatrices(world, camera, identity, identity, 0.25, 100, 1.5, 0, 2)).toBe(
			true,
		);
		expect(history.commitTransaction()).toBe(true);
		expectStacks(history, 1, 0);

		expect(history.undo(world)).toBe(true);
		expectStacks(history, 0, 1);
		expect(world.isAlive(parent)).toBe(false);
		expect(world.isAlive(entity)).toBe(false);
		expect(world.isAlive(camera)).toBe(false);
		expectBytes(world, bulk0, bulk, new Uint8Array([1, 0, 0, 0]));
		expectBytes(world, bulk1, bulk, new Uint8Array([2, 0, 0, 0]));

		expect(history.redo(world)).toBe(true);
		expectStacks(history, 1, 0);
		expect(world.isAlive(parent)).toBe(true);
		expect(world.isAlive(entity)).toBe(true);
		expect(world.isAlive(camera)).toBe(true);
		expectBytes(world, entity, cpu, new Uint8Array([2, 0, 0, 0]));
		expectBytes(world, bulk0, bulk, new Uint8Array([3, 0, 0, 0]));
		expectBytes(world, bulk1, bulk, new Uint8Array([4, 0, 0, 0]));
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
		expect(global?.[12]).toBeCloseTo(1);
		expect(global?.[13]).toBeCloseTo(2);
		expect(global?.[14]).toBeCloseTo(3);
		const cameraRow = world.cameraGpuRowCopy(camera);
		expect(cameraRow).not.toBeNull();
		expect(getF32(cameraRow ?? new Uint8Array(), 268)).toBeCloseTo(0.25);
		expect(getF32(cameraRow ?? new Uint8Array(), 276)).toBeCloseTo(1.5);
		expect(getF32(cameraRow ?? new Uint8Array(), 284)).toBeCloseTo(2);
	});

	it("round-trips tracked query and column callbacks in one transaction", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsInvariantQueryCpu", 4);
		const e0 = world.createEntity();
		const e1 = world.createEntity();
		const e2 = world.createEntity();
		expect(world.addComponentBytes(e0, cpu, f32Bytes([1]))).toBe(true);
		expect(world.addComponentBytes(e1, cpu, f32Bytes([2]))).toBe(true);
		expect(world.addComponentBytes(e2, cpu, f32Bytes([3]))).toBe(true);

		expect(history.beginTransaction("TS invariant query writes")).toBe(true);
		Query.new([cpu]).forEach(world, (row) => {
			expect(row.writeTracked(history, cpu, (bytes) => bytes.setF32(0, 4))).toBe(true);
		});
		RawQuery.new([cpu]).forEachArchetype(world, (archetype) => {
			expect(archetype.writeColumnTracked(history, cpu, (bytes) => bytes.setF32(0, 5))).toBe(true);
			expect(
				archetype.writeColumnRowsTracked(history, cpu, [1, 2], (row, bytes) => {
					bytes.setF32(0, row + 5);
				}),
			).toBe(true);
		});
		expect(history.commitTransaction()).toBe(true);
		expectStacks(history, 1, 0);
		expectF32(world, e0, cpu, 5);
		expectF32(world, e1, cpu, 6);
		expectF32(world, e2, cpu, 7);

		expect(history.undo(world)).toBe(true);
		expectStacks(history, 0, 1);
		expectF32(world, e0, cpu, 1);
		expectF32(world, e1, cpu, 2);
		expectF32(world, e2, cpu, 3);

		expect(history.redo(world)).toBe(true);
		expectStacks(history, 1, 0);
		expectF32(world, e0, cpu, 5);
		expectF32(world, e1, cpu, 6);
		expectF32(world, e2, cpu, 7);
	});

	it("keeps world and stacks unchanged after bulk validation failures", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const cpu = world.registerCpuComponent("TsInvariantBulkFailureCpu", 4);
		const marker = world.registerCpuComponent("TsInvariantBulkFailureMarker", 4);
		const e0 = world.createEntity();
		const e1 = world.createEntity();
		const missing = world.createEntity();
		expect(world.addComponentBytes(e0, cpu, new Uint8Array([1, 0, 0, 0]))).toBe(true);
		expect(world.addComponentBytes(e1, cpu, new Uint8Array([2, 0, 0, 0]))).toBe(true);

		expect(
			history.setComponentBytesMany(
				world,
				cpu,
				[e0, e0],
				[new Uint8Array([3, 0, 0, 0]), new Uint8Array([4, 0, 0, 0])],
			),
		).toBe(false);
		expectStacks(history, 0, 0);
		expectBytes(world, e0, cpu, new Uint8Array([1, 0, 0, 0]));
		expectBytes(world, e1, cpu, new Uint8Array([2, 0, 0, 0]));

		expect(
			history.addComponentBytesMany(
				world,
				marker,
				[missing, missing],
				[new Uint8Array([5, 0, 0, 0]), new Uint8Array([6, 0, 0, 0])],
			),
		).toBe(false);
		expectStacks(history, 0, 0);
		expect(world.hasComponent(missing, marker)).toBe(false);

		expect(
			history.setComponentBytesMany(
				world,
				cpu,
				[e0, missing],
				[new Uint8Array([7, 0, 0, 0]), new Uint8Array([8, 0, 0, 0])],
			),
		).toBe(false);
		expectStacks(history, 0, 0);
		expectBytes(world, e0, cpu, new Uint8Array([1, 0, 0, 0]));
		expect(world.hasComponent(missing, cpu)).toBe(false);
	});
});
