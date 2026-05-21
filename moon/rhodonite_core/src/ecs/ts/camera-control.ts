// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { ComponentTypeId, EntityId } from "./types.ts";
import type { World } from "./world.ts";

export const ORBIT_CAMERA_CONTROLLER_STRIDE = 80;
export const CAMERA_HOME_TRANSFORM_STRIDE = 48;
export const CAMERA_LENS_STRIDE = 32;

const ORBIT_YAW_OFFSET = 0;
const ORBIT_PITCH_OFFSET = 4;
const ORBIT_SENSITIVITY_OFFSET = 8;
const ORBIT_MIN_PITCH_OFFSET = 12;
const ORBIT_MAX_PITCH_OFFSET = 16;
const ORBIT_PAN_X_OFFSET = 20;
const ORBIT_PAN_Y_OFFSET = 24;
const ORBIT_PAN_SENSITIVITY_OFFSET = 28;
const ORBIT_DOLLY_OFFSET = 32;
const ORBIT_DOLLY_SENSITIVITY_OFFSET = 36;
const ORBIT_MIN_DOLLY_OFFSET = 40;
const ORBIT_MAX_DOLLY_OFFSET = 44;
const ORBIT_DISTANCE_OFFSET = 48;
const ORBIT_RESET_YAW_OFFSET = 52;
const ORBIT_RESET_PITCH_OFFSET = 56;
const ORBIT_RESET_PAN_X_OFFSET = 60;
const ORBIT_RESET_PAN_Y_OFFSET = 64;
const ORBIT_RESET_DOLLY_OFFSET = 68;
const ORBIT_RESET_DISTANCE_OFFSET = 72;
const ORBIT_RESET_REQUESTED_OFFSET = 76;

const LENS_PROJECTION_KIND_OFFSET = 0;
const LENS_NEAR_OFFSET = 4;
const LENS_FAR_OFFSET = 8;
const LENS_ASPECT_OFFSET = 12;
const LENS_FOV_Y_RAD_OFFSET = 16;
const LENS_ORTHO_HALF_HEIGHT_OFFSET = 20;
const LENS_FLAGS_OFFSET = 24;

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

function readF32(bytes: Uint8Array, offset: number): number {
	return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getFloat32(
		offset,
		true,
	);
}

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(
		offset,
		value,
		true,
	);
}

function componentBytesOrThrow(
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
	return world.registerCpuComponent(
		"OrbitCameraController",
		ORBIT_CAMERA_CONTROLLER_STRIDE,
	);
}

export function registerCameraHomeTransformComponent(
	world: World,
): ComponentTypeId {
	return world.registerCpuComponent(
		"CameraHomeTransform",
		CAMERA_HOME_TRANSFORM_STRIDE,
	);
}

