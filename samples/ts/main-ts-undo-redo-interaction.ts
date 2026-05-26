// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import "./style.css";
import {
	World,
	WorldHistory,
	type ComponentTypeId,
	type EntityId,
} from "../../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	createUndoRedoControls,
	installUndoRedoKeyboardShortcuts,
} from "./undo-redo-controls";

type InteractionState = {
	readonly world: World;
	readonly history: WorldHistory;
	readonly component: ComponentTypeId;
	readonly entity: EntityId;
	editIndex: number;
};

function createInteractionState(): InteractionState {
	const world = World.new();
	const history = WorldHistory.new();
	const component = world.registerCpuComponent("TsUndoRedoInteractionValue", 4);
	const entity = world.createEntity();
	if (!world.addComponentBytes(entity, component, valueBytes(0))) {
		throw new Error("Failed to initialize interaction component.");
	}
	return {
		world,
		history,
		component,
		entity,
		editIndex: 0,
	};
}

function valueBytes(value: number): Uint8Array {
	return new Uint8Array([value & 0xff, 0, 0, 0]);
}

function applyTrackedMove(state: InteractionState): boolean {
	const nextIndex = state.editIndex + 1;
	const ok = state.history.withTransaction(
		state.world,
		`Interaction Move ${nextIndex}`,
		() =>
			state.history.setComponentBytes(
				state.world,
				state.entity,
				state.component,
				valueBytes(nextIndex),
			),
	);
	if (ok) {
		state.editIndex = nextIndex;
	}
	return ok;
}

function main(): void {
	const state = createInteractionState();
	const controlState = {
		history: state.history,
		move: () => applyTrackedMove(state),
		undo: () => state.history.undo(state.world),
		redo: () => state.history.redo(state.world),
	};
	createUndoRedoControls(controlState, {
		parent: document.querySelector("#app"),
		moveLabel: "Move",
	});
	installUndoRedoKeyboardShortcuts(controlState);
}

main();
