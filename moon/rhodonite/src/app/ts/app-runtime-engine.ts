// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { requestLargeStorageBufferDevice } from "./webgpu-device-limits.ts";
import {
	Renderer,
	RenderTargetResources,
	cubePosition3VertexLayout,
} from "./renderer.ts";
import { InputState } from "./app-runtime-input.ts";
import {
	Phase,
	PhaseGroup,
	PhaseSlot,
	defaultPhaseGroups,
	type CommonOrbitCameraSystems,
	type EngineCallback,
	type EngineFrameCallback,
	type PhaseGroupKey,
	type PhaseGroupRecord,
	type PhaseHandler,
	type PhaseKey,
} from "./app-runtime-phases.ts";
import {
	Scene,
	defaultOrbitCameraInput,
	runtimeSceneIdentity,
	type RuntimeScene,
} from "./app-runtime-scene.ts";
import { FrameState, GpuSurface, SurfaceState, TimeState, type SurfaceId } from "./app-runtime-state.ts";

type EngineSurface = {
	readonly id: SurfaceId;
	readonly gpuSurface: GpuSurface;
	readonly input: InputState;
	readonly renderTargetResources: RenderTargetResources;
	scene: RuntimeScene;
	changed: boolean;
};

export class Engine {
	readonly canvas: HTMLCanvasElement;
	readonly adapter: GPUAdapter;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly context: GPUCanvasContext;
	readonly format: GPUTextureFormat;
	readonly input: InputState;
	readonly renderer: Renderer;
	readonly renderTargetResources: RenderTargetResources;
	private readonly scenes: RuntimeScene[];
	private readonly surfaces: EngineSurface[] = [];
	private readonly timeState: TimeState;
	private readonly phaseGroupsValue: PhaseGroupRecord[];
	private readonly phaseHandlers: PhaseHandler[] = [];
	private phaseRegistrationLocked = false;
	private initializing = false;
	private initialized = false;
	private mainSceneIndex = 0;
	private nextSurfaceId = 1;
	private surfaceStateValue: SurfaceState;
	private surfaceChangedValue = true;
	private renderRequestedValue = true;
	private continuousRenderRequestedValue = false;
	private renderWakeupValue: (() => void) | undefined;

	private constructor(
		canvas: HTMLCanvasElement,
		adapter: GPUAdapter,
		device: GPUDevice,
		context: GPUCanvasContext,
		format: GPUTextureFormat,
		mainScene: RuntimeScene,
	) {
		this.canvas = canvas;
		this.adapter = adapter;
		this.device = device;
		this.queue = device.queue;
		this.context = context;
		this.format = format;
		this.input = new InputState();
		this.renderer = new Renderer(device, this.queue, cubePosition3VertexLayout());
		this.scenes = [mainScene];
		this.timeState = new TimeState();
		this.phaseGroupsValue = defaultPhaseGroups();
		this.surfaceStateValue = SurfaceState.active(
			Math.max(canvas.width, 1),
			Math.max(canvas.height, 1),
			format,
			0,
		);
		this.renderTargetResources = new RenderTargetResources(
			device,
			this.surfaceStateValue.width,
			this.surfaceStateValue.height,
			format,
		);
	}

	static async create(
		canvas: HTMLCanvasElement,
		options: { mainScene?: RuntimeScene } = {},
	): Promise<Engine> {
		const adapter = await navigator.gpu.requestAdapter();
		if (adapter === null) {
			throw new Error("WebGPU adapter is not available.");
		}
		const device = await requestLargeStorageBufferDevice(adapter);
		const context = canvas.getContext("webgpu");
		if (context === null) {
			throw new Error("WebGPU canvas context is not available.");
		}
		const format = navigator.gpu.getPreferredCanvasFormat();
		context.configure({ device, format, alphaMode: "opaque" });
		return new Engine(
			canvas,
			adapter,
			device,
			context,
			format,
			options.mainScene ?? new Scene("main"),
		);
	}

	mainScene<TWorld = unknown, TMainCamera = unknown>(): Scene<
		TWorld,
		TMainCamera
	> {
		return this.scenes[this.mainSceneIndex] as Scene<TWorld, TMainCamera>;
	}

