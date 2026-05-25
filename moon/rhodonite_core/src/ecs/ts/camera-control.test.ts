// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, it } from "vitest";
import {
	World,
	WorldHistory,
	addCameraLensOrthographic,
	addCameraLensOrthographicTracked,
	addOrbitCameraControllerWithDistance,
	addOrbitCameraControllerWithPose,
	addOrbitCameraControllerWithPoseTracked,
	createOrbitCameraController,
	createOrbitOrthographicCameraDescFromYzPosition,
	readOrbitCameraControllerComponent,
	registerCameraHomeTransformComponent,
	registerCameraLensComponent,
	registerOrbitCameraControllerComponent,
	requestOrbitCameraReset,
	requestOrbitCameraResetTracked,
	setCameraHomeFromCurrentTransform,
	setCameraHomeFromCurrentTransformTracked,
	setCameraLensOrthographic,
	setCameraLensOrthographicTracked,
	setupOrbitOrthographicCamera,
	setupOrbitOrthographicCameraTracked,
	syncOrbitCameraBlobComponent,
	syncOrbitCameraBlobComponentTracked,
	syncOrbitCameraTransformComponent,
	syncOrbitCameraTransformComponentTracked,
	updateOrbitCameraControllerComponentFromMouseFrame,
	updateOrbitCameraControllerComponentFromMouseFrameTracked,
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
			updateOrbitCameraControllerComponentFromMouseFrame(world, camera, {
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

	it("sets up an orbit orthographic camera from a pitched Y/Z position", () => {
		const world = World.new();
		const camera = world.createEntity();
		const orbit = world.orbitCameraControllerComponent();
		const home = world.cameraHomeTransformComponent();
		const lens = world.cameraLensComponent();

		expect(
			setupOrbitOrthographicCamera(
				world,
				camera,
				createOrbitOrthographicCameraDescFromYzPosition(
					0.38,
					2,
					5.6,
					0.1,
					50,
					1,
					3.8,
				),
			),
		).toBe(true);

		const pose = readOrbitCameraControllerComponent(world, camera, orbit);
		expect(pose.pitch).toBeCloseTo(0.38);
		expect(pose.panY).toBeCloseTo(-2 / Math.cos(0.38));
		expect(world.drainCameraBlobWriteViews()).toHaveLength(1);
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
			updateOrbitCameraControllerComponentFromMouseFrame(world, camera, {
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

	it("tracks orbit orthographic camera setup as one undoable operation", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const camera = world.createEntity();
		const orbit = world.orbitCameraControllerComponent();
		const home = world.cameraHomeTransformComponent();
		const lens = world.cameraLensComponent();

		expect(
			setupOrbitOrthographicCameraTracked(
				history,
				world,
				camera,
				createOrbitOrthographicCameraDescFromYzPosition(
					0.38,
					2,
					5.6,
					0.1,
					50,
					1,
					3.8,
				),
			),
		).toBe(true);

		expect(history.undoLen()).toBe(1);
		expect(world.hasComponent(camera, world.transformComponent())).toBe(true);
		expect(world.hasComponent(camera, world.globalTransformComponent())).toBe(true);
		expect(world.hasComponent(camera, orbit)).toBe(true);
		expect(world.hasComponent(camera, home)).toBe(true);
		expect(world.hasComponent(camera, lens)).toBe(true);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(true);

		expect(history.undo(world)).toBe(true);
		expect(history.redoLen()).toBe(1);
		expect(world.hasComponent(camera, world.transformComponent())).toBe(false);
		expect(world.hasComponent(camera, world.globalTransformComponent())).toBe(false);
		expect(world.hasComponent(camera, orbit)).toBe(false);
		expect(world.hasComponent(camera, home)).toBe(false);
		expect(world.hasComponent(camera, lens)).toBe(false);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(false);

		expect(history.redo(world)).toBe(true);
		expect(history.undoLen()).toBe(1);
		expect(world.hasComponent(camera, orbit)).toBe(true);
		expect(world.hasComponent(camera, world.cameraComponent())).toBe(true);
		expect(world.drainCameraBlobWriteViews().length).toBeGreaterThan(0);
	});

	it("tracks camera-control component edits and sync helpers", () => {
		const world = World.new();
		const history = WorldHistory.new();
		const camera = world.createEntity();
		const orbit = world.orbitCameraControllerComponent();
		const home = world.cameraHomeTransformComponent();
		const lens = world.cameraLensComponent();

		expect(world.setTransformTrs(camera, 0, 0, 16, 0, 0, 0, 1, 1, 1, 1)).toBe(true);
		expect(world.addComponent(camera, world.globalTransformComponent())).toBe(true);
		expect(
			addOrbitCameraControllerWithPoseTracked(
				history,
				world,
				camera,
				orbit,
				0,
				0,
				0,
				0,
				1,
				16,
			),
		).toBe(true);
		expect(setCameraHomeFromCurrentTransformTracked(history, world, camera, home)).toBe(true);
		expect(
			addCameraLensOrthographicTracked(
				history,
				world,
				camera,
				lens,
				0.1,
				50,
				1,
				3.8,
				0,
			),
		).toBe(true);
		history.clear();

		const yawBefore = readOrbitCameraControllerComponent(world, camera, orbit).yaw;
		expect(history.beginTransaction("camera drag")).toBe(true);
		expect(
			updateOrbitCameraControllerComponentFromMouseFrameTracked(
				history,
				world,
				camera,
				{
					leftDown: true,
					leftPressed: false,
					middleDown: false,
					middlePressed: false,
					pointerDeltaX: 10,
					pointerDeltaY: 0,
					wheelDeltaY: 0,
				},
			),
		).toBe(true);
		expect(
			setCameraLensOrthographicTracked(
				history,
				world,
				camera,
				lens,
				0.1,
				50,
				1,
				4.5,
				0,
			),
		).toBe(true);
		syncOrbitCameraTransformComponentTracked(history, world, camera, orbit, home);
		syncOrbitCameraBlobComponentTracked(history, world, camera, orbit, lens);
		expect(history.commitTransaction()).toBe(true);
		expect(history.undoLen()).toBe(1);

		const yawAfter = readOrbitCameraControllerComponent(world, camera, orbit).yaw;
		expect(yawAfter).not.toBeCloseTo(yawBefore);
		expect(history.undo(world)).toBe(true);
		expect(readOrbitCameraControllerComponent(world, camera, orbit).yaw).toBeCloseTo(
			yawBefore,
		);
		expect(history.redo(world)).toBe(true);
		expect(readOrbitCameraControllerComponent(world, camera, orbit).yaw).toBeCloseTo(
			yawAfter,
		);

		history.clear();
		expect(history.beginTransaction("camera reset")).toBe(true);
		expect(requestOrbitCameraResetTracked(history, world, camera, orbit)).toBe(true);
		syncOrbitCameraTransformComponentTracked(history, world, camera, orbit, home);
		expect(history.commitTransaction()).toBe(true);
		expect(readOrbitCameraControllerComponent(world, camera, orbit).yaw).toBeCloseTo(0);
		expect(history.undo(world)).toBe(true);
		expect(readOrbitCameraControllerComponent(world, camera, orbit).yaw).toBeCloseTo(
			yawAfter,
		);
	});
});
