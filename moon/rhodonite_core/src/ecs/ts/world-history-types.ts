// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { ComponentTypeId, EntityId } from "./types.ts";

export type HistoryDeltaKind =
	| "entity_created"
	| "entity_destroyed"
	| "component_added"
	| "component_removed"
	| "component_changed"
	| "global_transform_changed"
	| "camera_changed";

export type HistoryDeltaSummary = {
	readonly kind: HistoryDeltaKind;
	readonly entity: EntityId | null;
	readonly component: ComponentTypeId | null;
	readonly componentCount: number;
	readonly payloadBytes: number;
	readonly beforePresent: boolean;
	readonly afterPresent: boolean;
};

export type HistoryRecordSummary = {
	readonly label: string;
	readonly deltaCount: number;
	readonly payloadBytes: number;
	readonly deltas: HistoryDeltaSummary[];
};

export type HistorySerializationReason =
	| "none"
	| "unknown_component"
	| "missing_stable_component_identity";

export type HistorySerializationComponentReport = {
	readonly component: ComponentTypeId;
	readonly serializable: boolean;
	readonly reason: HistorySerializationReason;
	readonly stableKey: string | null;
};

export type HistorySerializationDeltaReport = {
	readonly kind: HistoryDeltaKind;
	readonly entity: EntityId | null;
	readonly component: ComponentTypeId | null;
	readonly componentCount: number;
	readonly serializable: boolean;
	readonly reason: HistorySerializationReason;
	readonly payloadBytes: number;
	readonly components: HistorySerializationComponentReport[];
};

export type HistorySerializationRecordReport = {
	readonly label: string;
	readonly serializable: boolean;
	readonly reason: HistorySerializationReason;
	readonly deltaCount: number;
	readonly payloadBytes: number;
	readonly deltas: HistorySerializationDeltaReport[];
};

export type HistorySerializationReport = {
	readonly serializable: boolean;
	readonly recordCount: number;
	readonly records: HistorySerializationRecordReport[];
};

export type HistoryImportValidationReason =
	| "none"
	| "transaction_open"
	| "applying"
	| "import_unsupported_format"
	| "import_invalid_archive"
	| "import_identity_mismatch"
	| "import_invalid_payload"
	| "import_validation_failed";

export type HistoryImportValidationDeltaReport = {
	readonly index: number;
	readonly kind: string;
	readonly entity: EntityId | null;
	readonly component: ComponentTypeId | null;
	readonly componentKey: string | null;
	readonly valid: boolean;
	readonly reason: HistoryImportValidationReason;
};

export type HistoryImportValidationRecordReport = {
	readonly index: number;
	readonly label: string;
	readonly valid: boolean;
	readonly reason: HistoryImportValidationReason;
	readonly deltaCount: number;
	readonly deltas: HistoryImportValidationDeltaReport[];
};

export type HistoryImportValidationReport = {
	readonly valid: boolean;
	readonly reason: HistoryImportValidationReason;
	readonly formatVersion: number;
	readonly recordCount: number;
	readonly records: HistoryImportValidationRecordReport[];
};

export type HistoryExportComponentIdentity = {
	readonly localComponent: ComponentTypeId;
	readonly key: string;
	readonly builtin: boolean;
	readonly schemaVersion: string | null;
	readonly schemaHash: string | null;
};

export type HistoryExportPayload = {
	readonly globalTransformFormat: number | null;
	readonly bytes: Uint8Array;
};

export type HistoryExportComponentSnapshot = {
	readonly component: HistoryExportComponentIdentity;
	readonly bytes: Uint8Array;
};

export type HistoryExportDelta = {
	readonly kind: HistoryDeltaKind;
	readonly entity: EntityId | null;
	readonly component: HistoryExportComponentIdentity | null;
	readonly before: HistoryExportPayload | null;
	readonly after: HistoryExportPayload | null;
	readonly components: HistoryExportComponentSnapshot[];
};

export type HistoryExportRecord = {
	readonly label: string;
	readonly deltaCount: number;
	readonly deltas: HistoryExportDelta[];
};

export type HistoryExport = {
	readonly formatVersion: number;
	readonly recordCount: number;
	readonly records: HistoryExportRecord[];
};
