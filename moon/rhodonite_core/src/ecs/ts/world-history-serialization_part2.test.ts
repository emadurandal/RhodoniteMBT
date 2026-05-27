// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { readFileSync, readdirSync } from "node:fs";
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

function readHistoryFixture(name: string): string {
	return readFileSync(
		new URL(`./test-support/fixtures/history/${name}`, import.meta.url),
		"utf8",
	);
}

function parseHistoryFixture(name: string): unknown {
	return JSON.parse(readHistoryFixture(name));
}

const validHistoryFixtures = [
	"stable-component-change.undo.v1.json",
	"stable-component-change.redo.v1.json",
	"entity-destroy-snapshot.undo.v1.json",
	"builtin-global-camera.undo.v1.json",
] as const;

const invalidDecodeHistoryFixtures = [
	{
		name: "unsupported-format.v999.json",
		expectedError: /unsupported format_version/,
	},
	{
		name: "missing-component-key.v1.json",
		expectedError: /component.key/,
	},
	{
		name: "invalid-base64.v1.json",
		expectedError: /base64/,
	},
] as const;

function historyFixtureManifestNames(): string[] {
	return [
		...validHistoryFixtures,
		...invalidDecodeHistoryFixtures.map((fixture) => fixture.name),
	].sort();
}

function historyFixtureFileNames(): string[] {
	return readdirSync(
		new URL("./test-support/fixtures/history/", import.meta.url),
	)
		.filter((name) => name.endsWith(".json"))
		.sort();
}


