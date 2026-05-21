// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { type OrbitCameraController } from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import { updateOrbitCameraControllerFromInput } from "../moon/rhodonite/src/app/ts/index.ts";

export { updateOrbitCameraControllerFromInput };
export type { OrbitCameraController };

export const MASS_CUBES_ENTITY_COUNT = 800_000;
export const MASS_CUBES_CANVAS_WIDTH = 800;
export const MASS_CUBES_CANVAS_HEIGHT = 600;
export const MASS_CUBES_VERTEX_STRIDE_LOCAL = 12;
export const MASS_CUBES_INSTANCE_STRIDE = 24;
export const MASS_CUBES_VERTS_PER_CUBE = 8;
export const MASS_CUBES_INDEX_U16_COUNT = 36;
export const MASS_CUBES_CAMERA_ELEVATION_RAD = 0.42;
export const MASS_CUBES_GRID_SPACING = 0.14;
export const MASS_CUBES_CUBE_SCALE = 0.055;
export const MASS_CUBES_MIN_INTERACTIVE_GRID_PITCH_PX = 0.56;

type Mat4 = Float32Array;

export function gridSideLen(count: number): number {
	return Math.ceil(Math.sqrt(count));
}

export function writeF32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(
		offset,
		value,
		true,
	);
}

export function writeU16(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setUint16(
		offset,
		value,
		true,
	);
}

export function writeU32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setUint32(
		offset,
		value,
		true,
	);
}

export function createMassCubesInstanceBytesFromRefs(
	transformRefs: Uint32Array,
): Uint8Array {
	const bytes = new Uint8Array(MASS_CUBES_ENTITY_COUNT * MASS_CUBES_INSTANCE_STRIDE);
	for (let index = 0; index < MASS_CUBES_ENTITY_COUNT; index += 1) {
		const [r, g, b] = instanceColorRgb(index);
		const base = index * MASS_CUBES_INSTANCE_STRIDE;
		const refBase = index * 2;
		writeU32(bytes, base, transformRefs[refBase] ?? 0);
		writeU32(bytes, base + 4, transformRefs[refBase + 1] ?? 0);
		writeF32(bytes, base + 8, r);
		writeF32(bytes, base + 12, g);
		writeF32(bytes, base + 16, b);
	}
	return bytes;
}

export function instanceColorRgb(index: number): [number, number, number] {
	const i = index % 125;
	return [
		(i % 5) * 0.22 + 0.12,
		(Math.floor(i / 5) % 5) * 0.22 + 0.08,
		(Math.floor(i / 25) % 5) * 0.22 + 0.1,
	];
}

function mat4Identity(): Mat4 {
	const out = new Float32Array(16);
	out[0] = 1;
	out[5] = 1;
	out[10] = 1;
	out[15] = 1;
	return out;
}

function mat4Translation(x: number, y: number, z: number): Mat4 {
	const out = mat4Identity();
	out[12] = x;
	out[13] = y;
	out[14] = z;
	return out;
}

function mat4RotationX(rad: number): Mat4 {
	const out = mat4Identity();
	const c = Math.cos(rad);
	const s = Math.sin(rad);
	out[5] = c;
	out[6] = s;
	out[9] = -s;
	out[10] = c;
	return out;
}

function mat4RotationY(rad: number): Mat4 {
	const out = mat4Identity();
	const c = Math.cos(rad);
	const s = Math.sin(rad);
	out[0] = c;
	out[2] = -s;
	out[8] = s;
	out[10] = c;
	return out;
}

function mat4Mul(a: Mat4, b: Mat4): Mat4 {
	const out = new Float32Array(16);
	for (let col = 0; col < 4; col += 1) {
		for (let row = 0; row < 4; row += 1) {
			out[col * 4 + row] =
				a[0 * 4 + row] * b[col * 4 + 0] +
				a[1 * 4 + row] * b[col * 4 + 1] +
				a[2 * 4 + row] * b[col * 4 + 2] +
				a[3 * 4 + row] * b[col * 4 + 3];
		}
	}
	return out;
}

function mat4Ortho(
	left: number,
	right: number,
	bottom: number,
	top: number,
	near: number,
	far: number,
): Mat4 {
	const out = new Float32Array(16);
	out[0] = 2 / (right - left);
	out[5] = 2 / (top - bottom);
	out[10] = 1 / (near - far);
	out[12] = -(right + left) / (right - left);
	out[13] = -(top + bottom) / (top - bottom);
	out[14] = near / (near - far);
	out[15] = 1;
	return out;
}

function transformPoint(
	m: Mat4,
	x: number,
	y: number,
	z: number,
): [number, number, number] {
	return [
		m[0] * x + m[4] * y + m[8] * z + m[12],
		m[1] * x + m[5] * y + m[9] * z + m[13],
		m[2] * x + m[6] * y + m[10] * z + m[14],
	];
}