export function registerCameraLensComponent(world: World): ComponentTypeId {
	return world.registerCpuComponent("CameraLens", CAMERA_LENS_STRIDE);
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

function readOrbitCameraPoseComponent(
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
	component: ComponentTypeId,
	frame: OrbitCameraInputFrame,
): boolean {
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

function quatMul(
	a: readonly [number, number, number, number],
	b: readonly [number, number, number, number],
): [number, number, number, number] {
	const [ax, ay, az, aw] = a;
	const [bx, by, bz, bw] = b;
	return [
		aw * bx + ax * bw + ay * bz - az * by,
		aw * by - ax * bz + ay * bw + az * bx,
		aw * bz + ax * by - ay * bx + az * bw,
		aw * bw - ax * bx - ay * by - az * bz,
	];
}

function quatX(angle: number): [number, number, number, number] {
	const half = angle * 0.5;
	return [Math.sin(half), 0, 0, Math.cos(half)];
}

function quatY(angle: number): [number, number, number, number] {
	const half = angle * 0.5;
	return [0, Math.sin(half), 0, Math.cos(half)];
}

function quatRotateVec3(
	q: readonly [number, number, number, number],
	x: number,
	y: number,
	z: number,
): [number, number, number] {
	const [qx, qy, qz, qw] = q;
	const tx = 2 * (qy * z - qz * y);
	const ty = 2 * (qz * x - qx * z);
	const tz = 2 * (qx * y - qy * x);
	return [
		x + qw * tx + (qy * tz - qz * ty),
		y + qw * ty + (qz * tx - qx * tz),
		z + qw * tz + (qx * ty - qy * tx),
	];
}

function localMatrixFromTrs(
	px: number,
	py: number,
	pz: number,
	qx: number,
	qy: number,
	qz: number,
	qw: number,
	sx: number,
	sy: number,
	sz: number,
): Float32Array {
	const xx = qx * qx;
	const yy = qy * qy;
	const zz = qz * qz;
	const xy = qx * qy;
	const xz = qx * qz;
	const yz = qy * qz;
	const wx = qw * qx;
	const wy = qw * qy;
	const wz = qw * qz;
	const r00 = 1 - 2 * (yy + zz);
	const r01 = 2 * (xy - wz);
	const r02 = 2 * (xz + wy);
	const r10 = 2 * (xy + wz);
	const r11 = 1 - 2 * (xx + zz);
	const r12 = 2 * (yz - wx);
	const r20 = 2 * (xz - wy);
	const r21 = 2 * (yz + wx);
	const r22 = 1 - 2 * (xx + yy);
	return new Float32Array([
		r00 * sx,
		r10 * sx,
		r20 * sx,
		0,
		r01 * sy,
		r11 * sy,
		r21 * sy,
		0,
		r02 * sz,
		r12 * sz,
		r22 * sz,
		0,
		px,
		py,
		pz,
		1,
	]);
}

export function mat4Inverse(m: Float32Array): Float32Array | null {
	const a00 = m[0] ?? 0;
	const a01 = m[1] ?? 0;
	const a02 = m[2] ?? 0;
	const a03 = m[3] ?? 0;
	const a10 = m[4] ?? 0;
	const a11 = m[5] ?? 0;
	const a12 = m[6] ?? 0;
	const a13 = m[7] ?? 0;
	const a20 = m[8] ?? 0;
	const a21 = m[9] ?? 0;
	const a22 = m[10] ?? 0;
	const a23 = m[11] ?? 0;
	const a30 = m[12] ?? 0;
	const a31 = m[13] ?? 0;
	const a32 = m[14] ?? 0;
	const a33 = m[15] ?? 0;
	const b00 = a00 * a11 - a01 * a10;
	const b01 = a00 * a12 - a02 * a10;
	const b02 = a00 * a13 - a03 * a10;
	const b03 = a01 * a12 - a02 * a11;
	const b04 = a01 * a13 - a03 * a11;
	const b05 = a02 * a13 - a03 * a12;
	const b06 = a20 * a31 - a21 * a30;
	const b07 = a20 * a32 - a22 * a30;
	const b08 = a20 * a33 - a23 * a30;
	const b09 = a21 * a32 - a22 * a31;
	const b10 = a21 * a33 - a23 * a31;
	const b11 = a22 * a33 - a23 * a32;
	let det =
		b00 * b11 -
		b01 * b10 +
		b02 * b09 +
		b03 * b08 -
		b04 * b07 +
		b05 * b06;
	if (Math.abs(det) <= Number.EPSILON) {
		return null;
	}
	det = 1 / det;
	return new Float32Array([
		(a11 * b11 - a12 * b10 + a13 * b09) * det,
		(a02 * b10 - a01 * b11 - a03 * b09) * det,
		(a31 * b05 - a32 * b04 + a33 * b03) * det,
		(a22 * b04 - a21 * b05 - a23 * b03) * det,
		(a12 * b08 - a10 * b11 - a13 * b07) * det,
		(a00 * b11 - a02 * b08 + a03 * b07) * det,
		(a32 * b02 - a30 * b05 - a33 * b01) * det,
		(a20 * b05 - a22 * b02 + a23 * b01) * det,
		(a10 * b10 - a11 * b08 + a13 * b06) * det,
		(a01 * b08 - a00 * b10 - a03 * b06) * det,
		(a30 * b04 - a31 * b02 + a33 * b00) * det,
		(a21 * b02 - a20 * b04 - a23 * b00) * det,
		(a11 * b07 - a10 * b09 - a12 * b06) * det,
		(a00 * b09 - a01 * b07 + a02 * b06) * det,
		(a31 * b01 - a30 * b03 - a32 * b00) * det,
		(a20 * b03 - a21 * b01 + a22 * b00) * det,
	]);
}

function orthographicProjection(
	aspect: number,
	halfHeight: number,
	near: number,
	far: number,
): Float32Array {
	const halfWidth = halfHeight * aspect;
	const left = -halfWidth;
	const right = halfWidth;
	const bottom = -halfHeight;
	const top = halfHeight;
	return new Float32Array([
		2 / (right - left),
		0,
		0,
		0,
		0,
		2 / (top - bottom),
		0,
		0,
		0,
		0,
		1 / (near - far),
		0,
		-(right + left) / (right - left),
		-(top + bottom) / (top - bottom),
		near / (near - far),
		1,
	]);
}

function orbitOrthographicCameraDescTrs(
	desc: OrbitOrthographicCameraDesc,
): {
	px: number;
	py: number;
	pz: number;
	qx: number;
	qy: number;
	qz: number;
	qw: number;
} {
	const q = quatMul(quatY(-desc.yaw), quatX(-desc.pitch));
	const [dx, dy, dz] = quatRotateVec3(q, -desc.panX, -desc.panY, 0);
	return {
		px: dx,
		py: dy,
		pz: dz + desc.distance,
		qx: q[0],
		qy: q[1],
		qz: q[2],
		qw: q[3],
	};
}

export function setupOrbitOrthographicCamera(
	world: World,
	camera: EntityId,
	orbitComponent: ComponentTypeId,
	homeComponent: ComponentTypeId,
	lensComponent: ComponentTypeId,
	desc: OrbitOrthographicCameraDesc,
): boolean {
	const { px, py, pz, qx, qy, qz, qw } = orbitOrthographicCameraDescTrs(desc);
	const local = localMatrixFromTrs(px, py, pz, qx, qy, qz, qw, 1, 1, 1);
	const view = mat4Inverse(local);
	if (view === null) {
		return false;
	}
	return (
		world.setTransformTrs(camera, px, py, pz, qx, qy, qz, qw, 1, 1, 1) &&
		world.setGlobalTransform(camera, local) &&
		addOrbitCameraControllerWithPose(
			world,
			camera,
			orbitComponent,
			desc.yaw,
			desc.pitch,
			desc.panX,
			desc.panY,
			desc.dolly,
			desc.distance,
		) &&
		setCameraHomeFromCurrentTransform(world, camera, homeComponent) &&
		addCameraLensOrthographic(
			world,
			camera,
			lensComponent,
			desc.near,
			desc.far,
			desc.aspect,
			desc.orthoHalfHeight,
			desc.flags,
		) &&
		world.setCameraMatrices(
			camera,
			view,
			orthographicProjection(
				desc.aspect,
				desc.orthoHalfHeight * desc.dolly,
				desc.near,
				desc.far,
			),
			desc.near,
			desc.far,
			desc.aspect,
			CAMERA_PROJECTION_ORTHOGRAPHIC,
			desc.flags,
		)
	);
}

function perspectiveProjection(
	aspect: number,
	fovYRad: number,
	near: number,
	far: number,
): Float32Array {
	const f = 1 / Math.tan(fovYRad * 0.5);
	return new Float32Array([
		f / aspect,
		0,
		0,
		0,
		0,
		f,
		0,
		0,
		0,
		0,
		far / (near - far),
		-1,
		0,
		0,
		(near * far) / (near - far),
		0,
	]);
}

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
	const q = quatMul(quatY(-pose.yaw), quatX(-pose.pitch));
	const [dx, dy, dz] = quatRotateVec3(q, -pose.panX, -pose.panY, 0);
	const view = mat4Inverse(
		localMatrixFromTrs(dx, dy, dz + pose.distance, q[0], q[1], q[2], q[3], 1, 1, 1),
	);
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
