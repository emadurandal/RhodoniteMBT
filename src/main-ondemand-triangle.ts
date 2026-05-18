import "./style.css";
import {
	Engine,
	Phase,
	PhaseSlot,
	PlatformApp,
	PlatformConfig,
	PlatformOptions,
	runBrowserWebGpuCanvasDemo,
	runPlatform,
} from "./app-runtime";
import {
	createRgba8ReadbackTarget,
	destroyReadbackTarget,
	readRgba8Texture,
} from "./visual-regression/webgpu-readback";

type DemoState = {
	readonly engine: Engine;
	readonly pipeline: GPURenderPipeline;
	colorStep: number;
	snapshotColorView?: GPUTextureView;
};

const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;

const shaderCode = `
struct VertexOutput {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec3<f32>,
};

@vertex
fn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
  var pos = array<vec2<f32>, 3>(
    vec2<f32>(0.0, 0.58),
    vec2<f32>(-0.58, -0.48),
    vec2<f32>(0.58, -0.48),
  );
  var colors = array<vec3<f32>, 3>(
    vec3<f32>(1.0, 0.78, 0.18),
    vec3<f32>(0.08, 0.86, 0.72),
    vec3<f32>(0.96, 0.22, 0.38),
  );
  var output: VertexOutput;
  output.position = vec4<f32>(pos[vertexIndex], 0.0, 1.0);
  output.color = colors[vertexIndex];
  return output;
}

@fragment
fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  return vec4<f32>(color, 1.0);
}
`;

function createDemoStateForEngine(engine: Engine): DemoState {
	const shader = engine.device.createShaderModule({ code: shaderCode });
	const pipeline = engine.device.createRenderPipeline({
		layout: "auto",
		vertex: { module: shader, entryPoint: "vertexMain" },
		fragment: {
			module: shader,
			entryPoint: "fragmentMain",
			targets: [{ format: engine.format }],
		},
		primitive: { topology: "triangle-list" },
	});
	return { engine, pipeline, colorStep: 0 };
}

function clearColor(step: number): GPUColorDict {
	switch (step % 4) {
		case 0:
			return { r: 0.02, g: 0.03, b: 0.18, a: 1 };
		case 1:
			return { r: 0.16, g: 0.04, b: 0.08, a: 1 };
		case 2:
			return { r: 0.02, g: 0.13, b: 0.1, a: 1 };
		default:
			return { r: 0.12, g: 0.1, b: 0.02, a: 1 };
	}
}

function registerEngineHandlers(engine: Engine, demoState: DemoState): void {
	engine.addPhaseHandler(
		Phase.Input,
		(engine) => {
			const input = engine.input;
			const dragging =
				input.mouseDown("Left") &&
				(input.pointerDeltaX() !== 0 || input.pointerDeltaY() !== 0);
			if (
				input.mousePressed("Left") ||
				dragging ||
				input.keyPressed("Space") ||
				input.keyPressed("Enter") ||
				input.keyPressed("ArrowLeft") ||
				input.keyPressed("ArrowRight") ||
				input.wheelDeltaX() !== 0 ||
				input.wheelDeltaY() !== 0
			) {
				demoState.colorStep += 1;
			}
		},
		PhaseSlot.AfterSystems,
	);
	engine.addPhaseHandler(
		Phase.Render,
		() => renderCurrentFrame(demoState),
		PhaseSlot.AfterSystems,
	);
	engine.addPhaseHandler(Phase.Shutdown, () => releaseDemoState(demoState));
}

function renderCurrentFrame(demoState: DemoState): void {
	const colorView =
		demoState.snapshotColorView ??
		demoState.engine.context.getCurrentTexture().createView();
	renderToView(demoState, colorView);
}

function renderToView(demoState: DemoState, colorView: GPUTextureView): void {
	const encoder = demoState.engine.device.createCommandEncoder();
	const pass = encoder.beginRenderPass({
		colorAttachments: [
			{
				view: colorView,
				clearValue: clearColor(demoState.colorStep),
				loadOp: "clear",
				storeOp: "store",
			},
		],
	});
	pass.setPipeline(demoState.pipeline);
	pass.draw(3);
	pass.end();
	demoState.engine.queue.submit([encoder.finish()]);
}

function releaseDemoState(_demoState: DemoState): void {}

export async function renderTsOndemandTriangleBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = CANVAS_WIDTH;
	canvas.height = CANVAS_HEIGHT;
	const engine = await Engine.create(canvas);
	const demoState = createDemoStateForEngine(engine);
	registerEngineHandlers(engine, demoState);
	engine.initialize();
	const target = createRgba8ReadbackTarget(engine.device, CANVAS_WIDTH, CANVAS_HEIGHT);
	try {
		demoState.snapshotColorView = target.view;
		engine.runFrame(0);
		demoState.snapshotColorView = undefined;
		return await readRgba8Texture(
			engine.device,
			engine.queue,
			target.texture,
			CANVAS_WIDTH,
			CANVAS_HEIGHT,
		);
	} finally {
		demoState.snapshotColorView = undefined;
		engine.shutdown();
		destroyReadbackTarget(target);
	}
}

runBrowserWebGpuCanvasDemo({
	initialize: async (canvas) => {
		await runPlatform(
			new PlatformConfig(canvas),
			PlatformApp.defaultEngine((engine) => {
				const demoState = createDemoStateForEngine(engine);
				registerEngineHandlers(engine, demoState);
			}),
			PlatformOptions.interactiveOnDemand(),
		);
	},
});
