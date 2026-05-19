import { requestLargeStorageBufferDevice } from "./webgpu-device-limits";

export type EngineCallback = (engine: Engine, frame: FrameState) => void;

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

export function defaultFrameBeginPhases(): PhaseKey[] {
	return [Phase.Surface, Phase.Input];
}

export function defaultFixedStepPhases(): PhaseKey[] {
	return [Phase.FixedUpdate, Phase.FixedPostUpdate];
}

export function defaultMaxFixedStepsPerFrame(): number {
	return 5;
}

type PhaseGroupRecord = {
	key: PhaseGroupKey;
	phases: PhaseKey[];
};

function defaultPhaseGroups(): PhaseGroupRecord[] {
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
	readonly surfaceId: SurfaceId | undefined;
	readonly surface: SurfaceState;
	readonly surfaceChanged: boolean;
	readonly input: InputState | undefined;

	constructor(
		deltaSeconds: number,
		frameIndex: number,
		elapsedSeconds: number,
		surface: SurfaceState = SurfaceState.active(800, 600, "", 0),
		surfaceChanged = false,
		surfaceId: SurfaceId | undefined = undefined,
		input: InputState | undefined = undefined,
	) {
		this.deltaSeconds = deltaSeconds;
		this.frameIndex = frameIndex;
		this.elapsedSeconds = elapsedSeconds;
		this.surfaceId = surfaceId;
		this.surface = surface;
		this.surfaceChanged = surfaceChanged;
		this.input = input;
	}

	withSurface(surface: SurfaceState, surfaceChanged: boolean): FrameState {
		return new FrameState(
			this.deltaSeconds,
			this.frameIndex,
			this.elapsedSeconds,
			surface,
			surfaceChanged,
			this.surfaceId,
			this.input,
		);
	}

	withSurfaceView(
		surfaceId: SurfaceId,
		surface: SurfaceState,
		surfaceChanged: boolean,
		input: InputState,
	): FrameState {
		return new FrameState(
			this.deltaSeconds,
			this.frameIndex,
			this.elapsedSeconds,
			surface,
			surfaceChanged,
			surfaceId,
			input,
		);
	}
}

export type SurfaceId = number;

export class SurfaceState {
	readonly width: number;
	readonly height: number;
	readonly format: string;
	readonly active: boolean;
	readonly generation: number;

	private constructor(
		width: number,
		height: number,
		format: string,
		active: boolean,
		generation: number,
	) {
		this.width = width;
		this.height = height;
		this.format = format;
		this.active = active;
		this.generation = generation;
	}

	static active(
		width: number,
		height: number,
		format: string,
		generation: number,
	): SurfaceState {
		return new SurfaceState(width, height, format, true, generation);
	}

	static suspended(generation: number): SurfaceState {
		return new SurfaceState(0, 0, "", false, generation);
	}
}

export class GpuSurface {
	readonly canvas: HTMLCanvasElement;
	readonly context: GPUCanvasContext;
	readonly format: GPUTextureFormat;
	private stateValue: SurfaceState;

	constructor(
		canvas: HTMLCanvasElement,
		device: GPUDevice,
		format: GPUTextureFormat = navigator.gpu.getPreferredCanvasFormat(),
	) {
		const context = canvas.getContext("webgpu");
		if (context === null) {
			throw new Error("WebGPU canvas context is not available.");
		}
		context.configure({ device, format, alphaMode: "opaque" });
		this.canvas = canvas;
		this.context = context;
		this.format = format;
		this.stateValue =
			canvas.width > 0 && canvas.height > 0
				? SurfaceState.active(canvas.width, canvas.height, format, 0)
				: SurfaceState.suspended(0);
	}

	state(): SurfaceState {
		return this.stateValue;
	}

	syncFromCanvas(): boolean {
		const { width, height } = this.canvas;
		const current = this.stateValue;
		const next =
			width > 0 && height > 0
				? SurfaceState.active(width, height, this.format, current.generation + 1)
				: SurfaceState.suspended(current.generation + 1);
		if (
			current.active === next.active &&
			current.width === next.width &&
			current.height === next.height &&
			current.format === next.format
		) {
			return false;
		}
		this.stateValue = next;
		return true;
	}

