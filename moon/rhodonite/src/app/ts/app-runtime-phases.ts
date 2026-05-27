// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import type { ComponentTypeId } from "../../../../rhodonite_core/src/ecs/ts/index.ts";
import type { Engine } from "./app-runtime-engine.ts";
import type { InputState } from "./app-runtime-input.ts";
import type { FrameState } from "./app-runtime-state.ts";

export type EngineCallback = (engine: Engine, frame: FrameState) => void;

export type EngineFrameCallback = (frame: FrameState) => void;

export type SceneScheduleCallback<TWorld> = (
	world: TWorld,
	frame: FrameState,
) => void;

export type PhaseKey = string;
export type PhaseGroupKey = string;

export const Phase = {
	Startup: "rhodonite/startup",
	Surface: "rhodonite/surface",
	Input: "rhodonite/input",
	FixedUpdate: "rhodonite/fixed_update",
	FixedPostUpdate: "rhodonite/fixed_post_update",
	Update: "rhodonite/update",
	PostUpdate: "rhodonite/post_update",
	RenderExtract: "rhodonite/render_extract",
	RenderPrepare: "rhodonite/render_prepare",
	Render: "rhodonite/render",
	Present: "rhodonite/present",
	Shutdown: "rhodonite/shutdown",
} as const;

export const PhaseGroup = {
	FrameBegin: "rhodonite/frame_begin",
	RenderFrame: "rhodonite/render_frame",
	FixedStep: "rhodonite/fixed_step",
} as const;

export function phase(name: string): PhaseKey {
	return name;
}

export function phaseGroup(name: string): PhaseGroupKey {
	return name;
}

export function defaultRenderFramePhases(): PhaseKey[] {
	return [
		Phase.Update,
		Phase.PostUpdate,
		Phase.RenderExtract,
		Phase.RenderPrepare,
		Phase.Render,
		Phase.Present,
	];
}

export function defaultRenderStatePreparationPhases(): PhaseKey[] {
	return [Phase.Update, Phase.PostUpdate, Phase.RenderExtract];
}

export function defaultFrameBeginPhases(): PhaseKey[] {
	return [Phase.Surface, Phase.Input];
}

export function defaultFixedStepPhases(): PhaseKey[] {
	return [Phase.FixedUpdate, Phase.FixedPostUpdate];
}

export function defaultMaxFixedStepsPerFrame(): number {
	return 5;
}

export type PhaseGroupRecord = {
	key: PhaseGroupKey;
	phases: PhaseKey[];
};

export function defaultPhaseGroups(): PhaseGroupRecord[] {
	return [
		{ key: PhaseGroup.FrameBegin, phases: defaultFrameBeginPhases() },
		{ key: PhaseGroup.FixedStep, phases: defaultFixedStepPhases() },
		{ key: PhaseGroup.RenderFrame, phases: defaultRenderFramePhases() },
	];
}

export const PhaseSlot = {
	BeforeSystems: "BeforeSystems",
	AfterSystems: "AfterSystems",
} as const;

export type PhaseSlot = (typeof PhaseSlot)[keyof typeof PhaseSlot];

export type PhaseHandler = {
	phase: PhaseKey;
	slot: PhaseSlot;
	key: string | undefined;
	callback: EngineCallback;
};

export type SceneScheduleHandler<TWorld> = {
	phase: PhaseKey;
	callback: SceneScheduleCallback<TWorld>;
};

export type CommonOrbitCameraSystems<TWorld, TMainCamera> = {
	readonly updateOrbitCameraControllerFromInput?: (
		world: TWorld,
		camera: TMainCamera,
		input: InputState,
	) => void;
	readonly syncOrbitCameraTransform?: (
		world: TWorld,
		camera: TMainCamera,
		orbitComponent: ComponentTypeId,
		homeComponent: ComponentTypeId,
	) => void;
	readonly syncOrbitCameraBlob?: (
		world: TWorld,
		camera: TMainCamera,
		orbitComponent: ComponentTypeId,
		lensComponent: ComponentTypeId,
	) => void;
};

export type CommonSceneSystems<TWorld, TMainCamera> =
	CommonOrbitCameraSystems<TWorld, TMainCamera> & {
	readonly propagateTransforms?: (world: TWorld) => void;
};

export type CommonRuntimeOptions<TWorld = unknown> = {
	readonly transformPropagation?: boolean;
	readonly orbitCameraTransform?: boolean;
	readonly orbitCameraBlobSync?: boolean;
	readonly propagateTransforms?: (world: TWorld) => void;
};

export type CommonRuntimeConfig<TWorld, TMainCamera> = {
	readonly systems: CommonSceneSystems<TWorld, TMainCamera>;
	readonly options: CommonRuntimeOptions<TWorld>;
	readonly implicit: boolean;
};

export function defaultCommonRuntimeConfig<TWorld, TMainCamera>(): CommonRuntimeConfig<
	TWorld,
	TMainCamera
> {
	return {
		systems: {},
		options: {},
		implicit: true,
	};
}
