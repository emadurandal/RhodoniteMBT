// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { ComponentTypeId, EntityId } from "./types.ts";
import type {
	HistoryDeltaKind,
	HistoryExport,
	HistoryExportComponentIdentity,
	HistoryExportComponentSnapshot,
	HistoryExportDelta,
	HistoryExportPayload,
	HistoryExportRecord,
} from "./world.ts";

type JsonObject = Record<string, unknown>;

type HistoryArchiveJson = {
	format_version: number;
	record_count: number;
	records: HistoryArchiveRecordJson[];
};

type HistoryArchiveRecordJson = {
	label: string;
	delta_count: number;
	deltas: HistoryArchiveDeltaJson[];
};

type HistoryArchiveDeltaJson = {
	kind: HistoryDeltaKind;
	entity: HistoryArchiveEntityJson | null;
	component: HistoryArchiveComponentIdentityJson | null;
	before: HistoryArchivePayloadJson | null;
	after: HistoryArchivePayloadJson | null;
	components: HistoryArchiveComponentSnapshotJson[];
};

type HistoryArchiveEntityJson = {
	index: number;
	generation: number;
};

type HistoryArchiveComponentTypeJson = {
	index: number;
};

type HistoryArchiveComponentIdentityJson = {
	local_component: HistoryArchiveComponentTypeJson;
	key: string;
	builtin: boolean;
	schema_version: string | null;
	schema_hash: string | null;
};

type HistoryArchivePayloadJson = {
	global_transform_format: number | null;
	bytes_base64: string;
};

type HistoryArchiveComponentSnapshotJson = {
	component: HistoryArchiveComponentIdentityJson;
	bytes_base64: string;
};

const HISTORY_ARCHIVE_FORMAT_VERSION = 1;
const HISTORY_DELTA_KINDS = new Set<string>([
	"entity_created",
	"entity_destroyed",
	"component_added",
	"component_removed",
	"component_changed",
	"global_transform_changed",
	"camera_changed",
]);

function archiveError(message: string): Error {
	return new Error(`decodeHistoryExportJson: ${message}`);
}

