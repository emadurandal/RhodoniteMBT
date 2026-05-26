// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	WorldHistory,
	historyEditorState,
} from "../../moon/rhodonite_core/src/ecs/ts/index.ts";

export type UndoRedoControls = {
	readonly move: HTMLButtonElement;
	readonly undo: HTMLButtonElement;
	readonly redo: HTMLButtonElement;
	readonly status: HTMLElement;
};

export type UndoRedoControlState = {
	readonly history: WorldHistory;
	readonly move: () => boolean;
	readonly undo: () => boolean;
	readonly redo: () => boolean;
	controls?: UndoRedoControls;
};

export type UndoRedoControlMountOptions = {
	readonly before?: Element | null;
	readonly parent?: Element | null;
	readonly moveLabel?: string;
};

export function createUndoRedoControls(
	state: UndoRedoControlState,
	options: UndoRedoControlMountOptions = {},
): UndoRedoControls {
	const controls = document.createElement("div");
	controls.className = "sample-controls";
	const move = document.createElement("button");
	move.type = "button";
	move.textContent = options.moveLabel ?? "Move";
	const undo = document.createElement("button");
	undo.type = "button";
	const redo = document.createElement("button");
	redo.type = "button";
	const status = document.createElement("p");
	status.className = "sample-status";
	controls.append(move, undo, redo, status);
	const parent = options.parent ?? options.before?.parentElement ?? document.body;
	parent.insertBefore(controls, options.before ?? null);
	state.controls = { move, undo, redo, status };
	move.addEventListener("click", () => {
		state.move();
		refreshUndoRedoControls(state);
	});
	undo.addEventListener("click", () => {
		state.undo();
		refreshUndoRedoControls(state);
	});
	redo.addEventListener("click", () => {
		state.redo();
		refreshUndoRedoControls(state);
	});
	refreshUndoRedoControls(state);
	return state.controls;
}

export function refreshUndoRedoControls(state: UndoRedoControlState): void {
	const controls = state.controls;
	if (!controls) {
		return;
	}
	const editorState = historyEditorState(state.history);
	controls.undo.disabled = !editorState.undo.canRun;
	controls.redo.disabled = !editorState.redo.canRun;
	controls.undo.textContent = editorState.undo.text;
	controls.redo.textContent = editorState.redo.text;
	controls.status.textContent =
		`undo=${editorState.undo.count} redo=${editorState.redo.count}`;
}

export function installUndoRedoKeyboardShortcuts(
	state: UndoRedoControlState,
	target: Window = window,
): void {
	target.addEventListener("keydown", (event) => {
		const key = event.key.toLowerCase();
		const command = event.ctrlKey || event.metaKey;
		const moveKey = key === "m" || key === " " || key === "enter";
		const undoRedoKey = command && (key === "z" || key === "y");
		if (event.repeat) {
			if (undoRedoKey || (!command && moveKey)) {
				event.preventDefault();
			}
			return;
		}
		let handled = false;
		if (command && key === "z" && !event.shiftKey) {
			state.undo();
			handled = true;
		} else if ((command && key === "z" && event.shiftKey) || (command && key === "y")) {
			state.redo();
			handled = true;
		} else if (!command && moveKey) {
			state.move();
			handled = true;
		}
		if (handled) {
			event.preventDefault();
			refreshUndoRedoControls(state);
		}
	});
}
