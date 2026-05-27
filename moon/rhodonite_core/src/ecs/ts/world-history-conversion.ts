// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import * as bridge from "@moon/rhodonite_core/ecs/js_bridge";
import { ComponentTypeId, EntityId } from "./types.ts";
import { moonBool } from "./views.ts";
import type {
	HistoryDeltaKind,
	HistoryDeltaSummary,
	HistoryExport,
	HistoryExportComponentIdentity,
	HistoryExportComponentSnapshot,
	HistoryExportDelta,
	HistoryExportPayload,
	HistoryExportRecord,
	HistoryImportValidationDeltaReport,
	HistoryImportValidationReason,
	HistoryImportValidationRecordReport,
	HistoryImportValidationReport,
	HistoryRecordSummary,
	HistorySerializationComponentReport,
	HistorySerializationDeltaReport,
	HistorySerializationReason,
	HistorySerializationRecordReport,
	HistorySerializationReport,
} from "./world-history-types.ts";

export function historyExportBytes(bytes: Uint8Array | number[]): Uint8Array {
	return bytes instanceof Uint8Array ? new Uint8Array(bytes) : Uint8Array.from(bytes);
}

export function historySummaryEntity(
	entity:
		| ReturnType<typeof bridge.world_history_delta_summary_entity>
		| null
		| undefined,
): EntityId | null {
	return entity == null ? null : new EntityId(entity);
}

export function historySummaryComponent(
	component:
		| ReturnType<typeof bridge.world_history_delta_summary_component>
		| null
		| undefined,
): ComponentTypeId | null {
	return component == null ? null : new ComponentTypeId(component);
}

export function historyDeltaSummaryFromBridge(
	summary: bridge.MoonWorldHistoryDeltaSummary,
): HistoryDeltaSummary {
	return {
		kind: bridge.world_history_delta_summary_kind(summary) as HistoryDeltaKind,
		entity: historySummaryEntity(bridge.world_history_delta_summary_entity(summary)),
		component: historySummaryComponent(
			bridge.world_history_delta_summary_component(summary),
		),
		componentCount: bridge.world_history_delta_summary_component_count(summary),
		payloadBytes: bridge.world_history_delta_summary_payload_bytes(summary),
		beforePresent: moonBool(bridge.world_history_delta_summary_before_present(summary)),
		afterPresent: moonBool(bridge.world_history_delta_summary_after_present(summary)),
	};
}

export function historyRecordSummaryFromBridge(
	summary: bridge.MoonWorldHistoryRecordSummary,
): HistoryRecordSummary {
	return {
		label: bridge.world_history_record_summary_label(summary),
		deltaCount: bridge.world_history_record_summary_delta_count(summary),
		payloadBytes: bridge.world_history_record_summary_payload_bytes(summary),
		deltas: bridge.world_history_record_summary_deltas(summary).map((delta) =>
			historyDeltaSummaryFromBridge(delta),
		),
	};
}

export function historySerializationComponentReportFromBridge(
	report: bridge.MoonWorldHistorySerializationComponentReport,
): HistorySerializationComponentReport {
	return {
		component: new ComponentTypeId(
			bridge.world_history_serialization_component_report_component(report),
		),
		serializable: moonBool(
			bridge.world_history_serialization_component_report_serializable(report),
		),
		reason: bridge.world_history_serialization_component_report_reason(
			report,
		) as HistorySerializationReason,
		stableKey:
			bridge.world_history_serialization_component_report_stable_key(report) ?? null,
	};
}

export function historySerializationDeltaReportFromBridge(
	report: bridge.MoonWorldHistorySerializationDeltaReport,
): HistorySerializationDeltaReport {
	return {
		kind: bridge.world_history_serialization_delta_report_kind(
			report,
		) as HistoryDeltaKind,
		entity: historySummaryEntity(
			bridge.world_history_serialization_delta_report_entity(report),
		),
		component: historySummaryComponent(
			bridge.world_history_serialization_delta_report_component(report),
		),
		componentCount:
			bridge.world_history_serialization_delta_report_component_count(report),
		serializable: moonBool(
			bridge.world_history_serialization_delta_report_serializable(report),
		),
		reason: bridge.world_history_serialization_delta_report_reason(
			report,
		) as HistorySerializationReason,
		payloadBytes: bridge.world_history_serialization_delta_report_payload_bytes(report),
		components: bridge.world_history_serialization_delta_report_components(report).map(
			(component) => historySerializationComponentReportFromBridge(component),
		),
	};
}

export function historySerializationRecordReportFromBridge(
	report: bridge.MoonWorldHistorySerializationRecordReport,
): HistorySerializationRecordReport {
	return {
		label: bridge.world_history_serialization_record_report_label(report),
		serializable: moonBool(
			bridge.world_history_serialization_record_report_serializable(report),
		),
		reason: bridge.world_history_serialization_record_report_reason(
			report,
		) as HistorySerializationReason,
		deltaCount: bridge.world_history_serialization_record_report_delta_count(report),
		payloadBytes: bridge.world_history_serialization_record_report_payload_bytes(report),
		deltas: bridge.world_history_serialization_record_report_deltas(report).map(
			(delta) => historySerializationDeltaReportFromBridge(delta),
		),
	};
}