	acquireView(): GPUTextureView {
		return this.context.getCurrentTexture().createView();
	}
}

export class TimeState {
	private renderFrameIndexValue = 0;
	private renderElapsedSecondsValue = 0;
	private fixedFrameIndexValue = 0;
	private fixedElapsedSecondsValue = 0;
	private fixedAccumulatorSecondsValue = 0;
	private readonly fixedDeltaSeconds: number;
	private readonly maxFixedStepsPerFrameValue: number;

	constructor(
		fixedDeltaSeconds = 1 / 60,
		maxFixedStepsPerFrame = defaultMaxFixedStepsPerFrame(),
	) {
		if (fixedDeltaSeconds <= 0) {
			throw new Error("TimeState: fixed delta must be positive.");
		}
		if (maxFixedStepsPerFrame <= 0) {
			throw new Error("TimeState: max fixed steps must be positive.");
		}
		this.fixedDeltaSeconds = fixedDeltaSeconds;
		this.maxFixedStepsPerFrameValue = maxFixedStepsPerFrame;
	}

	nextRenderFrame(deltaSeconds: number): FrameState {
		this.renderFrameIndexValue += 1;
		this.renderElapsedSecondsValue += deltaSeconds;
		return new FrameState(
			deltaSeconds,
			this.renderFrameIndexValue,
			this.renderElapsedSecondsValue,
		);
	}

	pushFixedElapsed(elapsedSeconds: number): void {
		this.fixedAccumulatorSecondsValue += elapsedSeconds;
	}

	canStepFixed(): boolean {
		return this.fixedAccumulatorSecondsValue >= this.fixedDeltaSeconds;
	}

	maxFixedStepsPerFrame(): number {
		return this.maxFixedStepsPerFrameValue;
	}

	nextFixedFrame(): FrameState {
		this.fixedAccumulatorSecondsValue -= this.fixedDeltaSeconds;
		this.fixedFrameIndexValue += 1;
		this.fixedElapsedSecondsValue += this.fixedDeltaSeconds;
		return new FrameState(
			this.fixedDeltaSeconds,
			this.fixedFrameIndexValue,
			this.fixedElapsedSecondsValue,
		);
	}

	private discardFixedAccumulator(): void {
		this.fixedAccumulatorSecondsValue = 0;
	}

