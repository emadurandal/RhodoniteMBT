// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { Engine } from "./app-runtime-engine.ts";
import {
	installBrowserInput,
	installBrowserInputState,
	startBrowserFrameLoop,
	startBrowserOnDemandFrameLoop,
	type BrowserFrameLoop,
	type BrowserInputBinding,
} from "./app-runtime-input.ts";
import type { RuntimeScene } from "./app-runtime-scene.ts";
import { GpuSurface, type SurfaceId } from "./app-runtime-state.ts";

export type Platform = {
	readonly engine: Engine;
	readonly inputBinding?: BrowserInputBinding;
	readonly frameLoop?: BrowserFrameLoop;
	dispose: () => void;
};

type BrowserPlatformSurface = {
	readonly id: SurfaceId;
	readonly canvas: HTMLCanvasElement;
	readonly gpuSurface: GpuSurface;
	readonly inputBinding?: BrowserInputBinding;
};

export class MultiSurfacePlatform {
	readonly engine: Engine;
	private readonly options: PlatformOptions;
	private readonly surfacesValue: BrowserPlatformSurface[] = [];
	private frameLoopValue: BrowserFrameLoop | undefined;
	private disposed = false;
	private launched = false;

	constructor(
		engine: Engine,
		options: PlatformOptions = PlatformOptions.interactive(),
	) {
		this.engine = engine;
		this.options = options;
	}

	attachCanvas(canvas: HTMLCanvasElement): SurfaceId {
		const gpuSurface = new GpuSurface(canvas, this.engine.device, this.engine.format);
		return this.attachPreparedCanvas(canvas, gpuSurface);
	}

	async launch(): Promise<void> {
		if (this.launched || this.disposed) {
			return;
		}
		this.launched = true;
		this.engine.initialize();
		await this.startFrameLoop();
	}

	dispose(): void {
		if (this.disposed) {
			return;
		}
		this.disposed = true;
		this.engine.setRenderWakeup(undefined);
		this.frameLoopValue?.stop();
		for (const surface of this.surfacesValue) {
			surface.inputBinding?.dispose();
		}
		if (this.launched) {
			this.engine.shutdown();
		}
	}

	private attachPreparedCanvas(
		canvas: HTMLCanvasElement,
		gpuSurface: GpuSurface,
	): SurfaceId {
		const id = this.engine.addSurface(gpuSurface);
		const inputBinding = this.options.installInput
			? installBrowserInputState(this.engine.surfaceInput(id), canvas, {
					keyboardTarget: this.options.keyboardTarget,
					onInput: () => this.engine.requestRender("input"),
				})
			: undefined;
		this.surfacesValue.push({ id, canvas, gpuSurface, inputBinding });
		return id;
	}

	private runFrameTick(deltaSeconds: number): void {
		this.engine.runMultiSurfaceFrame(deltaSeconds);
	}

	private async startFrameLoop(): Promise<void> {
		if (this.options.frameMode === "single-frame") {
			this.runFrameTick(0);
			await this.engine.queue.onSubmittedWorkDone();
			return;
		}
		if (this.options.frameMode === "on-demand") {
			const frameLoop = startBrowserOnDemandFrameLoop(
				(deltaSeconds) => this.runFrameTick(deltaSeconds),
				() =>
					this.engine.renderRequested() ||
					this.engine.continuousRenderRequested(),
			);
			this.engine.setRenderWakeup(() => frameLoop.request());
			frameLoop.request();
			this.frameLoopValue = frameLoop;
			return;
		}
		this.frameLoopValue = startBrowserFrameLoop((deltaSeconds) =>
			this.runFrameTick(deltaSeconds),
		);
	}
}

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

export async function startPlatform(
	engine: Engine,
	options: PlatformOptions = PlatformOptions.interactive(),
): Promise<Platform> {
	syncBrowserEngineSurface(engine);
	if (options.frameMode === "single-frame") {
		engine.runFrame(0);
		await engine.queue.onSubmittedWorkDone();
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
	const platform = await startPlatform(engine, options);
	replacePlatformForCanvas(config.canvas, platform);
	return platform;
}

export async function runMultiSurfacePlatform(
	configs: readonly PlatformConfig[],
	app: PlatformApp,
	options: PlatformOptions = PlatformOptions.interactive(),
): Promise<MultiSurfacePlatform | undefined> {
	const firstConfig = configs[0];
	if (firstConfig === undefined) {
		return undefined;
	}
	const engine = await app.createEngine(firstConfig);
	if (app.setupEngine(engine) === false) {
		return undefined;
	}
	const platform = new MultiSurfacePlatform(engine, options);
	for (const config of configs) {
		platform.attachCanvas(config.canvas);
	}
	await platform.launch();
	return platform;
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
