import "./style.css";
import {
	World,
	computeGlobalTransformUploadRange,
	createGlobalTransformWordsBuffer,
	detectDenseGlobalTransformLayout,
	globalTransformRefInstanceVertexBufferLayout,
	globalTransformHelpersDefault,
	globalTransformWordsBindGroup,
	globalTransformWordsBindingDefault,
	uploadGlobalTransformWrites,
	writeGlobalTransformBlobRangeByRefs,
	type GlobalTransformBlobWriter,
	type GlobalTransformDenseLayout,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	createRgba8ReadbackTarget,
	destroyReadbackTarget,
	readRgba8Texture,
} from "./visual-regression/webgpu-readback";
import { App, Engine, Scene, type FrameState } from "./app-runtime";

const ENTITY_COUNT = 800_000;
type GlobalTransformPrecisionMode =
	| "all-f32"
	| "all-f16"
	| "first-half-f32-second-half-f16"
	| "even-id-f32-odd-id-f16";
const GLOBAL_TRANSFORM_PRECISION_MODE: GlobalTransformPrecisionMode = "all-f16";
const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;
const VERTEX_STRIDE_LOCAL = 12;
const INSTANCE_STRIDE = 24;
const VERTS_PER_CUBE = 8;
const INDEX_U16_COUNT = 36;
const CAMERA_ELEVATION_RAD = 0.42;
const GRID_SPACING = 0.14;
const CUBE_SCALE = 0.055;
type Mat4 = Float32Array;

type Camera = {
	uniformBytes: () => Uint8Array;
};

type DemoState = {
	readonly canvas: HTMLCanvasElement;
	readonly context: GPUCanvasContext;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly pipeline: GPURenderPipeline;
	readonly depthTexture: GPUTexture;
	readonly depthView: GPUTextureView;
	readonly vertexBuffer: GPUBuffer;
	readonly instanceBuffer: GPUBuffer;
	readonly indexBuffer: GPUBuffer;
	readonly transformStorage: GPUBuffer;
	readonly cameraUniform: GPUBuffer;
	readonly bindTransforms: GPUBindGroup;
	readonly bindCamera: GPUBindGroup;
	readonly scene: Scene<World, Camera>;
	readonly transformRefs: Uint32Array;
	readonly transformWordUploadFirst: number;
	readonly transformWordUploadCount: number;
	readonly denseTransformLayout: GlobalTransformDenseLayout | null;
	readonly perSide: number;
	snapshotColorView?: GPUTextureView;
	snapshotDepthView?: GPUTextureView;
	frame: number;
	lastFrameStartMs: number;
};

function gridSideLen(count: number): number {
	return Math.ceil(Math.sqrt(count));
}

function writeF32(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(
		offset,
		value,
		true,
	);
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
	new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setUint16(
		offset,
		value,
		true,
	);
}

function globalTransformDefaultIsF16(): boolean {
	return GLOBAL_TRANSFORM_PRECISION_MODE !== "all-f32";
}

function entityUsesF32(entityIndex: number, localIndex: number): boolean {
	switch (GLOBAL_TRANSFORM_PRECISION_MODE) {
		case "all-f32":
			return true;
		case "all-f16":
			return false;
		case "first-half-f32-second-half-f16":
			return localIndex < Math.floor(ENTITY_COUNT / 2);
		case "even-id-f32-odd-id-f16":
			return (entityIndex & 1) === 0;
	}
}

function applyGlobalTransformPrecisionMode(
	world: World,
	entities: ReturnType<World["spawnTransformGlobalBatchIdentity"]>,
): void {
	if (
		GLOBAL_TRANSFORM_PRECISION_MODE === "all-f32" ||
		GLOBAL_TRANSFORM_PRECISION_MODE === "all-f16"
	) {
		return;
	}
	entities.forEach((entity, localIndex) => {
		if (entityUsesF32(entity.index(), localIndex)) {
			world.setGlobalTransformFormat(entity, 0);
		}
	});
}

