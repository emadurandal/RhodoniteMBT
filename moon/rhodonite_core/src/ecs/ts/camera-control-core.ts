// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { ComponentTypeId, EntityId } from "./types.ts";
import type { World, WorldHistory } from "./world.ts";

export const ORBIT_CAMERA_CONTROLLER_STRIDE = 80;
export const CAMERA_HOME_TRANSFORM_STRIDE = 48;
export const CAMERA_LENS_STRIDE = 32;

export const ORBIT_YAW_OFFSET = 0;
export const ORBIT_PITCH_OFFSET = 4;
export const ORBIT_SENSITIVITY_OFFSET = 8;
export const ORBIT_MIN_PITCH_OFFSET = 12;
export const ORBIT_MAX_PITCH_OFFSET = 16;
export const ORBIT_PAN_X_OFFSET = 20;
export const ORBIT_PAN_Y_OFFSET = 24;
export const ORBIT_PAN_SENSITIVITY_OFFSET = 28;
export const ORBIT_DOLLY_OFFSET = 32;
export const ORBIT_DOLLY_SENSITIVITY_OFFSET = 36;
export const ORBIT_MIN_DOLLY_OFFSET = 40;
export const ORBIT_MAX_DOLLY_OFFSET = 44;
export const ORBIT_DISTANCE_OFFSET = 48;
export const ORBIT_RESET_YAW_OFFSET = 52;
export const ORBIT_RESET_PITCH_OFFSET = 56;
export const ORBIT_RESET_PAN_X_OFFSET = 60;
export const ORBIT_RESET_PAN_Y_OFFSET = 64;
export const ORBIT_RESET_DOLLY_OFFSET = 68;
export const ORBIT_RESET_DISTANCE_OFFSET = 72;
export const ORBIT_RESET_REQUESTED_OFFSET = 76;

export const LENS_PROJECTION_KIND_OFFSET = 0;
export const LENS_NEAR_OFFSET = 4;
export const LENS_FAR_OFFSET = 8;
export const LENS_ASPECT_OFFSET = 12;
export const LENS_FOV_Y_RAD_OFFSET = 16;
export const LENS_ORTHO_HALF_HEIGHT_OFFSET = 20;
export const LENS_FLAGS_OFFSET = 24;

export const CAMERA_PROJECTION_PERSPECTIVE = 0;
export const CAMERA_PROJECTION_ORTHOGRAPHIC = 1;

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

export type OrbitCameraPose = OrbitCameraController & {
	distance: number;
	resetRequested: boolean;
};

export type OrbitCameraInputFrame = {
	readonly leftDown: boolean;
	readonly leftPressed: boolean;
	readonly middleDown: boolean;
	readonly middlePressed: boolean;
	readonly pointerDeltaX: number;
	readonly pointerDeltaY: number;
	readonly wheelDeltaY: number;
};

export type OrbitOrthographicCameraDesc = {
	readonly yaw: number;
	readonly pitch: number;
	readonly panX: number;
	readonly panY: number;
	readonly dolly: number;
	readonly distance: number;
	readonly near: number;
	readonly far: number;
	readonly aspect: number;
	readonly orthoHalfHeight: number;
	readonly flags: number;
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

export function readF32(bytes: Uint8Array, offset: number): number {
	return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getFloat32(
		offset,
		true,
	);
}

export function writeF32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(
		offset,
		value,
		true,
	);
}

export function componentBytesOrThrow(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	name: string,
): Uint8Array {
	const bytes = world.componentBytesCopy(camera, component);
	if (bytes === null) {
		throw new Error(`${name}: camera is missing component.`);
	}
	return bytes;
}