function isObject(value: unknown): value is JsonObject {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function requireObject(value: unknown, path: string): JsonObject {
	if (!isObject(value)) {
		throw archiveError(`${path} must be an object`);
	}
	return value;
}

function requireArray(value: unknown, path: string): unknown[] {
	if (!Array.isArray(value)) {
		throw archiveError(`${path} must be an array`);
	}
	return value;
}

function requireString(value: unknown, path: string): string {
	if (typeof value !== "string") {
		throw archiveError(`${path} must be a string`);
	}
	return value;
}

function requireBoolean(value: unknown, path: string): boolean {
	if (typeof value !== "boolean") {
		throw archiveError(`${path} must be a boolean`);
	}
	return value;
}

function requireInteger(value: unknown, path: string): number {
	if (typeof value !== "number" || !Number.isInteger(value)) {
		throw archiveError(`${path} must be an integer`);
	}
	return value;
}

function requireNullableString(value: unknown, path: string): string | null {
	if (value === null) {
		return null;
	}
	return requireString(value, path);
}

function requireNullableInteger(value: unknown, path: string): number | null {
	if (value === null) {
		return null;
	}
	return requireInteger(value, path);
}

function requireDeltaKind(value: unknown, path: string): HistoryDeltaKind {
	const kind = requireString(value, path);
	if (!HISTORY_DELTA_KINDS.has(kind)) {
		throw archiveError(`${path} is not a supported history delta kind`);
	}
	return kind as HistoryDeltaKind;
}

function optionalField(object: JsonObject, key: string, path: string): unknown {
	if (!Object.prototype.hasOwnProperty.call(object, key)) {
		throw archiveError(`${path}.${key} is required`);
	}
	return object[key];
}

function entityIndex(entity: EntityId): number {
	const value = entity as EntityId & { inner?: { index: number }; index?: number };
	if (typeof value.index === "number") {
		return value.index;
	}
	if (value.inner != null) {
		return value.inner.index;
	}
	return entity.index();
}

function entityGeneration(entity: EntityId): number {
	const value = entity as EntityId & {
		inner?: { generation: number };
		generation?: number;
	};
	if (typeof value.generation === "number") {
		return value.generation;
	}
	if (value.inner != null) {
		return value.inner.generation;
	}
	return entity.generation();
}

function componentIndex(component: ComponentTypeId): number {
	const value = component as ComponentTypeId & {
		inner?: { index: number };
		index?: number;
	};
	if (typeof value.index === "number") {
		return value.index;
	}
	if (value.inner != null) {
		return value.inner.index;
	}
	return component.index();
}

function bytesToBase64(bytes: Uint8Array): string {
	const bufferConstructor = (globalThis as typeof globalThis & {
		Buffer?: { from(input: Uint8Array): { toString(encoding: string): string } };
	}).Buffer;
	if (bufferConstructor != null) {
		return bufferConstructor.from(bytes).toString("base64");
	}
	let binary = "";
	for (let i = 0; i < bytes.length; i += 0x8000) {
		const chunk = bytes.subarray(i, i + 0x8000);
		binary += String.fromCharCode(...chunk);
	}
	return btoa(binary);
}

function assertBase64(text: string, path: string): void {
	if (text.length % 4 !== 0 || !/^[A-Za-z0-9+/]*={0,2}$/.test(text)) {
		throw archiveError(`${path} must be base64`);
	}
	const padding = text.indexOf("=");
	if (padding >= 0 && !/^=+$/.test(text.slice(padding))) {
		throw archiveError(`${path} must be base64`);
	}
}

function base64ToBytes(text: string, path: string): Uint8Array {
	assertBase64(text, path);
	const bufferConstructor = (globalThis as typeof globalThis & {
		Buffer?: { from(input: string, encoding: string): Uint8Array };
	}).Buffer;
	if (bufferConstructor != null) {
		return new Uint8Array(bufferConstructor.from(text, "base64"));
	}
	const binary = atob(text);
	const bytes = new Uint8Array(binary.length);
	for (let i = 0; i < binary.length; i += 1) {
		bytes[i] = binary.charCodeAt(i);
	}
	return bytes;
}

function encodeEntity(entity: EntityId | null): HistoryArchiveEntityJson | null {
	if (entity === null) {
		return null;
	}
	return { index: entityIndex(entity), generation: entityGeneration(entity) };
}

function encodeComponentType(
	component: ComponentTypeId,
): HistoryArchiveComponentTypeJson {
	return { index: componentIndex(component) };
}

function encodeComponentIdentity(
	identity: HistoryExportComponentIdentity | null,
): HistoryArchiveComponentIdentityJson | null {
	if (identity === null) {
		return null;
	}
	return {
		local_component: encodeComponentType(identity.localComponent),
		key: identity.key,
		builtin: identity.builtin,
		schema_version: identity.schemaVersion,
		schema_hash: identity.schemaHash,
	};
}

function encodePayload(
	payload: HistoryExportPayload | null,
): HistoryArchivePayloadJson | null {
	if (payload === null) {
		return null;
	}
	return {
		global_transform_format: payload.globalTransformFormat,
		bytes_base64: bytesToBase64(payload.bytes),
	};
}

function encodeSnapshot(
	snapshot: HistoryExportComponentSnapshot,
): HistoryArchiveComponentSnapshotJson {
	return {
		component: encodeComponentIdentity(snapshot.component) ??
			(() => {
				throw new Error("unreachable");
			})(),
		bytes_base64: bytesToBase64(snapshot.bytes),
	};
}

function encodeDelta(delta: HistoryExportDelta): HistoryArchiveDeltaJson {
	return {
		kind: delta.kind,
		entity: encodeEntity(delta.entity),
		component: encodeComponentIdentity(delta.component),
		before: encodePayload(delta.before),
		after: encodePayload(delta.after),
		components: delta.components.map((snapshot) => encodeSnapshot(snapshot)),
	};
}

function encodeRecord(record: HistoryExportRecord): HistoryArchiveRecordJson {
	return {
		label: record.label,
		delta_count: record.deltaCount,
		deltas: record.deltas.map((delta) => encodeDelta(delta)),
	};
}

function encodeArchive(exported: HistoryExport): HistoryArchiveJson {
	return {
		format_version: exported.formatVersion,
		record_count: exported.recordCount,
		records: exported.records.map((record) => encodeRecord(record)),
	};
}

function decodeEntity(
	value: unknown,
	path: string,
): EntityId | null {
	if (value === null) {
		return null;
	}
	const object = requireObject(value, path);
	return EntityId.new(
		requireInteger(optionalField(object, "index", path), `${path}.index`),
		requireInteger(
			optionalField(object, "generation", path),
			`${path}.generation`,
		),
	);
}

function decodeComponentType(
	value: unknown,
	path: string,
): ComponentTypeId {
	const object = requireObject(value, path);
	return ComponentTypeId.new(
		requireInteger(optionalField(object, "index", path), `${path}.index`),
	);
}

function decodeComponentIdentity(
	value: unknown,
	path: string,
): HistoryExportComponentIdentity | null {
	if (value === null) {
		return null;
	}
	const object = requireObject(value, path);
	return {
		localComponent: decodeComponentType(
			optionalField(object, "local_component", path),
			`${path}.local_component`,
		),
		key: requireString(optionalField(object, "key", path), `${path}.key`),
		builtin: requireBoolean(
			optionalField(object, "builtin", path),
			`${path}.builtin`,
		),
		schemaVersion: requireNullableString(
			optionalField(object, "schema_version", path),
			`${path}.schema_version`,
		),
		schemaHash: requireNullableString(
			optionalField(object, "schema_hash", path),
			`${path}.schema_hash`,
		),
	};
}

function decodePayload(
	value: unknown,
	path: string,
): HistoryExportPayload | null {
	if (value === null) {
		return null;
	}
	const object = requireObject(value, path);
	return {
		globalTransformFormat: requireNullableInteger(
			optionalField(object, "global_transform_format", path),
			`${path}.global_transform_format`,
		),
		bytes: base64ToBytes(
			requireString(
				optionalField(object, "bytes_base64", path),
				`${path}.bytes_base64`,
			),
			`${path}.bytes_base64`,
		),
	};
}

function decodeSnapshot(
	value: unknown,
	path: string,
): HistoryExportComponentSnapshot {
	const object = requireObject(value, path);
	const component = decodeComponentIdentity(
		optionalField(object, "component", path),
		`${path}.component`,
	);
	if (component === null) {
		throw archiveError(`${path}.component must not be null`);
	}
	return {
		component,
		bytes: base64ToBytes(
			requireString(
				optionalField(object, "bytes_base64", path),
				`${path}.bytes_base64`,
			),
			`${path}.bytes_base64`,
		),
	};
}

function decodeDelta(value: unknown, path: string): HistoryExportDelta {
	const object = requireObject(value, path);
	return {
		kind: requireDeltaKind(optionalField(object, "kind", path), `${path}.kind`),
		entity: decodeEntity(optionalField(object, "entity", path), `${path}.entity`),
		component: decodeComponentIdentity(
			optionalField(object, "component", path),
			`${path}.component`,
		),
		before: decodePayload(optionalField(object, "before", path), `${path}.before`),
		after: decodePayload(optionalField(object, "after", path), `${path}.after`),
		components: requireArray(
			optionalField(object, "components", path),
			`${path}.components`,
		).map((snapshot, index) =>
			decodeSnapshot(snapshot, `${path}.components[${index}]`)
		),
	};
}

function decodeRecord(value: unknown, path: string): HistoryExportRecord {
	const object = requireObject(value, path);
	const deltas = requireArray(
		optionalField(object, "deltas", path),
		`${path}.deltas`,
	).map((delta, index) => decodeDelta(delta, `${path}.deltas[${index}]`));
	const deltaCount = requireInteger(
		optionalField(object, "delta_count", path),
		`${path}.delta_count`,
	);
	if (deltaCount !== deltas.length) {
		throw archiveError(`${path}.delta_count must match deltas.length`);
	}
	return {
		label: requireString(optionalField(object, "label", path), `${path}.label`),
		deltaCount,
		deltas,
	};
}

function decodeArchive(value: unknown): HistoryExport {
	const object = requireObject(value, "archive");
	const formatVersion = requireInteger(
		optionalField(object, "format_version", "archive"),
		"archive.format_version",
	);
	if (formatVersion !== HISTORY_ARCHIVE_FORMAT_VERSION) {
		throw archiveError(`unsupported format_version ${formatVersion}`);
	}
	const records = requireArray(
		optionalField(object, "records", "archive"),
		"archive.records",
	).map((record, index) => decodeRecord(record, `archive.records[${index}]`));
	const recordCount = requireInteger(
		optionalField(object, "record_count", "archive"),
		"archive.record_count",
	);
	if (recordCount !== records.length) {
		throw archiveError("archive.record_count must match records.length");
	}
	return {
		formatVersion,
		recordCount,
		records,
	};
}

export function encodeHistoryExportJson(exported: HistoryExport): string {
	return JSON.stringify(encodeArchive(exported));
}

export function decodeHistoryExportJson(json: string): HistoryExport {
	let value: unknown;
	try {
		value = JSON.parse(json);
	} catch (error) {
		const detail = error instanceof Error ? error.message : "parse failed";
		throw archiveError(`invalid JSON: ${detail}`);
	}
	return decodeArchive(value);
}