function mat4Identity(): Mat4 {
	const out = new Float32Array(16);
	out[0] = 1;
	out[5] = 1;
	out[10] = 1;
	out[15] = 1;
	return out;
}

function mat4Translation(x: number, y: number, z: number): Mat4 {
	const out = mat4Identity();
	out[12] = x;
	out[13] = y;
	out[14] = z;
	return out;
}

function mat4RotationX(rad: number): Mat4 {
	const out = mat4Identity();
	const c = Math.cos(rad);
	const s = Math.sin(rad);
	out[5] = c;
	out[6] = s;
	out[9] = -s;
	out[10] = c;
	return out;
}

function mat4Mul(a: Mat4, b: Mat4): Mat4 {
	const out = new Float32Array(16);
	for (let col = 0; col < 4; col += 1) {
		for (let row = 0; row < 4; row += 1) {
			out[col * 4 + row] =
				a[0 * 4 + row] * b[col * 4 + 0] +
				a[1 * 4 + row] * b[col * 4 + 1] +
				a[2 * 4 + row] * b[col * 4 + 2] +
				a[3 * 4 + row] * b[col * 4 + 3];
		}
	}
	return out;
}

function mat4Ortho(
	left: number,
	right: number,
	bottom: number,
	top: number,
	near: number,
	far: number,
): Mat4 {
	const out = new Float32Array(16);
	out[0] = 2 / (right - left);
	out[5] = 2 / (top - bottom);
	out[10] = 1 / (near - far);
	out[12] = -(right + left) / (right - left);
	out[13] = -(top + bottom) / (top - bottom);
	out[14] = near / (near - far);
	out[15] = 1;
	return out;
}

function transformPoint(m: Mat4, x: number, y: number, z: number): [number, number, number] {
	return [
		m[0] * x + m[4] * y + m[8] * z + m[12],
		m[1] * x + m[5] * y + m[9] * z + m[13],
		m[2] * x + m[6] * y + m[10] * z + m[14],
	];
}

function viewSpaceRangeCorners(
	viewRot: Mat4,
	extentXz: number,
	waveY: number,
	axis: 1 | 2,
): [number, number] {
	const sides = [-1, 1];
	let min = 0;
	let max = 0;
	let first = true;
	for (const sx of sides) {
		for (const sy of sides) {
			for (const sz of sides) {
				const v = transformPoint(
					viewRot,
					sx * extentXz,
					sy * waveY,
					sz * extentXz,
				)[axis];
				if (first) {
					min = v;
					max = v;
					first = false;
				} else {
					min = Math.min(min, v);
					max = Math.max(max, v);
				}
			}
		}
	}
	return [min, max];
}

function cameraUniformBytes(): Uint8Array {
	const viewRot = mat4Mul(
		mat4RotationX(CAMERA_ELEVATION_RAD),
		mat4Translation(0, 0, -16),
	);
	const perSide = gridSideLen(ENTITY_COUNT);
	const half = (perSide - 1) * 0.5;
	const extentXz = half * GRID_SPACING;
	const wave = 0.12;
	const margin = CUBE_SCALE * 2.5;
	const waveY = wave + CUBE_SCALE * 1.1;
	const [yLo, yHi] = viewSpaceRangeCorners(viewRot, extentXz, waveY, 1);
	const cy = (yLo + yHi) * 0.5;
	let halfH = (yHi - yLo) * 0.5 + margin;
	let halfW = extentXz + margin;
	const aspect = CANVAS_WIDTH / CANVAS_HEIGHT;
	if (halfW / halfH < aspect) {
		halfW = halfH * aspect;
	} else {
		halfH = halfW / aspect;
	}
	const [zLo, zHi] = viewSpaceRangeCorners(viewRot, extentXz, waveY, 2);
	const pullZ = zHi > -0.15 ? -zHi - 1 : 0;
	const view = mat4Mul(mat4Translation(0, 0, pullZ), viewRot);
	const farNeed = -(zLo + pullZ) + 8;
	const farClip = Math.max(farNeed, 80);
	const proj = mat4Ortho(-halfW, halfW, cy - halfH, cy + halfH, 0.1, farClip);
	const vp = mat4Mul(proj, view);
	const bytes = new Uint8Array(256);
	new Float32Array(bytes.buffer, 0, 16).set(vp);
	return bytes;
}

