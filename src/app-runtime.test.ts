import { afterEach, describe, expect, it, vi } from "vitest";
import {
	Engine,
	type EngineCallback,
	Phase,
	PhaseGroup,
	Scene,
	TimeState,
	BrowserEngineRuntimeSlot,
	createBrowserEngineRuntime,
	defaultMaxFixedStepsPerFrame,
	installBrowserInputCallbacks,
	startBrowserEngineRuntime,
	startBrowserFrameLoop,
} from "./app-runtime";

type FakeEventTarget = {
	addEventListener: ReturnType<typeof vi.fn>;
	removeEventListener: ReturnType<typeof vi.fn>;
	dispatch: (type: string, event?: Record<string, unknown>) => void;
};

function fakeEventTarget(): FakeEventTarget {
	const listeners = new Map<string, EventListener[]>();
	return {
		addEventListener: vi.fn((type: string, listener: EventListener) => {
			listeners.set(type, [...(listeners.get(type) ?? []), listener]);
		}),
		removeEventListener: vi.fn((type: string, listener: EventListener) => {
			listeners.set(
				type,
				(listeners.get(type) ?? []).filter((item) => item !== listener),
			);
		}),
		dispatch: (type, event = {}) => {
			for (const listener of listeners.get(type) ?? []) {
				listener(event as unknown as Event);
			}
		},
	};
}

function fakeCanvas(): HTMLCanvasElement & FakeEventTarget {
	const target = fakeEventTarget();
	return Object.assign(target, {
		width: 800,
		height: 600,
		getContext: vi.fn(() => ({
			configure: vi.fn(),
		})),
		getBoundingClientRect: vi.fn(() => ({
			left: 10,
			top: 20,
			width: 400,
			height: 300,
		})),
		setPointerCapture: vi.fn(),
	}) as unknown as HTMLCanvasElement & FakeEventTarget;
}

function stubAnimationFrame(): {
	callbacks: FrameRequestCallback[];
	cancel: ReturnType<typeof vi.fn>;
} {
	const callbacks: FrameRequestCallback[] = [];
	vi.stubGlobal(
		"requestAnimationFrame",
		vi.fn((callback: FrameRequestCallback) => {
			callbacks.push(callback);
			return callbacks.length;
		}),
	);
	const cancel = vi.fn();
	vi.stubGlobal("cancelAnimationFrame", cancel);
	return { callbacks, cancel };
}

function stubWebGpu(): void {
	vi.stubGlobal("navigator", {
		gpu: {
			requestAdapter: vi.fn(async () => ({
				limits: {},
				requestDevice: vi.fn(async () => ({ queue: {} })),
			})),
			getPreferredCanvasFormat: vi.fn(() => "rgba8unorm"),
		},
	});
}

async function createTestEngine(): Promise<Engine> {
	stubWebGpu();
	return Engine.create(fakeCanvas(), { mainScene: new Scene("test") });
}

