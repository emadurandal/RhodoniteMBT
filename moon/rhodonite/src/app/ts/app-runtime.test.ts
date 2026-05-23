// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import { afterEach, describe, expect, it, vi } from "vitest";
import {
	Engine,
	type EngineCallback,
	FrameState,
	GpuSurface,
	Phase,
	PhaseGroup,
	PhaseSlot,
	Scene,
	TimeState,
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	defaultMaxFixedStepsPerFrame,
	defaultRenderStatePreparationPhases,
	installBrowserInputCallbacks,
	runMultiSurfacePlatform,
	runPlatform,
	startPlatform,
	startBrowserFrameLoop,
	stopPlatform,
} from "./index.ts";
import { FakeDevice } from "../test-utils/fake-webgpu.ts";

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

function fakeOrbitWorld() {
	const component = { index: 4 };
	return {
		orbitCameraControllerComponent: () => component,
		cameraHomeTransformComponent: () => component,
		cameraLensComponent: () => component,
	};
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
	const device = new FakeDevice();
	vi.stubGlobal("navigator", {
		gpu: {
			requestAdapter: vi.fn(async () => ({
				limits: {},
				requestDevice: vi.fn(async () => device),
			})),
			getPreferredCanvasFormat: vi.fn(() => "rgba8unorm"),
		},
	});
}

async function createTestEngine(): Promise<Engine> {
	stubWebGpu();
	return Engine.create(fakeCanvas(), { mainScene: new Scene("test") });
}

function createTestGpuSurface(
	canvas: HTMLCanvasElement & FakeEventTarget,
): GpuSurface {
	return new GpuSurface(canvas, {} as GPUDevice, "rgba8unorm");
}

describe("GpuSurface.syncFromCanvas", () => {
	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it("keeps generation unchanged across no-op syncs", () => {
		const canvas = fakeCanvas();
		const surface = createTestGpuSurface(canvas);

		for (let index = 0; index < 8; index += 1) {
			expect(surface.syncFromCanvas()).toBe(false);
		}

		expect(surface.state().generation).toBe(0);
	});

	it("increments generation only on actual active/suspend transitions", () => {
		const canvas = fakeCanvas();
		const surface = createTestGpuSurface(canvas);

		expect(surface.syncFromCanvas()).toBe(false);
		expect(surface.state().generation).toBe(0);

		canvas.width = 0;
		canvas.height = 0;
		expect(surface.syncFromCanvas()).toBe(true);
		expect(surface.state().generation).toBe(1);

		for (let index = 0; index < 4; index += 1) {
			expect(surface.syncFromCanvas()).toBe(false);
			expect(surface.state().generation).toBe(1);
		}

		canvas.width = 800;
		canvas.height = 600;
		expect(surface.syncFromCanvas()).toBe(true);
		expect(surface.state().generation).toBe(2);
	});

	it("increments generation by one after intervening no-op syncs", () => {
		const canvas = fakeCanvas();
		const surface = createTestGpuSurface(canvas);

		for (let index = 0; index < 5; index += 1) {
			expect(surface.syncFromCanvas()).toBe(false);
		}

		canvas.width = 1024;
		canvas.height = 768;
		expect(surface.syncFromCanvas()).toBe(true);
		expect(surface.state().generation).toBe(1);
	});
});