function orbitCameraControllerBytes(
	controller: OrbitCameraController,
	distance: number,
	resetRequested: boolean,
): Uint8Array {
	const bytes = new Uint8Array(ORBIT_CAMERA_CONTROLLER_STRIDE);
	writeF32(bytes, ORBIT_YAW_OFFSET, controller.yaw);
	writeF32(bytes, ORBIT_PITCH_OFFSET, controller.pitch);
	writeF32(bytes, ORBIT_SENSITIVITY_OFFSET, controller.sensitivity);
	writeF32(bytes, ORBIT_MIN_PITCH_OFFSET, controller.minPitch);
	writeF32(bytes, ORBIT_MAX_PITCH_OFFSET, controller.maxPitch);
	writeF32(bytes, ORBIT_PAN_X_OFFSET, controller.panX);
	writeF32(bytes, ORBIT_PAN_Y_OFFSET, controller.panY);
	writeF32(bytes, ORBIT_PAN_SENSITIVITY_OFFSET, controller.panSensitivity);
	writeF32(bytes, ORBIT_DOLLY_OFFSET, controller.dolly);
	writeF32(bytes, ORBIT_DOLLY_SENSITIVITY_OFFSET, controller.dollySensitivity);
	writeF32(bytes, ORBIT_MIN_DOLLY_OFFSET, controller.minDolly);
	writeF32(bytes, ORBIT_MAX_DOLLY_OFFSET, controller.maxDolly);
	writeF32(bytes, ORBIT_DISTANCE_OFFSET, distance);
	writeF32(bytes, ORBIT_RESET_YAW_OFFSET, controller.yaw);
	writeF32(bytes, ORBIT_RESET_PITCH_OFFSET, controller.pitch);
	writeF32(bytes, ORBIT_RESET_PAN_X_OFFSET, controller.panX);
	writeF32(bytes, ORBIT_RESET_PAN_Y_OFFSET, controller.panY);
	writeF32(bytes, ORBIT_RESET_DOLLY_OFFSET, controller.dolly);
	writeF32(bytes, ORBIT_RESET_DISTANCE_OFFSET, distance);
	writeF32(bytes, ORBIT_RESET_REQUESTED_OFFSET, resetRequested ? 1 : 0);
	return bytes;
}

export function registerOrbitCameraControllerComponent(
	world: World,
): ComponentTypeId {
	return world.orbitCameraControllerComponent();
}

export function registerCameraHomeTransformComponent(
	world: World,
): ComponentTypeId {
	return world.cameraHomeTransformComponent();
}

export function registerCameraLensComponent(world: World): ComponentTypeId {
	return world.cameraLensComponent();
}

export function addOrbitCameraController(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	yaw: number,
	pitch: number,
): boolean {
	return addOrbitCameraControllerWithDistance(
		world,
		camera,
		component,
		yaw,
		pitch,
		16,
	);
}

export function addOrbitCameraControllerWithDistance(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	yaw: number,
	pitch: number,
	distance: number,
): boolean {
	return world.addComponentBytes(
		camera,
		component,
		orbitCameraControllerBytes(
			createOrbitCameraController(pitch, yaw),
			distance,
			false,
		),
	);
}

export function addOrbitCameraControllerWithPose(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	yaw: number,
	pitch: number,
	panX: number,
	panY: number,
	dolly: number,
	distance: number,
): boolean {
	const controller = createOrbitCameraController(pitch, yaw);
	controller.panX = panX;
	controller.panY = panY;
	controller.dolly = dolly;
	return world.addComponentBytes(
		camera,
		component,
		orbitCameraControllerBytes(controller, distance, false),
	);
}

export function setOrAddComponentBytesTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	bytes: Uint8Array,
): boolean {
	if (world.hasComponent(camera, component)) {
		return history.setComponentBytes(world, camera, component, bytes);
	}
	return history.addComponentBytes(world, camera, component, bytes);
}

export function addOrbitCameraControllerTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	yaw: number,
	pitch: number,
): boolean {
	return addOrbitCameraControllerWithDistanceTracked(
		history,
		world,
		camera,
		component,
		yaw,
		pitch,
		16,
	);
}

export function addOrbitCameraControllerWithDistanceTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	yaw: number,
	pitch: number,
	distance: number,
): boolean {
	return history.addComponentBytes(
		world,
		camera,
		component,
		orbitCameraControllerBytes(
			createOrbitCameraController(pitch, yaw),
			distance,
			false,
		),
	);
}

export function addOrbitCameraControllerWithPoseTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	yaw: number,
	pitch: number,
	panX: number,
	panY: number,
	dolly: number,
	distance: number,
): boolean {
	const controller = createOrbitCameraController(pitch, yaw);
	controller.panX = panX;
	controller.panY = panY;
	controller.dolly = dolly;
	return history.addComponentBytes(
		world,
		camera,
		component,
		orbitCameraControllerBytes(controller, distance, false),
	);
}

export function setCameraHomeFromCurrentTransform(
	world: World,
	camera: EntityId,
	homeComponent: ComponentTypeId,
): boolean {
	const bytes = world.componentBytesCopy(camera, world.transformComponent());
	if (bytes === null) {
		return false;
	}
	if (world.hasComponent(camera, homeComponent)) {
		return world.setComponentBytes(camera, homeComponent, bytes);
	}
	return world.addComponentBytes(camera, homeComponent, bytes);
}

export function setCameraHomeFromCurrentTransformTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	homeComponent: ComponentTypeId,
): boolean {
	const bytes = world.componentBytesCopy(camera, world.transformComponent());
	if (bytes === null) {
		return false;
	}
	return setOrAddComponentBytesTracked(
		history,
		world,
		camera,
		homeComponent,
		bytes,
	);
}

export function createOrbitOrthographicCameraDesc(
	yaw: number,
	pitch: number,
	panX: number,
	panY: number,
	dolly: number,
	distance: number,
	near: number,
	far: number,
	aspect: number,
	orthoHalfHeight: number,
	flags = 0,
): OrbitOrthographicCameraDesc {
	return {
		yaw,
		pitch,
		panX,
		panY,
		dolly,
		distance,
		near,
		far,
		aspect,
		orthoHalfHeight,
		flags,
	};
}

export function createOrbitOrthographicCameraDescFromYzPosition(
	pitch: number,
	positionY: number,
	positionZ: number,
	near: number,
	far: number,
	aspect: number,
	orthoHalfHeight: number,
	flags = 0,
): OrbitOrthographicCameraDesc {
	const panY = -positionY / Math.cos(pitch);
	const distance = positionZ - panY * Math.sin(pitch);
	return createOrbitOrthographicCameraDesc(
		0,
		pitch,
		0,
		panY,
		1,
		distance,
		near,
		far,
		aspect,
		orthoHalfHeight,
		flags,
	);
}

function cameraLensBytes(
	projectionKind: number,
	near: number,
	far: number,
	aspect: number,
	fovYRad: number,
	orthoHalfHeight: number,
	flags: number,
): Uint8Array {
	const bytes = new Uint8Array(CAMERA_LENS_STRIDE);
	writeF32(bytes, LENS_PROJECTION_KIND_OFFSET, projectionKind);
	writeF32(bytes, LENS_NEAR_OFFSET, near);
	writeF32(bytes, LENS_FAR_OFFSET, far);
	writeF32(bytes, LENS_ASPECT_OFFSET, aspect);
	writeF32(bytes, LENS_FOV_Y_RAD_OFFSET, fovYRad);
	writeF32(bytes, LENS_ORTHO_HALF_HEIGHT_OFFSET, orthoHalfHeight);
	writeF32(bytes, LENS_FLAGS_OFFSET, flags);
	return bytes;
}

export function addCameraLensPerspective(
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	fovYRad: number,
	flags: number,
): boolean {
	return world.addComponentBytes(
		camera,
		lensComponent,
		cameraLensBytes(
			CAMERA_PROJECTION_PERSPECTIVE,
			near,
			far,
			aspect,
			fovYRad,
			1,
			flags,
		),
	);
}

export function addCameraLensPerspectiveTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	fovYRad: number,
	flags: number,
): boolean {
	return history.addComponentBytes(
		world,
		camera,
		lensComponent,
		cameraLensBytes(
			CAMERA_PROJECTION_PERSPECTIVE,
			near,
			far,
			aspect,
			fovYRad,
			1,
			flags,
		),
	);
}

export function addCameraLensOrthographic(
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	orthoHalfHeight: number,
	flags: number,
): boolean {
	return world.addComponentBytes(
		camera,
		lensComponent,
		cameraLensBytes(
			CAMERA_PROJECTION_ORTHOGRAPHIC,
			near,
			far,
			aspect,
			1,
			orthoHalfHeight,
			flags,
		),
	);
}