	drainReadyFixedFrames(run: (frame: FrameState) => void): number {
		let count = 0;
		const maxSteps = this.maxFixedStepsPerFrame();
		while (count < maxSteps && this.canStepFixed()) {
			run(this.nextFixedFrame());
			count += 1;
		}
		if (this.canStepFixed()) {
			this.discardFixedAccumulator();
		}
		return count;
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

export type RuntimeScene = {
	enabled: () => boolean;
	visible: () => boolean;
	runSchedulePhase: (phase: PhaseKey, frame: FrameState) => boolean;
};

export type KeyCode = string;

export const MouseButton = {
	Left: "Left",
	Middle: "Middle",
	Right: "Right",
	Back: "Back",
	Forward: "Forward",
	Other: "Other",
} as const;

export type MouseButton =
	| (typeof MouseButton)[keyof typeof MouseButton]
	| `Other:${number}`;

export type Modifiers = {
	readonly shift: boolean;
	readonly ctrl: boolean;
	readonly alt: boolean;
	readonly meta: boolean;
};

export type InputEvent =
	| {
			readonly type: "KeyDown";
			readonly key: KeyCode;
			readonly modifiers: Modifiers;
			readonly repeat: boolean;
	  }
	| {
			readonly type: "KeyUp";
			readonly key: KeyCode;
			readonly modifiers: Modifiers;
	  }
	| { readonly type: "TextInput"; readonly text: string }
	| { readonly type: "PointerMove"; readonly x: number; readonly y: number }
	| {
			readonly type: "MouseDown";
			readonly button: MouseButton;
			readonly x: number;
			readonly y: number;
	  }
	| {
			readonly type: "MouseUp";
			readonly button: MouseButton;
			readonly x: number;
			readonly y: number;
	  }
	| { readonly type: "Wheel"; readonly deltaX: number; readonly deltaY: number }
	| { readonly type: "FocusLost" };

export class InputState {
	private readonly keysDownValue = new Set<KeyCode>();
	private readonly keysPressedValue = new Set<KeyCode>();
	private readonly keysReleasedValue = new Set<KeyCode>();
	private readonly mouseButtonsDownValue = new Set<MouseButton>();
	private readonly mouseButtonsPressedValue = new Set<MouseButton>();
	private readonly mouseButtonsReleasedValue = new Set<MouseButton>();
	private pointerXValue = 0;
	private pointerYValue = 0;
	private pointerDeltaXValue = 0;
	private pointerDeltaYValue = 0;
	private wheelDeltaXValue = 0;
	private wheelDeltaYValue = 0;
	private readonly eventsValue: InputEvent[] = [];
	private readonly queuedEvents: InputEvent[] = [];

	beginFrame(): void {
		this.keysPressedValue.clear();
		this.keysReleasedValue.clear();
		this.mouseButtonsPressedValue.clear();
		this.mouseButtonsReleasedValue.clear();
		this.pointerDeltaXValue = 0;
		this.pointerDeltaYValue = 0;
		this.wheelDeltaXValue = 0;
		this.wheelDeltaYValue = 0;
		this.eventsValue.length = 0;
		for (const event of this.queuedEvents) {
			this.applyEventToFrame(event);
		}
		this.queuedEvents.length = 0;
	}

	enqueueEvent(event: InputEvent): void {
		this.queuedEvents.push(event);
	}

	applyEvent(event: InputEvent): void {
		this.applyEventToFrame(event);
	}

	keyDown(key: KeyCode): boolean {
		return this.keysDownValue.has(key);
	}

	keyPressed(key: KeyCode): boolean {
		return this.keysPressedValue.has(key);
	}

	keyReleased(key: KeyCode): boolean {
		return this.keysReleasedValue.has(key);
	}

	mouseDown(button: MouseButton): boolean {
		return this.mouseButtonsDownValue.has(button);
	}

	mousePressed(button: MouseButton): boolean {
		return this.mouseButtonsPressedValue.has(button);
	}

	mouseReleased(button: MouseButton): boolean {
		return this.mouseButtonsReleasedValue.has(button);
	}

	pointerX(): number {
		return this.pointerXValue;
	}

	pointerY(): number {
		return this.pointerYValue;
	}

	pointerDeltaX(): number {
		return this.pointerDeltaXValue;
	}

	pointerDeltaY(): number {
		return this.pointerDeltaYValue;
	}

	wheelDeltaX(): number {
		return this.wheelDeltaXValue;
	}

	wheelDeltaY(): number {
		return this.wheelDeltaYValue;
	}

	events(): InputEvent[] {
		return [...this.eventsValue];
	}

	private applyEventToFrame(event: InputEvent): void {
		switch (event.type) {
			case "KeyDown":
				if (!event.repeat && !this.keysDownValue.has(event.key)) {
					this.keysPressedValue.add(event.key);
				}
				this.keysDownValue.add(event.key);
				break;
			case "KeyUp":
				if (this.keysDownValue.has(event.key)) {
					this.keysReleasedValue.add(event.key);
				}
				this.keysDownValue.delete(event.key);
				break;
			case "TextInput":
				break;
			case "PointerMove":
				this.applyPointerMove(event.x, event.y);
				break;
			case "MouseDown":
				this.applyPointerMove(event.x, event.y);
				if (!this.mouseButtonsDownValue.has(event.button)) {
					this.mouseButtonsPressedValue.add(event.button);
				}
				this.mouseButtonsDownValue.add(event.button);
				break;
			case "MouseUp":
				this.applyPointerMove(event.x, event.y);
				if (this.mouseButtonsDownValue.has(event.button)) {
					this.mouseButtonsReleasedValue.add(event.button);
				}
				this.mouseButtonsDownValue.delete(event.button);
				break;
			case "Wheel":
				this.wheelDeltaXValue += event.deltaX;
				this.wheelDeltaYValue += event.deltaY;
				break;
			case "FocusLost":
				this.keysDownValue.clear();
				this.mouseButtonsDownValue.clear();
				break;
		}
		this.eventsValue.push(event);
	}

	private applyPointerMove(x: number, y: number): void {
		this.pointerDeltaXValue += x - this.pointerXValue;
		this.pointerDeltaYValue += y - this.pointerYValue;
		this.pointerXValue = x;
		this.pointerYValue = y;
	}
}

export type BrowserInputBinding = {
	dispose: () => void;
};

export type BrowserFrameLoop = {
	request: () => void;
	stop: () => void;
};

export type Platform = {
	readonly engine: Engine;
	readonly inputBinding?: BrowserInputBinding;
	readonly frameLoop?: BrowserFrameLoop;
	dispose: () => void;
};

export class PlatformConfig {
	readonly canvas: HTMLCanvasElement;
	readonly mainScene: RuntimeScene | undefined;

	constructor(
		canvas: HTMLCanvasElement,
		options: { readonly mainScene?: RuntimeScene } = {},
	) {
		this.canvas = canvas;
		this.mainScene = options.mainScene;
	}
}

export class PlatformApp {
	readonly createEngine: (config: PlatformConfig) => Promise<Engine>;
	readonly setupEngine: (engine: Engine) => boolean | void;

	constructor(options: {
		readonly createEngine: (config: PlatformConfig) => Promise<Engine>;
		readonly setupEngine: (engine: Engine) => boolean | void;
	}) {
		this.createEngine = options.createEngine;
		this.setupEngine = options.setupEngine;
	}

	static defaultEngine(
		setupEngine: (engine: Engine) => boolean | void,
	): PlatformApp {
		return new PlatformApp({
			createEngine: (config) =>
				Engine.create(config.canvas, { mainScene: config.mainScene }),
			setupEngine,
		});
	}
}

export class PlatformOptions {
	readonly keyboardTarget: Window | HTMLElement | undefined;
	readonly frameMode: "loop" | "single-frame" | "on-demand";
	readonly installInput: boolean;

	constructor(options: {
		readonly keyboardTarget?: Window | HTMLElement;
		readonly frameMode?: "loop" | "single-frame" | "on-demand";
		readonly installInput?: boolean;
	} = {}) {
		this.keyboardTarget = options.keyboardTarget;
		this.frameMode = options.frameMode ?? "loop";
		this.installInput = options.installInput ?? true;
	}

	static interactive(): PlatformOptions {
		return new PlatformOptions();
	}

	static renderLoop(): PlatformOptions {
		return new PlatformOptions({ frameMode: "loop", installInput: false });
	}

	static interactiveOnDemand(): PlatformOptions {
		return new PlatformOptions({ frameMode: "on-demand", installInput: true });
	}

	static renderOnDemand(): PlatformOptions {
		return new PlatformOptions({ frameMode: "on-demand", installInput: false });
	}

	static singleFrame(): PlatformOptions {
		return new PlatformOptions({
			frameMode: "single-frame",
			installInput: false,
		});
	}
}

const browserPlatforms = new WeakMap<HTMLCanvasElement, Platform>();

function replacePlatformForCanvas(
	canvas: HTMLCanvasElement,
	platform: Platform,
): void {
	const existing = browserPlatforms.get(canvas);
	if (existing !== undefined && existing !== platform) {
		existing.dispose();
	}
	browserPlatforms.set(canvas, platform);
}

export function stopPlatform(canvas: HTMLCanvasElement): void {
	const existing = browserPlatforms.get(canvas);
	if (existing === undefined) {
		return;
	}
	existing.dispose();
	browserPlatforms.delete(canvas);
}

function keyboardModifiers(event: KeyboardEvent): Modifiers {
	return {
		shift: event.shiftKey,
		ctrl: event.ctrlKey,
		alt: event.altKey,
		meta: event.metaKey,
	};
}

function pointerPosition(
	canvas: HTMLCanvasElement,
	event: PointerEvent | WheelEvent,
): { x: number; y: number } {
	const rect = canvas.getBoundingClientRect();
	const scaleX = canvas.width / rect.width;
	const scaleY = canvas.height / rect.height;
	return {
		x: (event.clientX - rect.left) * scaleX,
		y: (event.clientY - rect.top) * scaleY,
	};
}

function pointerButton(button: number): MouseButton {
	switch (button) {
		case 0:
			return MouseButton.Left;
		case 1:
			return MouseButton.Middle;
		case 2:
			return MouseButton.Right;
		case 3:
			return MouseButton.Back;
		case 4:
			return MouseButton.Forward;
		default:
			return `Other:${button}`;
	}
}

export type BrowserInputCallbacks = {
	readonly keyDown?: (
		key: KeyCode,
		modifiers: Modifiers,
		repeat: boolean,
	) => void;
	readonly keyUp?: (key: KeyCode, modifiers: Modifiers) => void;
	readonly pointerMove?: (x: number, y: number) => void;
	readonly mouseDown?: (button: number, x: number, y: number) => void;
	readonly mouseUp?: (button: number, x: number, y: number) => void;
	readonly wheel?: (deltaX: number, deltaY: number) => void;
	readonly focusLost?: () => void;
};

export function startBrowserFrameLoop(
	onFrame: (deltaSeconds: number) => void,
): BrowserFrameLoop {
	let stopped = false;
	let previousTimestamp: number | null = null;
	let requestId = 0;
	const loop = (timestamp: number): void => {
		if (stopped) {
			return;
		}
		const deltaSeconds =
			previousTimestamp === null ? 0 : (timestamp - previousTimestamp) / 1000;
		previousTimestamp = timestamp;
		onFrame(deltaSeconds);
		if (!stopped) {
			requestId = requestAnimationFrame(loop);
		}
	};
	requestId = requestAnimationFrame(loop);
	return {
		request: (): void => {},
		stop: (): void => {
			stopped = true;
			if (requestId !== 0) {
				cancelAnimationFrame(requestId);
				requestId = 0;
			}
		},
	};
}

export function startBrowserOnDemandFrameLoop(
	onFrame: (deltaSeconds: number) => void,
	shouldContinue: () => boolean,
): BrowserFrameLoop {
	let stopped = false;
	let scheduled = false;
	let previousTimestamp: number | null = null;
	let requestId = 0;
	const request = (): void => {
		if (stopped || scheduled) {
			return;
		}
		scheduled = true;
		requestId = requestAnimationFrame(loop);
	};
	const loop = (timestamp: number): void => {
		if (stopped) {
			return;
		}
		scheduled = false;
		const deltaSeconds =
			previousTimestamp === null ? 0 : (timestamp - previousTimestamp) / 1000;
		previousTimestamp = timestamp;
		onFrame(deltaSeconds);
		if (!stopped && shouldContinue()) {
			request();
		} else {
			previousTimestamp = null;
		}
	};
	return {
		request,
		stop: (): void => {
			stopped = true;
			if (scheduled && requestId !== 0) {
				cancelAnimationFrame(requestId);
			}
			scheduled = false;
			requestId = 0;
		},
	};
}

export function installBrowserInputCallbacks(
	canvas: HTMLCanvasElement,
	callbacks: BrowserInputCallbacks,
	options: { keyboardTarget?: Window | HTMLElement } = {},
): BrowserInputBinding {
	const keyboardTarget = options.keyboardTarget ?? window;
	const onKeyDown: EventListener = (event): void => {
		const keyboardEvent = event as KeyboardEvent;
		callbacks.keyDown?.(
			keyboardEvent.code,
			keyboardModifiers(keyboardEvent),
			keyboardEvent.repeat,
		);
	};
	const onKeyUp: EventListener = (event): void => {
		const keyboardEvent = event as KeyboardEvent;
		callbacks.keyUp?.(keyboardEvent.code, keyboardModifiers(keyboardEvent));
	};
	const onPointerMove = (event: PointerEvent): void => {
		const { x, y } = pointerPosition(canvas, event);
		callbacks.pointerMove?.(x, y);
	};
	const onPointerDown = (event: PointerEvent): void => {
		event.preventDefault();
		canvas.setPointerCapture(event.pointerId);
		const { x, y } = pointerPosition(canvas, event);
		callbacks.mouseDown?.(event.button, x, y);
	};
	const onPointerUp = (event: PointerEvent): void => {
		const { x, y } = pointerPosition(canvas, event);
		callbacks.mouseUp?.(event.button, x, y);
	};
	const onWheel = (event: WheelEvent): void => {
		event.preventDefault();
		callbacks.wheel?.(event.deltaX, event.deltaY);
	};
	const onBlur = (): void => {
		callbacks.focusLost?.();
	};
	keyboardTarget.addEventListener("keydown", onKeyDown);
	keyboardTarget.addEventListener("keyup", onKeyUp);
	canvas.addEventListener("pointermove", onPointerMove);
	canvas.addEventListener("pointerdown", onPointerDown);
	canvas.addEventListener("pointerup", onPointerUp);
	canvas.addEventListener("wheel", onWheel, { passive: false });
	window.addEventListener("blur", onBlur);
	return {
		dispose: (): void => {
			keyboardTarget.removeEventListener("keydown", onKeyDown);
			keyboardTarget.removeEventListener("keyup", onKeyUp);
			canvas.removeEventListener("pointermove", onPointerMove);
			canvas.removeEventListener("pointerdown", onPointerDown);
			canvas.removeEventListener("pointerup", onPointerUp);
			canvas.removeEventListener("wheel", onWheel);
			window.removeEventListener("blur", onBlur);
		},
	};
}

export function installBrowserInputState(
	input: InputState,
	canvas: HTMLCanvasElement,
	options: { keyboardTarget?: Window | HTMLElement; onInput?: () => void } = {},
): BrowserInputBinding {
	return installBrowserInputCallbacks(
		canvas,
		{
			keyDown: (key, modifiers, repeat) => {
				input.enqueueEvent({ type: "KeyDown", key, modifiers, repeat });
				options.onInput?.();
			},
			keyUp: (key, modifiers) => {
				input.enqueueEvent({ type: "KeyUp", key, modifiers });
				options.onInput?.();
			},
			pointerMove: (x, y) => {
				input.enqueueEvent({ type: "PointerMove", x, y });
				options.onInput?.();
			},
			mouseDown: (button, x, y) => {
				input.enqueueEvent({
					type: "MouseDown",
					button: pointerButton(button),
					x,
					y,
				});
				options.onInput?.();
			},
			mouseUp: (button, x, y) => {
				input.enqueueEvent({
					type: "MouseUp",
					button: pointerButton(button),
					x,
					y,
				});
				options.onInput?.();
			},
			wheel: (deltaX, deltaY) => {
				input.enqueueEvent({ type: "Wheel", deltaX, deltaY });
				options.onInput?.();
			},
			focusLost: () => {
				input.enqueueEvent({ type: "FocusLost" });
				options.onInput?.();
			},
		},
		options,
	);
}

export function installBrowserInput(
	engine: Engine,
	options: { keyboardTarget?: Window | HTMLElement } = {},
): BrowserInputBinding {
	return installBrowserInputState(engine.input, engine.canvas, {
		...options,
		onInput: () => engine.requestRender("input"),
	});
}

export function startPlatform(
	engine: Engine,
	options: PlatformOptions = PlatformOptions.interactive(),
): Platform {
	syncBrowserEngineSurface(engine);
	if (options.frameMode === "single-frame") {
		engine.runFrame(0);
	}
	const inputBinding = options.installInput
		? installBrowserInput(engine, options)
		: undefined;
	const frameLoop =
		options.frameMode === "loop"
			? startBrowserFrameLoop((deltaSeconds) => {
				syncBrowserEngineSurface(engine);
				engine.runFrame(deltaSeconds);
			})
			: options.frameMode === "on-demand"
				? startBrowserOnDemandFrameLoop(
						(deltaSeconds) => {
							syncBrowserEngineSurface(engine);
							engine.runFrame(deltaSeconds);
						},
						() =>
							engine.renderRequested() || engine.continuousRenderRequested(),
					)
				: undefined;
	if (frameLoop !== undefined && options.frameMode === "on-demand") {
		engine.setRenderWakeup(() => frameLoop.request());
		frameLoop.request();
	}
	let disposed = false;
	return {
		engine,
		inputBinding,
		frameLoop,
		dispose: (): void => {
			if (disposed) {
				return;
			}
			disposed = true;
			engine.setRenderWakeup(undefined);
			frameLoop?.stop();
			inputBinding?.dispose();
			engine.shutdown();
		},
	};
}

export async function runPlatform(
	config: PlatformConfig,
	app: PlatformApp,
	options: PlatformOptions = PlatformOptions.interactive(),
): Promise<Platform | undefined> {
	const engine = await app.createEngine(config);
	if (app.setupEngine(engine) === false) {
		return undefined;
	}
	engine.initialize();
	const platform = startPlatform(engine, options);
	replacePlatformForCanvas(config.canvas, platform);
	return platform;
}

export async function runSingleCanvasPlatform(
	canvas: HTMLCanvasElement,
	app: PlatformApp,
	options: PlatformOptions = PlatformOptions.interactive(),
): Promise<Platform | undefined> {
	return runPlatform(new PlatformConfig(canvas), app, options);
}

export function attachCanvasSurface(
	engine: Engine,
	canvas: HTMLCanvasElement,
	options: { readonly scene?: RuntimeScene } = {},
): SurfaceId {
	return engine.addSurface(new GpuSurface(canvas, engine.device, engine.format), options);
}

export function syncBrowserEngineSurface(engine: Engine): void {
	if (engine.canvas.width <= 0 || engine.canvas.height <= 0) {
		engine.setSurfaceSuspended();
		return;
	}
	engine.setSurfaceActive(engine.canvas.width, engine.canvas.height, engine.format);
}

export function runBrowserWebGpuCanvasDemo(options: {
	readonly initialize: (canvas: HTMLCanvasElement) => void | Promise<void>;
	readonly canvasId?: string;
	readonly unsupportedMessage?: string;
	readonly missingCanvasMessage?: string;
	readonly failureMessage?: string;
}): void {
	const {
		initialize,
		canvasId = "webgpu-canvas",
		unsupportedMessage = "WebGPU is not supported in this browser.",
		missingCanvasMessage = "Missing WebGPU canvas.",
		failureMessage = "Failed to initialize WebGPU. Check the console for errors.",
	} = options;
	if (!navigator.gpu) {
		document.body.innerHTML = `<h1>${unsupportedMessage}</h1>`;
		return;
	}
	window.addEventListener("load", () => {
		const canvas = document.getElementById(canvasId);
		if (!(canvas instanceof HTMLCanvasElement)) {
			document.body.innerHTML = `<h1>${missingCanvasMessage}</h1>`;
			return;
		}
		Promise.resolve(initialize(canvas)).catch((error: unknown) => {
			console.error("Failed to initialize WebGPU:", error);
			document.body.innerHTML = `<h1>${failureMessage}</h1>`;
		});
	});
}

export type CommonOrbitCameraHandlers<TWorld, TMainCamera, TComponent> = {
	readonly orbitControllerComponent?: TComponent;
	readonly homeComponent?: TComponent;
	readonly updateOrbitCameraControllerFromInput?: (
		world: TWorld,
		camera: TMainCamera,
		orbitComponent: TComponent,
		input: InputState,
	) => void;
	readonly syncOrbitCameraTransform?: (
		world: TWorld,
		camera: TMainCamera,
		orbitComponent: TComponent,
		homeComponent: TComponent,
	) => void;
};

type EngineSurface = {
	readonly id: SurfaceId;
	readonly gpuSurface: GpuSurface;
	readonly input: InputState;
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
		this.scenes = [mainScene];
		this.timeState = new TimeState();
		this.phaseGroupsValue = defaultPhaseGroups();
		this.surfaceStateValue = SurfaceState.active(
			Math.max(canvas.width, 1),
			Math.max(canvas.height, 1),
			format,
			0,
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
		this.surfaces.splice(index, 1);
		this.requestRender("surface");
	}

	surfaceInput(surfaceId: SurfaceId): InputState {
		return this.requireSurface(surfaceId).input;
	}

	surfaceGpuSurface(surfaceId: SurfaceId): GpuSurface {
		return this.requireSurface(surfaceId).gpuSurface;
	}

	setSurfaceScene(surfaceId: SurfaceId, scene: RuntimeScene): void {
		this.requireSurface(surfaceId).scene = scene;
		this.requestRender("surface-scene");
	}

	private requireSurface(surfaceId: SurfaceId): EngineSurface {
		const surface = this.surfaces.find((candidate) => candidate.id === surfaceId);
		if (surface === undefined) {
			throw new Error(`Unknown engine surface '${surfaceId}'.`);
		}
		return surface;
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
		this.surfaceChangedValue = true;
		this.requestRender("surface");
	}

	addPhaseHandler(
		phase: PhaseKey,
		callback: EngineCallback,
		slot: PhaseSlot = PhaseSlot.BeforeSystems,
	): void {
		if (this.phaseRegistrationLocked) {
			throw new Error(
				"Engine.addPhaseHandler cannot register phase handlers after engine initialization.",
			);
		}
		this.phaseHandlers.push({ phase, slot, callback });
	}

	addCommonHandlers<TWorld, TMainCamera, TComponent>(
		scene: Scene<TWorld, TMainCamera>,
		options: CommonOrbitCameraHandlers<TWorld, TMainCamera, TComponent> = {},
	): void {
		const {
			orbitControllerComponent,
			homeComponent,
			updateOrbitCameraControllerFromInput,
			syncOrbitCameraTransform,
		} = options;
		if (homeComponent !== undefined && orbitControllerComponent === undefined) {
			throw new Error(
				"Engine.addCommonHandlers: homeComponent requires orbitControllerComponent.",
			);
		}
		if (orbitControllerComponent === undefined) {
			return;
		}
		if (updateOrbitCameraControllerFromInput === undefined) {
			throw new Error(
				"Engine.addCommonHandlers: orbitControllerComponent requires updateOrbitCameraControllerFromInput.",
			);
		}
		this.addPhaseHandler(Phase.Input, (engine, frame) => {
			const camera = scene.mainCamera();
			if (camera === null) {
				throw new Error("Engine.addCommonHandlers requires Scene.mainCamera.");
			}
			updateOrbitCameraControllerFromInput(
				scene.world(),
				camera,
				orbitControllerComponent,
				frame.input ?? engine.input,
			);
		});
		if (homeComponent === undefined) {
			return;
		}
		if (syncOrbitCameraTransform === undefined) {
			throw new Error(
				"Engine.addCommonHandlers: homeComponent requires syncOrbitCameraTransform.",
			);
		}
		scene.setSchedule((world) => {
			const camera = scene.mainCamera();
			if (camera === null) {
				throw new Error("Engine.addCommonHandlers requires Scene.mainCamera.");
			}
			syncOrbitCameraTransform(
				world,
				camera,
				orbitControllerComponent,
				homeComponent,
			);
		}, Phase.PostUpdate);
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
			surface.changed = surface.gpuSurface.syncFromCanvas() || surface.changed;
			surface.input.beginFrame();
			const frame = baseFrame.withSurfaceView(
				surface.id,
				surface.gpuSurface.state(),
				surface.changed,
				surface.input,
			);
			this.runPhaseGroup(PhaseGroup.FrameBegin, frame);
		}
		this.timeState.pushFixedElapsed(elapsedSeconds);
		const fixedSteps = this.timeState.drainReadyFixedFrames((fixedFrame) => {
			this.runPhaseGroup(PhaseGroup.FixedStep, fixedFrame);
		});
		for (const phase of this.phaseGroupOrder(PhaseGroup.RenderFrame)) {
			if (phaseIsRenderPath(phase)) {
				for (const surface of this.surfaces) {
					const state = surface.gpuSurface.state();
					if (!state.active) {
						continue;
					}
					this.runPhase(
						phase,
						baseFrame.withSurfaceView(
							surface.id,
							state,
							surface.changed,
							surface.input,
						),
					);
				}
			} else {
				this.runPhase(phase, baseFrame);
			}
		}
		for (const surface of this.surfaces) {
			surface.changed = false;
		}
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
