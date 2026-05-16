import { describe, expect, it } from "vitest";
import { InputState } from "./app-runtime";
import {
	createOrbitCameraController,
	updateOrbitCameraControllerFromInput,
} from "./orbit-camera-controller";

describe("OrbitCameraController", () => {
	it("allows wheel dolly to zoom in to the default lower clamp", () => {
		const controller = createOrbitCameraController(0);
		const input = new InputState();
		input.enqueueEvent({ type: "Wheel", deltaX: 0, deltaY: -10000 });
		input.beginFrame();

		expect(updateOrbitCameraControllerFromInput(controller, input)).toBe(true);
		expect(controller.dolly).toBeCloseTo(0.1);
	});
});