describe("ECS TypeScript wrapper: history-serialization", () => {
	it("rejects invalid history imports without mutating world or retained stacks", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const undoTarget = WorldHistory.new();
		const redoTarget = WorldHistory.new();
		const stable = world.registerComponentWithIdentity(
			"TsHistoryAtomicImportStable",
			4,
			{
				stableKey: "com.example.TsHistoryAtomicImportStable",
				schemaVersion: "1",
			},
		);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, stable, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			source.setComponentBytes(
				world,
				entity,
				stable,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		const undoArchive = source.exportUndoStack(world);
		expect(undoArchive).not.toBeNull();
		if (undoArchive == null) {
			throw new Error("expected undo archive");
		}
		expect(undoTarget.importUndoStack(world, undoArchive)).toBe(true);
		expect(undoTarget.undoLen()).toBe(1);
		expect(undoTarget.redoLen()).toBe(0);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);

		const badUndoArchive = {
			...JSON.parse(JSON.stringify(undoArchive)),
			formatVersion: 999,
		};
		const undoDiagnostic = undoTarget.lastDiagnostic();
		const undoReport = undoTarget.validateImportUndoStack(world, badUndoArchive);
		expect(undoReport).toMatchObject({
			valid: false,
			reason: "import_unsupported_format",
			formatVersion: 999,
		});
		expect(undoTarget.undoLen()).toBe(1);
		expect(undoTarget.redoLen()).toBe(0);
		expect(undoTarget.lastDiagnostic()).toBe(undoDiagnostic);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);
		expect(undoTarget.importUndoStack(world, badUndoArchive)).toBe(false);
		expect(undoTarget.undoLen()).toBe(1);
		expect(undoTarget.redoLen()).toBe(0);
		expect(undoTarget.lastDiagnostic()).toBe("import_unsupported_format");
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);

		const badUndoPayloadArchive = JSON.parse(JSON.stringify(undoArchive));
		badUndoPayloadArchive.records[0].deltas[0].after.bytes = [3, 0, 0];
		const undoPayloadDiagnostic = undoTarget.lastDiagnostic();
		const undoPayloadReport =
			undoTarget.validateImportUndoStack(world, badUndoPayloadArchive);
		expect(undoPayloadReport).toMatchObject({
			valid: false,
			reason: "import_invalid_payload",
			records: [
				{
					index: 0,
					valid: false,
					reason: "import_invalid_payload",
					deltas: [
						{
							index: 0,
							valid: false,
							reason: "import_invalid_payload",
						},
					],
				},
			],
		});
		expect(undoTarget.lastDiagnostic()).toBe(undoPayloadDiagnostic);
		expect(undoTarget.undoLen()).toBe(1);
		expect(undoTarget.redoLen()).toBe(0);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);
		expect(undoTarget.importUndoStack(world, badUndoPayloadArchive)).toBe(false);
		expect(undoTarget.undoLen()).toBe(1);
		expect(undoTarget.redoLen()).toBe(0);
		expect(undoTarget.lastDiagnostic()).toBe("import_invalid_payload");
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);

		expect(undoTarget.undo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);
		const redoArchive = undoTarget.exportRedoStack(world);
		expect(redoArchive).not.toBeNull();
		if (redoArchive == null) {
			throw new Error("expected redo archive");
		}
		expect(redoTarget.importRedoStack(world, redoArchive)).toBe(true);
		expect(redoTarget.undoLen()).toBe(0);
		expect(redoTarget.redoLen()).toBe(1);

		const badRedoPayloadArchive = JSON.parse(JSON.stringify(redoArchive));
		badRedoPayloadArchive.records[0].deltas[0].before.bytes = [3, 0, 0];
		const redoPayloadDiagnostic = redoTarget.lastDiagnostic();
		const redoPayloadReport =
			redoTarget.validateImportRedoStack(world, badRedoPayloadArchive);
		expect(redoPayloadReport).toMatchObject({
			valid: false,
			reason: "import_invalid_payload",
			records: [
				{
					index: 0,
					valid: false,
					reason: "import_invalid_payload",
					deltas: [
						{
							index: 0,
							valid: false,
							reason: "import_invalid_payload",
						},
					],
				},
			],
		});
		expect(redoTarget.lastDiagnostic()).toBe(redoPayloadDiagnostic);
		expect(redoTarget.undoLen()).toBe(0);
		expect(redoTarget.redoLen()).toBe(1);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);
		expect(redoTarget.importRedoStack(world, badRedoPayloadArchive)).toBe(false);
		expect(redoTarget.undoLen()).toBe(0);
		expect(redoTarget.redoLen()).toBe(1);
		expect(redoTarget.lastDiagnostic()).toBe("import_invalid_payload");
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);

		const badRedoArchive = {
			...JSON.parse(JSON.stringify(redoArchive)),
			formatVersion: 999,
		};
		expect(redoTarget.importRedoStack(world, badRedoArchive)).toBe(false);
		expect(redoTarget.undoLen()).toBe(0);
		expect(redoTarget.redoLen()).toBe(1);
		expect(redoTarget.lastDiagnostic()).toBe("import_unsupported_format");
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);
	});


	it("reports replay validation failures for inapplicable history imports", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const imported = WorldHistory.new();
		const componentA = world.registerComponentWithIdentity(
			"TsHistoryReplayValidationA",
			4,
			{ stableKey: "com.example.TsHistoryReplayValidationA" },
		);
		const componentB = world.registerComponentWithIdentity(
			"TsHistoryReplayValidationB",
			4,
			{ stableKey: "com.example.TsHistoryReplayValidationB" },
		);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, componentA, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			world.addComponentBytes(entity, componentB, new Uint8Array([3, 0, 0, 0])),
		).toBe(true);
		expect(
			source.setComponentBytes(
				world,
				entity,
				componentA,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		expect(source.beginTransaction("TS replay validation multi-set")).toBe(true);
		expect(
			source.setComponentBytes(
				world,
				entity,
				componentA,
				new Uint8Array([5, 0, 0, 0]),
			),
		).toBe(true);
		expect(
			source.setComponentBytes(
				world,
				entity,
				componentB,
				new Uint8Array([4, 0, 0, 0]),
			),
		).toBe(true);
		expect(source.commitTransaction()).toBe(true);

		const undoArchive = source.exportUndoStack(world);
		expect(undoArchive).not.toBeNull();
		if (undoArchive == null) {
			throw new Error("expected undo archive");
		}
		expect(undoArchive.recordCount).toBe(2);
		expect(undoArchive.records[0]?.deltaCount).toBe(2);
		expect(imported.importUndoStack(world, undoArchive)).toBe(true);
		expect(imported.undoLen()).toBe(2);
		const diagnostic = imported.lastDiagnostic();

		expect(world.removeComponent(entity, componentB)).toBe(true);
		const report = imported.validateImportUndoStack(world, undoArchive);
		expect(report).toMatchObject({
			valid: false,
			reason: "import_validation_failed",
			recordCount: 2,
			records: [
				{
					index: 0,
					valid: false,
					reason: "import_validation_failed",
					deltaCount: 2,
					deltas: [
						{
							index: 0,
							valid: false,
							reason: "import_validation_failed",
						},
						{
							index: 1,
							valid: false,
							reason: "import_validation_failed",
						},
					],
				},
				{
					index: 1,
					valid: false,
					reason: "import_validation_failed",
					deltas: [
						{
							index: 0,
							valid: false,
							reason: "import_validation_failed",
						},
					],
				},
			],
		});
		expect(imported.lastDiagnostic()).toBe(diagnostic);
		expect(imported.undoLen()).toBe(2);
		expect(imported.redoLen()).toBe(0);
		expect(world.hasComponent(entity, componentB)).toBe(false);
		expect(imported.importUndoStack(world, undoArchive)).toBe(false);
		expect(imported.lastDiagnostic()).toBe("import_validation_failed");
		expect(imported.undoLen()).toBe(2);
		expect(imported.redoLen()).toBe(0);
		expect(world.hasComponent(entity, componentB)).toBe(false);

		const redoWorld = World.new();
		const redoSource = WorldHistory.new();
		const redoTarget = WorldHistory.new();
		const redoComponent = redoWorld.registerComponentWithIdentity(
			"TsHistoryReplayValidationRedo",
			4,
			{ stableKey: "com.example.TsHistoryReplayValidationRedo" },
		);
		const redoEntity = redoWorld.createEntity();
		expect(
			redoWorld.addComponentBytes(
				redoEntity,
				redoComponent,
				new Uint8Array([1, 0, 0, 0]),
			),
		).toBe(true);
		expect(
			redoSource.setComponentBytes(
				redoWorld,
				redoEntity,
				redoComponent,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		expect(redoSource.undo(redoWorld)).toBe(true);
		const redoArchive = redoSource.exportRedoStack(redoWorld);
		expect(redoArchive).not.toBeNull();
		if (redoArchive == null) {
			throw new Error("expected redo archive");
		}
		expect(redoTarget.importRedoStack(redoWorld, redoArchive)).toBe(true);
		expect(redoTarget.redoLen()).toBe(1);
		const redoDiagnostic = redoTarget.lastDiagnostic();

		expect(redoWorld.removeComponent(redoEntity, redoComponent)).toBe(true);
		const redoReport = redoTarget.validateImportRedoStack(redoWorld, redoArchive);
		expect(redoReport).toMatchObject({
			valid: false,
			reason: "import_validation_failed",
			records: [
				{
					index: 0,
					valid: false,
					reason: "import_validation_failed",
					deltas: [
						{
							index: 0,
							valid: false,
							reason: "import_validation_failed",
						},
					],
				},
			],
		});
		expect(redoTarget.lastDiagnostic()).toBe(redoDiagnostic);
		expect(redoTarget.undoLen()).toBe(0);
		expect(redoTarget.redoLen()).toBe(1);
		expect(redoWorld.hasComponent(redoEntity, redoComponent)).toBe(false);
		expect(redoTarget.importRedoStack(redoWorld, redoArchive)).toBe(false);
		expect(redoTarget.lastDiagnostic()).toBe("import_validation_failed");
		expect(redoTarget.undoLen()).toBe(0);
		expect(redoTarget.redoLen()).toBe(1);
		expect(redoWorld.hasComponent(redoEntity, redoComponent)).toBe(false);
	});


	it("imports v1 stable component golden fixtures", () => {
		const world = World.new();
		const stable = world.registerComponentWithIdentity(
			"TsHistoryGoldenStable",
			4,
			{
				stableKey: "com.example.TsHistoryGoldenStable",
				schemaVersion: "1",
				schemaHash: "sha256:ts-history-golden-stable",
			},
		);
		const entity = world.createEntity();
		expect(stable.index()).toBe(7);
		expect(entity.index()).toBe(0);
		expect(
			world.addComponentBytes(entity, stable, new Uint8Array([2, 0, 0, 0])),
		).toBe(true);

		const undoArchive = decodeHistoryExportJson(
			readHistoryFixture("stable-component-change.undo.v1.json"),
		);
		const undoHistory = WorldHistory.new();
		expect(undoHistory.importUndoStack(world, undoArchive)).toBe(true);
		expect(undoHistory.undo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);

		const redoArchive = decodeHistoryExportJson(
			readHistoryFixture("stable-component-change.redo.v1.json"),
		);
		const redoHistory = WorldHistory.new();
		expect(redoHistory.importRedoStack(world, redoArchive)).toBe(true);
		expect(redoHistory.redo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);
	});

	it("matches stable component exports against the v1 golden fixture", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const stable = world.registerComponentWithIdentity(
			"TsHistoryGoldenStable",
			4,
			{
				stableKey: "com.example.TsHistoryGoldenStable",
				schemaVersion: "1",
				schemaHash: "sha256:ts-history-golden-stable",
			},
		);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, stable, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				entity,
				stable,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		const exported = history.exportUndoStack(world);
		expect(exported).not.toBeNull();
		if (exported == null) {
			throw new Error("expected stable component archive");
		}
		expect(JSON.parse(encodeHistoryExportJson(exported))).toEqual(
			parseHistoryFixture("stable-component-change.undo.v1.json"),
		);
	});

	it("imports v1 entity destroy snapshot golden fixtures", () => {
		const world = World.new();
		const stable = world.registerComponentWithIdentity(
			"TsHistoryGoldenDestroyStable",
			4,
			{ stableKey: "com.example.TsHistoryGoldenDestroyStable" },
		);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, stable, new Uint8Array([7, 0, 0, 0])),
		).toBe(true);
		expect(world.destroyEntity(entity)).toBe(true);

		const archive = decodeHistoryExportJson(
			readHistoryFixture("entity-destroy-snapshot.undo.v1.json"),
		);
		const history = WorldHistory.new();
		expect(history.importUndoStack(world, archive)).toBe(true);
		expect(history.undo(world)).toBe(true);
		expect(world.isAlive(entity)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			7, 0, 0, 0,
		]);
		expect(history.redo(world)).toBe(true);
		expect(world.isAlive(entity)).toBe(false);
	});

	it("imports v1 builtin GlobalTransform and Camera golden fixtures", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(world.setGlobalTransform(entity, translationMat4ColMajor(4, 5, 6))).toBe(true);
		expect(world.setGlobalTransformFormat(entity, 1)).toBe(true);
		expect(
			world.setCameraMatrices(camera, identity, identity, 0.25, 100, 1.5, 0, 2),
		).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		const archive = decodeHistoryExportJson(
			readHistoryFixture("builtin-global-camera.undo.v1.json"),
		);
		expect(history.importUndoStack(world, archive)).toBe(true);
		expect(history.undo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			0,
		);
		expect(Array.from(world.getGlobalTransform(entity) ?? [])).toEqual(
			translationMat4ColMajor(1, 2, 3),
		);
		const cameraRow = world.cameraGpuRowCopy(camera);
		expect(cameraRow).not.toBeNull();
		expect(getF32(cameraRow ?? new Uint8Array(), 268)).toBeCloseTo(0.1);
		expect(getF32(cameraRow ?? new Uint8Array(), 272)).toBeCloseTo(50);
		expect(getF32(cameraRow ?? new Uint8Array(), 280)).toBeCloseTo(1);
	});

	it("rejects invalid history manifest fixtures", () => {
		for (const fixture of invalidDecodeHistoryFixtures) {
			expect(() =>
				decodeHistoryExportJson(readHistoryFixture(fixture.name)),
			).toThrow(fixture.expectedError);
		}
	});

	it("encodes and decodes history archives as JSON", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const importedUndo = WorldHistory.new();
		const importedRedo = WorldHistory.new();
		const stable = world.registerComponentWithIdentity(
			"TsHistoryJsonStable",
			4,
			{
				stableKey: "com.example.TsHistoryJsonStable",
				schemaHash: "sha256:ts-history-json-stable",
			},
		);
		const entity = world.createEntity();

		expect(
			world.addComponentBytes(entity, stable, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			source.setComponentBytes(
				world,
				entity,
				stable,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);

		const undoArchive = source.exportUndoStack(world);
		expect(undoArchive).not.toBeNull();
		const json = encodeHistoryExportJson(undoArchive ?? {
			formatVersion: 1,
			recordCount: 0,
			records: [],
		});
		const wire = JSON.parse(json);
		expect(wire).toMatchObject({
			format_version: 1,
			record_count: 1,
		});
		expect(wire.records[0].delta_count).toBe(1);
		expect(wire.records[0].deltas[0].component.local_component).toEqual({
			index: stable.index(),
		});
		expect(wire.records[0].deltas[0].before.bytes_base64).toBe("AQAAAA==");
		expect(wire.records[0].deltas[0].before.bytes).toBeUndefined();

		const decoded = decodeHistoryExportJson(json);
		expect(importedUndo.importUndoStack(world, decoded)).toBe(true);
		expect(importedUndo.undo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);

		const redoArchive = importedUndo.exportRedoStack(world);
		expect(redoArchive).not.toBeNull();
		const redoJson = encodeHistoryExportJson(redoArchive ?? {
			formatVersion: 1,
			recordCount: 0,
			records: [],
		});
		expect(
			importedRedo.importRedoStack(world, decodeHistoryExportJson(redoJson)),
		).toBe(true);
		expect(importedRedo.redo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);

		expect(() =>
			decodeHistoryExportJson(JSON.stringify({ ...wire, format_version: 999 })),
		).toThrow(/unsupported format_version/);
		expect(() =>
			decodeHistoryExportJson(JSON.stringify({ ...wire, record_count: 2 })),
		).toThrow(/record_count/);
		expect(() =>
			decodeHistoryExportJson(
				JSON.stringify({
					...wire,
					records: [{ ...wire.records[0], delta_count: "1" }],
				}),
			),
		).toThrow(/delta_count/);
		expect(() =>
			decodeHistoryExportJson(
				JSON.stringify({
					...wire,
					records: [{ ...wire.records[0], delta_count: 2 }],
				}),
			),
		).toThrow(/delta_count/);
		const unknownKindWire = JSON.parse(JSON.stringify(wire));
		unknownKindWire.records[0].deltas[0].kind = "future_delta";
		expect(() =>
			decodeHistoryExportJson(JSON.stringify(unknownKindWire)),
		).toThrow(/history delta kind/);
		const missingComponentKeyWire = JSON.parse(JSON.stringify(wire));
		delete missingComponentKeyWire.records[0].deltas[0].component.key;
		expect(() =>
			decodeHistoryExportJson(JSON.stringify(missingComponentKeyWire)),
		).toThrow(/component.key/);
		expect(() =>
			decodeHistoryExportJson(
				JSON.stringify({
					...wire,
					records: [
						{
							...wire.records[0],
							deltas: [
								{
									...wire.records[0].deltas[0],
									before: {
										...wire.records[0].deltas[0].before,
										bytes_base64: "not base64",
									},
								},
							],
						},
					],
				}),
			),
		).toThrow(/base64/);
		expect(() => decodeHistoryExportJson("{")).toThrow(/invalid JSON/);
	});

});
