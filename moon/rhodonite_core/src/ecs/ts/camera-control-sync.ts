// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { ComponentTypeId, EntityId } from "./types.ts";
import type { World, WorldHistory } from "./world.ts";
import {
	CAMERA_PROJECTION_PERSPECTIVE,
	LENS_ASPECT_OFFSET,
	LENS_FAR_OFFSET,
	LENS_FLAGS_OFFSET,
	LENS_FOV_Y_RAD_OFFSET,
	LENS_NEAR_OFFSET,
	LENS_ORTHO_HALF_HEIGHT_OFFSET,
	LENS_PROJECTION_KIND_OFFSET,
	ORBIT_DISTANCE_OFFSET,
	ORBIT_DOLLY_OFFSET,
	ORBIT_PAN_X_OFFSET,
	ORBIT_PAN_Y_OFFSET,
	ORBIT_PITCH_OFFSET,
	ORBIT_RESET_DISTANCE_OFFSET,
	ORBIT_RESET_DOLLY_OFFSET,
	ORBIT_RESET_PAN_X_OFFSET,
	ORBIT_RESET_PAN_Y_OFFSET,
	ORBIT_RESET_PITCH_OFFSET,
	ORBIT_RESET_REQUESTED_OFFSET,
	ORBIT_RESET_YAW_OFFSET,
	ORBIT_YAW_OFFSET,
	componentBytesOrThrow,
	readF32,
	readOrbitCameraPoseComponent,
	writeF32,
} from "./camera-control-core.ts";
import {
	localMatrixFromTrs,
	mat4Inverse,

orthographicProjection,
	perspectiveProjection,
	quatMul,
	quatRotateVec3,
	quatX,
	quatY,
	runTrackedCameraControlTransaction,
} from "./camera-control-projection.ts";

export function syncOrbitCameraBlobComponent(
	world: World,
	camera: EntityId,
	orbitComponent: ComponentTypeId,
	lensComponent: ComponentTypeId,
): void {
	const pose = readOrbitCameraPoseComponent(world, camera, orbitComponent);
	const lensBytes = componentBytesOrThrow(
		world,
		camera,
		lensComponent,
		"syncOrbitCameraBlobComponent",
	);
	const global = world.getGlobalTransform(camera);
	if (global === null) {
		throw new Error("Camera is missing GlobalTransform.");
	}
	const view = mat4Inverse(global);
	if (view === null) {
		throw new Error("Failed to invert Camera GlobalTransform.");
	}
	const projectionKind = readF32(lensBytes, LENS_PROJECTION_KIND_OFFSET);
	const near = readF32(lensBytes, LENS_NEAR_OFFSET);
	const far = readF32(lensBytes, LENS_FAR_OFFSET);
	const aspect = readF32(lensBytes, LENS_ASPECT_OFFSET);
	const fovYRad = readF32(lensBytes, LENS_FOV_Y_RAD_OFFSET);
	const orthoHalfHeight = readF32(lensBytes, LENS_ORTHO_HALF_HEIGHT_OFFSET);
	const flags = readF32(lensBytes, LENS_FLAGS_OFFSET);
	const proj =
		projectionKind === CAMERA_PROJECTION_PERSPECTIVE
			? perspectiveProjection(aspect, fovYRad, near, far)
			: orthographicProjection(aspect, orthoHalfHeight * pose.dolly, near, far);
	if (
		!world.setCameraMatrices(
			camera,
			view,
			proj,
			near,
			far,
			aspect,
			projectionKind,
			flags,
		)
	) {
		throw new Error("Failed to update Camera matrices.");
	}
}

export function syncOrbitCameraBlobComponentTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	orbitComponent: ComponentTypeId,
	lensComponent: ComponentTypeId,
): void {
	const pose = readOrbitCameraPoseComponent(world, camera, orbitComponent);
	const lensBytes = componentBytesOrThrow(
		world,
		camera,
		lensComponent,
		"syncOrbitCameraBlobComponentTracked",
	);
	const global = world.getGlobalTransform(camera);
	if (global === null) {
		throw new Error("Camera is missing GlobalTransform.");
	}
	const view = mat4Inverse(global);
	if (view === null) {
		throw new Error("Failed to invert Camera GlobalTransform.");
	}
	const projectionKind = readF32(lensBytes, LENS_PROJECTION_KIND_OFFSET);
	const near = readF32(lensBytes, LENS_NEAR_OFFSET);
	const far = readF32(lensBytes, LENS_FAR_OFFSET);
	const aspect = readF32(lensBytes, LENS_ASPECT_OFFSET);
	const fovYRad = readF32(lensBytes, LENS_FOV_Y_RAD_OFFSET);
	const orthoHalfHeight = readF32(lensBytes, LENS_ORTHO_HALF_HEIGHT_OFFSET);
	const flags = readF32(lensBytes, LENS_FLAGS_OFFSET);
	const proj =
		projectionKind === CAMERA_PROJECTION_PERSPECTIVE
			? perspectiveProjection(aspect, fovYRad, near, far)
			: orthographicProjection(aspect, orthoHalfHeight * pose.dolly, near, far);
	if (
		!history.setCameraMatrices(
			world,
			camera,
			view,
			proj,
			near,
			far,
			aspect,
			projectionKind,
			flags,
		)
	) {
		throw new Error("Failed to update Camera matrices.");
	}
}

function localMatrixFromTransformBytes(bytes: Uint8Array): Float32Array {
	return localMatrixFromTrs(
		readF32(bytes, 0),
		readF32(bytes, 4),
		readF32(bytes, 8),
		readF32(bytes, 12),
		readF32(bytes, 16),
		readF32(bytes, 20),
		readF32(bytes, 24),
		readF32(bytes, 28),
		readF32(bytes, 32),
		readF32(bytes, 36),
	);
}

export function syncOrbitCameraTransformComponent(
	world: World,
	camera: EntityId,
	orbitComponent: ComponentTypeId,
	homeComponent: ComponentTypeId,
): void {
	const pose = readOrbitCameraPoseComponent(world, camera, orbitComponent);
	if (pose.resetRequested) {
		const homeBytes = componentBytesOrThrow(
			world,
			camera,
			homeComponent,
			"syncOrbitCameraTransformComponent",
		);
		const orbitBytes = componentBytesOrThrow(
			world,
			camera,
			orbitComponent,
			"syncOrbitCameraTransformComponent",
		);
		if (!world.setComponentBytes(camera, world.transformComponent(), homeBytes)) {
			throw new Error("Failed to reset camera Transform3D from CameraHomeTransform.");
		}
		writeF32(orbitBytes, ORBIT_YAW_OFFSET, readF32(orbitBytes, ORBIT_RESET_YAW_OFFSET));
		writeF32(
			orbitBytes,
			ORBIT_PITCH_OFFSET,
			readF32(orbitBytes, ORBIT_RESET_PITCH_OFFSET),
		);
		writeF32(orbitBytes, ORBIT_PAN_X_OFFSET, readF32(orbitBytes, ORBIT_RESET_PAN_X_OFFSET));
		writeF32(orbitBytes, ORBIT_PAN_Y_OFFSET, readF32(orbitBytes, ORBIT_RESET_PAN_Y_OFFSET));
		writeF32(orbitBytes, ORBIT_DOLLY_OFFSET, readF32(orbitBytes, ORBIT_RESET_DOLLY_OFFSET));
		writeF32(
			orbitBytes,
			ORBIT_DISTANCE_OFFSET,
			readF32(orbitBytes, ORBIT_RESET_DISTANCE_OFFSET),
		);
		writeF32(orbitBytes, ORBIT_RESET_REQUESTED_OFFSET, 0);
		if (!world.setComponentBytes(camera, orbitComponent, orbitBytes)) {
			throw new Error("Failed to clear OrbitCameraController reset request.");
		}
		if (!world.setGlobalTransform(camera, localMatrixFromTransformBytes(homeBytes))) {
			throw new Error("Failed to reset camera GlobalTransform.");
		}
		return;
	}
	const q = quatMul(quatY(-pose.yaw), quatX(-pose.pitch));
	const [dx, dy, dz] = quatRotateVec3(q, -pose.panX, -pose.panY, 0);
	const px = dx;
	const py = dy;
	const pz = dz + pose.distance;
	if (!world.setTransformTrs(camera, px, py, pz, q[0], q[1], q[2], q[3], 1, 1, 1)) {
		throw new Error("Failed to update camera Transform3D.");
	}
	if (
		!world.setGlobalTransform(
			camera,
			localMatrixFromTrs(px, py, pz, q[0], q[1], q[2], q[3], 1, 1, 1),
		)
	) {
		throw new Error("Failed to update camera GlobalTransform.");
	}
}

export function syncOrbitCameraTransformComponentTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	orbitComponent: ComponentTypeId,
	homeComponent: ComponentTypeId,
): void {
	if (
		!runTrackedCameraControlTransaction(
			history,
			world,
			"syncOrbitCameraTransformComponent",
			() =>
				syncOrbitCameraTransformComponentTrackedBody(
					history,
					world,
					camera,
					orbitComponent,
					homeComponent,
				),
		)
	) {
		throw new Error("Failed to update camera Transform3D.");
	}
}

function syncOrbitCameraTransformComponentTrackedBody(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	orbitComponent: ComponentTypeId,
	homeComponent: ComponentTypeId,
): boolean {
	const pose = readOrbitCameraPoseComponent(world, camera, orbitComponent);
	if (
		pose.resetRequested &&
		!world.hasComponent(camera, world.transformComponent())
	) {
		return false;
	}
	let ok = true;
	if (pose.resetRequested) {
		const homeBytes = componentBytesOrThrow(
			world,
			camera,
			homeComponent,
			"syncOrbitCameraTransformComponentTracked",
		);
		const orbitBytes = componentBytesOrThrow(
			world,
			camera,
			orbitComponent,
			"syncOrbitCameraTransformComponentTracked",
		);
		ok = history.setComponentBytes(
			world,
			camera,
			world.transformComponent(),
			homeBytes,
		);
		writeF32(orbitBytes, ORBIT_YAW_OFFSET, readF32(orbitBytes, ORBIT_RESET_YAW_OFFSET));
		writeF32(
			orbitBytes,
			ORBIT_PITCH_OFFSET,
			readF32(orbitBytes, ORBIT_RESET_PITCH_OFFSET),
		);
		writeF32(orbitBytes, ORBIT_PAN_X_OFFSET, readF32(orbitBytes, ORBIT_RESET_PAN_X_OFFSET));
		writeF32(orbitBytes, ORBIT_PAN_Y_OFFSET, readF32(orbitBytes, ORBIT_RESET_PAN_Y_OFFSET));
		writeF32(orbitBytes, ORBIT_DOLLY_OFFSET, readF32(orbitBytes, ORBIT_RESET_DOLLY_OFFSET));
		writeF32(
			orbitBytes,
			ORBIT_DISTANCE_OFFSET,
			readF32(orbitBytes, ORBIT_RESET_DISTANCE_OFFSET),
		);
		writeF32(orbitBytes, ORBIT_RESET_REQUESTED_OFFSET, 0);
		ok =
			ok &&
			history.setComponentBytes(world, camera, orbitComponent, orbitBytes) &&
			history.setGlobalTransform(
				world,
				camera,
				localMatrixFromTransformBytes(homeBytes),
			);
	} else {
		const q = quatMul(quatY(-pose.yaw), quatX(-pose.pitch));
		const [dx, dy, dz] = quatRotateVec3(q, -pose.panX, -pose.panY, 0);
		const px = dx;
		const py = dy;
		const pz = dz + pose.distance;
		ok =
			history.setTransformTrs(
				world,
				camera,
				px,
				py,
				pz,
				q[0],
				q[1],
				q[2],
				q[3],
				1,
				1,
				1,
			) &&
			history.setGlobalTransform(
				world,
				camera,
				localMatrixFromTrs(px, py, pz, q[0], q[1], q[2], q[3], 1, 1, 1),
			);
	}
	return ok;
}
