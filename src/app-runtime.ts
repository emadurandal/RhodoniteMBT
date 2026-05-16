export type AppCallback = (engine: Engine, frame: FrameState) => void;

export type SceneScheduleCallback<TWorld> = (
	world: TWorld,
	frame: FrameState,
) => void;

export type PhaseKey = string;

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

export function phase(name: string): PhaseKey {
	return name;
}

export function defaultFramePhases(): PhaseKey[] {
	return [
		Phase.Update,
		Phase.PostUpdate,
		Phase.RenderExtract,
		Phase.RenderPrepare,
		Phase.Render,
		Phase.Present,
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
	callback: AppCallback;
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

export class App {
	private readonly phaseHandlers: PhaseHandler[] = [];
	private phaseRegistrationLocked = false;

	onPhase(
		phase: PhaseKey,
		callback: AppCallback,
		slot: PhaseSlot = PhaseSlot.BeforeSchedule,
	): void {
		if (this.phaseRegistrationLocked) {
			throw new Error(
				"App.onPhase cannot register phase handlers after app initialization.",
			);
		}
		this.phaseHandlers.push({ phase, slot, callback });
	}

	lockPhaseRegistration(): void {
		this.phaseRegistrationLocked = true;
	}

	validateForEngine(phaseCanRun: (phase: PhaseKey) => boolean): void {
		for (const handler of this.phaseHandlers) {
			if (!phaseCanRun(handler.phase)) {
				throw new Error(
					`App phase '${handler.phase}' is not registered in this engine.`,
				);
			}
		}
	}

	runPhaseHandlers(
		phase: PhaseKey,
		slot: PhaseSlot,
		engine: Engine,
		frame: FrameState,
	): void {
		for (const handler of this.phaseHandlers) {
			if (handler.phase === phase && handler.slot === slot) {
				handler.callback(engine, frame);
			}
		}
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
	private readonly phaseOrderValue: PhaseKey[];
	private initializingApp = false;
	private appInitialized = false;
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
		this.phaseOrderValue = defaultFramePhases();
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

	initializeApp(app: App): void {
		if (this.initializingApp || this.appInitialized) {
			throw new Error("Engine app is already initialized.");
		}
		app.lockPhaseRegistration();
		this.initializingApp = true;
		this.runPhaseUnchecked(app, Phase.Startup, new FrameState(0, 0, 0));
		this.initializingApp = false;
		app.validateForEngine((phaseKey) => this.phaseCanRun(phaseKey));
		this.appInitialized = true;
	}

	shutdownApp(app: App): void {
		this.ensureAppInitialized("Engine.shutdownApp");
		this.runPhase(app, Phase.Shutdown, new FrameState(0, 0, 0));
	}

	phaseOrder(): PhaseKey[] {
		return [...this.phaseOrderValue];
	}

	insertPhaseBefore(anchor: PhaseKey, phaseKey: PhaseKey): void {
		this.insertPhase(anchor, phaseKey, 0);
	}

	insertPhaseAfter(anchor: PhaseKey, phaseKey: PhaseKey): void {
		this.insertPhase(anchor, phaseKey, 1);
	}

	runPhase(app: App, phase: PhaseKey, frame: FrameState): void {
		this.ensureAppInitialized("Engine.runPhase");
		if (!this.phaseCanRun(phase)) {
			throw new Error(`Phase '${phase}' is not registered in this engine.`);
		}
		this.runPhaseUnchecked(app, phase, frame);
	}

	private runPhaseUnchecked(app: App, phase: PhaseKey, frame: FrameState): void {
		app.runPhaseHandlers(phase, PhaseSlot.BeforeSchedule, this, frame);
		for (const scene of this.scenes) {
			if (this.sceneParticipatesInPhase(scene, phase)) {
				scene.runSchedulePhase(phase, frame);
			}
		}
		app.runPhaseHandlers(phase, PhaseSlot.AfterSchedule, this, frame);
	}

	tick(app: App): void {
		this.ensureAppInitialized("Engine.tick");
		const frame = this.timeState.nextFrame();
		for (const phase of this.phaseOrderValue) {
			this.runPhase(app, phase, frame);
		}
	}

	private sceneParticipatesInPhase(scene: RuntimeScene, phase: PhaseKey): boolean {
		if (phaseIsRenderPath(phase)) {
			return scene.visible();
		}
		return scene.enabled();
	}

	private insertPhase(anchor: PhaseKey, phaseKey: PhaseKey, offset: number): void {
		if (!this.initializingApp) {
			throw new Error("Engine phases can only be inserted during initializeApp.");
		}
		if (phaseIsLifecycleOnly(phaseKey)) {
			throw new Error(
				"Startup/shutdown phases cannot be inserted into frame phase order.",
			);
		}
		if (this.phaseOrderValue.includes(phaseKey)) {
			throw new Error(`Frame phase '${phaseKey}' already exists.`);
		}
		if (phaseIsLifecycleOnly(anchor)) {
			throw new Error(
				"Startup/shutdown phases cannot be used as frame phase anchors.",
			);
		}
		const anchorIndex = this.phaseOrderValue.indexOf(anchor);
		if (anchorIndex < 0) {
			throw new Error(
				`Anchor phase '${anchor}' is not registered in frame phase order.`,
			);
		}
		this.phaseOrderValue.splice(anchorIndex + offset, 0, phaseKey);
	}

	private phaseCanRun(phase: PhaseKey): boolean {
		return (
			phase === Phase.Startup ||
			phase === Phase.Shutdown ||
			this.phaseOrderValue.includes(phase)
		);
	}

	private ensureAppInitialized(caller: string): void {
		if (!this.appInitialized) {
			throw new Error(
				`${caller} requires Engine.initializeApp(app) to run first.`,
			);
		}
	}
}

function phaseIsLifecycleOnly(phaseKey: PhaseKey): boolean {
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