	surfaceState(): SurfaceState {
		return this.surfaceStateValue;
	}

	surfaceActive(): boolean {
		return this.surfaceStateValue.active;
	}

	addSurface(
		gpuSurface: GpuSurface,
		options: { readonly scene?: RuntimeScene } = {},
	): SurfaceId {
		const id = this.nextSurfaceId;
		this.nextSurfaceId += 1;
		this.surfaces.push({
			id,
			gpuSurface,
			input: new InputState(),
			renderTargetResources: new RenderTargetResources(
					this.device,
					gpuSurface.state().width,
					gpuSurface.state().height,
					gpuSurface.state().format as GPUTextureFormat,
				),
			scene: options.scene ?? this.scenes[this.mainSceneIndex],
			changed: true,
		});
		this.requestRender("surface");
		return id;
	}

	removeSurface(surfaceId: SurfaceId): void {
		const index = this.surfaces.findIndex((surface) => surface.id === surfaceId);
		if (index < 0) {
			return;
		}
		this.surfaces[index]!.renderTargetResources.release();
		this.surfaces.splice(index, 1);
		this.requestRender("surface");
	}

	surfaceInput(surfaceId: SurfaceId): InputState {
		return this.requireSurface(surfaceId).input;
	}

	surfaceGpuSurface(surfaceId: SurfaceId): GpuSurface {
		return this.requireSurface(surfaceId).gpuSurface;
	}

	surfaceRenderTargetResources(surfaceId: SurfaceId): RenderTargetResources {
		return this.requireSurface(surfaceId).renderTargetResources;
	}

	surfaceCount(): number {
		return this.surfaces.length;
	}

	surfaceIdAt(index: number): SurfaceId {
		const surface = this.surfaces[index];
		if (surface === undefined) {
			throw new Error(`Engine surface index '${index}' is out of range.`);
		}
		return surface.id;
	}

	setSurfaceScene(surfaceId: SurfaceId, scene: RuntimeScene): void {
		this.requireSurface(surfaceId).scene = scene;
		if (scene instanceof Scene) {
			this.tryInstallDeclaredCommonRuntime(scene);
		}
		this.requestRender("surface-scene");
	}

	private requireSurface(surfaceId: SurfaceId): EngineSurface {
		const surface = this.surfaces.find((candidate) => candidate.id === surfaceId);
		if (surface === undefined) {
			throw new Error(`Unknown engine surface '${surfaceId}'.`);
		}
		return surface;
	}

	private frameTargetsScene(frame: FrameState, scene: RuntimeScene): boolean {
		if (frame.surfaceId === undefined) {
			return true;
		}
		return this.requireSurface(frame.surfaceId).scene === scene;
	}

	setRenderWakeup(wakeup: (() => void) | undefined): void {
		this.renderWakeupValue = wakeup;
	}

	requestRender(_reason: string): void {
		this.renderRequestedValue = true;
		this.renderWakeupValue?.();
	}

	renderRequested(): boolean {
		return this.renderRequestedValue;
	}

	consumeRenderRequested(): boolean {
		const requested = this.renderRequestedValue;
		this.renderRequestedValue = false;
		return requested;
	}

	requestContinuousRender(_reason: string): void {
		this.continuousRenderRequestedValue = true;
		this.renderWakeupValue?.();
	}

	stopContinuousRender(_reason: string): void {
		this.continuousRenderRequestedValue = false;
	}

	continuousRenderRequested(): boolean {
		return this.continuousRenderRequestedValue;
	}

	setSurfaceActive(width: number, height: number, format: string): void {
		if (width <= 0 || height <= 0) {
			this.setSurfaceSuspended();
			return;
		}
		if (
			this.surfaceStateValue.active &&
			this.surfaceStateValue.width === width &&
			this.surfaceStateValue.height === height &&
			this.surfaceStateValue.format === format
		) {
			return;
		}
		this.surfaceStateValue = SurfaceState.active(
			width,
			height,
			format,
			this.surfaceStateValue.generation + 1,
		);
		this.renderTargetResources.resize(width, height, format as GPUTextureFormat);
		this.surfaceChangedValue = true;
		this.requestRender("surface");
	}

