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
	readonly valueStatus: HTMLElement;
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
		valueStatus: createValueStatus(),
	};
}

function valueBytes(value: number): Uint8Array {
	return new Uint8Array([value & 0xff, 0, 0, 0]);
}

function readValue(state: InteractionState): number {
	return state.world.componentBytesCopy(state.entity, state.component)?.[0] ?? 0;
}

function createValueStatus(): HTMLElement {
	const status = document.createElement("p");
	status.className = "sample-value";
	status.textContent = "value=0";
	document.querySelector("#app")?.append(status);
	return status;
}

function refreshValueStatus(state: InteractionState): void {
	state.valueStatus.textContent = `value=${readValue(state)}`;
}

function applyTrackedMove(state: InteractionState): boolean {
	const nextIndex = readValue(state) + 1;
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
		refreshValueStatus(state);
	}
	return ok;
}

function main(): void {
	const state = createInteractionState();
	const controlState = {
		history: state.history,
		move: () => applyTrackedMove(state),
		undo: () => {
			const ok = state.history.undo(state.world);
			if (ok) {
				refreshValueStatus(state);
			}
			return ok;
		},
		redo: () => {
			const ok = state.history.redo(state.world);
			if (ok) {
				refreshValueStatus(state);
			}
			return ok;
		},
	};
	createUndoRedoControls(controlState, {
		parent: document.querySelector("#app"),
		moveLabel: "Move",
	});
	installUndoRedoKeyboardShortcuts(controlState);
}

main();