export function addCameraLensOrthographicTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	orthoHalfHeight: number,
	flags: number,
): boolean {
	return history.addComponentBytes(
		world,
		camera,
		lensComponent,
		cameraLensBytes(
			CAMERA_PROJECTION_ORTHOGRAPHIC,
			near,
			far,
			aspect,
			1,
			orthoHalfHeight,
			flags,
		),
	);
}

export function setCameraLensPerspective(
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	fovYRad: number,
	flags: number,
): boolean {
	const bytes = cameraLensBytes(
		CAMERA_PROJECTION_PERSPECTIVE,
		near,
		far,
		aspect,
		fovYRad,
		1,
		flags,
	);
	if (world.hasComponent(camera, lensComponent)) {
		return world.setComponentBytes(camera, lensComponent, bytes);
	}
	return world.addComponentBytes(camera, lensComponent, bytes);
}

export function setCameraLensPerspectiveTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	fovYRad: number,
	flags: number,
): boolean {
	const bytes = cameraLensBytes(
		CAMERA_PROJECTION_PERSPECTIVE,
		near,
		far,
		aspect,
		fovYRad,
		1,
		flags,
	);
	return setOrAddComponentBytesTracked(
		history,
		world,
		camera,
		lensComponent,
		bytes,
	);
}

export function setCameraLensOrthographic(
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	orthoHalfHeight: number,
	flags: number,
): boolean {
	const bytes = cameraLensBytes(
		CAMERA_PROJECTION_ORTHOGRAPHIC,
		near,
		far,
		aspect,
		1,
		orthoHalfHeight,
		flags,
	);
	if (world.hasComponent(camera, lensComponent)) {
		return world.setComponentBytes(camera, lensComponent, bytes);
	}
	return world.addComponentBytes(camera, lensComponent, bytes);
}

export function setCameraLensOrthographicTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	lensComponent: ComponentTypeId,
	near: number,
	far: number,
	aspect: number,
	orthoHalfHeight: number,
	flags: number,
): boolean {
	const bytes = cameraLensBytes(
		CAMERA_PROJECTION_ORTHOGRAPHIC,
		near,
		far,
		aspect,
		1,
		orthoHalfHeight,
		flags,
	);
	return setOrAddComponentBytesTracked(
		history,
		world,
		camera,
		lensComponent,
		bytes,
	);
}

function readOrbitCameraControllerFromBytes(bytes: Uint8Array): OrbitCameraController {
	return {
		yaw: readF32(bytes, ORBIT_YAW_OFFSET),
		pitch: readF32(bytes, ORBIT_PITCH_OFFSET),
		sensitivity: readF32(bytes, ORBIT_SENSITIVITY_OFFSET),
		minPitch: readF32(bytes, ORBIT_MIN_PITCH_OFFSET),
		maxPitch: readF32(bytes, ORBIT_MAX_PITCH_OFFSET),
		panX: readF32(bytes, ORBIT_PAN_X_OFFSET),
		panY: readF32(bytes, ORBIT_PAN_Y_OFFSET),
		panSensitivity: readF32(bytes, ORBIT_PAN_SENSITIVITY_OFFSET),
		dolly: readF32(bytes, ORBIT_DOLLY_OFFSET),
		dollySensitivity: readF32(bytes, ORBIT_DOLLY_SENSITIVITY_OFFSET),
		minDolly: readF32(bytes, ORBIT_MIN_DOLLY_OFFSET),
		maxDolly: readF32(bytes, ORBIT_MAX_DOLLY_OFFSET),
	};
}

export function readOrbitCameraControllerComponent(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
): OrbitCameraController {
	return readOrbitCameraControllerFromBytes(
		componentBytesOrThrow(
			world,
			camera,
			component,
			"readOrbitCameraControllerComponent",
		),
	);
}

function readOrbitCameraPoseFromBytes(bytes: Uint8Array): OrbitCameraPose {
	return {
		...readOrbitCameraControllerFromBytes(bytes),
		distance: readF32(bytes, ORBIT_DISTANCE_OFFSET),
		resetRequested: readF32(bytes, ORBIT_RESET_REQUESTED_OFFSET) !== 0,
	};
}

