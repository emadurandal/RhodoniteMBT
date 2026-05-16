import { MouseButton, type InputState } from "./app-runtime";

export type OrbitCameraController = {
	yaw: number;
	pitch: number;
	sensitivity: number;
	minPitch: number;
	maxPitch: number;
	panX: number;
	panY: number;
	panSensitivity: number;
	dolly: number;
	dollySensitivity: number;
	minDolly: number;
	maxDolly: number;
};

export function createOrbitCameraController(
	pitch: number,
	yaw = 0,
): OrbitCameraController {
	return {
		yaw,
		pitch,
		sensitivity: 0.006,
		minPitch: -1.25,
		maxPitch: 1.25,
		panX: 0,
		panY: 0,
		panSensitivity: 0.01,
		dolly: 1,
		dollySensitivity: 0.001,
		minDolly: 0.01,
		maxDolly: 4,
	};
}

export function updateOrbitCameraControllerFromInput(
	controller: OrbitCameraController,
	input: InputState,
): boolean {
	let changed = false;
	if (input.mouseDown(MouseButton.Left) && !input.mousePressed(MouseButton.Left)) {
		controller.yaw += input.pointerDeltaX() * controller.sensitivity;
		controller.pitch = Math.min(
			controller.maxPitch,
			Math.max(
				controller.minPitch,
				controller.pitch + input.pointerDeltaY() * controller.sensitivity,
			),
		);
		changed = true;
	}
	if (
		input.mouseDown(MouseButton.Middle) &&
		!input.mousePressed(MouseButton.Middle)
	) {
		controller.panX +=
			input.pointerDeltaX() * controller.panSensitivity * controller.dolly;
		controller.panY -=
			input.pointerDeltaY() * controller.panSensitivity * controller.dolly;
		changed = true;
	}
	if (input.wheelDeltaY() !== 0) {
		controller.dolly = Math.min(
			controller.maxDolly,
			Math.max(
				controller.minDolly,
				controller.dolly +
					input.wheelDeltaY() * controller.dollySensitivity * controller.dolly,
			),
		);
		changed = true;
	}
	return changed;
}