function viewSpaceRangeCorners(
	viewRot: Mat4,
	extentXz: number,
	waveY: number,
	axis: 1 | 2,
): [number, number] {
	const sides = [-1, 1];
	let min = 0;
	let max = 0;
	let first = true;
	for (const sx of sides) {
		for (const sy of sides) {
			for (const sz of sides) {
				const v = transformPoint(
					viewRot,
					sx * extentXz,
					sy * waveY,
					sz * extentXz,
				)[axis];
				if (first) {
					min = v;
					max = v;
					first = false;
				} else {
					min = Math.min(min, v);
					max = Math.max(max, v);
				}
			}
		}
	}
	return [min, max];
}

export type MassCubesCameraMatrices = {
	readonly view: Float32Array;
	readonly proj: Float32Array;
	readonly near: number;
	readonly far: number;
	readonly aspect: number;
	readonly projectionKind: number;
	readonly flags: number;
};

export function massCubesCameraMatrices(
	orbit: OrbitCameraController,
): MassCubesCameraMatrices {
	const viewBase = mat4Mul(
		mat4Mul(mat4RotationX(orbit.pitch), mat4RotationY(orbit.yaw)),
		mat4Translation(0, 0, -16),
	);
	const perSide = gridSideLen(MASS_CUBES_ENTITY_COUNT);
	const half = (perSide - 1) * 0.5;
	const extentXz = half * MASS_CUBES_GRID_SPACING;
	const wave = 0.12;
	const margin = MASS_CUBES_CUBE_SCALE * 2.5;
	const waveY = wave + MASS_CUBES_CUBE_SCALE * 1.1;
	const [yLo, yHi] = viewSpaceRangeCorners(viewBase, extentXz, waveY, 1);
	const cy = (yLo + yHi) * 0.5;
	let halfH = (yHi - yLo) * 0.5 + margin;
	let halfW = extentXz + margin;
	const aspect = MASS_CUBES_CANVAS_WIDTH / MASS_CUBES_CANVAS_HEIGHT;
	if (halfW / halfH < aspect) {
		halfW = halfH * aspect;
	} else {
		halfH = halfW / aspect;
	}
	const maxHalfWForGridPitch =
		(MASS_CUBES_GRID_SPACING * MASS_CUBES_CANVAS_WIDTH) /
		(2 * MASS_CUBES_MIN_INTERACTIVE_GRID_PITCH_PX);
	if (halfW > maxHalfWForGridPitch) {
		halfW = maxHalfWForGridPitch;
		halfH = halfW / aspect;
	}
	const [zLo, zHi] = viewSpaceRangeCorners(viewBase, extentXz, waveY, 2);
	const pullZ = zHi > -0.15 ? -zHi - 1 : 0;
	const view = mat4Mul(
		mat4Translation(orbit.panX, orbit.panY, pullZ),
		viewBase,
	);
	const farNeed = -(zLo + pullZ) + 8;
	const farClip = Math.max(farNeed, 80);
	const scaledHalfW = halfW * orbit.dolly;
	const scaledHalfH = halfH * orbit.dolly;
	const proj = mat4Ortho(
		-scaledHalfW,
		scaledHalfW,
		cy - scaledHalfH,
		cy + scaledHalfH,
		0.1,
		farClip,
	);
	return {
		view,
		proj,
		near: 0.1,
		far: farClip,
		aspect,
		projectionKind: 1,
		flags: 0,
	};
}

function cubeLocalCorners(): [number, number, number][] {
	return [
		[-1, -1, -1],
		[1, -1, -1],
		[1, 1, -1],
		[-1, 1, -1],
		[-1, -1, 1],
		[1, -1, 1],
		[1, 1, 1],
		[-1, 1, 1],
	];
}

export function massCubesVertexPositionBytes(scale: number): Uint8Array {
	const bytes = new Uint8Array(
		MASS_CUBES_VERTS_PER_CUBE * MASS_CUBES_VERTEX_STRIDE_LOCAL,
	);
	cubeLocalCorners().forEach(([x, y, z], vertexIndex) => {
		const base = vertexIndex * MASS_CUBES_VERTEX_STRIDE_LOCAL;
		writeF32(bytes, base, x * scale);
		writeF32(bytes, base + 4, y * scale);
		writeF32(bytes, base + 8, z * scale);
	});
	return bytes;
}

export function massCubesIndexU16Bytes(): Uint8Array {
	const indices = [
		0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 0, 4, 7, 7, 3, 0, 1, 5, 6, 6, 2,
		1, 0, 1, 5, 5, 4, 0, 3, 2, 6, 6, 7, 3,
	];
	const bytes = new Uint8Array(indices.length * 2);
	indices.forEach((index, i) => writeU16(bytes, i * 2, index));
	return bytes;
}