describe("app-runtime Engine", () => {
	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it("runs the standard frame order with fixed steps between input and render", async () => {
		const engine = await createTestEngine();
		const calls: Array<{
			phase: string;
			deltaSeconds: number;
			frameIndex: number;
		}> = [];
		const record =
			(phase: string): EngineCallback =>
			(_engine, frame) => {
				calls.push({
					phase,
					deltaSeconds: frame.deltaSeconds,
					frameIndex: frame.frameIndex,
				});
			};

		engine.addPhaseHandler(Phase.Input, record("input"));
		engine.addPhaseHandler(Phase.FixedUpdate, record("fixed_update"));
		engine.addPhaseHandler(Phase.FixedPostUpdate, record("fixed_post_update"));
		engine.addPhaseHandler(Phase.Update, record("update"));
		engine.addPhaseHandler(Phase.PostUpdate, record("post_update"));
		engine.addPhaseHandler(Phase.RenderExtract, record("render_extract"));
		engine.addPhaseHandler(Phase.RenderPrepare, record("render_prepare"));
		engine.addPhaseHandler(Phase.Render, record("render"));
		engine.addPhaseHandler(Phase.Present, record("present"));
		engine.initialize();

		const fixedSteps = engine.runFrame(1 / 30);

		expect(fixedSteps).toBe(2);
		expect(calls.map((call) => call.phase)).toEqual([
			"input",
			"fixed_update",
			"fixed_post_update",
			"fixed_update",
			"fixed_post_update",
			"update",
			"post_update",
			"render_extract",
			"render_prepare",
			"render",
			"present",
		]);
		expect(calls[0]?.deltaSeconds).toBe(1 / 30);
		expect(calls[1]?.deltaSeconds).toBe(1 / 60);
		expect(calls[1]?.frameIndex).toBe(1);
		expect(calls[3]?.frameIndex).toBe(2);
		expect(calls.at(-1)?.frameIndex).toBe(1);
	});

	it("exposes frame-begin, fixed-step, and render-frame groups separately", async () => {
		const engine = await createTestEngine();
		engine.initialize();

		expect(engine.phaseGroupOrder(PhaseGroup.FrameBegin)).toEqual([
			Phase.Surface,
			Phase.Input,
		]);
		expect(engine.phaseGroupOrder(PhaseGroup.FixedStep)).toEqual([
			Phase.FixedUpdate,
			Phase.FixedPostUpdate,
		]);
		expect(engine.phaseGroupOrder(PhaseGroup.RenderFrame)).toEqual([
			Phase.Update,
			Phase.PostUpdate,
			Phase.RenderExtract,
			Phase.RenderPrepare,
			Phase.Render,
			Phase.Present,
		]);
	});

	it("caps fixed-step catch-up and drops excess backlog", () => {
		const time = new TimeState(1 / 60);
		const frames: number[] = [];
		time.pushFixedElapsed(10);

		const steps = time.drainReadyFixedFrames((frame) => {
			frames.push(frame.frameIndex);
		});

		expect(steps).toBe(defaultMaxFixedStepsPerFrame());
		expect(frames).toEqual([1, 2, 3, 4, 5]);
		expect(time.canStepFixed()).toBe(false);
		time.pushFixedElapsed(1 / 60);
		expect(time.nextFixedFrame().frameIndex).toBe(6);
	});

	it("starts a browser frame loop with zero first delta and stoppable rAF", () => {
		const { callbacks, cancel } = stubAnimationFrame();
		const deltas: number[] = [];

		const loop = startBrowserFrameLoop((deltaSeconds) => {
			deltas.push(deltaSeconds);
		});
		callbacks[0]?.(100);
		callbacks[1]?.(125);
		loop.stop();
		callbacks[2]?.(150);

		expect(deltas).toEqual([0, 0.025]);
		expect(cancel).toHaveBeenCalledWith(3);
	});

	it("normalizes browser input callbacks from canvas and window events", () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		const calls: unknown[] = [];
		const binding = installBrowserInputCallbacks(canvas, {
			keyDown: (key, modifiers, repeat) => {
				calls.push(["keyDown", key, modifiers.shift, repeat]);
			},
			pointerMove: (x, y) => {
				calls.push(["pointerMove", x, y]);
			},
			mouseDown: (button, x, y) => {
				calls.push(["mouseDown", button, x, y]);
			},
			wheel: (deltaX, deltaY) => {
				calls.push(["wheel", deltaX, deltaY]);
			},
			focusLost: () => {
				calls.push(["focusLost"]);
			},
		});

		windowTarget.dispatch("keydown", {
			code: "KeyW",
			shiftKey: true,
			ctrlKey: false,
			altKey: false,
			metaKey: false,
			repeat: false,
		});
		canvas.dispatch("pointermove", { clientX: 210, clientY: 170 });
		canvas.dispatch("pointerdown", {
			button: 2,
			clientX: 410,
			clientY: 320,
			pointerId: 7,
			preventDefault: vi.fn(),
		});
		canvas.dispatch("wheel", {
			deltaX: 1,
			deltaY: -2,
			preventDefault: vi.fn(),
		});
		windowTarget.dispatch("blur");
		binding.dispose();

		expect(calls).toEqual([
			["keyDown", "KeyW", true, false],
			["pointerMove", 400, 300],
			["mouseDown", 2, 800, 600],
			["wheel", 1, -2],
			["focusLost"],
		]);
		expect(canvas.removeEventListener).toHaveBeenCalledWith(
			"pointermove",
			expect.any(Function),
		);
	});

	it("starts and disposes a browser engine runtime", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		const { cancel } = stubAnimationFrame();
		stubWebGpu();
		const engine = await Engine.create(canvas, { mainScene: new Scene("test") });
		engine.initialize();

		const runtime = startBrowserEngineRuntime(engine);
		runtime.dispose();
		runtime.dispose();

		expect(cancel).toHaveBeenCalled();
		expect(canvas.removeEventListener).toHaveBeenCalledWith(
			"pointermove",
			expect.any(Function),
		);
	});

	it("runs a single-frame browser engine runtime without input or loop", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		const { callbacks } = stubAnimationFrame();
		stubWebGpu();
		const engine = await Engine.create(canvas, { mainScene: new Scene("test") });
		const frames: number[] = [];
		engine.addPhaseHandler(Phase.Render, (_engine, frame) => {
			frames.push(frame.frameIndex);
		});
		engine.initialize();

		const runtime = startBrowserEngineRuntime(engine, {
			runLoop: false,
			installInput: false,
			runFirstFrame: true,
		});
		runtime.dispose();

		expect(frames).toEqual([1]);
		expect(callbacks).toHaveLength(0);
		expect(canvas.addEventListener).not.toHaveBeenCalledWith(
			"pointermove",
			expect.any(Function),
		);
	});

	it("replaces browser engine runtimes through a slot", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const first = await Engine.create(canvas, { mainScene: new Scene("first") });
		const second = await Engine.create(canvas, { mainScene: new Scene("second") });
		const shutdowns: string[] = [];
		first.addPhaseHandler(Phase.Shutdown, () => {
			shutdowns.push("first");
		});
		second.addPhaseHandler(Phase.Shutdown, () => {
			shutdowns.push("second");
		});
		first.initialize();
		second.initialize();
		const slot = new BrowserEngineRuntimeSlot();

		slot.replace(startBrowserEngineRuntime(first));
		slot.replace(startBrowserEngineRuntime(second));
		slot.dispose();

		expect(shutdowns).toEqual(["first", "second"]);
	});

	it("creates a browser engine runtime around setup and initialization", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const calls: string[] = [];

		const runtime = await createBrowserEngineRuntime(
			canvas,
			(engine) => {
				engine.addPhaseHandler(Phase.Startup, () => {
					calls.push("startup");
				});
			},
			{ runLoop: false, installInput: false },
		);
		runtime?.dispose();

		expect(calls).toEqual(["startup"]);
	});
});
