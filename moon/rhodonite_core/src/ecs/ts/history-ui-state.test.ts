// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it, World, WorldHistory } from "./test-support/world-test-support.ts";
import { historyEditorState } from "./history-ui-state.ts";

describe("ECS TypeScript wrapper: history UI state", () => {
	it("reports empty undo and redo command state without warnings", () => {
		const history = WorldHistory.new();

		const state = historyEditorState(history);
		expect(state.enabled).toBe(true);
		expect(state.diagnostic).toBe("none");
		expect(state.warningKind).toBe("none");
		expect(state.warningText).toBeNull();
		expect(state.undo).toMatchObject({
			canRun: false,
			label: null,
			text: "Undo",
			count: 0,
			bytes: 0,
			summary: null,
		});
		expect(state.redo).toMatchObject({
			canRun: false,
			label: null,
			text: "Redo",
			count: 0,
			bytes: 0,
			summary: null,
		});
	});

	it("formats labelled undo and redo commands with stack metadata", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const component = world.registerComponent("TsHistoryUiStateLabelled", 4);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, component, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(history.beginTransaction("Move Entity")).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				entity,
				component,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		expect(history.commitTransaction()).toBe(true);

		const undoState = historyEditorState(history);
		expect(undoState.undo.canRun).toBe(true);
		expect(undoState.undo.label).toBe("Move Entity");
		expect(undoState.undo.text).toBe("Undo Move Entity");
		expect(undoState.undo.count).toBe(1);
		expect(undoState.undo.bytes).toBe(8);
		expect(undoState.undo.summary).toMatchObject({
			label: "Move Entity",
			deltaCount: 1,
			payloadBytes: 8,
		});
		expect(undoState.redo.text).toBe("Redo");

		expect(history.undo(world)).toBe(true);
		const redoState = historyEditorState(history, {
			undoVerb: "戻す",
			redoVerb: "やり直す",
		});
		expect(redoState.undo.text).toBe("戻す");
		expect(redoState.redo.canRun).toBe(true);
		expect(redoState.redo.label).toBe("Move Entity");
		expect(redoState.redo.text).toBe("やり直す Move Entity");
		expect(redoState.redo.count).toBe(1);
		expect(redoState.redo.bytes).toBe(8);
	});

	it("does not append whitespace for empty labels", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const component = world.registerComponent("TsHistoryUiStateEmptyLabel", 4);
		const entity = world.createEntity();
		expect(
			world.addComponentBytes(entity, component, new Uint8Array([1, 0, 0, 0])),
		).toBe(true);
		expect(history.beginTransaction("")).toBe(true);
		expect(
			history.setComponentBytes(
				world,
				entity,
				component,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		expect(history.commitTransaction()).toBe(true);

		const state = historyEditorState(history);
		expect(state.undo.canRun).toBe(true);
		expect(state.undo.label).toBe("");
		expect(state.undo.text).toBe("Undo");
	});

	it("maps retained diagnostics into UI warnings", () => {
		const byteLimitWorld = World.new();
		const byteLimitHistory = WorldHistory.new();
		const byteLimitComponent = byteLimitWorld.registerComponent(
			"TsHistoryUiStateByteLimit",
			4,
		);
		const byteLimitEntity = byteLimitWorld.createEntity();
		expect(
			byteLimitWorld.addComponentBytes(
				byteLimitEntity,
				byteLimitComponent,
				new Uint8Array([1, 0, 0, 0]),
			),
		).toBe(true);
		byteLimitHistory.setMaxUndoBytes(4);
		expect(
			byteLimitHistory.setComponentBytes(
				byteLimitWorld,
				byteLimitEntity,
				byteLimitComponent,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		const byteLimitState = historyEditorState(byteLimitHistory);
		expect(byteLimitState.diagnostic).toBe("record_dropped_byte_limit");
		expect(byteLimitState.warningKind).toBe("record_dropped_byte_limit");
		expect(byteLimitState.warningText).toContain("byte limit");
		expect(byteLimitState.undo.count).toBe(0);
		expect(byteLimitState.undo.canRun).toBe(false);

		const disabledWorld = World.new();
		const disabledHistory = WorldHistory.new();
		const disabledComponent = disabledWorld.registerComponent(
			"TsHistoryUiStateDisabled",
			4,
		);
		const disabledEntity = disabledWorld.createEntity();
		expect(
			disabledWorld.addComponentBytes(
				disabledEntity,
				disabledComponent,
				new Uint8Array([1, 0, 0, 0]),
			),
		).toBe(true);
		disabledHistory.setEnabled(false);
		expect(
			disabledHistory.setComponentBytes(
				disabledWorld,
				disabledEntity,
				disabledComponent,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		const disabledState = historyEditorState(disabledHistory);
		expect(disabledState.enabled).toBe(false);
		expect(disabledState.diagnostic).toBe("recording_disabled");
		expect(disabledState.warningKind).toBe("recording_disabled");
		expect(disabledState.warningText).toContain("disabled");

		const staleWorld = World.new();
		const staleHistory = WorldHistory.new();
		const staleComponent = staleWorld.registerComponent(
			"TsHistoryUiStateStale",
			4,
		);
		const staleEntity = staleWorld.createEntity();
		expect(
			staleWorld.addComponentBytes(
				staleEntity,
				staleComponent,
				new Uint8Array([1, 0, 0, 0]),
			),
		).toBe(true);
		expect(
			staleHistory.setComponentBytes(
				staleWorld,
				staleEntity,
				staleComponent,
				new Uint8Array([2, 0, 0, 0]),
			),
		).toBe(true);
		expect(staleWorld.destroyEntity(staleEntity)).toBe(true);
		expect(staleHistory.undo(staleWorld)).toBe(false);
		const staleState = historyEditorState(staleHistory);
		expect(staleState.diagnostic).toBe("validation_failed");
		expect(staleState.warningKind).toBe("validation_failed");
		expect(staleState.warningText).toContain("current world");
		expect(staleState.undo.count).toBe(1);
	});

	it("keeps flow-only diagnostics out of UI warnings", () => {
		const world = World.new();
		const history = WorldHistory.new();
		expect(history.undo(world)).toBe(false);

		const state = historyEditorState(history);
		expect(state.diagnostic).toBe("empty_undo_stack");
		expect(state.warningKind).toBe("none");
		expect(state.warningText).toBeNull();
	});
});
