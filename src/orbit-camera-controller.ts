import { MouseButton, type InputState } from "./app-runtime";

export type OrbitCameraController = {
	yaw: number;
	pitch: number;
	sensitivity: number;
	minPitch: number;
	maxPitch: number;
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
	};
}

export function updateOrbitCameraControllerFromInput(
	controller: OrbitCameraController,
	input: InputState,
): boolean {
	if (!input.mouseDown(MouseButton.Left) || input.mousePressed(MouseButton.Left)) {
		return false;
	}
	controller.yaw += input.pointerDeltaX() * controller.sensitivity;
	controller.pitch = Math.min(
		controller.maxPitch,
		Math.max(
			controller.minPitch,
			controller.pitch + input.pointerDeltaY() * controller.sensitivity,
		),
	);
	return true;
}
