// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from "vitest";
import { createOrbitCameraController } from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import {
	InputState,
	updateOrbitCameraControllerFromInput,
} from "./index.ts";

describe("orbit camera input adapter", () => {
	it("folds app InputState into the core orbit camera mouse frame", () => {
		const controller = createOrbitCameraController(0);
		const input = new InputState();
		input.enqueueEvent({ type: "Wheel", deltaX: 0, deltaY: -10000 });
		input.beginFrame();

		expect(updateOrbitCameraControllerFromInput(controller, input)).toBe(true);
		expect(controller.dolly).toBeCloseTo(0.01);
	});
});
