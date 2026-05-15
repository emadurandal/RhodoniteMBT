export type AppCallback = (engine: Engine, frame: FrameState) => void;

export type AppInitCallback = (engine: Engine) => void;

export type SceneScheduleCallback<TWorld> = (
	world: TWorld,
	frame: FrameState,
) => void;

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

export class Scene<TWorld = unknown> {
	readonly name: string;
	readonly world: TWorld | null;
	private scheduleCallback: SceneScheduleCallback<TWorld> | null = null;
	private enabledValue = true;
	private visibleValue = true;

	constructor(name: string, world: TWorld | null = null) {
		this.name = name;
		this.world = world;
	}

	setSchedule(schedule: SceneScheduleCallback<TWorld>): void {
		this.scheduleCallback = schedule;
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

	runSchedule(frame: FrameState): boolean {
		if (this.world === null || this.scheduleCallback === null) {
			return true;
		}
		this.scheduleCallback(this.world, frame);
		return true;
	}
}

export class App {
	private readonly onInit: AppInitCallback;
	private readonly onUpdate: AppCallback;
	private readonly onRender: AppCallback;
	private readonly onShutdown: AppInitCallback;

	constructor(callbacks: {
		init?: AppInitCallback;
		update?: AppCallback;
		render?: AppCallback;
		shutdown?: AppInitCallback;
	}) {
		this.onInit = callbacks.init ?? (() => {});
		this.onUpdate = callbacks.update ?? (() => {});
		this.onRender = callbacks.render ?? (() => {});
		this.onShutdown = callbacks.shutdown ?? (() => {});
	}

	init(engine: Engine): void {
		this.onInit(engine);
	}

	update(engine: Engine, frame: FrameState): void {
		this.onUpdate(engine, frame);
	}

	render(engine: Engine, frame: FrameState): void {
		this.onRender(engine, frame);
	}

	shutdown(engine: Engine): void {
		this.onShutdown(engine);
	}
}

export class Engine {
	readonly canvas: HTMLCanvasElement;
	readonly adapter: GPUAdapter;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly context: GPUCanvasContext;
	readonly format: GPUTextureFormat;
	private readonly scenes: Scene[];
	private readonly timeState: TimeState;
	private mainSceneIndex = 0;

	private constructor(
		canvas: HTMLCanvasElement,
		adapter: GPUAdapter,
		device: GPUDevice,
		context: GPUCanvasContext,
		format: GPUTextureFormat,
		mainScene: Scene,
	) {
		this.canvas = canvas;
		this.adapter = adapter;
		this.device = device;
		this.queue = device.queue;
		this.context = context;
		this.format = format;
		this.scenes = [mainScene];
		this.timeState = new TimeState();
	}

	static async create(
		canvas: HTMLCanvasElement,
		options: { mainScene?: Scene } = {},
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

	mainScene(): Scene {
		return this.scenes[this.mainSceneIndex];
	}

	initializeApp(app: App): void {
		app.init(this);
	}

	shutdownApp(app: App): void {
		app.shutdown(this);
	}

	tick(app: App): void {
		const frame = this.timeState.nextFrame();
		app.update(this, frame);
		for (const scene of this.scenes) {
			if (scene.enabled()) {
				scene.runSchedule(frame);
			}
		}
		app.render(this, frame);
	}
}
