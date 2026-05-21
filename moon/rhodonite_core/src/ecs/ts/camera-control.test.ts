// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from "vitest";
import {
	World,
	addCameraLensOrthographic,
	addOrbitCameraControllerWithDistance,
	addOrbitCameraControllerWithPose,
	createOrbitCameraController,
	readOrbitCameraControllerComponent,
	registerCameraHomeTransformComponent,
	registerCameraLensComponent,
	registerOrbitCameraControllerComponent,
	requestOrbitCameraReset,
	setCameraHomeFromCurrentTransform,
	setCameraLensOrthographic,
	syncOrbitCameraBlobComponent,
	syncOrbitCameraTransformComponent,
	updateOrbitCameraControllerComponentFromMouseFrame,
	updateOrbitCameraControllerFromMouseFrame,
} from "./index.ts";

describe("OrbitCameraController TypeScript wrapper", () => {
	it("allows wheel dolly to zoom in to the default lower clamp", () => {
		const controller = createOrbitCameraController(0);

		expect(
			updateOrbitCameraControllerFromMouseFrame(controller, {
				leftDown: false,
				leftPressed: false,
				middleDown: false,
				middlePressed: false,
				pointerDeltaX: 0,
				pointerDeltaY: 0,
				wheelDeltaY: -10000,
			}),
		).toBe(true);
		expect(controller.dolly).toBeCloseTo(0.01);
	});

	it("stores and updates orbit camera state as ECS components", () => {
		const world = World.new();
		const camera = world.createEntity();
		const orbit = registerOrbitCameraControllerComponent(world);
		const home = registerCameraHomeTransformComponent(world);
		const lens = registerCameraLensComponent(world);
		expect(world.setTransformTrs(camera, 0, 0, 16, 0, 0, 0, 1, 1, 1, 1)).toBe(true);
		expect(world.addComponent(camera, world.globalTransformComponent())).toBe(true);
		expect(addOrbitCameraControllerWithDistance(world, camera, orbit, 0, 0.42, 16)).toBe(true);
		expect(setCameraHomeFromCurrentTransform(world, camera, home)).toBe(true);
		expect(addCameraLensOrthographic(world, camera, lens, 0.1, 80, 4 / 3, 1, 0)).toBe(true);

		expect(
			updateOrbitCameraControllerComponentFromMouseFrame(world, camera, orbit, {
				leftDown: false,
				leftPressed: false,
				middleDown: false,
				middlePressed: false,
				pointerDeltaX: 0,
				pointerDeltaY: 0,
				wheelDeltaY: -10000,
			}),
		).toBe(true);
		syncOrbitCameraTransformComponent(world, camera, orbit, home);
		expect(readOrbitCameraControllerComponent(world, camera, orbit).dolly).toBeCloseTo(0.01);
	});

	it("syncs orbit camera pose and lens into the builtin Camera blob", () => {
		const world = World.new();
		const camera = world.createEntity();
		const orbit = registerOrbitCameraControllerComponent(world);
		const lens = registerCameraLensComponent(world);

		expect(
			addOrbitCameraControllerWithPose(world, camera, orbit, 0.25, 0.42, 1, -2, 1.5, 12),
		).toBe(true);
		expect(setCameraLensOrthographic(world, camera, lens, 0.1, 80, 16 / 9, 3.8, 0)).toBe(true);

		syncOrbitCameraBlobComponent(world, camera, orbit, lens);

		const writes = world.drainCameraBlobWriteViews();
		expect(writes).toHaveLength(1);
		expect(writes[0]?.byteOffset()).toBe(0);
		expect(writes[0]?.bytes().length).toBe(72 * 4);
		expect(writes[0]?.bytes().getF32(0)).not.toBeCloseTo(1);
	});

	it("resets orbit camera state from its home transform", () => {
		const world = World.new();
		const camera = world.createEntity();
		const orbit = registerOrbitCameraControllerComponent(world);
		const home = registerCameraHomeTransformComponent(world);
		expect(world.setTransformTrs(camera, 0, 0, 16, 0, 0, 0, 1, 1, 1, 1)).toBe(true);
		expect(world.addComponent(camera, world.globalTransformComponent())).toBe(true);
		expect(addOrbitCameraControllerWithDistance(world, camera, orbit, 0, 0.42, 16)).toBe(true);
		expect(setCameraHomeFromCurrentTransform(world, camera, home)).toBe(true);
		expect(
			updateOrbitCameraControllerComponentFromMouseFrame(world, camera, orbit, {
				leftDown: true,
				leftPressed: false,
				middleDown: false,
				middlePressed: false,
				pointerDeltaX: 100,
				pointerDeltaY: 0,
				wheelDeltaY: 0,
			}),
		).toBe(true);
		expect(requestOrbitCameraReset(world, camera, orbit)).toBe(true);

		syncOrbitCameraTransformComponent(world, camera, orbit, home);

		expect(readOrbitCameraControllerComponent(world, camera, orbit).yaw).toBeCloseTo(0);
	});
});
