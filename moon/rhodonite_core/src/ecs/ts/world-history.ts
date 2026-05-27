// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import * as bridge from "@moon/rhodonite_core/ecs/js_bridge";
import { ComponentTypeId, EntityId } from "./types.ts";
import type { PhaseKey, SystemContext, SystemRunner } from "./system.ts";
import { SystemRunReport } from "./system.ts";
import { bytesInput, moonBool } from "./views.ts";
import type { World } from "./world-core.ts";
import { SpawnBatchRow } from "./world-primitives.ts";
import {
	historyExportFromBridge,
	historyExportToBridge,
	historyImportValidationReportFromBridge,
	historyRecordSummaryFromBridge,
	historySerializationReportFromBridge,
} from "./world-history-conversion.ts";
import type {
	HistoryExport,
	HistoryDiagnosticReason,
	HistoryImportValidationReport,
	HistoryRecordSummary,
	HistorySerializationReport,
} from "./world-history-types.ts";

export type WorldHistoryTransactionOptions = {
	readonly guarded?: boolean;
};

export class WorldHistory {
	readonly inner: bridge.MoonWorldHistory;

	constructor(inner: bridge.MoonWorldHistory) {
		this.inner = inner;
	}

	static new(): WorldHistory {
		return new WorldHistory(bridge.world_history_new());
	}

	enabled(): boolean {
		return moonBool(bridge.world_history_enabled(this.inner));
	}

	setEnabled(enabled: boolean): void {
		bridge.world_history_set_enabled(this.inner, enabled);
	}

	rawMutationGuardEnabled(): boolean {
		return moonBool(bridge.world_history_raw_mutation_guard_enabled(this.inner));
	}

	setRawMutationGuardEnabled(enabled: boolean): void {
		bridge.world_history_set_raw_mutation_guard_enabled(this.inner, enabled);
	}

	maxUndoRecords(): number {
		return bridge.world_history_max_undo_records(this.inner);
	}

	maxUndoBytes(): number {
		return bridge.world_history_max_undo_bytes(this.inner);
	}

	setMaxUndoRecords(limit: number): void {
		bridge.world_history_set_max_undo_records(this.inner, limit);
	}

	setMaxUndoBytes(limit: number): void {
		bridge.world_history_set_max_undo_bytes(this.inner, limit);
	}

	clear(): void {
		bridge.world_history_clear(this.inner);
	}

	undoLen(): number {
		return bridge.world_history_undo_len(this.inner);
	}

	redoLen(): number {
		return bridge.world_history_redo_len(this.inner);
	}

	undoBytes(): number {
		return bridge.world_history_undo_bytes(this.inner);
	}

	redoBytes(): number {
		return bridge.world_history_redo_bytes(this.inner);
	}

	undoSummary(): HistoryRecordSummary[] {
		return bridge.world_history_undo_summary(this.inner).map((summary) =>
			historyRecordSummaryFromBridge(summary),
		);
	}

	redoSummary(): HistoryRecordSummary[] {
		return bridge.world_history_redo_summary(this.inner).map((summary) =>
			historyRecordSummaryFromBridge(summary),
		);
	}

	undoSerializationReport(world: World): HistorySerializationReport {
		return historySerializationReportFromBridge(
			bridge.world_history_undo_serialization_report(this.inner, world.inner),
		);
	}

	redoSerializationReport(world: World): HistorySerializationReport {
		return historySerializationReportFromBridge(
			bridge.world_history_redo_serialization_report(this.inner, world.inner),
		);
	}

	exportUndoStack(world: World): HistoryExport | null {
		const exported = bridge.world_history_export_undo_stack(this.inner, world.inner);
		return exported == null ? null : historyExportFromBridge(exported);
	}

	exportRedoStack(world: World): HistoryExport | null {
		const exported = bridge.world_history_export_redo_stack(this.inner, world.inner);
		return exported == null ? null : historyExportFromBridge(exported);
	}