export function historySerializationReportFromBridge(
	report: bridge.MoonWorldHistorySerializationReport,
): HistorySerializationReport {
	return {
		serializable: moonBool(
			bridge.world_history_serialization_report_serializable(report),
		),
		recordCount: bridge.world_history_serialization_report_record_count(report),
		records: bridge.world_history_serialization_report_records(report).map((record) =>
			historySerializationRecordReportFromBridge(record),
		),
	};
}

export function historyImportValidationDeltaReportFromBridge(
	report: bridge.MoonWorldHistoryImportValidationDeltaReport,
): HistoryImportValidationDeltaReport {
	return {
		index: bridge.world_history_import_validation_delta_report_index(report),
		kind: bridge.world_history_import_validation_delta_report_kind(report),
		entity: historySummaryEntity(
			bridge.world_history_import_validation_delta_report_entity(report),
		),
		component: historySummaryComponent(
			bridge.world_history_import_validation_delta_report_component(report),
		),
		componentKey:
			bridge.world_history_import_validation_delta_report_component_key(report) ??
			null,
		valid: moonBool(bridge.world_history_import_validation_delta_report_valid(report)),
		reason: bridge.world_history_import_validation_delta_report_reason(
			report,
		) as HistoryImportValidationReason,
	};
}

export function historyImportValidationRecordReportFromBridge(
	report: bridge.MoonWorldHistoryImportValidationRecordReport,
): HistoryImportValidationRecordReport {
	return {
		index: bridge.world_history_import_validation_record_report_index(report),
		label: bridge.world_history_import_validation_record_report_label(report),
		valid: moonBool(bridge.world_history_import_validation_record_report_valid(report)),
		reason: bridge.world_history_import_validation_record_report_reason(
			report,
		) as HistoryImportValidationReason,
		deltaCount: bridge.world_history_import_validation_record_report_delta_count(report),
		deltas: bridge.world_history_import_validation_record_report_deltas(report).map(
			(delta) => historyImportValidationDeltaReportFromBridge(delta),
		),
	};
}

export function historyImportValidationReportFromBridge(
	report: bridge.MoonWorldHistoryImportValidationReport,
): HistoryImportValidationReport {
	return {
		valid: moonBool(bridge.world_history_import_validation_report_valid(report)),
		reason: bridge.world_history_import_validation_report_reason(
			report,
		) as HistoryImportValidationReason,
		formatVersion: bridge.world_history_import_validation_report_format_version(report),
		recordCount: bridge.world_history_import_validation_report_record_count(report),
		records: bridge.world_history_import_validation_report_records(report).map(
			(record) => historyImportValidationRecordReportFromBridge(record),
		),
	};
}

export function historyExportComponentIdentityFromBridge(
	identity: bridge.MoonWorldHistoryExportComponentIdentity,
): HistoryExportComponentIdentity {
	return {
		localComponent: new ComponentTypeId(
			bridge.world_history_export_component_identity_local_component(identity),
		),
		key: bridge.world_history_export_component_identity_key(identity),
		builtin: moonBool(bridge.world_history_export_component_identity_builtin(identity)),
		schemaVersion:
			bridge.world_history_export_component_identity_schema_version(identity) ?? null,
		schemaHash:
			bridge.world_history_export_component_identity_schema_hash(identity) ?? null,
	};
}

export function historyExportPayloadFromBridge(
	payload: bridge.MoonWorldHistoryExportPayload,
): HistoryExportPayload {
	return {
		globalTransformFormat:
			bridge.world_history_export_payload_global_transform_format(payload) ?? null,
		bytes: historyExportBytes(bridge.world_history_export_payload_bytes(payload)),
	};
}

export function historyExportComponentSnapshotFromBridge(
	snapshot: bridge.MoonWorldHistoryExportComponentSnapshot,
): HistoryExportComponentSnapshot {
	return {
		component: historyExportComponentIdentityFromBridge(
			bridge.world_history_export_component_snapshot_component(snapshot),
		),
		bytes: historyExportBytes(
			bridge.world_history_export_component_snapshot_bytes(snapshot),
		),
	};
}

export function historyExportDeltaFromBridge(
	delta: bridge.MoonWorldHistoryExportDelta,
): HistoryExportDelta {
	const component = bridge.world_history_export_delta_component(delta);
	const before = bridge.world_history_export_delta_before(delta);
	const after = bridge.world_history_export_delta_after(delta);
	return {
		kind: bridge.world_history_export_delta_kind(delta) as HistoryDeltaKind,
		entity: historySummaryEntity(bridge.world_history_export_delta_entity(delta)),
		component:
			component == null
				? null
				: historyExportComponentIdentityFromBridge(component),
		before: before == null ? null : historyExportPayloadFromBridge(before),
		after: after == null ? null : historyExportPayloadFromBridge(after),
		components: bridge.world_history_export_delta_components(delta).map((snapshot) =>
			historyExportComponentSnapshotFromBridge(snapshot),
		),
	};
}

