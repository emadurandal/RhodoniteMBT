// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { WorldHistory } from "./world-history.ts";
import type {
	HistoryDiagnosticReason,
	HistoryRecordSummary,
} from "./world-history-types.ts";

export type HistoryCommandState = {
	readonly canRun: boolean;
	readonly label: string | null;
	readonly text: string;
	readonly count: number;
	readonly bytes: number;
	readonly summary: HistoryRecordSummary | null;
};

export type HistoryEditorWarningKind =
	| "none"
	| "recording_disabled"
	| "validation_failed"
	| "apply_failed_rolled_back"
	| "apply_failed"
	| "operation_failed"
	| "record_dropped_byte_limit"
	| "stack_trimmed_record_limit"
	| "stack_trimmed_byte_limit"
	| "stack_trimmed_limits"
	| "import_unsupported_format"
	| "import_invalid_archive"
	| "import_identity_mismatch"
	| "import_invalid_payload"
	| "import_validation_failed";

export type HistoryEditorState = {
	readonly enabled: boolean;
	readonly diagnostic: HistoryDiagnosticReason;
	readonly warningKind: HistoryEditorWarningKind;
	readonly warningText: string | null;
	readonly undo: HistoryCommandState;
	readonly redo: HistoryCommandState;
};

export type HistoryEditorStateOptions = {
	readonly undoVerb?: string;
	readonly redoVerb?: string;
	readonly fallbackUndoText?: string;
	readonly fallbackRedoText?: string;
};

const historyWarningMessages: Record<
	Exclude<HistoryEditorWarningKind, "none">,
	string
> = {
	recording_disabled: "History recording is disabled.",
	validation_failed: "The history record no longer matches the current world.",
	apply_failed_rolled_back:
		"The history operation failed and previous replay steps were rolled back.",
	apply_failed: "The history operation failed.",
	operation_failed: "The history operation failed.",
	record_dropped_byte_limit:
		"The change was applied, but the undo record exceeded the byte limit and was not retained.",
	stack_trimmed_record_limit:
		"Older history records were trimmed to satisfy the record limit.",
	stack_trimmed_byte_limit:
		"Older history records were trimmed to satisfy the byte limit.",
	stack_trimmed_limits: "Older history records were trimmed to satisfy history limits.",
	import_unsupported_format: "The history archive format is not supported.",
	import_invalid_archive: "The history archive is invalid.",
	import_identity_mismatch:
		"The history archive does not match the current component identities.",
	import_invalid_payload: "The history archive contains invalid payload data.",
	import_validation_failed:
		"The history archive does not match the current world state.",
};

function commandText(
	canRun: boolean,
	label: string | null,
	verb: string,
	fallback: string,
): string {
	if (!canRun) {
		return fallback;
	}
	return label == null || label.length === 0 ? verb : `${verb} ${label}`;
}

function warningKindForDiagnostic(
	diagnostic: HistoryDiagnosticReason,
): HistoryEditorWarningKind {
	return diagnostic in historyWarningMessages
		? (diagnostic as HistoryEditorWarningKind)
		: "none";
}

function historyCommandState(
	canRun: boolean,
	label: string | null,
	verb: string,
	fallback: string,
	count: number,
	bytes: number,
	summaries: HistoryRecordSummary[],
): HistoryCommandState {
	return {
		canRun,
		label,
		text: commandText(canRun, label, verb, fallback),
		count,
		bytes,
		summary: summaries[0] ?? null,
	};
}

export function historyEditorState(
	history: WorldHistory,
	options: HistoryEditorStateOptions = {},
): HistoryEditorState {
	const undoVerb = options.undoVerb ?? "Undo";
	const redoVerb = options.redoVerb ?? "Redo";
	const fallbackUndoText = options.fallbackUndoText ?? undoVerb;
	const fallbackRedoText = options.fallbackRedoText ?? redoVerb;
	const diagnostic = history.lastDiagnostic();
	const warningKind = warningKindForDiagnostic(diagnostic);
	return {
		enabled: history.enabled(),
		diagnostic,
		warningKind,
		warningText:
			warningKind === "none" ? null : historyWarningMessages[warningKind],
		undo: historyCommandState(
			history.canUndo(),
			history.undoLabel(),
			undoVerb,
			fallbackUndoText,
			history.undoLen(),
			history.undoBytes(),
			history.undoSummary(),
		),
		redo: historyCommandState(
			history.canRedo(),
			history.redoLabel(),
			redoVerb,
			fallbackRedoText,
			history.redoLen(),
			history.redoBytes(),
			history.redoSummary(),
		),
	};
}