	setSurfaceSuspended(): void {
		if (!this.surfaceStateValue.active) {
			return;
		}
		this.surfaceStateValue = SurfaceState.suspended(
			this.surfaceStateValue.generation + 1,
		);
		this.renderTargetResources.resize(0, 0, this.format);
		this.surfaceChangedValue = true;
		this.requestRender("surface");
	}

	addPhaseHandler(
		phase: PhaseKey,
		callback: EngineCallback,
		slot: PhaseSlot = PhaseSlot.BeforeSystems,
		key?: string,
	): void {
		if (this.phaseRegistrationLocked) {
			throw new Error(
				"Engine.addPhaseHandler cannot register phase handlers after engine initialization.",
			);
		}
		this.addPhaseHandlerUnchecked(phase, callback, slot, key);
	}

	onFrameUpdate(callback: EngineFrameCallback, key?: string): void {
		this.addPhaseHandler(
			Phase.Update,
			(_engine, frame) => {
				callback(frame);
			},
			PhaseSlot.BeforeSystems,
			key,
		);
	}

	onFrameRender(callback: EngineFrameCallback, key?: string): void {
		this.addPhaseHandler(
			Phase.Render,
			(_engine, frame) => {
				callback(frame);
			},
			PhaseSlot.AfterSystems,
			key,
		);
	}

	onSceneUpdate(
		scene: RuntimeScene,
		callback: EngineFrameCallback,
		key?: string,
	): void {
		this.addPhaseHandler(
			Phase.Update,
			(engine, frame) => {
				if (engine.frameTargetsScene(frame, scene) && scene.enabled()) {
					callback(frame);
				}
			},
			PhaseSlot.BeforeSystems,
			key,
		);
	}

	onSceneRender(
		scene: RuntimeScene,
		callback: EngineFrameCallback,
		key?: string,
	): void {
		this.addPhaseHandler(
			Phase.Render,
			(engine, frame) => {
				if (engine.frameTargetsScene(frame, scene) && scene.visible()) {
					callback(frame);
				}
			},
			PhaseSlot.AfterSystems,
			key,
		);
	}

	private addPhaseHandlerUnchecked(
		phase: PhaseKey,
		callback: EngineCallback,
		slot: PhaseSlot = PhaseSlot.BeforeSystems,
		key?: string,
	): void {
		if (
			key !== undefined &&
			this.phaseHandlers.some(
				(handler) =>
					handler.phase === phase &&
					handler.slot === slot &&
					handler.key === key,
			)
		) {
			return;
		}
		this.phaseHandlers.push({ phase, slot, key, callback });
	}

	private addCommonRuntimeOrbitCameraInputHandler<TWorld, TMainCamera>(
		scene: Scene<TWorld, TMainCamera>,
		orbit: CommonOrbitCameraSystems<TWorld, TMainCamera>,
		unchecked = false,
		requireMainCamera = true,
	): void {
		const register = unchecked
			? this.addPhaseHandlerUnchecked.bind(this)
			: this.addPhaseHandler.bind(this);
		register(
			Phase.Input,
			(engine, frame) => {
				if (!engine.frameTargetsScene(frame, scene)) {
					return;
				}
				const camera = scene.mainCamera();
				if (camera === null) {
					if (requireMainCamera) {
						throw new Error("Engine common runtime requires Scene.mainCamera.");
					}
					return;
				}
				const input = frame.input ?? engine.input;
				const update =
					orbit.updateOrbitCameraControllerFromInput ?? defaultOrbitCameraInput;
				update(
					scene.world(),
					camera,
					input,
				);
			},
			PhaseSlot.BeforeSystems,
			`rhodonite/orbit-camera-input/${runtimeSceneIdentity(scene)}`,
		);
	}

