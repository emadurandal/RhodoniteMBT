// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { readFileSync } from "node:fs";
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

type MoonBitAuditedReceiver =
	| "World"
	| "WorldHistory"
	| "QueryRow"
	| "RawQueryRow"
	| "RawQueryArchetype"
	| "SystemRunner"
	| "CommandBuffer"
	| "SpawnBatchRow";

type CoverageClass =
	| "tracked"
	| "tracked_callback"
	| "tracked_command_phase"
	| "raw_guarded"
	| "intentionally_untracked"
	| "read_only"
	| "history_control";

type Prototype = { readonly prototype: object };

type MethodLedger = Record<CoverageClass, readonly string[]>;

type SurfaceAudit = {
	readonly name: AuditedClass;
	readonly ctor: Prototype;
	readonly methods: MethodLedger;
};

type MoonBitSurfaceAudit = {
	readonly name: MoonBitAuditedReceiver;
	readonly methods: MethodLedger;
};

const emptyMethods = (): MethodLedger => ({
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
	methods: Partial<MethodLedger>,
): SurfaceAudit => ({
	name,
	ctor,
	methods: { ...emptyMethods(), ...methods },
});

const moonBitSurfaceAudit = (
	name: MoonBitAuditedReceiver,
	methods: Partial<MethodLedger>,
): MoonBitSurfaceAudit => ({
	name,
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

const auditedMoonBitSurfaces: readonly MoonBitSurfaceAudit[] = [
	moonBitSurfaceAudit("World", {
		raw_guarded: [
			"add_component",
			"add_component_bytes",
			"create_entity",
			"destroy_entity",
			"remove_component",
			"reserve_batch_capacity",
			"set_camera_matrices",
			"set_child_of",
			"set_component_bytes",
			"set_global_transform",
			"set_global_transform_format",
			"set_transform",
			"set_transform_trs",
			"spawn_batch",
			"spawn_transform_global_batch",
		],
		intentionally_untracked: [
			"drain_camera_blob_resize_events",
			"drain_camera_blob_write_views",
			"drain_global_transform_blob_resize_events",
			"drain_global_transform_blob_write_views",
			"register_cpu_component",
			"register_cpu_component_with_identity",
			"update_camera_views_from_global_transforms",
			"update_global_transforms_from_transforms",
			"update_transform3d_positions",
			"write_global_transform_blob_range_by_refs",
			"write_global_transform_blob_range_views",
			"write_global_transform_refs_into",
			"write_global_transforms_dense",
			"write_global_transforms_dense_range_views",
			"write_global_transforms_dense_views",
		],
		read_only: [
			"camera_blob_word_capacity",
			"camera_component",
			"camera_gpu_row",
			"camera_home_transform_component",
			"camera_lens_component",
			"camera_ref",
			"child_of_component",
			"component_by_stable_key",
			"component_bytes",
			"component_cpu_stride",
			"component_info",
			"component_matches_identity",
			"component_registration_locked",
			"compute_global_transform",
			"extract_global_transform_refs",
			"get_child_of",
			"get_global_transform",
			"get_transform",
			"global_transform_blob_word_capacity",
			"global_transform_component",
			"global_transform_gpu_format",
			"global_transform_ref",
			"has_component",
			"is_alive",
			"location",
			"new",
			"new_with_global_transform_format",
			"orbit_camera_controller_component",
			"transform_component",
		],
	}),
	moonBitSurfaceAudit("WorldHistory", {
		tracked: [
			"add_component",
			"add_component_bytes",
			"add_component_bytes_many",
			"create_entities",
			"create_entity",
			"destroy_entity",
			"remove_component",
			"run_system_phase",
			"set_camera_matrices",
			"set_child_of",
			"set_component_bytes",
			"set_component_bytes_many",
			"set_global_transform",
			"set_global_transform_format",
			"set_transform_trs",
			"spawn_batch",
		],
		read_only: [
			"can_redo",
			"can_undo",
			"enabled",
			"last_diagnostic",
			"max_undo_bytes",
			"max_undo_records",
			"raw_mutation_guard_enabled",
			"redo_bytes",
			"redo_label",
			"redo_len",
			"redo_serialization_report",
			"redo_summary",
			"undo_bytes",
			"undo_label",
			"undo_len",
			"undo_serialization_report",
			"undo_summary",
			"validate_import_redo_stack",
			"validate_import_undo_stack",
		],
		history_control: [
			"begin_guarded_transaction",
			"begin_transaction",
			"cancel_transaction",
			"cancel_transaction_reverting",
			"clear",
			"commit_transaction",
			"export_redo_stack",
			"export_undo_stack",
			"import_redo_stack",
			"import_undo_stack",
			"new",
			"redo",
			"set_enabled",
			"set_max_undo_bytes",
			"set_max_undo_records",
			"set_raw_mutation_guard_enabled",
			"undo",
		],
	}),
	moonBitSurfaceAudit("QueryRow", {
		tracked_callback: [
			"write_child_of_tracked",
			"write_global_transform_tracked",
			"write_tracked",
			"write_transform3d_tracked",
		],
		raw_guarded: [
			"write",
			"write_child_of",
			"write_global_transform",
			"write_transform3d",
		],
		read_only: ["entity", "has", "read", "read_child_of", "read_transform3d"],
	}),
	moonBitSurfaceAudit("RawQueryRow", {
		tracked_callback: ["write_tracked"],
		raw_guarded: ["write_view"],
		read_only: ["entity", "has", "read_view"],
	}),
	moonBitSurfaceAudit("RawQueryArchetype", {
		tracked_callback: ["write_column_rows_tracked", "write_column_tracked"],
		raw_guarded: ["write_column"],
		read_only: ["component_stride", "entity", "has", "length", "read_column"],
	}),
	moonBitSurfaceAudit("SystemRunner", {
		raw_guarded: ["run_phase"],
		intentionally_untracked: ["add_system"],
		read_only: ["has_parallel_access_conflicts", "len", "new"],
	}),
	moonBitSurfaceAudit("CommandBuffer", {
		tracked_command_phase: [
			"add_component",
			"add_component_bytes",
			"create_entity",
			"destroy_entity",
			"remove_component",
			"set_camera_matrices",
			"set_component_bytes",
			"set_global_transform",
			"set_global_transform_format",
		],
		read_only: ["is_empty", "len"],
	}),
	moonBitSurfaceAudit("SpawnBatchRow", {
		raw_guarded: ["write", "write_view"],
		read_only: ["entity"],
	}),
];

function prototypeMethods(ctor: Prototype): string[] {
	return Object.getOwnPropertyNames(ctor.prototype)
		.filter((name) => name !== "constructor")
		.sort();
}

function ledgerEntries(
	surface: Pick<SurfaceAudit, "name" | "methods">,
): Map<string, CoverageClass> {
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

function moonBitPublicMethodsByReceiver(
	mbti: string,
	receivers: readonly MoonBitAuditedReceiver[],
): Map<MoonBitAuditedReceiver, string[]> {
	const receiverSet = new Set<string>(receivers);
	const methods = new Map<MoonBitAuditedReceiver, string[]>(
		receivers.map((receiver) => [receiver, []]),
	);
	const pattern = /^pub fn ([A-Za-z][A-Za-z0-9_]*)::([A-Za-z_][A-Za-z0-9_]*)\(/gm;
	for (const match of mbti.matchAll(pattern)) {
		const receiver = match[1] as MoonBitAuditedReceiver;
		const method = match[2];
		if (method !== undefined && receiverSet.has(receiver)) {
			methods.get(receiver)?.push(method);
		}
	}
	for (const values of methods.values()) {
		values.sort();
	}
	return methods;
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

	it("classifies every audited MoonBit public method", () => {
		const mbti = readFileSync(new URL("../pkg.generated.mbti", import.meta.url), {
			encoding: "utf8",
		});
		const publicMethods = moonBitPublicMethodsByReceiver(
			mbti,
			auditedMoonBitSurfaces.map((surface) => surface.name),
		);

		for (const surface of auditedMoonBitSurfaces) {
			const actual = publicMethods.get(surface.name) ?? [];
			const ledger = ledgerEntries(surface);
			const expected = [...ledger.keys()].sort();

			expect(actual, `${surface.name} MoonBit public method audit drifted`).toEqual(
				expected,
			);
			expect(
				expected.length,
				`${surface.name} must keep an explicit MoonBit history coverage classification`,
			).toBeGreaterThan(0);
		}
	});
});