function cubeLocalCorners(): [number, number, number][] {
	return [
		[-1, -1, -1],
		[1, -1, -1],
		[1, 1, -1],
		[-1, 1, -1],
		[-1, -1, 1],
		[1, -1, 1],
		[1, 1, 1],
		[-1, 1, 1],
	];
}

function vertexPositionBytes(scale: number): Uint8Array {
	const bytes = new Uint8Array(VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL);
	cubeLocalCorners().forEach(([x, y, z], vertexIndex) => {
		const base = vertexIndex * VERTEX_STRIDE_LOCAL;
		writeF32(bytes, base, x * scale);
		writeF32(bytes, base + 4, y * scale);
		writeF32(bytes, base + 8, z * scale);
	});
	return bytes;
}

function indexCubeU16Bytes(): Uint8Array {
	const indices = [
		0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4, 0, 4, 7, 7, 3, 0, 1, 5, 6, 6, 2,
		1, 0, 1, 5, 5, 4, 0, 3, 2, 6, 6, 7, 3,
	];
	const bytes = new Uint8Array(indices.length * 2);
	indices.forEach((index, i) => writeU16(bytes, i * 2, index));
	return bytes;
}

function instanceColorRgb(index: number): [number, number, number] {
	const i = index % 125;
	return [
		(i % 5) * 0.22 + 0.12,
		(Math.floor(i / 5) % 5) * 0.22 + 0.08,
		(Math.floor(i / 25) % 5) * 0.22 + 0.1,
	];
}

function instanceBytes(entities: ReturnType<World["spawnTransformGlobalBatchIdentity"]>, refs: Uint8Array): Uint8Array {
	const bytes = new Uint8Array(entities.length * INSTANCE_STRIDE);
	entities.forEach((entity, i) => {
		const index = entity.index();
		const [r, g, b] = instanceColorRgb(index);
		const base = i * INSTANCE_STRIDE;
		bytes.set(refs.subarray(i * 8, i * 8 + 8), base);
		writeF32(bytes, base + 8, r);
		writeF32(bytes, base + 12, g);
		writeF32(bytes, base + 16, b);
	});
	return bytes;
}

function writeMassCubesTransformBlob(
	writer: GlobalTransformBlobWriter,
	perSide: number,
	t: number,
	fullRows: boolean,
): void {
	const waveTime = t * 1.8;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	if (!fullRows) {
		const setY = writer.elementSetter(1, 3);
		let i = 0;
		let waveSin = Math.sin(waveTime);
		let waveCos = Math.cos(waveTime);
		while (i < ENTITY_COUNT) {
			setY(i, waveSin * 0.12);
			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			i += 1;
		}
		return;
	}
	const half = (perSide - 1) * 0.5;
	let localIndex = 0;
	let row = 0;
	let column = 0;
	const setAffine3x4At = writer.setAffine3x4At;
	while (localIndex < ENTITY_COUNT) {
		const rowCount = Math.min(perSide - column, ENTITY_COUNT - localIndex);
		let x = (column - half) * GRID_SPACING;
		const z = (row - half) * GRID_SPACING;
		let waveSin = Math.sin(localIndex * 0.09 + waveTime);
		let waveCos = Math.cos(localIndex * 0.09 + waveTime);
		for (let ix = 0; ix < rowCount; ix += 1) {
			const y = waveSin * 0.12;
			setAffine3x4At(
				localIndex,
				CUBE_SCALE,
				0,
				0,
				x,
				0,
				CUBE_SCALE,
				0,
				y,
				0,
				0,
				CUBE_SCALE,
				z,
			);
			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			localIndex += 1;
			x += GRID_SPACING;
		}
		row += 1;
		column = 0;
	}
}