	private declaredCommonRuntimeScenes(): Scene<unknown, unknown>[] {
		const result: Scene<unknown, unknown>[] = [];
		const seen = new Set<RuntimeScene>();
		const add = (scene: RuntimeScene): void => {
			if (!(scene instanceof Scene) || seen.has(scene)) {
				return;
			}
			seen.add(scene);
			result.push(scene);
		};
		for (const scene of this.scenes) {
			add(scene);
		}
		for (const surface of this.surfaces) {
			add(surface.scene);
		}
		return result;
	}

	private tryInstallDeclaredCommonRuntime(
		scene: Scene<unknown, unknown>,
	): void {
		const orbit = scene.applyCommonRuntime();
		if (orbit !== undefined) {
			this.addCommonRuntimeOrbitCameraInputHandler(
				scene,
				orbit,
				true,
				scene.commonRuntimeRequiresMainCamera(),
			);
		}
	}

	private installDeclaredCommonRuntimes(): void {
		for (const scene of this.declaredCommonRuntimeScenes()) {
			this.tryInstallDeclaredCommonRuntime(scene);
		}
	}

	initialize(): void {
		if (this.initializing || this.initialized) {
			throw new Error("Engine is already initialized.");
		}
		this.lockPhaseRegistration();
		this.initializing = true;
		this.runPhaseUnchecked(Phase.Startup, new FrameState(0, 0, 0));
		this.initializing = false;
		this.installDeclaredCommonRuntimes();
		this.validatePhaseHandlers();
		this.initialized = true;
	}

	shutdown(): void {
		this.ensureInitialized("Engine.shutdown");
		this.runPhase(Phase.Shutdown, new FrameState(0, 0, 0));
		for (const surface of this.surfaces) {
			surface.renderTargetResources.release();
		}
		this.renderTargetResources.release();
		this.renderer.release();
	}

	phaseGroupOrder(group: PhaseGroupKey): PhaseKey[] {
		const phaseGroup = this.findPhaseGroup("Engine.phaseGroupOrder", group);
		return [...phaseGroup.phases];
	}

	addPhaseGroup(group: PhaseGroupKey): void {
		const caller = "Engine.addPhaseGroup";
		this.ensurePhaseGroupEditWindow(caller);
		if (this.phaseGroupsValue.some((phaseGroup) => phaseGroup.key === group)) {
			throw new Error(`Phase group '${group}' already exists.`);
		}
		this.phaseGroupsValue.push({ key: group, phases: [] });
	}

	appendPhaseToGroup(group: PhaseGroupKey, phaseKey: PhaseKey): void {
		const caller = "Engine.appendPhaseToGroup";
		this.ensurePhaseGroupEditWindow(caller);
		this.ensureInsertableGroupPhase(caller, phaseKey);
		if (this.phaseRegisteredInAnyGroup(phaseKey)) {
			throw new Error(`Phase '${phaseKey}' already exists in a phase group.`);
		}
		this.findPhaseGroup(caller, group).phases.push(phaseKey);
	}

	insertPhaseBeforeInGroup(
		group: PhaseGroupKey,
		anchor: PhaseKey,
		phaseKey: PhaseKey,
	): void {
		this.insertPhaseInGroup(group, anchor, phaseKey, 0);
	}

	insertPhaseAfterInGroup(
		group: PhaseGroupKey,
		anchor: PhaseKey,
		phaseKey: PhaseKey,
	): void {
		this.insertPhaseInGroup(group, anchor, phaseKey, 1);
	}

	runPhase(phase: PhaseKey, frame: FrameState): void {
		this.ensureInitialized("Engine.runPhase");
		if (!this.phaseCanRun(phase)) {
			throw new Error(`Phase '${phase}' is not registered in this engine.`);
		}
		this.runPhaseUnchecked(phase, frame);
	}

	private runPhaseUnchecked(phase: PhaseKey, frame: FrameState): void {
		this.runPhaseHandlers(phase, PhaseSlot.BeforeSystems, frame);
		const scenes =
			frame.surfaceId === undefined
				? this.scenes
				: [this.requireSurface(frame.surfaceId).scene];
		for (const scene of scenes) {
			if (this.sceneParticipatesInPhase(scene, phase)) {
				scene.runSchedulePhase(phase, frame);
			}
		}
		this.runPhaseHandlers(phase, PhaseSlot.AfterSystems, frame);
	}