describe("app-runtime Scene", () => {
	it("prepares render state with update post-update and render-extract schedules", () => {
		const scene = new Scene<Record<string, never>>("prepare", {});
		const calls: string[] = [];

		scene.setSchedule((_world, frame) => {
			calls.push(`update:${frame.frameIndex}`);
		}, Phase.Update);
		scene.setSchedule((_world, frame) => {
			calls.push(`post-update:${frame.frameIndex}`);
		}, Phase.PostUpdate);
		scene.setSchedule((_world, frame) => {
			calls.push(`render-extract:${frame.frameIndex}`);
		}, Phase.RenderExtract);

		expect(scene.prepareRenderState()).toBe(true);
		expect(calls).toEqual([
			"update:0",
			"post-update:0",
			"render-extract:0",
		]);
	});

	it("runs an explicit ordered phase list with one frame state", () => {
		const scene = new Scene<Record<string, never>>("phase-list", {});
		const calls: string[] = [];
		const frame = new FrameState(0.016, 7, 0.112);

		scene.setSchedule((_world, runFrame) => {
			calls.push(`update:${runFrame.frameIndex}`);
		}, Phase.Update);
		scene.setSchedule((_world, runFrame) => {
			calls.push(`post-update:${runFrame.frameIndex}`);
		}, Phase.PostUpdate);

		expect(
			scene.runSchedulePhases([Phase.PostUpdate, Phase.Update], frame),
		).toBe(true);
		expect(calls).toEqual(["post-update:7", "update:7"]);
	});

	it("exposes the render state preparation phase list", () => {
		expect(defaultRenderStatePreparationPhases()).toEqual([
			Phase.Update,
			Phase.PostUpdate,
			Phase.RenderExtract,
		]);
	});
});

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

	it("attaches legacy surface state to fixed steps in multi-surface frames", async () => {
		const engine = await createTestEngine();
		const fixedFrames: Array<{
			format: string;
			surfaceChanged: boolean;
			surfaceId: number | undefined;
		}> = [];

		engine.addPhaseHandler(Phase.FixedUpdate, (_engine, frame) => {
			fixedFrames.push({
				format: frame.surface.format,
				surfaceChanged: frame.surfaceChanged,
				surfaceId: frame.surfaceId,
			});
		});
		engine.initialize();
		engine.addSurface(createTestGpuSurface(fakeCanvas()));

		const fixedSteps = engine.runMultiSurfaceFrame(1 / 60);

		expect(fixedSteps).toBe(1);
		expect(fixedFrames).toEqual([
			{
				format: engine.format,
				surfaceChanged: true,
				surfaceId: undefined,
			},
		]);
	});

	it("keeps surfaceChanged stable across render-frame phases in multi-surface frames", async () => {
		const engine = await createTestEngine();
		const renderSurfaceChanged: boolean[] = [];

		engine.addPhaseHandler(Phase.Update, () => {
			const surfaces = (
				engine as unknown as { surfaces: Array<{ changed: boolean }> }
			).surfaces;
			surfaces[0]!.changed = false;
		});
		engine.addPhaseHandler(Phase.Render, (_engine, frame) => {
			renderSurfaceChanged.push(frame.surfaceChanged);
		});
		engine.initialize();
		engine.addSurface(createTestGpuSurface(fakeCanvas()));

		engine.runMultiSurfaceFrame(1 / 60);

		expect(renderSurfaceChanged).toEqual([true]);
	});

	it("deduplicates keyed addPhaseHandler registrations", async () => {
		const engine = await createTestEngine();
		let inputCount = 0;
		let afterInputCount = 0;

		engine.addPhaseHandler(
			Phase.Input,
			() => {
				inputCount += 1;
			},
			PhaseSlot.BeforeSystems,
			"test/input",
		);
		engine.addPhaseHandler(
			Phase.Input,
			() => {
				inputCount += 1;
			},
			PhaseSlot.BeforeSystems,
			"test/input",
		);
		engine.addPhaseHandler(
			Phase.Input,
			() => {
				afterInputCount += 1;
			},
			PhaseSlot.AfterSystems,
			"test/input",
		);
		engine.initialize();

		engine.runFrame(1 / 60);

		expect(inputCount).toBe(1);
		expect(afterInputCount).toBe(1);
	});

	it("runs frame callbacks in the standard update and render slots", async () => {
		const engine = await createTestEngine();
		const scene = engine.mainScene<Record<string, never>>();
		scene.setWorld({});
		const calls: string[] = [];

		engine.onFrameUpdate(() => {
			calls.push("frame-update");
		});
		scene.setSchedule(() => {
			calls.push("update-system");
		}, Phase.Update);
		scene.setSchedule(() => {
			calls.push("render-system");
		}, Phase.Render);
		engine.onFrameRender(() => {
			calls.push("frame-render");
		});
		engine.initialize();

		engine.runFrame(1 / 60);

		expect(calls).toEqual([
			"frame-update",
			"update-system",
			"render-system",
			"frame-render",
		]);
	});

	it("deduplicates keyed frame and scene callback registrations", async () => {
		const engine = await createTestEngine();
		const scene = engine.mainScene();
		let frameUpdateCount = 0;
		let sceneRenderCount = 0;

		engine.onFrameUpdate(() => {
			frameUpdateCount += 1;
		}, "test/frame-update");
		engine.onFrameUpdate(() => {
			frameUpdateCount += 1;
		}, "test/frame-update");
		engine.onSceneRender(scene, () => {
			sceneRenderCount += 1;
		}, "test/scene-render");
		engine.onSceneRender(scene, () => {
			sceneRenderCount += 1;
		}, "test/scene-render");
		engine.initialize();

		engine.runFrame(1 / 60);

		expect(frameUpdateCount).toBe(1);
		expect(sceneRenderCount).toBe(1);
	});

	it("runs scene callbacks only for matching multi-surface scenes", async () => {
		const engine = await createTestEngine();
		const first = new Scene("first");
		const second = new Scene("second");
		const firstSurface = engine.addSurface(createTestGpuSurface(fakeCanvas()));
		const secondSurface = engine.addSurface(createTestGpuSurface(fakeCanvas()));
		const updateSurfaces: Array<number | undefined> = [];
		const renderSurfaces: Array<number | undefined> = [];

		engine.setSurfaceScene(firstSurface, first);
		engine.setSurfaceScene(secondSurface, second);
		engine.onSceneUpdate(first, (frame) => {
			updateSurfaces.push(frame.surfaceId);
		});
		engine.onSceneRender(second, (frame) => {
			renderSurfaces.push(frame.surfaceId);
		});
		engine.initialize();

		engine.runMultiSurfaceFrame(1 / 60);

		expect(updateSurfaces).toEqual([firstSurface]);
		expect(renderSurfaces).toEqual([secondSurface]);
	});

	it("skips scene callbacks when the scene is disabled or hidden", async () => {
		const engine = await createTestEngine();
		const scene = engine.mainScene();
		let updateCount = 0;
		let renderCount = 0;

		scene.setEnabled(false);
		scene.setVisible(false);
		engine.onSceneUpdate(scene, () => {
			updateCount += 1;
		});
		engine.onSceneRender(scene, () => {
			renderCount += 1;
		});
		engine.initialize();

		engine.runFrame(1 / 60);

		expect(updateCount).toBe(0);
		expect(renderCount).toBe(0);
	});

	it("installs declared common runtime orbit input during initialize", async () => {
		const engine = await createTestEngine();
		const scene = engine.mainScene<ReturnType<typeof fakeOrbitWorld>, string>();
		scene.setWorld(fakeOrbitWorld());
		scene.setMainCamera("camera");

		let orbitUpdateCount = 0;
		scene.useCommonRuntime({}, {
			updateOrbitCameraControllerFromInput: () => {
				orbitUpdateCount += 1;
			},
			syncOrbitCameraTransform: () => {},
			syncOrbitCameraBlob: () => {},
		});
		engine.initialize();

		engine.runFrame(1 / 60);

		expect(orbitUpdateCount).toBe(1);
	});

	it("uses builtin transform propagation when a common runtime world supports it", async () => {
		const engine = await createTestEngine();
		const scene = engine.mainScene<
			{ updateGlobalTransformsFromTransforms: () => void },
			string
		>();
		let propagationCount = 0;
		scene.setWorld({
			updateGlobalTransformsFromTransforms: () => {
				propagationCount += 1;
			},
		});
		scene.useCommonRuntime({
			orbitCameraTransform: false,
			orbitCameraBlobSync: false,
		});
		engine.initialize();

		engine.runFrame(1 / 60);

		expect(propagationCount).toBe(1);
	});

	it("installs declared common runtime for surface scenes created during startup", async () => {
		const engine = await createTestEngine();
		const surfaceId = engine.addSurface(createTestGpuSurface(fakeCanvas()));
		let orbitUpdateCount = 0;

		engine.addPhaseHandler(Phase.Startup, () => {
			const scene = new Scene("startup-surface", fakeOrbitWorld());
			scene.setMainCamera("camera");
			scene.useCommonRuntime({}, {
				updateOrbitCameraControllerFromInput: () => {
					orbitUpdateCount += 1;
				},
				syncOrbitCameraTransform: () => {},
				syncOrbitCameraBlob: () => {},
			});
			engine.setSurfaceScene(surfaceId, scene);
		});
		engine.initialize();

		engine.runMultiSurfaceFrame(1 / 60);

		expect(orbitUpdateCount).toBe(1);
	});

	it("installs declared common runtime when a surface scene is bound after initialize", async () => {
		const engine = await createTestEngine();
		const surfaceId = engine.addSurface(createTestGpuSurface(fakeCanvas()));
		let orbitUpdateCount = 0;

		engine.initialize();
		const scene = new Scene("surface-after-init", fakeOrbitWorld());
		scene.setMainCamera("camera");
		scene.useCommonRuntime({}, {
			updateOrbitCameraControllerFromInput: () => {
				orbitUpdateCount += 1;
			},
			syncOrbitCameraTransform: () => {},
			syncOrbitCameraBlob: () => {},
		});
		engine.setSurfaceScene(surfaceId, scene);

		engine.runMultiSurfaceFrame(1 / 60);

		expect(orbitUpdateCount).toBe(1);
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

	it("starts and disposes a browser engine platform", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		const { cancel } = stubAnimationFrame();
		stubWebGpu();
		const engine = await Engine.create(canvas, { mainScene: new Scene("test") });
		engine.initialize();

		const platform = startPlatform(engine);
		platform.dispose();
		platform.dispose();

		expect(cancel).toHaveBeenCalled();
		expect(canvas.removeEventListener).toHaveBeenCalledWith(
			"pointermove",
			expect.any(Function),
		);
	});

	it("runs a single-frame browser engine platform without input or loop", async () => {
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

		const platform = startPlatform(engine, PlatformOptions.singleFrame());
		platform.dispose();

		expect(frames).toEqual([1]);
		expect(callbacks).toHaveLength(0);
		expect(canvas.addEventListener).not.toHaveBeenCalledWith(
			"pointermove",
			expect.any(Function),
		);
	});

	it("replaces browser engine platforms per canvas through runPlatform", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const shutdowns: string[] = [];

		await runPlatform(
			new PlatformConfig(canvas, { mainScene: new Scene("first") }),
			PlatformApp.defaultEngine((engine) => {
				engine.addPhaseHandler(Phase.Shutdown, () => {
					shutdowns.push("first");
				});
			}),
			PlatformOptions.singleFrame(),
		);
		await runPlatform(
			new PlatformConfig(canvas, { mainScene: new Scene("second") }),
			PlatformApp.defaultEngine((engine) => {
				engine.addPhaseHandler(Phase.Shutdown, () => {
					shutdowns.push("second");
				});
			}),
			PlatformOptions.singleFrame(),
		);
		stopPlatform(canvas);

		expect(shutdowns).toEqual(["first", "second"]);
	});

	it("keeps browser engine platforms isolated by canvas", async () => {
		const firstCanvas = fakeCanvas();
		const secondCanvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const shutdowns: string[] = [];

		await runPlatform(
			new PlatformConfig(firstCanvas, { mainScene: new Scene("first") }),
			PlatformApp.defaultEngine((engine) => {
				engine.addPhaseHandler(Phase.Shutdown, () => {
					shutdowns.push("first");
				});
			}),
			PlatformOptions.singleFrame(),
		);
		await runPlatform(
			new PlatformConfig(secondCanvas, { mainScene: new Scene("second") }),
			PlatformApp.defaultEngine((engine) => {
				engine.addPhaseHandler(Phase.Shutdown, () => {
					shutdowns.push("second");
				});
			}),
			PlatformOptions.singleFrame(),
		);
		stopPlatform(firstCanvas);
		expect(shutdowns).toEqual(["first"]);

		stopPlatform(secondCanvas);
		expect(shutdowns).toEqual(["first", "second"]);
	});

	it("keeps the current browser engine platform when setup fails", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const shutdowns: string[] = [];

		await runPlatform(
			new PlatformConfig(canvas, { mainScene: new Scene("current") }),
			PlatformApp.defaultEngine((engine) => {
				engine.addPhaseHandler(Phase.Shutdown, () => {
					shutdowns.push("current");
				});
			}),
			PlatformOptions.singleFrame(),
		);
		const failed = await runPlatform(
			new PlatformConfig(canvas, { mainScene: new Scene("failed") }),
			PlatformApp.defaultEngine(() => false),
			PlatformOptions.singleFrame(),
		);

		expect(failed).toBeUndefined();
		expect(shutdowns).toEqual([]);

		stopPlatform(canvas);
		expect(shutdowns).toEqual(["current"]);
	});

	it("runs a browser engine platform around setup and initialization", async () => {
		const canvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const calls: string[] = [];

		const platform = await runPlatform(
			new PlatformConfig(canvas),
			PlatformApp.defaultEngine((engine) => {
				engine.addPhaseHandler(Phase.Startup, () => {
					calls.push("startup");
				});
			}),
			PlatformOptions.singleFrame(),
		);
		platform?.dispose();

		expect(calls).toEqual(["startup"]);
	});

	it("launches a browser multi-surface platform after attaching configured canvases", async () => {
		const firstCanvas = fakeCanvas();
		const secondCanvas = fakeCanvas();
		const windowTarget = fakeEventTarget();
		vi.stubGlobal("window", windowTarget);
		stubAnimationFrame();
		stubWebGpu();
		const calls: string[] = [];

		const platform = await runMultiSurfacePlatform(
			[new PlatformConfig(firstCanvas), new PlatformConfig(secondCanvas)],
			PlatformApp.defaultEngine((engine) => {
				calls.push(`setup:${engine.surfaceCount()}`);
				engine.addPhaseHandler(Phase.Startup, () => {
					calls.push(`startup:${engine.surfaceCount()}`);
					calls.push(`surface:${engine.surfaceIdAt(0)}`);
					calls.push(`surface:${engine.surfaceIdAt(1)}`);
				});
				engine.addPhaseHandler(Phase.Render, (_engine, frame) => {
					calls.push(`render:${frame.surfaceId}`);
				});
			}),
			PlatformOptions.singleFrame(),
		);

		expect(platform).toBeDefined();
		platform?.dispose();

		expect(calls).toEqual([
			"setup:0",
			"startup:2",
			"surface:1",
			"surface:2",
			"render:1",
			"render:2",
		]);
	});
});
