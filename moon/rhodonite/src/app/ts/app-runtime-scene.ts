// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import {
	syncOrbitCameraBlobComponent,
	syncOrbitCameraTransformComponent,
	updateOrbitCameraControllerComponentFromMouseFrame,
	type ComponentTypeId,
	type EntityId,
} from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import { MouseButton, type InputState } from "./app-runtime-input.ts";
import {
	Phase,
	defaultCommonRuntimeConfig,
	defaultRenderStatePreparationPhases,
	type CommonOrbitCameraSystems,
	type CommonRuntimeConfig,
	type CommonRuntimeOptions,
	type CommonSceneSystems,
	type PhaseKey,
	type SceneScheduleCallback,
	type SceneScheduleHandler,
} from "./app-runtime-phases.ts";
import { FrameState } from "./app-runtime-state.ts";

type BuiltinTransformPropagationWorld = {
	updateGlobalTransformsFromTransforms: () => void;
};

type BuiltinOrbitCameraWorld = {
	orbitCameraControllerComponent: () => ComponentTypeId;
	cameraHomeTransformComponent: () => ComponentTypeId;
	cameraLensComponent: () => ComponentTypeId;
};

function defaultTransformPropagation(world: unknown): void {
	const candidate = world as Partial<BuiltinTransformPropagationWorld>;
	if (typeof candidate.updateGlobalTransformsFromTransforms === "function") {
		candidate.updateGlobalTransformsFromTransforms();
	}
}

function builtinOrbitCameraWorld(world: unknown): BuiltinOrbitCameraWorld {
	const candidate = world as Partial<BuiltinOrbitCameraWorld>;
	if (
		typeof candidate.orbitCameraControllerComponent !== "function" ||
		typeof candidate.cameraHomeTransformComponent !== "function" ||
		typeof candidate.cameraLensComponent !== "function"
	) {
		throw new Error(
			"Scene common orbit camera runtime requires a World with builtin orbit camera component accessors.",
		);
	}
	return candidate as BuiltinOrbitCameraWorld;
}

function inputFrame(input: InputState) {
	return {
		leftDown: input.mouseDown(MouseButton.Left),
		leftPressed: input.mousePressed(MouseButton.Left),
		middleDown: input.mouseDown(MouseButton.Middle),
		middlePressed: input.mousePressed(MouseButton.Middle),
		pointerDeltaX: input.pointerDeltaX(),
		pointerDeltaY: input.pointerDeltaY(),
		wheelDeltaY: input.wheelDeltaY(),
	};
}

export function defaultOrbitCameraInput(
	world: unknown,
	camera: unknown,
	input: InputState,
): void {
	updateOrbitCameraControllerComponentFromMouseFrame(
		world as Parameters<typeof updateOrbitCameraControllerComponentFromMouseFrame>[0],
		camera as EntityId,
		inputFrame(input),
	);
}

function defaultOrbitCameraTransform(
	world: unknown,
	camera: unknown,
	orbitComponent: ComponentTypeId,
	homeComponent: ComponentTypeId,
): void {
	syncOrbitCameraTransformComponent(
		world as Parameters<typeof syncOrbitCameraTransformComponent>[0],
		camera as EntityId,
		orbitComponent,
		homeComponent,
	);
}

function defaultOrbitCameraBlobSync(
	world: unknown,
	camera: unknown,
	orbitComponent: ComponentTypeId,
	lensComponent: ComponentTypeId,
): void {
	syncOrbitCameraBlobComponent(
		world as Parameters<typeof syncOrbitCameraBlobComponent>[0],
		camera as EntityId,
		orbitComponent,
		lensComponent,
	);
}


export class Scene<TWorld = unknown, TMainCamera = unknown> {
	readonly name: string;
	private worldValue: TWorld | null;
	private mainCameraValue: TMainCamera | null = null;
	private readonly scheduleHandlers: SceneScheduleHandler<TWorld>[] = [];
	private commonOrbitCameraValue:
		| CommonOrbitCameraSystems<TWorld, TMainCamera>
		| undefined;
	private commonRuntimeValue:
		| CommonRuntimeConfig<TWorld, TMainCamera>
		| undefined = defaultCommonRuntimeConfig();
	private commonOrbitCameraTransformScheduled = false;
	private commonOrbitCameraBlobSyncScheduled = false;
	private commonTransformPropagationScheduled = false;
	private enabledValue = true;
	private visibleValue = true;

	constructor(name: string, world: TWorld | null = null) {
		this.name = name;
		this.worldValue = world;
	}

	setWorld(world: TWorld): void {
		this.worldValue = world;
	}

	world(): TWorld {
		if (this.worldValue === null) {
			throw new Error(`Scene '${this.name}' does not have a world.`);
		}
		return this.worldValue;
	}

	setMainCamera(camera: TMainCamera | null): void {
		this.mainCameraValue = camera;
	}

	mainCamera(): TMainCamera | null {
		return this.mainCameraValue;
	}

	setSchedule(
		schedule: SceneScheduleCallback<TWorld>,
		phase: PhaseKey = Phase.Update,
	): void {
		this.scheduleHandlers.push({ phase, callback: schedule });
	}