export function historyExportRecordFromBridge(
	record: bridge.MoonWorldHistoryExportRecord,
): HistoryExportRecord {
	return {
		label: bridge.world_history_export_record_label(record),
		deltaCount: bridge.world_history_export_record_delta_count(record),
		deltas: bridge.world_history_export_record_deltas(record).map((delta) =>
			historyExportDeltaFromBridge(delta),
		),
	};
}

export function historyExportFromBridge(exported: bridge.MoonWorldHistoryExport): HistoryExport {
	return {
		formatVersion: bridge.world_history_export_format_version(exported),
		recordCount: bridge.world_history_export_record_count(exported),
		records: bridge.world_history_export_records(exported).map((record) =>
			historyExportRecordFromBridge(record),
		),
	};
}

export function historyEntityToBridge(entity: EntityId | null): bridge.MoonEntityId | undefined {
	if (entity == null) {
		return undefined;
	}
	const value = entity as EntityId & { inner?: bridge.MoonEntityId };
	if (value.inner != null) {
		return value.inner;
	}
	return entity as unknown as bridge.MoonEntityId;
}

export function historyComponentToBridge(
	component: ComponentTypeId,
): bridge.MoonComponentTypeId {
	const value = component as ComponentTypeId & { inner?: bridge.MoonComponentTypeId };
	if (value.inner != null) {
		return value.inner;
	}
	return component as unknown as bridge.MoonComponentTypeId;
}

export function historyExportInputBytes(bytes: Uint8Array): Uint8Array {
	if (bytes instanceof Uint8Array) {
		return new Uint8Array(bytes);
	}
	if (Array.isArray(bytes)) {
		return Uint8Array.from(bytes);
	}
	const value = bytes as unknown as Record<string, number>;
	return Uint8Array.from(
		Object.keys(value)
			.filter((key) => /^\d+$/.test(key))
			.sort((a, b) => Number(a) - Number(b))
			.map((key) => value[key] ?? 0),
	);
}

export function historyExportComponentIdentityToBridge(
	identity: HistoryExportComponentIdentity | null,
): bridge.MoonWorldHistoryExportComponentIdentity | undefined {
	if (identity == null) {
		return undefined;
	}
	return bridge.world_history_export_component_identity_new(
		historyComponentToBridge(identity.localComponent),
		identity.key,
		identity.builtin,
		identity.schemaVersion ?? undefined,
		identity.schemaHash ?? undefined,
	);
}

export function historyExportPayloadToBridge(
	payload: HistoryExportPayload | null,
): bridge.MoonWorldHistoryExportPayload | undefined {
	if (payload == null) {
		return undefined;
	}
	return bridge.world_history_export_payload_new(
		payload.globalTransformFormat ?? undefined,
		historyExportInputBytes(payload.bytes),
	);
}

export function historyExportComponentSnapshotToBridge(
	snapshot: HistoryExportComponentSnapshot,
): bridge.MoonWorldHistoryExportComponentSnapshot {
	return bridge.world_history_export_component_snapshot_new(
		bridge.world_history_export_component_identity_new(
			historyComponentToBridge(snapshot.component.localComponent),
			snapshot.component.key,
			snapshot.component.builtin,
			snapshot.component.schemaVersion ?? undefined,
			snapshot.component.schemaHash ?? undefined,
		),
		historyExportInputBytes(snapshot.bytes),
	);
}

export function historyExportDeltaToBridge(
	delta: HistoryExportDelta,
): bridge.MoonWorldHistoryExportDelta {
	return bridge.world_history_export_delta_new(
		delta.kind,
		historyEntityToBridge(delta.entity),
		historyExportComponentIdentityToBridge(delta.component),
		historyExportPayloadToBridge(delta.before),
		historyExportPayloadToBridge(delta.after),
		delta.components.map((snapshot) =>
			historyExportComponentSnapshotToBridge(snapshot),
		),
	);
}

export function historyExportRecordToBridge(
	record: HistoryExportRecord,
): bridge.MoonWorldHistoryExportRecord {
	return bridge.world_history_export_record_new(
		record.label,
		record.deltaCount,
		record.deltas.map((delta) => historyExportDeltaToBridge(delta)),
	);
}

export function historyExportToBridge(exported: HistoryExport): bridge.MoonWorldHistoryExport {
	return bridge.world_history_export_new(
		exported.formatVersion,
		exported.recordCount,
		exported.records.map((record) => historyExportRecordToBridge(record)),
	);
}