export function readOrbitCameraPoseComponent(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
): OrbitCameraPose {
	return readOrbitCameraPoseFromBytes(
		componentBytesOrThrow(
			world,
			camera,
			component,
			"readOrbitCameraPoseComponent",
		),
	);
}

export function updateOrbitCameraControllerComponentFromMouseFrame(
	world: World,
	camera: EntityId,
	frame: OrbitCameraInputFrame,
): boolean {
	const component = world.orbitCameraControllerComponent();
	const bytes = componentBytesOrThrow(
		world,
		camera,
		component,
		"updateOrbitCameraControllerComponentFromMouseFrame",
	);
	const controller = readOrbitCameraControllerFromBytes(bytes);
	if (!updateOrbitCameraControllerFromMouseFrame(controller, frame)) {
		return false;
	}
	writeF32(bytes, ORBIT_YAW_OFFSET, controller.yaw);
	writeF32(bytes, ORBIT_PITCH_OFFSET, controller.pitch);
	writeF32(bytes, ORBIT_PAN_X_OFFSET, controller.panX);
	writeF32(bytes, ORBIT_PAN_Y_OFFSET, controller.panY);
	writeF32(bytes, ORBIT_DOLLY_OFFSET, controller.dolly);
	return world.setComponentBytes(camera, component, bytes);
}

export function updateOrbitCameraControllerComponentFromMouseFrameTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	frame: OrbitCameraInputFrame,
): boolean {
	const component = world.orbitCameraControllerComponent();
	const bytes = componentBytesOrThrow(
		world,
		camera,
		component,
		"updateOrbitCameraControllerComponentFromMouseFrameTracked",
	);
	const controller = readOrbitCameraControllerFromBytes(bytes);
	if (!updateOrbitCameraControllerFromMouseFrame(controller, frame)) {
		return false;
	}
	writeF32(bytes, ORBIT_YAW_OFFSET, controller.yaw);
	writeF32(bytes, ORBIT_PITCH_OFFSET, controller.pitch);
	writeF32(bytes, ORBIT_PAN_X_OFFSET, controller.panX);
	writeF32(bytes, ORBIT_PAN_Y_OFFSET, controller.panY);
	writeF32(bytes, ORBIT_DOLLY_OFFSET, controller.dolly);
	return history.setComponentBytes(world, camera, component, bytes);
}

export function requestOrbitCameraReset(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
): boolean {
	const bytes = world.componentBytesCopy(camera, component);
	if (bytes === null) {
		return false;
	}
	writeF32(bytes, ORBIT_RESET_REQUESTED_OFFSET, 1);
	return world.setComponentBytes(camera, component, bytes);
}

export function requestOrbitCameraResetTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
): boolean {
	const bytes = world.componentBytesCopy(camera, component);
	if (bytes === null) {
		return false;
	}
	writeF32(bytes, ORBIT_RESET_REQUESTED_OFFSET, 1);
	return history.setComponentBytes(world, camera, component, bytes);
}

export function updateOrbitCameraControllerFromMouseFrame(
	controller: OrbitCameraController,
	frame: OrbitCameraInputFrame,
): boolean {
	let changed = false;
	if (frame.leftDown && !frame.leftPressed) {
		controller.yaw += frame.pointerDeltaX * controller.sensitivity;
		controller.pitch = Math.min(
			controller.maxPitch,
			Math.max(
				controller.minPitch,
				controller.pitch + frame.pointerDeltaY * controller.sensitivity,
			),
		);
		changed = true;
	}
	if (frame.middleDown && !frame.middlePressed) {
		controller.panX +=
			frame.pointerDeltaX * controller.panSensitivity * controller.dolly;
		controller.panY -=
			frame.pointerDeltaY * controller.panSensitivity * controller.dolly;
		changed = true;
	}
	if (frame.wheelDeltaY !== 0) {
		controller.dolly = Math.min(
			controller.maxDolly,
			Math.max(
				controller.minDolly,
				controller.dolly +
					frame.wheelDeltaY * controller.dollySensitivity * controller.dolly,
			),
		);
		changed = true;
	}
	return changed;
}
