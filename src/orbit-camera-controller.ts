import { MouseButton, type InputState } from "./app-runtime";
import type {
	ComponentTypeId,
	EntityId,
	World,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";

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

const CAMERA_PROJECTION_ORTHOGRAPHIC = 1;

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
	const bytes = new Uint8Array(CAMERA_LENS_STRIDE);
	writeF32(bytes, LENS_PROJECTION_KIND_OFFSET, CAMERA_PROJECTION_ORTHOGRAPHIC);
	writeF32(bytes, LENS_NEAR_OFFSET, near);
	writeF32(bytes, LENS_FAR_OFFSET, far);
	writeF32(bytes, LENS_ASPECT_OFFSET, aspect);
	writeF32(bytes, LENS_FOV_Y_RAD_OFFSET, 1);
	writeF32(bytes, LENS_ORTHO_HALF_HEIGHT_OFFSET, orthoHalfHeight);
	writeF32(bytes, LENS_FLAGS_OFFSET, flags);
	return world.addComponentBytes(camera, lensComponent, bytes);
}

export function readOrbitCameraControllerComponent(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
): OrbitCameraController {
	const bytes = componentBytesOrThrow(
		world,
		camera,
		component,
		"readOrbitCameraControllerComponent",
	);
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

function readOrbitCameraPoseComponent(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
): OrbitCameraPose {
	const bytes = componentBytesOrThrow(
		world,
		camera,
		component,
		"readOrbitCameraPoseComponent",
	);
	return {
		...readOrbitCameraControllerComponent(world, camera, component),
		distance: readF32(bytes, ORBIT_DISTANCE_OFFSET),
		resetRequested: readF32(bytes, ORBIT_RESET_REQUESTED_OFFSET) !== 0,
	};
}

export function updateOrbitCameraControllerComponentFromInput(
	world: World,
	camera: EntityId,
	component: ComponentTypeId,
	input: InputState,
): boolean {
	const bytes = componentBytesOrThrow(
		world,
		camera,
		component,
		"updateOrbitCameraControllerComponentFromInput",
	);
	const controller = readOrbitCameraControllerComponent(world, camera, component);
	if (!updateOrbitCameraControllerFromInput(controller, input)) {
		return false;
	}
	writeF32(bytes, ORBIT_YAW_OFFSET, controller.yaw);
	writeF32(bytes, ORBIT_PITCH_OFFSET, controller.pitch);
	writeF32(bytes, ORBIT_PAN_X_OFFSET, controller.panX);
	writeF32(bytes, ORBIT_PAN_Y_OFFSET, controller.panY);
	writeF32(bytes, ORBIT_DOLLY_OFFSET, controller.dolly);
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
