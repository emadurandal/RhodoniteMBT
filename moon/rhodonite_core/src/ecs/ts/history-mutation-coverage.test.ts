// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from "vitest";
import {
	CommandBuffer,
	QueryRow,
	RawQueryArchetype,
	RawQueryRow,
	SystemRunner,
	World,
	WorldHistory,
} from "./index.ts";

type AuditedClass =
	| "World"
	| "WorldHistory"
	| "QueryRow"
	| "RawQueryRow"
	| "RawQueryArchetype"
	| "SystemRunner"
	| "CommandBuffer";

type CoverageClass =
	| "tracked"
	| "tracked_callback"
	| "tracked_command_phase"
	| "raw_guarded"
	| "intentionally_untracked"
	| "read_only"
	| "history_control";

type Prototype = { readonly prototype: object };

type SurfaceAudit = {
	readonly name: AuditedClass;
	readonly ctor: Prototype;
	readonly methods: Record<CoverageClass, readonly string[]>;
};

const emptyMethods = (): Record<CoverageClass, readonly string[]> => ({
	tracked: [],
	tracked_callback: [],
	tracked_command_phase: [],
	raw_guarded: [],
	intentionally_untracked: [],
	read_only: [],
	history_control: [],
});

const surfaceAudit = (
	name: AuditedClass,
	ctor: Prototype,
	methods: Partial<Record<CoverageClass, readonly string[]>>,
): SurfaceAudit => ({
	name,
	ctor,
	methods: { ...emptyMethods(), ...methods },
});

const auditedSurfaces: readonly SurfaceAudit[] = [
	surfaceAudit("World", World, {
		raw_guarded: [
			"createEntity",
			"destroyEntity",
			"addComponent",
			"addComponentBytes",
			"setComponentBytes",
			"removeComponent",
			"setTransformTrs",
			"setChildOf",
			"setGlobalTransform",
			"setCameraMatrices",
			"setGlobalTransformFormat",
			"spawnTransformGlobalBatchIdentity",
			"reserveBatchCapacity",
			"spawnBatch",
		],
		intentionally_untracked: [
			"registerCpuComponent",
			"registerCpuComponentWithIdentity",
			"drainGlobalTransformBlobWriteViews",
			"drainCameraBlobWriteViews",
			"writeGlobalTransformBlobRangeViews",
			"updateGlobalTransformsFromTransforms",
			"writeGlobalTransformsDenseRangeViews",
		],
		read_only: [
			"isAlive",
			"transformComponent",
			"globalTransformComponent",
			"childOfComponent",
			"cameraComponent",
			"orbitCameraControllerComponent",
			"cameraHomeTransformComponent",
			"cameraLensComponent",
			"location",
			"componentCpuStride",
			"componentInfo",
			"componentByStableKey",
			"componentMatchesIdentity",
			"hasComponent",
			"componentBytesCopy",
			"cameraGpuRowCopy",
			"getGlobalTransform",
			"globalTransformBlobWordCapacity",
			"cameraBlobWordCapacity",
			"extractGlobalTransformRefs",
		],
	}),
	surfaceAudit("WorldHistory", WorldHistory, {
		tracked: [
			"createEntity",
			"createEntities",
			"spawnBatch",
			"destroyEntity",
			"addComponent",
			"addComponentBytes",
			"addComponentBytesMany",
			"setComponentBytes",
			"setComponentBytesMany",
			"removeComponent",
			"setTransformTrs",
			"setChildOf",
			"setGlobalTransform",
			"setGlobalTransformFormat",
			"setCameraMatrices",
			"runSystemPhase",
		],
		read_only: [
			"enabled",
			"rawMutationGuardEnabled",
			"maxUndoRecords",
			"maxUndoBytes",
			"undoLen",
			"redoLen",
			"undoBytes",
			"redoBytes",
			"undoSummary",
			"redoSummary",
			"undoSerializationReport",
			"redoSerializationReport",
			"validateImportUndoStack",
			"validateImportRedoStack",
			"lastDiagnostic",
			"undoLabel",
			"redoLabel",
			"canUndo",
			"canRedo",
		],
		history_control: [
			"setEnabled",
			"setRawMutationGuardEnabled",
			"setMaxUndoRecords",
			"setMaxUndoBytes",
			"clear",
			"exportUndoStack",
			"exportRedoStack",
			"importUndoStack",
			"importRedoStack",
			"beginTransaction",
			"beginGuardedTransaction",
			"commitTransaction",
			"cancelTransaction",
			"cancelTransactionReverting",
			"undo",
			"redo",
		],
	}),
	surfaceAudit("QueryRow", QueryRow, {
		tracked_callback: ["writeTracked"],
		raw_guarded: ["write"],
		read_only: ["entity", "has", "read"],
	}),
	surfaceAudit("RawQueryRow", RawQueryRow, {
		tracked_callback: ["writeTracked"],
		raw_guarded: ["writeView"],
		read_only: ["entity", "has", "readView"],
	}),
	surfaceAudit("RawQueryArchetype", RawQueryArchetype, {
		tracked_callback: ["writeColumnTracked", "writeColumnRowsTracked"],
		raw_guarded: ["writeColumn"],
		read_only: ["length", "entity", "has", "componentStride", "readColumn"],
	}),
	surfaceAudit("SystemRunner", SystemRunner, {
		raw_guarded: ["runPhase"],
		intentionally_untracked: ["addSystem"],
		read_only: ["len", "hasParallelAccessConflicts"],
	}),
	surfaceAudit("CommandBuffer", CommandBuffer, {
		tracked_command_phase: [
			"createEntity",
			"destroyEntity",
			"addComponent",
			"addComponentBytes",
			"setComponentBytes",
			"setGlobalTransform",
			"setGlobalTransformFormat",
			"setCameraMatrices",
			"removeComponent",
		],
		read_only: ["len", "isEmpty"],
	}),
];

function prototypeMethods(ctor: Prototype): string[] {
	return Object.getOwnPropertyNames(ctor.prototype)
		.filter((name) => name !== "constructor")
		.sort();
}

function ledgerEntries(surface: SurfaceAudit): Map<string, CoverageClass> {
	const entries = new Map<string, CoverageClass>();
	for (const [coverageClass, methods] of Object.entries(surface.methods) as Array<
		[CoverageClass, readonly string[]]
	>) {
		for (const method of methods) {
			expect(entries.has(method), `${surface.name}.${method} is classified twice`).toBe(
				false,
			);
			entries.set(method, coverageClass);
		}
	}
	return entries;
}

describe("ECS TypeScript wrapper: history mutation coverage audit", () => {
	it("classifies every audited public prototype method", () => {
		for (const surface of auditedSurfaces) {
			const actual = prototypeMethods(surface.ctor);
			const ledger = ledgerEntries(surface);
			const expected = [...ledger.keys()].sort();

			expect(actual, `${surface.name} public method audit drifted`).toEqual(
				expected,
			);
			expect(
				expected.length,
				`${surface.name} must keep an explicit history coverage classification`,
			).toBeGreaterThan(0);
		}
	});
});