function uploadInitialGlobalTransforms(renderer: DemoState): void {
	const world = renderer.scene.world();
	uploadGlobalTransformWrites(
		renderer.queue,
		renderer.transformStorage,
		writeGlobalTransformBlobRangeByRefs(world, {
			refs: renderer.transformRefs,
			count: ENTITY_COUNT,
			range: {
				firstWord: renderer.transformWordUploadFirst,
				wordCount: renderer.transformWordUploadCount,
			},
			denseLayout: renderer.denseTransformLayout,
			write: (writer) =>
				writeMassCubesTransformBlob(writer, renderer.perSide, 0, true),
		}),
	);
}

function updateAndDrainGlobalTransforms(renderer: DemoState, t: number): void {
	const world = renderer.scene.world();
	uploadGlobalTransformWrites(
		renderer.queue,
		renderer.transformStorage,
		writeGlobalTransformBlobRangeByRefs(world, {
			refs: renderer.transformRefs,
			count: ENTITY_COUNT,
			range: {
				firstWord: renderer.transformWordUploadFirst,
				wordCount: renderer.transformWordUploadCount,
			},
			denseLayout: renderer.denseTransformLayout,
			write: (writer) =>
				writeMassCubesTransformBlob(writer, renderer.perSide, t, false),
		}),
	);
}

function shaderWgsl(): string {
	const prefix =
		`
struct CameraUniform {
  view_proj: mat4x4<f32>,
}

` +
		globalTransformWordsBindingDefault() +
		`
@group(1) @binding(0) var<uniform> camera: CameraUniform;
`;

	const suffix = `
struct VertexOut {
  @builtin(position) position: vec4<f32>,
  @location(0) color: vec3<f32>,
};

@vertex
fn vertexMain(
  @location(0) local_pos: vec3<f32>,
  @location(1) transform_ref: vec2<u32>,
  @location(2) color: vec3<f32>,
) -> VertexOut {
  let world_pos = rn_transform_point(
    rn_load_global_transform(transform_ref),
    local_pos,
  );
  let clip = camera.view_proj * world_pos;
  var o: VertexOut;
  o.position = clip;
  o.color = color;
  return o;
}

@fragment
fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  return vec4<f32>(color, 1.0);
}
`;
	return prefix + globalTransformHelpersDefault() + suffix;
}

