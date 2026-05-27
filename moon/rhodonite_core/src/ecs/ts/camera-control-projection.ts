// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { EntityId } from "./types.ts";
import type { World, WorldHistory } from "./world.ts";
import {
	CAMERA_PROJECTION_ORTHOGRAPHIC,
	addCameraLensOrthographic,
	addCameraLensOrthographicTracked,
	addOrbitCameraControllerWithPose,
	addOrbitCameraControllerWithPoseTracked,
	setCameraHomeFromCurrentTransform,
	setCameraHomeFromCurrentTransformTracked,
	type OrbitOrthographicCameraDesc,
} from "./camera-control-core.ts";

export function quatMul(
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

export function quatX(angle: number): [number, number, number, number] {
	const half = angle * 0.5;
	return [Math.sin(half), 0, 0, Math.cos(half)];
}

export function quatY(angle: number): [number, number, number, number] {
	const half = angle * 0.5;
	return [0, Math.sin(half), 0, Math.cos(half)];
}

export function quatRotateVec3(
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

export function localMatrixFromTrs(
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

export function orthographicProjection(
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
			world.orbitCameraControllerComponent(),
			desc.yaw,
			desc.pitch,
			desc.panX,
			desc.panY,
			desc.dolly,
			desc.distance,
		) &&
		setCameraHomeFromCurrentTransform(
			world,
			camera,
			world.cameraHomeTransformComponent(),
		) &&
		addCameraLensOrthographic(
			world,
			camera,
			world.cameraLensComponent(),
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

export function runTrackedCameraControlTransaction(
	history: WorldHistory,
	world: World,
	label: string,
	callback: () => boolean,
): boolean {
	if (!history.beginTransaction(label)) {
		const diagnostic = history.lastDiagnostic();
		if (diagnostic === "transaction_open" || diagnostic === "recording_disabled") {
			return callback();
		}
		return false;
	}
	try {
		if (!callback()) {
			history.cancelTransactionReverting(world);
			return false;
		}
		if (history.commitTransaction()) {
			return true;
		}
		const diagnostic = history.lastDiagnostic();
		history.cancelTransaction();
		return diagnostic === "recording_disabled";
	} catch (error) {
		history.cancelTransactionReverting(world);
		throw error;
	}
}

function canSetupOrbitOrthographicCameraTracked(
	world: World,
	camera: EntityId,
): boolean {
	return (
		world.isAlive(camera) &&
		!world.hasComponent(camera, world.orbitCameraControllerComponent()) &&
		!world.hasComponent(camera, world.cameraLensComponent()) &&
		(!world.hasComponent(camera, world.globalTransformComponent()) ||
			world.getGlobalTransform(camera) !== null) &&
		(!world.hasComponent(camera, world.cameraComponent()) ||
			world.cameraGpuRowCopy(camera) !== null)
	);
}

export function setupOrbitOrthographicCameraTracked(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	desc: OrbitOrthographicCameraDesc,
): boolean {
	if (!canSetupOrbitOrthographicCameraTracked(world, camera)) {
		return false;
	}
	return runTrackedCameraControlTransaction(
		history,
		world,
		"setupOrbitOrthographicCamera",
		() => setupOrbitOrthographicCameraTrackedBody(history, world, camera, desc),
	);
}

function setupOrbitOrthographicCameraTrackedBody(
	history: WorldHistory,
	world: World,
	camera: EntityId,
	desc: OrbitOrthographicCameraDesc,
): boolean {
	const { px, py, pz, qx, qy, qz, qw } = orbitOrthographicCameraDescTrs(desc);
	const local = localMatrixFromTrs(px, py, pz, qx, qy, qz, qw, 1, 1, 1);
	const view = mat4Inverse(local);
	if (view === null) {
		return false;
	}
	return (
		history.setTransformTrs(
			world,
			camera,
			px,
			py,
			pz,
			qx,
			qy,
			qz,
			qw,
			1,
			1,
			1,
		) &&
		history.setGlobalTransform(world, camera, local) &&
		addOrbitCameraControllerWithPoseTracked(
			history,
			world,
			camera,
			world.orbitCameraControllerComponent(),
			desc.yaw,
			desc.pitch,
			desc.panX,
			desc.panY,
			desc.dolly,
			desc.distance,
		) &&
		setCameraHomeFromCurrentTransformTracked(
			history,
			world,
			camera,
			world.cameraHomeTransformComponent(),
		) &&
		addCameraLensOrthographicTracked(
			history,
			world,
			camera,
			world.cameraLensComponent(),
			desc.near,
			desc.far,
			desc.aspect,
			desc.orthoHalfHeight,
			desc.flags,
		) &&
		history.setCameraMatrices(
			world,
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

export function perspectiveProjection(
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
