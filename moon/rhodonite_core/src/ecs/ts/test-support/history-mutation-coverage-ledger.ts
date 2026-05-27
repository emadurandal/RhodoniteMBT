// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { expect } from "vitest";
import {
	CommandBuffer,
	QueryRow,
	RawQueryArchetype,
	RawQueryRow,
	SystemRunner,
	World,
	WorldHistory,
} from "../index.ts";

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

export type WrapperSourceName = "world-history.ts" | "query.ts" | "system.ts";

type BridgeParityEntry = {
	readonly label: string;
	readonly bridge: string;
	readonly wrapperSource: WrapperSourceName;
	readonly surface: AuditedClass;
	readonly tsMethod: string;
	readonly moonBitReceiver?: MoonBitAuditedReceiver;
	readonly moonBitMethod?: string;
};

type CameraControlParityEntry = {
	readonly moonBitFunction: string;
	readonly tsExport: string;
};

type MoonBitOnlyTrackedEntry = {
	readonly label: string;
	readonly receiver: MoonBitAuditedReceiver;
	readonly method: string;
	readonly reservedBridge: string;
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

export const auditedSurfaces: readonly SurfaceAudit[] = [
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
			"runSystemPhaseReport",
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
			"withTransaction",
			"withGuardedTransaction",
			"commitTransaction",
			"cancelTransaction",
			"cancelTransactionReverting",
			"undo",
			"redo",
		],
	}),
	surfaceAudit("QueryRow", QueryRow, {
		tracked_callback: ["writeTracked", "writeTrackedAt"],
		raw_guarded: ["write", "writeAt"],
		read_only: ["entity", "has", "hasAt", "read", "readAt"],
	}),
	surfaceAudit("RawQueryRow", RawQueryRow, {
		tracked_callback: ["writeTracked", "writeTrackedAt"],
		raw_guarded: ["writeView", "writeViewAt"],
		read_only: ["entity", "has", "hasAt", "readView", "readViewAt"],
	}),
	surfaceAudit("RawQueryArchetype", RawQueryArchetype, {
		tracked_callback: [
			"writeColumnTracked",
			"writeColumnTrackedAt",
			"writeColumnRowsTracked",
			"writeColumnRowsTrackedAt",
		],
		raw_guarded: ["writeColumn", "writeColumnAt"],
		read_only: [
			"length",
			"entity",
			"has",
			"hasAt",
			"componentStride",
			"componentStrideAt",
			"readColumn",
			"readColumnAt",
		],
	}),
	surfaceAudit("SystemRunner", SystemRunner, {
		raw_guarded: ["runPhase", "runPhaseReport"],
		intentionally_untracked: ["addSystem"],
		read_only: ["len", "hasParallelAccessConflicts", "planPhase"],
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

export const auditedMoonBitSurfaces: readonly MoonBitSurfaceAudit[] = [
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
			"has_camera_blob_write_views",
			"has_component",
			"has_global_transform_blob_write_views",
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
			"run_system_phase_report",
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
			"cancel_transaction_preserving_diagnostic",
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
			"with_guarded_transaction",
			"with_transaction",
		],
	}),
	moonBitSurfaceAudit("QueryRow", {
		tracked_callback: [
			"write_child_of_tracked",
			"write_global_transform_tracked",
			"write_tracked",
			"write_tracked_at",
			"write_transform3d_tracked",
		],
		raw_guarded: [
			"write",
			"write_at",
			"write_child_of",
			"write_global_transform",
			"write_transform3d",
		],
		read_only: [
			"entity",
			"has",
			"has_at",
			"read",
			"read_at",
			"read_child_of",
			"read_transform3d",
		],
	}),
	moonBitSurfaceAudit("RawQueryRow", {
		tracked_callback: ["write_tracked", "write_tracked_at"],
		raw_guarded: ["write_view", "write_view_at"],
		read_only: ["entity", "has", "has_at", "read_view", "read_view_at"],
	}),
	moonBitSurfaceAudit("RawQueryArchetype", {
		tracked_callback: [
			"write_column_rows_tracked",
			"write_column_rows_tracked_at",
			"write_column_tracked",
			"write_column_tracked_at",
		],
		raw_guarded: ["write_column", "write_column_at"],
		read_only: [
			"component_stride",
			"component_stride_at",
			"entity",
			"has",
			"has_at",
			"length",
			"read_column",
			"read_column_at",
		],
	}),
	moonBitSurfaceAudit("SystemRunner", {
		raw_guarded: ["run_phase", "run_phase_report"],
		intentionally_untracked: ["add_system"],
		read_only: ["has_parallel_access_conflicts", "len", "new", "plan_phase"],
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

export const bridgeParityEntries: readonly BridgeParityEntry[] = [
	{
		label: "WorldHistory::create_entity",
		bridge: "world_history_create_entity",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "createEntity",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "create_entity",
	},
	{
		label: "WorldHistory::create_entities",
		bridge: "world_history_create_entities",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "createEntities",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "create_entities",
	},
	{
		label: "WorldHistory::spawn_batch",
		bridge: "world_history_spawn_batch",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "spawnBatch",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "spawn_batch",
	},
	{
		label: "WorldHistory::destroy_entity",
		bridge: "world_history_destroy_entity",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "destroyEntity",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "destroy_entity",
	},
	{
		label: "WorldHistory::add_component",
		bridge: "world_history_add_component",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "addComponent",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "add_component",
	},
	{
		label: "WorldHistory::add_component_bytes",
		bridge: "world_history_add_component_bytes",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "addComponentBytes",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "add_component_bytes",
	},
	{
		label: "WorldHistory::add_component_bytes_many",
		bridge: "world_history_add_component_bytes_many",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "addComponentBytesMany",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "add_component_bytes_many",
	},
	{
		label: "WorldHistory::set_component_bytes",
		bridge: "world_history_set_component_bytes",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setComponentBytes",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_component_bytes",
	},
	{
		label: "WorldHistory::set_component_bytes_many",
		bridge: "world_history_set_component_bytes_many",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setComponentBytesMany",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_component_bytes_many",
	},
	{
		label: "WorldHistory::remove_component",
		bridge: "world_history_remove_component",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "removeComponent",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "remove_component",
	},
	{
		label: "WorldHistory::set_transform_trs",
		bridge: "world_history_set_transform_trs",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setTransformTrs",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_transform_trs",
	},
	{
		label: "WorldHistory::set_child_of",
		bridge: "world_history_set_child_of",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setChildOf",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_child_of",
	},
	{
		label: "WorldHistory::set_global_transform",
		bridge: "world_history_set_global_transform_col_major",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setGlobalTransform",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_global_transform",
	},
	{
		label: "WorldHistory::set_global_transform_format",
		bridge: "world_history_set_global_transform_format",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setGlobalTransformFormat",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_global_transform_format",
	},
	{
		label: "WorldHistory::set_camera_matrices",
		bridge: "world_history_set_camera_matrices_col_major",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "setCameraMatrices",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "set_camera_matrices",
	},
	{
		label: "WorldHistory::run_system_phase",
		bridge: "world_history_run_system_phase",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "runSystemPhase",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "run_system_phase",
	},
	{
		label: "WorldHistory::run_system_phase_report",
		bridge: "world_history_run_system_phase_report",
		wrapperSource: "world-history.ts",
		surface: "WorldHistory",
		tsMethod: "runSystemPhaseReport",
		moonBitReceiver: "WorldHistory",
		moonBitMethod: "run_system_phase_report",
	},
	{
		label: "QueryRow::write_tracked",
		bridge: "query_row_write_tracked",
		wrapperSource: "query.ts",
		surface: "QueryRow",
		tsMethod: "writeTracked",
		moonBitReceiver: "QueryRow",
		moonBitMethod: "write_tracked",
	},
	{
		label: "QueryRow::write_tracked_at",
		bridge: "query_row_write_tracked_at",
		wrapperSource: "query.ts",
		surface: "QueryRow",
		tsMethod: "writeTrackedAt",
		moonBitReceiver: "QueryRow",
		moonBitMethod: "write_tracked_at",
	},
	{
		label: "RawQueryRow::write_tracked",
		bridge: "raw_query_row_write_tracked",
		wrapperSource: "query.ts",
		surface: "RawQueryRow",
		tsMethod: "writeTracked",
		moonBitReceiver: "RawQueryRow",
		moonBitMethod: "write_tracked",
	},
	{
		label: "RawQueryRow::write_tracked_at",
		bridge: "raw_query_row_write_tracked_at",
		wrapperSource: "query.ts",
		surface: "RawQueryRow",
		tsMethod: "writeTrackedAt",
		moonBitReceiver: "RawQueryRow",
		moonBitMethod: "write_tracked_at",
	},
	{
		label: "RawQueryArchetype::write_column_tracked",
		bridge: "raw_query_archetype_write_column_tracked",
		wrapperSource: "query.ts",
		surface: "RawQueryArchetype",
		tsMethod: "writeColumnTracked",
		moonBitReceiver: "RawQueryArchetype",
		moonBitMethod: "write_column_tracked",
	},
	{
		label: "RawQueryArchetype::write_column_tracked_at",
		bridge: "raw_query_archetype_write_column_tracked_at",
		wrapperSource: "query.ts",
		surface: "RawQueryArchetype",
		tsMethod: "writeColumnTrackedAt",
		moonBitReceiver: "RawQueryArchetype",
		moonBitMethod: "write_column_tracked_at",
	},
	{
		label: "RawQueryArchetype::write_column_rows_tracked",
		bridge: "raw_query_archetype_write_column_rows_tracked",
		wrapperSource: "query.ts",
		surface: "RawQueryArchetype",
		tsMethod: "writeColumnRowsTracked",
		moonBitReceiver: "RawQueryArchetype",
		moonBitMethod: "write_column_rows_tracked",
	},
	{
		label: "RawQueryArchetype::write_column_rows_tracked_at",
		bridge: "raw_query_archetype_write_column_rows_tracked_at",
		wrapperSource: "query.ts",
		surface: "RawQueryArchetype",
		tsMethod: "writeColumnRowsTrackedAt",
		moonBitReceiver: "RawQueryArchetype",
		moonBitMethod: "write_column_rows_tracked_at",
	},
	{
		label: "CommandBuffer::create_entity",
		bridge: "command_buffer_create_entity",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "createEntity",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "create_entity",
	},
	{
		label: "CommandBuffer::destroy_entity",
		bridge: "command_buffer_destroy_entity",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "destroyEntity",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "destroy_entity",
	},
	{
		label: "CommandBuffer::add_component",
		bridge: "command_buffer_add_component",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "addComponent",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "add_component",
	},
	{
		label: "CommandBuffer::add_component_bytes",
		bridge: "command_buffer_add_component_bytes",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "addComponentBytes",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "add_component_bytes",
	},
	{
		label: "CommandBuffer::set_component_bytes",
		bridge: "command_buffer_set_component_bytes",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "setComponentBytes",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "set_component_bytes",
	},
	{
		label: "CommandBuffer::set_global_transform",
		bridge: "command_buffer_set_global_transform_col_major",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "setGlobalTransform",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "set_global_transform",
	},
	{
		label: "CommandBuffer::set_global_transform_format",
		bridge: "command_buffer_set_global_transform_format",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "setGlobalTransformFormat",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "set_global_transform_format",
	},
	{
		label: "CommandBuffer::set_camera_matrices",
		bridge: "command_buffer_set_camera_matrices_col_major",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "setCameraMatrices",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "set_camera_matrices",
	},
	{
		label: "CommandBuffer::remove_component",
		bridge: "command_buffer_remove_component",
		wrapperSource: "system.ts",
		surface: "CommandBuffer",
		tsMethod: "removeComponent",
		moonBitReceiver: "CommandBuffer",
		moonBitMethod: "remove_component",
	},
];

export const cameraControlParityEntries: readonly CameraControlParityEntry[] = [
	{
		moonBitFunction: "add_camera_lens_orthographic_tracked",
		tsExport: "addCameraLensOrthographicTracked",
	},
	{
		moonBitFunction: "add_camera_lens_perspective_tracked",
		tsExport: "addCameraLensPerspectiveTracked",
	},
	{
		moonBitFunction: "add_orbit_camera_controller_tracked",
		tsExport: "addOrbitCameraControllerTracked",
	},
	{
		moonBitFunction: "add_orbit_camera_controller_with_distance_tracked",
		tsExport: "addOrbitCameraControllerWithDistanceTracked",
	},
	{
		moonBitFunction: "add_orbit_camera_controller_with_pose_tracked",
		tsExport: "addOrbitCameraControllerWithPoseTracked",
	},
	{
		moonBitFunction: "request_orbit_camera_reset_tracked",
		tsExport: "requestOrbitCameraResetTracked",
	},
	{
		moonBitFunction: "set_camera_home_from_current_transform_tracked",
		tsExport: "setCameraHomeFromCurrentTransformTracked",
	},
	{
		moonBitFunction: "set_camera_lens_orthographic_tracked",
		tsExport: "setCameraLensOrthographicTracked",
	},
	{
		moonBitFunction: "set_camera_lens_perspective_tracked",
		tsExport: "setCameraLensPerspectiveTracked",
	},
	{
		moonBitFunction: "setup_orbit_orthographic_camera_tracked",
		tsExport: "setupOrbitOrthographicCameraTracked",
	},
	{
		moonBitFunction: "sync_orbit_camera_blob_component_tracked",
		tsExport: "syncOrbitCameraBlobComponentTracked",
	},
	{
		moonBitFunction: "sync_orbit_camera_transform_component_tracked",
		tsExport: "syncOrbitCameraTransformComponentTracked",
	},
	{
		moonBitFunction: "update_orbit_camera_controller_from_mouse_frame_tracked",
		tsExport: "updateOrbitCameraControllerComponentFromMouseFrameTracked",
	},
];

export const moonBitOnlyTrackedEntries: readonly MoonBitOnlyTrackedEntry[] = [
	{
		label: "QueryRow::write_child_of_tracked",
		receiver: "QueryRow",
		method: "write_child_of_tracked",
		reservedBridge: "query_row_write_child_of_tracked",
	},
	{
		label: "QueryRow::write_global_transform_tracked",
		receiver: "QueryRow",
		method: "write_global_transform_tracked",
		reservedBridge: "query_row_write_global_transform_tracked",
	},
	{
		label: "QueryRow::write_transform3d_tracked",
		receiver: "QueryRow",
		method: "write_transform3d_tracked",
		reservedBridge: "query_row_write_transform3d_tracked",
	},
];

export const auditedClassByName: Record<AuditedClass, Prototype> = {
	World,
	WorldHistory,
	QueryRow,
	RawQueryRow,
	RawQueryArchetype,
	SystemRunner,
	CommandBuffer,
};

export const wrapperSourceUrls: Record<WrapperSourceName, URL> = {
	"world-history.ts": new URL("../world-history.ts", import.meta.url),
	"query.ts": new URL("../query.ts", import.meta.url),
	"system.ts": new URL("../system.ts", import.meta.url),
};

export function prototypeMethods(ctor: Prototype): string[] {
	return Object.getOwnPropertyNames(ctor.prototype)
		.filter((name) => name !== "constructor")
		.sort();
}

export function ledgerEntries(
	surface: { readonly name: string; readonly methods: MethodLedger },
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

export function assertUniqueLabels(
	labels: readonly string[],
	kind: string,
): void {
	const seen = new Set<string>();
	for (const label of labels) {
		expect(seen.has(label), `${kind} duplicates ${label}`).toBe(false);
		seen.add(label);
	}
}