	runPhaseGroup(group: PhaseGroupKey, frame: FrameState): void {
		this.ensureInitialized("Engine.runPhaseGroup");
		const phaseGroup = this.findPhaseGroup("Engine.runPhaseGroup", group);
		for (const phase of phaseGroup.phases) {
			this.runPhase(phase, frame);
		}
	}

	private runReadyFixedSteps(
		elapsedSeconds: number,
		surface: SurfaceState,
		surfaceChanged: boolean,
	): number {
		this.timeState.pushFixedElapsed(elapsedSeconds);
		return this.timeState.drainReadyFixedFrames((fixedFrame) => {
			const frame = fixedFrame.withSurface(surface, surfaceChanged);
			this.runPhaseGroup(PhaseGroup.FixedStep, frame);
		});
	}

	runFrame(elapsedSeconds: number): number {
		this.ensureInitialized("Engine.runFrame");
		this.consumeRenderRequested();
		this.input.beginFrame();
		const surface = this.surfaceStateValue;
		const surfaceChanged = this.surfaceChangedValue;
		const frame = this.timeState
			.nextRenderFrame(elapsedSeconds)
			.withSurface(surface, surfaceChanged);
		this.runPhaseGroup(PhaseGroup.FrameBegin, frame);
		const fixedSteps = this.runReadyFixedSteps(
			elapsedSeconds,
			surface,
			surfaceChanged,
		);
		this.runRenderFrameGroupForSurface(frame);
		this.surfaceChangedValue = false;
		return fixedSteps;
	}

	runMultiSurfaceFrame(elapsedSeconds: number): number {
		this.ensureInitialized("Engine.runMultiSurfaceFrame");
		if (this.surfaces.length === 0) {
			return this.runFrame(elapsedSeconds);
		}
		this.consumeRenderRequested();
		this.input.beginFrame();
		const baseFrame = this.timeState.nextRenderFrame(elapsedSeconds);
		for (const surface of this.surfaces) {
			const canvasChanged = surface.gpuSurface.syncFromCanvas();
			if (canvasChanged) {
				const state = surface.gpuSurface.state();
				surface.renderTargetResources.resize(
					state.width,
					state.height,
					state.format as GPUTextureFormat,
				);
			}
			surface.changed = canvasChanged || surface.changed;
			surface.input.beginFrame();
			const changed = surface.changed;
			const frame = baseFrame.withSurfaceView(
				surface.id,
				surface.gpuSurface.state(),
				changed,
				surface.input,
			);
			this.runPhaseGroup(PhaseGroup.FrameBegin, frame);
		}
		const fixedSteps = this.runReadyFixedSteps(
			elapsedSeconds,
			this.surfaceStateValue,
			this.surfaceChangedValue,
		);
		this.runRenderFrameGroupForMultiSurface(baseFrame);
		for (const surface of this.surfaces) {
			surface.changed = false;
		}
		this.surfaceChangedValue = false;
		return fixedSteps;
	}

	private runRenderFrameGroupForSurface(frame: FrameState): void {
		const phaseGroup = this.findPhaseGroup(
			"Engine.runRenderFrameGroupForSurface",
			PhaseGroup.RenderFrame,
		);
		for (const phase of phaseGroup.phases) {
			if (frame.surface.active || !phaseIsRenderPath(phase)) {
				this.runPhase(phase, frame);
			}
		}
	}

	private runRenderFrameGroupForMultiSurface(baseFrame: FrameState): void {
		const phaseGroup = this.findPhaseGroup(
			"Engine.runRenderFrameGroupForMultiSurface",
			PhaseGroup.RenderFrame,
		);
		const surfaceViews = this.surfaces.map((surface) => ({
			id: surface.id,
			state: surface.gpuSurface.state(),
			changed: surface.changed,
			input: surface.input,
		}));
		for (const phase of phaseGroup.phases) {
			for (const surfaceView of surfaceViews) {
				if (!surfaceView.state.active && phaseIsRenderPath(phase)) {
					continue;
				}
				this.runPhase(
					phase,
					baseFrame.withSurfaceView(
						surfaceView.id,
						surfaceView.state,
						surfaceView.changed,
						surfaceView.input,
					),
				);
			}
		}
	}