	importUndoStack(world: World, archive: HistoryExport): boolean {
		return moonBool(
			bridge.world_history_import_undo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	importRedoStack(world: World, archive: HistoryExport): boolean {
		return moonBool(
			bridge.world_history_import_redo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	validateImportUndoStack(
		world: World,
		archive: HistoryExport,
	): HistoryImportValidationReport {
		return historyImportValidationReportFromBridge(
			bridge.world_history_validate_import_undo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	validateImportRedoStack(
		world: World,
		archive: HistoryExport,
	): HistoryImportValidationReport {
		return historyImportValidationReportFromBridge(
			bridge.world_history_validate_import_redo_stack(
				this.inner,
				world.inner,
				historyExportToBridge(archive),
			),
		);
	}

	lastDiagnostic(): HistoryDiagnosticReason {
		return bridge.world_history_last_diagnostic(this.inner) as HistoryDiagnosticReason;
	}

	undoLabel(): string | null {
		return bridge.world_history_undo_label(this.inner) ?? null;
	}

	redoLabel(): string | null {
		return bridge.world_history_redo_label(this.inner) ?? null;
	}

	beginTransaction(label: string): boolean {
		return moonBool(bridge.world_history_begin_transaction(this.inner, label));
	}

	beginGuardedTransaction(world: World, label: string): boolean {
		return moonBool(
			bridge.world_history_begin_guarded_transaction(this.inner, world.inner, label),
		);
	}

	commitTransaction(): boolean {
		return moonBool(bridge.world_history_commit_transaction(this.inner));
	}

	cancelTransaction(): boolean {
		return moonBool(bridge.world_history_cancel_transaction(this.inner));
	}

	cancelTransactionReverting(world: World): boolean {
		return moonBool(
			bridge.world_history_cancel_transaction_reverting(this.inner, world.inner),
		);
	}

	withTransaction(
		world: World,
		label: string,
		callback: () => boolean,
		options: WorldHistoryTransactionOptions = {},
	): boolean {
		const opened =
			options.guarded === true
				? this.beginGuardedTransaction(world, label)
				: this.beginTransaction(label);
		if (!opened) {
			return false;
		}
		try {
			if (callback()) {
				if (this.commitTransaction()) {
					return true;
				}
				bridge.world_history_cancel_transaction_preserving_diagnostic(this.inner);
				return false;
			}
			this.cancelTransactionReverting(world);
			return false;
		} catch (error) {
			this.cancelTransactionReverting(world);
			throw error;
		}
	}

	withGuardedTransaction(
		world: World,
		label: string,
		callback: () => boolean,
	): boolean {
		return this.withTransaction(world, label, callback, { guarded: true });
	}

	canUndo(): boolean {
		return moonBool(bridge.world_history_can_undo(this.inner));
	}

	canRedo(): boolean {
		return moonBool(bridge.world_history_can_redo(this.inner));
	}

	undo(world: World): boolean {
		return moonBool(bridge.world_history_undo(this.inner, world.inner));
	}

	redo(world: World): boolean {
		return moonBool(bridge.world_history_redo(this.inner, world.inner));
	}

	createEntity(world: World): EntityId {
		return new EntityId(bridge.world_history_create_entity(this.inner, world.inner));
	}

	createEntities(world: World, count: number): EntityId[] {
		return bridge.world_history_create_entities(this.inner, world.inner, count).map(
			(entity) => new EntityId(entity),
		);
	}

	spawnBatch(
		world: World,
		components: ComponentTypeId[],
		count: number,
		f: (index: number, entity: EntityId, row: SpawnBatchRow) => void,
	): EntityId[] {
		return bridge.world_history_spawn_batch(
			this.inner,
			world.inner,
			components.map((component) => component.inner),
			count,
			(index, entity, row) =>
				f(index, new EntityId(entity), new SpawnBatchRow(row)),
		).map((entity) => new EntityId(entity));
	}

	destroyEntity(world: World, entity: EntityId): boolean {
		return moonBool(
			bridge.world_history_destroy_entity(this.inner, world.inner, entity.inner),
		);
	}

	addComponent(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
	): boolean {
		return moonBool(
			bridge.world_history_add_component(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
			),
		);
	}

	addComponentBytes(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): boolean {
		return moonBool(
			bridge.world_history_add_component_bytes(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
				bytesInput(bytes),
			),
		);
	}

	addComponentBytesMany(
		world: World,
		component: ComponentTypeId,
		entities: EntityId[],
		bytesList: Array<Uint8Array | ArrayLike<number>>,
	): boolean {
		return moonBool(
			bridge.world_history_add_component_bytes_many(
				this.inner,
				world.inner,
				component.inner,
				entities.map((entity) => entity.inner),
				bytesList.map((bytes) => bytesInput(bytes)),
			),
		);
	}

	setComponentBytes(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
		bytes: Uint8Array | ArrayLike<number>,
	): boolean {
		return moonBool(
			bridge.world_history_set_component_bytes(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
				bytesInput(bytes),
			),
		);
	}

	setComponentBytesMany(
		world: World,
		component: ComponentTypeId,
		entities: EntityId[],
		bytesList: Array<Uint8Array | ArrayLike<number>>,
	): boolean {
		return moonBool(
			bridge.world_history_set_component_bytes_many(
				this.inner,
				world.inner,
				component.inner,
				entities.map((entity) => entity.inner),
				bytesList.map((bytes) => bytesInput(bytes)),
			),
		);
	}

	removeComponent(
		world: World,
		entity: EntityId,
		component: ComponentTypeId,
	): boolean {
		return moonBool(
			bridge.world_history_remove_component(
				this.inner,
				world.inner,
				entity.inner,
				component.inner,
			),
		);
	}

	setTransformTrs(
		world: World,
		entity: EntityId,
		px: number,
		py: number,
		pz: number,
		qx: number,
		qy: number,
		qz: number,
		qw: number,
		sx: number,
		sy: number,
		sz: number,
	): boolean {
		return moonBool(
			bridge.world_history_set_transform_trs(
				this.inner,
				world.inner,
				entity.inner,
				px,
				py,
				pz,
				qx,
				qy,
				qz,
				qw,
				sx,
				sy,
				sz,
			),
		);
	}

	setChildOf(world: World, entity: EntityId, parent: EntityId): boolean {
		return moonBool(
			bridge.world_history_set_child_of(
				this.inner,
				world.inner,
				entity.inner,
				parent.inner,
			),
		);
	}

	setGlobalTransform(
		world: World,
		entity: EntityId,
		matrixColMajor: ArrayLike<number>,
	): boolean {
		return moonBool(
			bridge.world_history_set_global_transform_col_major(
				this.inner,
				world.inner,
				entity.inner,
				Array.from(matrixColMajor),
			),
		);
	}

	setGlobalTransformFormat(
		world: World,
		entity: EntityId,
		formatCode: 0 | 1,
	): boolean {
		return moonBool(
			bridge.world_history_set_global_transform_format(
				this.inner,
				world.inner,
				entity.inner,
				formatCode,
			),
		);
	}

	setCameraMatrices(
		world: World,
		entity: EntityId,
		viewColMajor: ArrayLike<number>,
		projColMajor: ArrayLike<number>,
		near: number,
		far: number,
		aspect: number,
		projectionKind: number,
		flags: number,
	): boolean {
		return moonBool(
			bridge.world_history_set_camera_matrices_col_major(
				this.inner,
				world.inner,
				entity.inner,
				Array.from(viewColMajor),
				Array.from(projColMajor),
				near,
				far,
				aspect,
				projectionKind,
				flags,
			),
		);
	}

	runSystemPhase(
		runner: SystemRunner,
		world: World,
		ctx: SystemContext,
		phase: PhaseKey,
		label: string,
	): boolean {
		return moonBool(
			bridge.world_history_run_system_phase(
				this.inner,
				runner.inner,
				world.inner,
				ctx.inner,
				phase.inner,
				label,
			),
		);
	}

	runSystemPhaseReport(
		runner: SystemRunner,
		world: World,
		ctx: SystemContext,
		phase: PhaseKey,
		label: string,
	): SystemRunReport {
		return new SystemRunReport(
			bridge.world_history_run_system_phase_report(
				this.inner,
				runner.inner,
				world.inner,
				ctx.inner,
				phase.inner,
				label,
			),
		);
	}
}
