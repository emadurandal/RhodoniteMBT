export type EngineCallback = (engine: Engine, frame: FrameState) => void;

export type SceneScheduleCallback<TWorld> = (
	world: TWorld,
	frame: FrameState,
) => void;

export type PhaseKey = string;
export type PhaseGroupKey = string;

export const Phase = {
	Startup: "rhodonite/startup",
	Update: "rhodonite/update",
	PostUpdate: "rhodonite/post_update",
	RenderExtract: "rhodonite/render_extract",
	RenderPrepare: "rhodonite/render_prepare",
	Render: "rhodonite/render",
	Present: "rhodonite/present",
	Shutdown: "rhodonite/shutdown",
} as const;

export const PhaseGroup = {
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

type PhaseGroupRecord = {
	key: PhaseGroupKey;
	phases: PhaseKey[];
};

function defaultPhaseGroups(): PhaseGroupRecord[] {
	return [
		{ key: PhaseGroup.RenderFrame, phases: defaultRenderFramePhases() },
		{ key: PhaseGroup.FixedStep, phases: [] },
	];
}

export const PhaseSlot = {
	BeforeSchedule: "BeforeSchedule",
	AfterSchedule: "AfterSchedule",
} as const;

export type PhaseSlot = (typeof PhaseSlot)[keyof typeof PhaseSlot];

type PhaseHandler = {
	phase: PhaseKey;
	slot: PhaseSlot;
	callback: EngineCallback;
};

type SceneScheduleHandler<TWorld> = {
	phase: PhaseKey;
	callback: SceneScheduleCallback<TWorld>;
};

export class FrameState {
	readonly deltaSeconds: number;
	readonly frameIndex: number;
	readonly elapsedSeconds: number;

	constructor(deltaSeconds: number, frameIndex: number, elapsedSeconds: number) {
		this.deltaSeconds = deltaSeconds;
		this.frameIndex = frameIndex;
		this.elapsedSeconds = elapsedSeconds;
	}
}

export class TimeState {
	private frameIndexValue = 0;
	private elapsedSecondsValue = 0;
	private readonly fixedDeltaSeconds: number;

	constructor(fixedDeltaSeconds = 0.022) {
		this.fixedDeltaSeconds = fixedDeltaSeconds;
	}

	nextFrame(): FrameState {
		this.frameIndexValue += 1;
		this.elapsedSecondsValue += this.fixedDeltaSeconds;
		return new FrameState(
			this.fixedDeltaSeconds,
			this.frameIndexValue,
			this.elapsedSecondsValue,
		);
	}
}

export class Scene<TWorld = unknown, TMainCamera = unknown> {
	readonly name: string;
	private worldValue: TWorld | null;
	private mainCameraValue: TMainCamera | null = null;
	private readonly scheduleHandlers: SceneScheduleHandler<TWorld>[] = [];
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
}

type RuntimeScene = {
	enabled: () => boolean;
	visible: () => boolean;
	runSchedulePhase: (phase: PhaseKey, frame: FrameState) => boolean;
};

export class Engine {
	readonly canvas: HTMLCanvasElement;
	readonly adapter: GPUAdapter;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly context: GPUCanvasContext;
	readonly format: GPUTextureFormat;
	private readonly scenes: RuntimeScene[];
	private readonly timeState: TimeState;
	private readonly phaseGroupsValue: PhaseGroupRecord[];
	private readonly phaseHandlers: PhaseHandler[] = [];
	private phaseRegistrationLocked = false;
	private initializing = false;
	private initialized = false;
	private mainSceneIndex = 0;

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
		this.scenes = [mainScene];
		this.timeState = new TimeState();
		this.phaseGroupsValue = defaultPhaseGroups();
	}

	static async create(
		canvas: HTMLCanvasElement,
		options: { mainScene?: RuntimeScene } = {},
	): Promise<Engine> {
		const adapter = await navigator.gpu.requestAdapter();
		if (adapter === null) {
			throw new Error("WebGPU adapter is not available.");
		}
		const device = await adapter.requestDevice();
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

	onPhase(
		phase: PhaseKey,
		callback: EngineCallback,
		slot: PhaseSlot = PhaseSlot.BeforeSchedule,
	): void {
		if (this.phaseRegistrationLocked) {
			throw new Error(
				"Engine.onPhase cannot register phase handlers after engine initialization.",
			);
		}
		this.phaseHandlers.push({ phase, slot, callback });
	}

	initialize(): void {
		if (this.initializing || this.initialized) {
			throw new Error("Engine is already initialized.");
		}
		this.lockPhaseRegistration();
		this.initializing = true;
		this.runPhaseUnchecked(Phase.Startup, new FrameState(0, 0, 0));
		this.initializing = false;
		this.validatePhaseHandlers();
		this.initialized = true;
	}

	shutdown(): void {
		this.ensureInitialized("Engine.shutdown");
		this.runPhase(Phase.Shutdown, new FrameState(0, 0, 0));
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
		this.runPhaseHandlers(phase, PhaseSlot.BeforeSchedule, frame);
		for (const scene of this.scenes) {
			if (this.sceneParticipatesInPhase(scene, phase)) {
				scene.runSchedulePhase(phase, frame);
			}
		}
		this.runPhaseHandlers(phase, PhaseSlot.AfterSchedule, frame);
	}

	runPhaseGroup(group: PhaseGroupKey, frame: FrameState): void {
		this.ensureInitialized("Engine.runPhaseGroup");
		const phaseGroup = this.findPhaseGroup("Engine.runPhaseGroup", group);
		for (const phase of phaseGroup.phases) {
			this.runPhase(phase, frame);
		}
	}

	runRenderFrame(): void {
		this.ensureInitialized("Engine.runRenderFrame");
		const frame = this.timeState.nextFrame();
		this.runPhaseGroup(PhaseGroup.RenderFrame, frame);
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