	private sceneParticipatesInPhase(scene: RuntimeScene, phase: PhaseKey): boolean {
		if (phaseIsRenderPath(phase)) {
			return scene.visible();
		}
		return scene.enabled();
	}

	private insertPhaseInGroup(
		group: PhaseGroupKey,
		anchor: PhaseKey,
		phaseKey: PhaseKey,
		offset: number,
	): void {
		const caller =
			offset === 0
				? "Engine.insertPhaseBeforeInGroup"
				: "Engine.insertPhaseAfterInGroup";
		this.ensurePhaseGroupEditWindow(caller);
		this.ensureInsertableGroupPhase(caller, phaseKey);
		if (this.phaseRegisteredInAnyGroup(phaseKey)) {
			throw new Error(`Phase '${phaseKey}' already exists in a phase group.`);
		}
		if (phaseIsOneShot(anchor)) {
			throw new Error("One-shot phases cannot be used as phase group anchors.");
		}
		const phaseGroup = this.findPhaseGroup(caller, group);
		const anchorIndex = phaseGroup.phases.indexOf(anchor);
		if (anchorIndex < 0) {
			throw new Error(
				`Anchor phase '${anchor}' is not registered in phase group '${group}'.`,
			);
		}
		phaseGroup.phases.splice(anchorIndex + offset, 0, phaseKey);
	}

	private ensurePhaseGroupEditWindow(caller: string): void {
		if (!this.initializing) {
			throw new Error(
				`${caller} can only edit phase groups during Engine.initialize.`,
			);
		}
	}

	private ensureInsertableGroupPhase(caller: string, phaseKey: PhaseKey): void {
		if (phaseIsOneShot(phaseKey)) {
			throw new Error(
				`${caller} cannot insert one-shot phases into phase groups.`,
			);
		}
	}

	private findPhaseGroup(caller: string, group: PhaseGroupKey): PhaseGroupRecord {
		const phaseGroup = this.phaseGroupsValue.find(
			(candidate) => candidate.key === group,
		);
		if (phaseGroup === undefined) {
			throw new Error(`${caller}: phase group '${group}' is not registered.`);
		}
		return phaseGroup;
	}

	private phaseRegisteredInAnyGroup(phase: PhaseKey): boolean {
		return this.phaseGroupsValue.some((group) => group.phases.includes(phase));
	}

	private phaseCanRun(phase: PhaseKey): boolean {
		return (
			phase === Phase.Startup ||
			phase === Phase.Shutdown ||
			this.phaseRegisteredInAnyGroup(phase)
		);
	}

	private lockPhaseRegistration(): void {
		this.phaseRegistrationLocked = true;
	}

	private validatePhaseHandlers(): void {
		for (const handler of this.phaseHandlers) {
			if (!this.phaseCanRun(handler.phase)) {
				throw new Error(
					`Engine phase handler target '${handler.phase}' is not registered in this engine.`,
				);
			}
		}
	}

	private runPhaseHandlers(
		phase: PhaseKey,
		slot: PhaseSlot,
		frame: FrameState,
	): void {
		for (const handler of this.phaseHandlers) {
			if (handler.phase === phase && handler.slot === slot) {
				handler.callback(this, frame);
			}
		}
	}

	private ensureInitialized(caller: string): void {
		if (!this.initialized) {
			throw new Error(
				`${caller} requires Engine.initialize() to run first.`,
			);
		}
	}
}

function phaseIsOneShot(phaseKey: PhaseKey): boolean {
	return phaseKey === Phase.Startup || phaseKey === Phase.Shutdown;
}

function phaseIsRenderPath(phaseKey: PhaseKey): boolean {
	return (
		phaseKey === Phase.RenderExtract ||
		phaseKey === Phase.RenderPrepare ||
		phaseKey === Phase.Render ||
		phaseKey === Phase.Present
	);
}