function createDemoStateForEngine(
	engine: Engine,
	renderFormat?: GPUTextureFormat,
): DemoState {
	const { canvas, context, device, queue, format } = engine;
	const scene = engine.mainScene<World, Camera>();
	const targetFormat = renderFormat ?? format;

	const shader = device.createShaderModule({
		code: shaderWgsl(),
	});
	const pipeline = device.createRenderPipeline({
		layout: "auto",
		vertex: {
			module: shader,
			entryPoint: "vertexMain",
			buffers: [
				{
					arrayStride: VERTEX_STRIDE_LOCAL,
					stepMode: "vertex",
					attributes: [{ shaderLocation: 0, offset: 0, format: "float32x3" }],
				},
				globalTransformRefInstanceVertexBufferLayout(INSTANCE_STRIDE, {
					extraAttributes: [
						{ shaderLocation: 2, offset: 8, format: "float32x3" },
					],
				}),
			],
		},
		fragment: {
			module: shader,
			entryPoint: "fragmentMain",
			targets: [{ format: targetFormat }],
		},
		primitive: { topology: "triangle-list" },
		depthStencil: {
			format: "depth24plus",
			depthWriteEnabled: true,
			depthCompare: "less",
		},
	});

	const world = globalTransformDefaultIsF16()
		? World.newWithGlobalTransformF16()
		: World.new();
	scene.setWorld(world);
	const perSide = gridSideLen(ENTITY_COUNT);
	const entities = world.spawnTransformGlobalBatchIdentity(ENTITY_COUNT);
	applyGlobalTransformPrecisionMode(world, entities);
	const transformRefsBytes = world.extractGlobalTransformRefs(entities);
	const transformRefs = new Uint32Array(
		transformRefsBytes.buffer,
		transformRefsBytes.byteOffset,
		transformRefsBytes.byteLength >>> 2,
	);
	const denseTransformLayout = detectDenseGlobalTransformLayout(
		transformRefs,
		ENTITY_COUNT,
	);
	const transformUploadRange = computeGlobalTransformUploadRange(
		transformRefs,
		ENTITY_COUNT,
		denseTransformLayout,
	);
	const transformStorage = createGlobalTransformWordsBuffer(device, world);
	const cameraUniform = device.createBuffer({
		size: 256,
		usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
	});
	const camera = { uniformBytes: cameraUniformBytes };
	scene.setMainCamera(camera);
	queue.writeBuffer(cameraUniform, 0, camera.uniformBytes());

	const bindTransforms = globalTransformWordsBindGroup(
		device,
		pipeline,
		transformStorage,
	);
	const bindCamera = device.createBindGroup({
		layout: pipeline.getBindGroupLayout(1),
		entries: [{ binding: 0, resource: { buffer: cameraUniform } }],
	});

	const vertexBuffer = device.createBuffer({
		size: VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL,
		usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(vertexBuffer, 0, vertexPositionBytes(0.42));
	const instanceData = instanceBytes(entities, transformRefsBytes);
	const instanceBuffer = device.createBuffer({
		size: instanceData.byteLength,
		usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(instanceBuffer, 0, instanceData);
	const indexData = indexCubeU16Bytes();
	const indexBuffer = device.createBuffer({
		size: indexData.byteLength,
		usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
	});
	queue.writeBuffer(indexBuffer, 0, indexData);
	const depthTexture = device.createTexture({
		size: [CANVAS_WIDTH, CANVAS_HEIGHT],
		format: "depth24plus",
		usage: GPUTextureUsage.RENDER_ATTACHMENT,
	});
	const depthView = depthTexture.createView();

	const renderer: DemoState = {
		canvas,
		context,
		device,
		queue,
		pipeline,
		depthTexture,
		depthView,
		vertexBuffer,
		instanceBuffer,
		indexBuffer,
		transformStorage,
		cameraUniform,
		bindTransforms,
		bindCamera,
		scene,
		transformRefs,
		transformWordUploadFirst: transformUploadRange.firstWord,
		transformWordUploadCount: transformUploadRange.wordCount,
		denseTransformLayout,
		perSide,
		snapshotColorView: undefined,
		snapshotDepthView: undefined,
		frame: 0,
		lastFrameStartMs: -1,
	};
	uploadInitialGlobalTransforms(renderer);
	return renderer;
}

function createApp(renderer: DemoState): App {
	return new App({
		update: (_engine, frame) => updateScene(renderer, frame),
		render: () => {
			if (renderer.scene.visible()) {
				renderCurrentFrame(renderer);
			}
		},
		shutdown: () => releaseDemoState(renderer),
	});
}

function updatePerfOverlay(fps: number, cpuMs: number): void {
	const el = document.getElementById("ecs-mass-cubes-perf");
	if (el === null) {
		return;
	}
	el.textContent = `FPS ${fps.toFixed(1)}  ·  CPU ${cpuMs.toFixed(2)} ms / frame (submit まで)`;
}

function updateScene(renderer: DemoState, frame: FrameState): void {
	renderer.frame = frame.frameIndex;
	updateAndDrainGlobalTransforms(renderer, renderer.frame * 0.018);
}

function renderCurrentFrame(renderer: DemoState): void {
	const frameStart = performance.now();
	const fps =
		renderer.lastFrameStartMs >= 0
			? 1000 / Math.max(frameStart - renderer.lastFrameStartMs, 1.0e-9)
			: 0;
	renderer.lastFrameStartMs = frameStart;

	const colorView =
		renderer.snapshotColorView ?? renderer.context.getCurrentTexture().createView();
	renderScene(renderer, renderer.scene, colorView);
	updatePerfOverlay(fps, performance.now() - frameStart);
}

function renderScene(
	renderer: DemoState,
	scene: Scene<World, Camera>,
	colorView: GPUTextureView,
): void {
	const camera = scene.mainCamera();
	if (camera === null) {
		throw new Error("renderScene requires Scene.mainCamera.");
	}
	renderer.queue.writeBuffer(renderer.cameraUniform, 0, camera.uniformBytes());
	const depthView = renderer.snapshotDepthView ?? renderer.depthView;
	const encoder = renderer.device.createCommandEncoder();
	const pass = encoder.beginRenderPass({
		colorAttachments: [
			{
				view: colorView,
				clearValue: { r: 0.03, g: 0.04, b: 0.09, a: 1 },
				loadOp: "clear",
				storeOp: "store",
			},
		],
		depthStencilAttachment: {
			view: depthView,
			depthClearValue: 1,
			depthLoadOp: "clear",
			depthStoreOp: "store",
		},
	});
	pass.setPipeline(renderer.pipeline);
	pass.setBindGroup(0, renderer.bindTransforms);
	pass.setBindGroup(1, renderer.bindCamera);
	pass.setIndexBuffer(renderer.indexBuffer, "uint16", 0, INDEX_U16_COUNT * 2);
	pass.setVertexBuffer(0, renderer.vertexBuffer, 0, VERTS_PER_CUBE * VERTEX_STRIDE_LOCAL);
	pass.setVertexBuffer(1, renderer.instanceBuffer, 0, ENTITY_COUNT * INSTANCE_STRIDE);
	pass.drawIndexed(INDEX_U16_COUNT, ENTITY_COUNT);
	pass.end();
	renderer.queue.submit([encoder.finish()]);
}

function releaseDemoState(renderer: DemoState): void {
	renderer.depthTexture.destroy();
	renderer.vertexBuffer.destroy();
	renderer.instanceBuffer.destroy();
	renderer.indexBuffer.destroy();
	renderer.transformStorage.destroy();
	renderer.cameraUniform.destroy();
}

export async function renderTsEcsMassCubesBrowserSnapshot(): Promise<Uint8Array> {
	const canvas = document.createElement("canvas");
	canvas.width = CANVAS_WIDTH;
	canvas.height = CANVAS_HEIGHT;
	const engine = await Engine.create(canvas, {
		mainScene: new Scene<World, Camera>("ts-ecs-mass-cubes"),
	});
	const renderer = createDemoStateForEngine(engine, "rgba8unorm");
	const app = createApp(renderer);
	engine.initializeApp(app);
	const target = createRgba8ReadbackTarget(renderer.device, CANVAS_WIDTH, CANVAS_HEIGHT);
	try {
		renderer.snapshotColorView = target.view;
		renderer.snapshotDepthView = target.depthView;
		engine.tick(app);
		renderer.snapshotColorView = undefined;
		renderer.snapshotDepthView = undefined;
		return await readRgba8Texture(
			renderer.device,
			renderer.queue,
			target.texture,
			CANVAS_WIDTH,
			CANVAS_HEIGHT,
		);
	} finally {
		renderer.snapshotColorView = undefined;
		renderer.snapshotDepthView = undefined;
		engine.shutdownApp(app);
		destroyReadbackTarget(target);
	}
}

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", () => {
		const canvas = document.getElementById("webgpu-canvas");
		if (!(canvas instanceof HTMLCanvasElement)) {
			document.body.innerHTML = "<h1>Missing WebGPU canvas.</h1>";
			return;
		}
		void Engine.create(canvas, {
			mainScene: new Scene<World, Camera>("ts-ecs-mass-cubes"),
		})
			.then((engine) => {
				const renderer = createDemoStateForEngine(engine);
				const app = createApp(renderer);
				engine.initializeApp(app);
				const loop = () => {
					engine.tick(app);
					requestAnimationFrame(loop);
				};
				requestAnimationFrame(loop);
			})
			.catch((error: unknown) => {
				console.error("Failed to initialize WebGPU:", error);
				document.body.innerHTML =
					"<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
			});
	});
}
