import { afterEach, describe, expect, it, vi } from "vitest";
import {
	Engine,
	type EngineCallback,
	Phase,
	PhaseGroup,
	Scene,
} from "./app-runtime";

function fakeCanvas(): HTMLCanvasElement {
	return {
		getContext: vi.fn(() => ({
			configure: vi.fn(),
		})),
	} as unknown as HTMLCanvasElement;
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
});
