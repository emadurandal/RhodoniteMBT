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
	it("keeps v1 history fixture manifest in sync", () => {
		expect(historyFixtureFileNames()).toEqual(historyFixtureManifestNames());
	});

	it("decodes every valid v1 history fixture", () => {
		for (const name of validHistoryFixtures) {
			expect(() => decodeHistoryExportJson(readHistoryFixture(name))).not.toThrow();
		}
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


	it("exports history stacks when retained components have stable identity", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const stable = world.registerCpuComponentWithIdentity(
			"TsHistoryExportStable",
			4,
			{
				stableKey: "com.example.TsHistoryExportStable",
				schemaVersion: "1",
				schemaHash: "sha256:ts-history-export-stable",
			},
		);
		const legacy = world.registerCpuComponent("TsHistoryExportLegacy", 4);
		const stableEntity = world.createEntity();
		const legacyEntity = world.createEntity();

		expect(
			world.addComponentBytes(stableEntity, stable, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(
			world.addComponentBytes(legacyEntity, legacy, new Uint8Array([3, 0, 0, 0])),
		).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				stableEntity,
				stable,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);

		const diagnostic = history.lastDiagnostic();
		const exported = history.exportUndoStack(world);
		expect(exported).not.toBeNull();
		expect(exported?.formatVersion).toBe(1);
		expect(exported?.recordCount).toBe(1);
		expect(exported?.records[0]?.label).toBe("set_component_bytes");
		expect(exported?.records[0]?.deltaCount).toBe(1);
		const delta = exported?.records[0]?.deltas[0];
		expect(delta?.kind).toBe("component_changed");
		expect(delta?.entity?.index()).toBe(stableEntity.index());
		expect(delta?.component).toMatchObject({
			key: "com.example.TsHistoryExportStable",
			builtin: false,
			schemaVersion: "1",
			schemaHash: "sha256:ts-history-export-stable",
		});
		expect(delta?.component?.localComponent.index()).toBe(stable.index());
		expect(delta?.before?.globalTransformFormat).toBeNull();
		expect(delta?.before?.bytes).toBeInstanceOf(Uint8Array);
		expect(Array.from(delta?.before?.bytes ?? [])).toEqual([1, 0, 0, 0]);
		expect(Array.from(delta?.after?.bytes ?? [])).toEqual([2, 0, 0, 0]);
		expect(history.lastDiagnostic()).toBe(diagnostic);

		expect(
			history.setComponentBytes(
				world,
				legacyEntity,
				legacy,
				new Uint8Array([4, 0, 0, 0]),
			),
		).toBe(true);
		expect(history.exportUndoStack(world)).toBeNull();
		expect(history.undo(world)).toBe(true);
		expect(history.exportRedoStack(world)).toBeNull();
	});


	it("round-trips builtin history archives through TypeScript JSON helpers", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const imported = WorldHistory.new();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(world.setGlobalTransform(entity, translationMat4ColMajor(1, 2, 3))).toBe(true);
		expect(world.setGlobalTransformFormat(entity, 0)).toBe(true);
		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 50, 1, 1, 0),
		).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		expect(source.beginTransaction("TS builtin archive")).toBe(true);
		expect(
			source.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(4, 5, 6),
			),
		).toBe(true);
		expect(source.setGlobalTransformFormat(world, entity, 1)).toBe(true);
		expect(
			source.setCameraMatrices(
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
		expect(source.commitTransaction()).toBe(true);

		const archive = source.exportUndoStack(world);
		expect(archive).not.toBeNull();
		if (archive == null) {
			throw new Error("expected builtin archive");
		}
		expect(archive.recordCount).toBe(1);
		const deltas = archive.records[0]?.deltas ?? [];
		const globalDelta = deltas.find(
			(delta) => delta.kind === "global_transform_changed",
		);
		const cameraDelta = deltas.find((delta) => delta.kind === "camera_changed");
		expect(globalDelta?.component).toMatchObject({
			key: "GlobalTransform",
			builtin: true,
		});
		expect(globalDelta?.before?.globalTransformFormat).toBe(0);
		expect(globalDelta?.after?.globalTransformFormat).toBe(1);
		expect(globalDelta?.before?.bytes).toBeInstanceOf(Uint8Array);
		expect(globalDelta?.after?.bytes).toBeInstanceOf(Uint8Array);
		expect(getF32(globalDelta?.before?.bytes ?? new Uint8Array(), 12)).toBeCloseTo(1);
		expect(cameraDelta?.component).toMatchObject({
			key: "Camera",
			builtin: true,
		});
		expect(cameraDelta?.before?.globalTransformFormat).toBeNull();
		expect(cameraDelta?.after?.globalTransformFormat).toBeNull();
		expect(getF32(cameraDelta?.before?.bytes ?? new Uint8Array(), 268)).toBeCloseTo(0.1);
		expect(getF32(cameraDelta?.after?.bytes ?? new Uint8Array(), 268)).toBeCloseTo(0.25);

		const json = encodeHistoryExportJson(archive);
		const decoded = decodeHistoryExportJson(json);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();
		expect(imported.importUndoStack(world, decoded)).toBe(true);
		expect(imported.undo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			0,
		);
		expect(Array.from(world.getGlobalTransform(entity) ?? [])).toEqual(
			translationMat4ColMajor(1, 2, 3),
		);
		const cameraWrites = world.drainCameraBlobWriteViews();
		expect(
			getF32(cameraWrites[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.1);
	});


	it("round-trips builtin redo history archives through TypeScript JSON helpers", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const imported = WorldHistory.new();
		const entity = world.createEntity();
		const camera = world.createEntity();
		const identity = identityMat4ColMajor();

		expect(world.setGlobalTransform(entity, translationMat4ColMajor(1, 2, 3))).toBe(true);
		expect(world.setGlobalTransformFormat(entity, 0)).toBe(true);
		expect(
			world.setCameraMatrices(camera, identity, identity, 0.1, 50, 1, 1, 0),
		).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();

		expect(source.beginTransaction("TS builtin redo archive")).toBe(true);
		expect(
			source.setGlobalTransform(
				world,
				entity,
				translationMat4ColMajor(4, 5, 6),
			),
		).toBe(true);
		expect(source.setGlobalTransformFormat(world, entity, 1)).toBe(true);
		expect(
			source.setCameraMatrices(
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
		expect(source.commitTransaction()).toBe(true);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();
		expect(source.undo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			0,
		);
		expect(Array.from(world.getGlobalTransform(entity) ?? [])).toEqual(
			translationMat4ColMajor(1, 2, 3),
		);

		const archive = source.exportRedoStack(world);
		expect(archive).not.toBeNull();
		if (archive == null) {
			throw new Error("expected builtin redo archive");
		}
		expect(archive.recordCount).toBe(1);
		const deltas = archive.records[0]?.deltas ?? [];
		const globalDelta = deltas.find(
			(delta) => delta.kind === "global_transform_changed",
		);
		const cameraDelta = deltas.find((delta) => delta.kind === "camera_changed");
		expect(globalDelta?.component).toMatchObject({
			key: "GlobalTransform",
			builtin: true,
		});
		expect(globalDelta?.before?.globalTransformFormat).toBe(0);
		expect(globalDelta?.after?.globalTransformFormat).toBe(1);
		expect(globalDelta?.before?.bytes).toBeInstanceOf(Uint8Array);
		expect(globalDelta?.after?.bytes).toBeInstanceOf(Uint8Array);
		expect(getF32(globalDelta?.before?.bytes ?? new Uint8Array(), 12)).toBeCloseTo(1);
		expect(cameraDelta?.component).toMatchObject({
			key: "Camera",
			builtin: true,
		});
		expect(cameraDelta?.before?.globalTransformFormat).toBeNull();
		expect(cameraDelta?.after?.globalTransformFormat).toBeNull();
		expect(getF32(cameraDelta?.before?.bytes ?? new Uint8Array(), 268)).toBeCloseTo(0.1);
		expect(getF32(cameraDelta?.after?.bytes ?? new Uint8Array(), 268)).toBeCloseTo(0.25);

		const json = encodeHistoryExportJson(archive);
		const decoded = decodeHistoryExportJson(json);
		world.drainGlobalTransformBlobWriteViews();
		world.drainCameraBlobWriteViews();
		expect(imported.importRedoStack(world, decoded)).toBe(true);
		expect(imported.redo(world)).toBe(true);
		expect(globalTransformFormatCode(world.extractGlobalTransformRefs([entity]))).toBe(
			1,
		);
		expect(Array.from(world.getGlobalTransform(entity) ?? [])).toEqual(
			translationMat4ColMajor(4, 5, 6),
		);
		const cameraWrites = world.drainCameraBlobWriteViews();
		expect(
			getF32(cameraWrites[0]?.bytes().asUint8Array() ?? new Uint8Array(), 268),
		).toBeCloseTo(0.25);
	});


	it("imports history stacks from exported plain objects", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const importedUndo = WorldHistory.new();
		const importedRedo = WorldHistory.new();
		const stable = world.registerCpuComponentWithIdentity(
			"TsHistoryImportStable",
			4,
			{
				stableKey: "com.example.TsHistoryImportStable",
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
		const plainUndoArchive = JSON.parse(JSON.stringify(undoArchive));
		const report = importedUndo.validateImportUndoStack(world, plainUndoArchive);
		expect(report).toMatchObject({
			valid: true,
			reason: "none",
			recordCount: 1,
			records: [
				{
					index: 0,
					label: "set_component_bytes",
					valid: true,
					reason: "none",
					deltaCount: 1,
					deltas: [
						{
							index: 0,
							kind: "component_changed",
							valid: true,
							reason: "none",
							componentKey: "com.example.TsHistoryImportStable",
						},
					],
				},
			],
		});
		expect(importedUndo.undoLen()).toBe(0);
		expect(importedUndo.lastDiagnostic()).toBe("none");
		expect(importedUndo.importUndoStack(world, plainUndoArchive)).toBe(true);
		expect(importedUndo.undoLen()).toBe(1);
		expect(importedUndo.undo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			1, 0, 0, 0,
		]);
		const redoArchive = importedUndo.exportRedoStack(world);
		expect(redoArchive).not.toBeNull();
		expect(importedRedo.importRedoStack(world, redoArchive ?? plainUndoArchive)).toBe(
			true,
		);
		expect(importedRedo.redoLen()).toBe(1);
		expect(importedRedo.redo(world)).toBe(true);
		expect(Array.from(world.componentBytesCopy(entity, stable) ?? [])).toEqual([
			2, 0, 0, 0,
		]);

		const badFormat = { ...plainUndoArchive, formatVersion: 999 };
		const badFormatReport = importedUndo.validateImportUndoStack(world, badFormat);
		expect(badFormatReport).toMatchObject({
			valid: false,
			reason: "import_unsupported_format",
			formatVersion: 999,
		});
		expect(importedUndo.lastDiagnostic()).toBe("none");
		const badIdentityArchive = JSON.parse(JSON.stringify(plainUndoArchive));
		badIdentityArchive.records[0].deltas[0].component.key =
			"com.example.MissingTsHistoryImportStable";
		const badIdentityReport =
			importedUndo.validateImportUndoStack(world, badIdentityArchive);
		expect(badIdentityReport).toMatchObject({
			valid: false,
			reason: "import_identity_mismatch",
			records: [
				{
					index: 0,
					valid: false,
					reason: "import_identity_mismatch",
					deltas: [
						{
							index: 0,
							componentKey: "com.example.MissingTsHistoryImportStable",
							valid: false,
							reason: "import_identity_mismatch",
						},
					],
				},
			],
		});
		expect(importedUndo.lastDiagnostic()).toBe("none");
		expect(importedUndo.importUndoStack(world, badFormat)).toBe(false);
		expect(importedUndo.lastDiagnostic()).toBe("import_unsupported_format");
	});


	it("rejects invalid history imports without mutating world or retained stacks", () => {
		const world = World.new();
		const source = WorldHistory.new();
		const undoTarget = WorldHistory.new();
		const redoTarget = WorldHistory.new();
		const stable = world.registerCpuComponentWithIdentity(
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
		const componentA = world.registerCpuComponentWithIdentity(
			"TsHistoryReplayValidationA",
			4,
			{ stableKey: "com.example.TsHistoryReplayValidationA" },
		);
		const componentB = world.registerCpuComponentWithIdentity(
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
		const redoComponent = redoWorld.registerCpuComponentWithIdentity(
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
		const stable = world.registerCpuComponentWithIdentity(
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
		const stable = world.registerCpuComponentWithIdentity(
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
		const stable = world.registerCpuComponentWithIdentity(
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
		const stable = world.registerCpuComponentWithIdentity(
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
