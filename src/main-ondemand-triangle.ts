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
	readonly uniformBuffer: GPUBuffer;
	readonly bindGroup: GPUBindGroup;
	angle: number;
	snapshotColorView?: GPUTextureView;
};

const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;

const shaderCode = `
struct DemoUniform {
  angle: f32,
};

@group(0) @binding(0) var<uniform> demo: DemoUniform;

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
  let c = cos(demo.angle);
  let s = sin(demo.angle);
  let p = pos[vertexIndex];
  let rotated = vec2<f32>(p.x * c - p.y * s, p.x * s + p.y * c);
  var output: VertexOutput;
  output.position = vec4<f32>(rotated, 0.0, 1.0);
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
	const uniformBuffer = engine.device.createBuffer({
		size: 16,
		usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
	});
	const bindGroup = engine.device.createBindGroup({
		layout: pipeline.getBindGroupLayout(0),
		entries: [{ binding: 0, resource: { buffer: uniformBuffer } }],
	});
	const demoState = { engine, pipeline, uniformBuffer, bindGroup, angle: 0 };
	writeAngleUniform(demoState);
	return demoState;
}

function clearColor(): GPUColorDict {
	return { r: 0.02, g: 0.03, b: 0.18, a: 1 };
}

function writeAngleUniform(demoState: DemoState): void {
	const uniform = new Float32Array(4);
	uniform[0] = demoState.angle;
	demoState.engine.queue.writeBuffer(demoState.uniformBuffer, 0, uniform);
}

function registerEngineHandlers(engine: Engine, demoState: DemoState): void {
	engine.addPhaseHandler(
		Phase.Input,
		(engine) => {
			const input = engine.input;
			const dragging =
				input.mouseDown("Left") &&
				(input.pointerDeltaX() !== 0 || input.pointerDeltaY() !== 0);
			let delta = 0;
			if (dragging) {
				delta += input.pointerDeltaX() * 0.012;
			}
			if (input.keyPressed("ArrowLeft") || input.keyPressed("KeyA")) {
				delta -= 0.18;
			}
			if (
				input.keyPressed("ArrowRight") ||
				input.keyPressed("KeyD") ||
				input.keyPressed("Space") ||
				input.keyPressed("Enter")
			) {
				delta += 0.18;
			}
			if (input.wheelDeltaY() !== 0) {
				delta += input.wheelDeltaY() * 0.002;
			}
			if (delta !== 0) {
				demoState.angle += delta;
				writeAngleUniform(demoState);
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
				clearValue: clearColor(),
				loadOp: "clear",
				storeOp: "store",
			},
		],
	});
	pass.setPipeline(demoState.pipeline);
	pass.setBindGroup(0, demoState.bindGroup);
	pass.draw(3);
	pass.end();
	demoState.engine.queue.submit([encoder.finish()]);
}

function releaseDemoState(demoState: DemoState): void {
	demoState.uniformBuffer.destroy();
}

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
