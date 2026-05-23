// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	type EntityId,
	type OrbitCameraController,
	type OrbitCameraInputFrame,
	type World,
	updateOrbitCameraControllerComponentFromMouseFrame,
	updateOrbitCameraControllerFromMouseFrame,
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import { InputState, MouseButton } from "./app-runtime.ts";

export function orbitCameraInputFrameFromInput(
	input: InputState,
): OrbitCameraInputFrame {
	return {
		leftDown: input.mouseDown(MouseButton.Left),
		leftPressed: input.mousePressed(MouseButton.Left),
		middleDown: input.mouseDown(MouseButton.Middle),
		middlePressed: input.mousePressed(MouseButton.Middle),
		pointerDeltaX: input.pointerDeltaX(),
		pointerDeltaY: input.pointerDeltaY(),
		wheelDeltaY: input.wheelDeltaY(),
	};
}

export function updateOrbitCameraControllerComponentFromInput(
	world: World,
	camera: EntityId,
	input: InputState,
): boolean {
	return updateOrbitCameraControllerComponentFromMouseFrame(
		world,
		camera,
		orbitCameraInputFrameFromInput(input),
	);
}

export function updateOrbitCameraControllerFromInput(
	controller: OrbitCameraController,
	input: InputState,
): boolean {
	return updateOrbitCameraControllerFromMouseFrame(
		controller,
		orbitCameraInputFrameFromInput(input),
	);
}