	addCommonSystems(
		options: CommonRuntimeOptions<TWorld> = {},
		systems: CommonSceneSystems<TWorld, TMainCamera> = {},
	): void {
		this.commonOrbitCameraValue = systems;
		this.installCommonSystems({ ...options, transformPropagation: false });
	}

	useCommonRuntime(
		options: CommonRuntimeOptions<TWorld> = {},
		systems: CommonSceneSystems<TWorld, TMainCamera> = {},
	): void {
		this.commonRuntimeValue = {
			systems,
			options,
			implicit: false,
		};
		this.applyCommonRuntime();
	}

	applyCommonRuntime():
		| CommonOrbitCameraSystems<TWorld, TMainCamera>
		| undefined {
		const runtime = this.commonRuntimeValue;
		if (runtime === undefined) {
			return undefined;
		}
		if (runtime.implicit && this.mainCameraValue === null) {
			return undefined;
		}
		this.commonOrbitCameraValue = runtime.systems;
		return this.installCommonSystems(runtime.options);
	}

	commonRuntimeRequiresMainCamera(): boolean {
		return this.commonRuntimeValue?.implicit !== true;
	}

	installCommonSystems(
		options: CommonRuntimeOptions<TWorld> = {},
	): CommonOrbitCameraSystems<TWorld, TMainCamera> | undefined {
		const {
			transformPropagation = true,
			orbitCameraTransform = true,
			orbitCameraBlobSync = true,
			propagateTransforms,
		} = options;
		if (
			transformPropagation &&
			!this.commonTransformPropagationScheduled
		) {
			const propagate = propagateTransforms ?? defaultTransformPropagation;
			this.setSchedule((world) => {
				propagate(world);
			}, Phase.Update);
			this.commonTransformPropagationScheduled = true;
		}
		const orbit: CommonOrbitCameraSystems<TWorld, TMainCamera> =
			this.commonOrbitCameraValue ?? {};
		if (
			orbitCameraTransform &&
			!this.commonOrbitCameraTransformScheduled
		) {
			this.setSchedule((world) => {
				const camera = this.mainCamera();
				if (camera === null) {
					throw new Error("Scene.installCommonSystems requires Scene.mainCamera.");
				}
				const builtin = builtinOrbitCameraWorld(world);
				const syncTransform =
					orbit.syncOrbitCameraTransform ?? defaultOrbitCameraTransform;
				syncTransform(
					world,
					camera,
					builtin.orbitCameraControllerComponent(),
					builtin.cameraHomeTransformComponent(),
				);
			}, Phase.PostUpdate);
			this.commonOrbitCameraTransformScheduled = true;
		}
		if (
			orbitCameraBlobSync &&
			!this.commonOrbitCameraBlobSyncScheduled
		) {
			this.setSchedule((world) => {
				const camera = this.mainCamera();
				if (camera === null) {
					throw new Error("Scene.installCommonSystems requires Scene.mainCamera.");
				}
				const builtin = builtinOrbitCameraWorld(world);
				const syncBlob =
					orbit.syncOrbitCameraBlob ?? defaultOrbitCameraBlobSync;
				syncBlob(
					world,
					camera,
					builtin.orbitCameraControllerComponent(),
					builtin.cameraLensComponent(),
				);
			}, Phase.RenderExtract);
			this.commonOrbitCameraBlobSyncScheduled = true;
		}
		return orbitCameraTransform || orbitCameraBlobSync ? orbit : undefined;
	}

	setEnabled(enabled: boolean): void {
		this.enabledValue = enabled;
	}

	enabled(): boolean {
		return this.enabledValue;
	}

	setVisible(visible: boolean): void {
		this.visibleValue = visible;
	}

	visible(): boolean {
		return this.visibleValue;
	}

	runSchedulePhase(phase: PhaseKey, frame: FrameState): boolean {
		if (this.worldValue === null) {
			return true;
		}
		for (const handler of this.scheduleHandlers) {
			if (handler.phase === phase) {
				handler.callback(this.worldValue, frame);
			}
		}
		return true;
	}

	runSchedulePhases(phases: PhaseKey[], frame: FrameState): boolean {
		let ok = true;
		for (const phase of phases) {
			if (!this.runSchedulePhase(phase, frame)) {
				ok = false;
			}
		}
		return ok;
	}

	prepareRenderState(frame: FrameState = FrameState.zero()): boolean {
		this.applyCommonRuntime();
		return this.runSchedulePhases(defaultRenderStatePreparationPhases(), frame);
	}
}

export type RuntimeScene = {
	enabled: () => boolean;
	visible: () => boolean;
	runSchedulePhase: (phase: PhaseKey, frame: FrameState) => boolean;
};

const runtimeSceneIds = new WeakMap<RuntimeScene, number>();
let nextRuntimeSceneId = 1;

export function runtimeSceneIdentity(scene: RuntimeScene): number {
	const existing = runtimeSceneIds.get(scene);
	if (existing !== undefined) {
		return existing;
	}
	const id = nextRuntimeSceneId;
	nextRuntimeSceneId += 1;
	runtimeSceneIds.set(scene, id);
	return id;
}

