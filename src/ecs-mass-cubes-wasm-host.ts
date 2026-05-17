import "./style.css";
import {
	createCameraWordsBuffer,
	createGlobalTransformWordsBuffer,
	uploadGlobalTransformBytes,
} from "../moon/rhodonite_core/src/ecs/ts/index.ts";
import {
	createRgba8ReadbackTarget,
	destroyReadbackTarget,
	readRgba8Texture,
} from "./visual-regression/webgpu-readback";
import { InputState, MouseButton, installBrowserInputState } from "./app-runtime";
import {
	MASS_CUBES_CANVAS_HEIGHT,
	MASS_CUBES_CANVAS_WIDTH,
	MASS_CUBES_CUBE_SCALE,
	MASS_CUBES_ENTITY_COUNT,
	MASS_CUBES_GRID_SPACING,
	createMassCubesInstanceBytesFromRefs,
	createMassCubesRenderResourcesFromCameraStorage,
	gridSideLen,
	renderMassCubesScene,
	type MassCubesRenderResources,
} from "./ecs-mass-cubes-renderer";
import {
	createMassCubesHalfArray,
	writeHalf,
	writeMassCubesDenseYTransformWaveToArrays,
} from "./ecs-mass-cubes-transform-writer";
import { requestLargeStorageBufferDevice } from "./webgpu-device-limits";

type GlobalTransformPrecisionMode =
	| "all-f32"
	| "all-f16"
	| "first-half-f32-second-half-f16"
	| "even-id-f32-odd-id-f16";
const GLOBAL_TRANSFORM_PRECISION_MODE: GlobalTransformPrecisionMode = "all-f16";
const GLOBAL_TRANSFORM_FORMAT_F32 = 0;
const GLOBAL_TRANSFORM_FORMAT_F16 = 1;
const TRANSFORM_WORDS_PER_ENTITY_F16 = 6;
const TRANSFORM_WORDS_PER_ENTITY_F32 = 12;
const CAMERA_WORD_COUNT = 72;

type TransformLayout = {
	readonly refs: Uint32Array;
	readonly wordCapacity: number;
	readonly uploadFirstWord: number;
	readonly uploadWordCount: number;
};

type DemoState = {
	readonly context: GPUCanvasContext;
	readonly device: GPUDevice;
	readonly queue: GPUQueue;
	readonly render: MassCubesRenderResources;
	readonly transformStorage: GPUBuffer;
	readonly input: InputState;
	readonly transformRefs: Uint32Array;
	readonly transformBytes: Uint8Array;
	readonly transformWords: Uint32Array;
	readonly transformFloats: Float32Array;
	readonly transformHalves: ReturnType<typeof createMassCubesHalfArray>;
	readonly cameraBytes: Uint8Array;
	readonly cameraWords: Uint32Array;
	readonly transformWordUploadFirst: number;
	readonly transformWordUploadCount: number;
	perSide: number;
	transformStride: number;
	snapshotColorView?: GPUTextureView;
	snapshotDepthView?: GPUTextureView;
	wasmTransformUploadBuffer?: ArrayBufferLike;
	wasmTransformUploadPtr?: number;
	wasmTransformUploadByteLength?: number;
	wasmTransformUploadView?: Uint8Array;
};

type WasmExports = {
	_start?: () => void;
	memory?: WebAssembly.Memory;
	create_wasm_demo_state: () => void;
	ecs_mass_cubes_wasm_update_tick: () => void;
	ecs_mass_cubes_wasm_render_extract: () => void;
	ecs_mass_cubes_wasm_render: () => void;
	ecs_mass_cubes_wasm_render_tick: () => void;
};

function entityUsesF32(entityIndex: number): boolean {
	switch (GLOBAL_TRANSFORM_PRECISION_MODE) {
		case "all-f32":
			return true;
		case "all-f16":
			return false;
		case "first-half-f32-second-half-f16":
			return entityIndex < Math.floor(MASS_CUBES_ENTITY_COUNT / 2);
		case "even-id-f32-odd-id-f16":
			return (entityIndex & 1) === 0;
	}
}

function transformWordsForFormat(format: number): number {
	return format === GLOBAL_TRANSFORM_FORMAT_F16
		? TRANSFORM_WORDS_PER_ENTITY_F16
		: TRANSFORM_WORDS_PER_ENTITY_F32;
}

function createTransformLayout(): TransformLayout {
	const refs = new Uint32Array(MASS_CUBES_ENTITY_COUNT * 2);
	let nextWord = 0;
	if (GLOBAL_TRANSFORM_PRECISION_MODE === "all-f32") {
		for (let i = 0; i < MASS_CUBES_ENTITY_COUNT; i += 1) {
			const refBase = i * 2;
			refs[refBase] = GLOBAL_TRANSFORM_FORMAT_F32;
			refs[refBase + 1] = i * TRANSFORM_WORDS_PER_ENTITY_F32;
		}
		nextWord = MASS_CUBES_ENTITY_COUNT * TRANSFORM_WORDS_PER_ENTITY_F32;
	} else {
		for (let i = 0; i < MASS_CUBES_ENTITY_COUNT; i += 1) {
			const refBase = i * 2;
			refs[refBase] = GLOBAL_TRANSFORM_FORMAT_F16;
			refs[refBase + 1] = i * TRANSFORM_WORDS_PER_ENTITY_F16;
		}
		nextWord = MASS_CUBES_ENTITY_COUNT * TRANSFORM_WORDS_PER_ENTITY_F16;
		if (GLOBAL_TRANSFORM_PRECISION_MODE !== "all-f16") {
			for (let i = 0; i < MASS_CUBES_ENTITY_COUNT; i += 1) {
				if (entityUsesF32(i)) {
					const refBase = i * 2;
					refs[refBase] = GLOBAL_TRANSFORM_FORMAT_F32;
					refs[refBase + 1] = nextWord;
					nextWord += TRANSFORM_WORDS_PER_ENTITY_F32;
				}
			}
		}
	}
	let firstWord = Number.POSITIVE_INFINITY;
	let endWord = 0;
	for (let i = 0; i < MASS_CUBES_ENTITY_COUNT; i += 1) {
		const refBase = i * 2;
		const wordOffset = refs[refBase + 1] ?? 0;
		const wordEnd = wordOffset + transformWordsForFormat(refs[refBase] ?? 0);
		firstWord = Math.min(firstWord, wordOffset);
		endWord = Math.max(endWord, wordEnd);
	}
	return {
		refs,
		wordCapacity: nextWord,
		uploadFirstWord: Number.isFinite(firstWord) ? firstWord : 0,
		uploadWordCount: Number.isFinite(firstWord) ? Math.max(endWord - firstWord, 0) : 0,
	};
}

function writeMassCubesFullTransformData(
	demoState: DemoState,
	perSide: number,
	waveTime: number,
): void {
	const refs = demoState.transformRefs;
	const words = demoState.transformWords;
	const floats = demoState.transformFloats;
	const halves = demoState.transformHalves;
	const uploadFirstWord = demoState.transformWordUploadFirst;
	const half = (perSide - 1) * 0.5;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let localIndex = 0;
	let row = 0;
	let column = 0;
	while (localIndex < MASS_CUBES_ENTITY_COUNT) {
		const rowCount = Math.min(perSide - column, MASS_CUBES_ENTITY_COUNT - localIndex);
		let x = (column - half) * MASS_CUBES_GRID_SPACING;
			const z = (row - half) * MASS_CUBES_GRID_SPACING;
			let waveSin = Math.sin(localIndex * 0.09 + waveTime);
			let waveCos = Math.cos(localIndex * 0.09 + waveTime);
			for (let ix = 0; ix < rowCount; ix += 1) {
				const refBase = localIndex * 2;
				const format = refs[refBase] ?? 0;
				const wordOffset = (refs[refBase + 1] ?? 0) - uploadFirstWord;
				const y = waveSin * 0.12;
				if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
					const out = wordOffset * 2;
					writeHalf(halves, out, MASS_CUBES_CUBE_SCALE);
					writeHalf(halves, out + 1, 0);
					writeHalf(halves, out + 2, 0);
					writeHalf(halves, out + 3, x);
					writeHalf(halves, out + 4, 0);
					writeHalf(halves, out + 5, MASS_CUBES_CUBE_SCALE);
					writeHalf(halves, out + 6, 0);
					writeHalf(halves, out + 7, y);
					writeHalf(halves, out + 8, 0);
					writeHalf(halves, out + 9, 0);
					writeHalf(halves, out + 10, MASS_CUBES_CUBE_SCALE);
					writeHalf(halves, out + 11, z);
				} else {
					floats[wordOffset] = MASS_CUBES_CUBE_SCALE;
					words[wordOffset + 1] = 0;
					words[wordOffset + 2] = 0;
					floats[wordOffset + 3] = x;
					words[wordOffset + 4] = 0;
					floats[wordOffset + 5] = MASS_CUBES_CUBE_SCALE;
					words[wordOffset + 6] = 0;
					floats[wordOffset + 7] = y;
					words[wordOffset + 8] = 0;
					words[wordOffset + 9] = 0;
					floats[wordOffset + 10] = MASS_CUBES_CUBE_SCALE;
					floats[wordOffset + 11] = z;
				}

			const nextSin = waveSin * cosStep + waveCos * sinStep;
			waveCos = waveCos * cosStep - waveSin * sinStep;
			waveSin = nextSin;
			localIndex += 1;
			x += MASS_CUBES_GRID_SPACING;
		}
		row += 1;
		column = 0;
	}
}

function writeMassCubesYTransformData(demoState: DemoState, waveTime: number): void {
	const floats = demoState.transformFloats;
	const halves = demoState.transformHalves;
	if (GLOBAL_TRANSFORM_PRECISION_MODE === "all-f16") {
		writeMassCubesDenseYTransformWaveToArrays(
			floats,
			halves,
			MASS_CUBES_ENTITY_COUNT,
			demoState.transformWordUploadFirst,
			TRANSFORM_WORDS_PER_ENTITY_F16,
			GLOBAL_TRANSFORM_FORMAT_F16,
			waveTime,
		);
		return;
	}
	if (GLOBAL_TRANSFORM_PRECISION_MODE === "all-f32") {
		writeMassCubesDenseYTransformWaveToArrays(
			floats,
			halves,
			MASS_CUBES_ENTITY_COUNT,
			demoState.transformWordUploadFirst,
			TRANSFORM_WORDS_PER_ENTITY_F32,
			GLOBAL_TRANSFORM_FORMAT_F32,
			waveTime,
		);
		return;
	}
	const refs = demoState.transformRefs;
	const uploadFirstWord = demoState.transformWordUploadFirst;
	const sinStep = Math.sin(0.09);
	const cosStep = Math.cos(0.09);
	let waveSin = Math.sin(waveTime);
	let waveCos = Math.cos(waveTime);
	let localIndex = 0;
	while (localIndex < MASS_CUBES_ENTITY_COUNT) {
		const refBase = localIndex * 2;
		const format = refs[refBase] ?? 0;
		const wordOffset = (refs[refBase + 1] ?? 0) - uploadFirstWord;
		const y = waveSin * 0.12;
		if (format === GLOBAL_TRANSFORM_FORMAT_F16) {
			writeHalf(halves, wordOffset * 2 + 7, y);
		} else {
			floats[wordOffset + 7] = y;
		}
		const nextSin = waveSin * cosStep + waveCos * sinStep;
		waveCos = waveCos * cosStep - waveSin * sinStep;
		waveSin = nextSin;
		localIndex += 1;
	}
}

function writeWasmBytesToBuffer(
	queue: GPUQueue,
	gpuBuffer: GPUBuffer,
	memory: WebAssembly.Memory | undefined,
	ptr: number,
	byteLength: number,
	getCached: () => {
		buffer?: ArrayBufferLike;
		ptr?: number;
		byteLength?: number;
		view?: Uint8Array;
	},
	setCached: (
		buffer: ArrayBufferLike,
		ptr: number,
		byteLength: number,
		view: Uint8Array,
	) => void,
): void {
	if (memory === undefined) {
		throw new Error("WASM linear memory is not exported.");
	}
	if (ptr <= 0 || byteLength <= 0) {
		throw new Error(`Invalid WASM transform byte range: ${ptr}, ${byteLength}`);
	}
	const buffer = memory.buffer;
	const cached = getCached();
	let view = cached.view;
	if (
		view === undefined ||
		cached.buffer !== buffer ||
		cached.ptr !== ptr ||
		cached.byteLength !== byteLength
	) {
		view = new Uint8Array(buffer, ptr, byteLength);
		setCached(buffer, ptr, byteLength, view);
	}
	uploadGlobalTransformBytes(queue, gpuBuffer, view);
}

function writeTransformBytesFromWasmMemory(
	demoState: DemoState,
	memory: WebAssembly.Memory | undefined,
	ptr: number,
	byteLength: number,
): void {
	writeWasmBytesToBuffer(
		demoState.queue,
		demoState.transformStorage,
		memory,
		ptr,
		byteLength,
		() => ({
			buffer: demoState.wasmTransformUploadBuffer,
			ptr: demoState.wasmTransformUploadPtr,
			byteLength: demoState.wasmTransformUploadByteLength,
			view: demoState.wasmTransformUploadView,
		}),
		(buffer, cachedPtr, cachedByteLength, view) => {
			demoState.wasmTransformUploadBuffer = buffer;
			demoState.wasmTransformUploadPtr = cachedPtr;
			demoState.wasmTransformUploadByteLength = cachedByteLength;
			demoState.wasmTransformUploadView = view;
		},
	);
}

async function createDemoState(
	canvas: HTMLCanvasElement,
	renderFormat?: GPUTextureFormat,
): Promise<DemoState> {
	const adapter = await navigator.gpu.requestAdapter();
	if (adapter === null) {
		throw new Error("WebGPU adapter is not available.");
	}
	const device = await requestLargeStorageBufferDevice(adapter);
	const queue = device.queue;
	const context = canvas.getContext("webgpu");
	if (context === null) {
		throw new Error("WebGPU canvas context is not available.");
	}
	const format = navigator.gpu.getPreferredCanvasFormat();
	context.configure({ device, format, alphaMode: "opaque" });
	const targetFormat = renderFormat ?? format;

	const transformLayout = createTransformLayout();
	const transformStorage = createGlobalTransformWordsBuffer(
		device,
		transformLayout.wordCapacity,
	);
	const cameraStorage = createCameraWordsBuffer(device, CAMERA_WORD_COUNT);
	const render = createMassCubesRenderResourcesFromCameraStorage({
		device,
		queue,
		targetFormat,
		transformStorage,
		cameraStorage,
		instanceData: createMassCubesInstanceBytesFromRefs(transformLayout.refs),
	});

	const transformBytes = new Uint8Array(transformLayout.uploadWordCount * 4);
	const transformWords = new Uint32Array(
		transformBytes.buffer,
		transformBytes.byteOffset,
		transformBytes.byteLength >>> 2,
	);
	const transformFloats = new Float32Array(
		transformBytes.buffer,
		transformBytes.byteOffset,
		transformBytes.byteLength >>> 2,
	);
	const transformHalves = createMassCubesHalfArray(transformBytes);
	const cameraBytes = new Uint8Array(CAMERA_WORD_COUNT * 4);
	const cameraWords = new Uint32Array(
		cameraBytes.buffer,
		cameraBytes.byteOffset,
		cameraBytes.byteLength >>> 2,
	);
	return {
		context,
		device,
		queue,
		render,
		transformStorage,
		input: new InputState(),
		transformRefs: transformLayout.refs,
		transformBytes,
		transformWords,
		transformFloats,
		transformHalves,
		cameraBytes,
		cameraWords,
		transformWordUploadFirst: transformLayout.uploadFirstWord,
		transformWordUploadCount: transformLayout.uploadWordCount,
		perSide: gridSideLen(MASS_CUBES_ENTITY_COUNT),
		transformStride: 0,
		snapshotColorView: undefined,
		snapshotDepthView: undefined,
	};
}

function updatePerfOverlay(label: string, fps: number, cpuMs: number): void {
	const el = document.getElementById("ecs-mass-cubes-perf");
	if (el === null) {
		return;
	}
	el.textContent = `FPS ${fps.toFixed(1)}  ·  ${label} ${cpuMs.toFixed(2)} ms / frame (submit まで)`;
}

function createHostImports(
	demoState: DemoState,
	label: string,
	getMemory: () => WebAssembly.Memory | undefined,
): WebAssembly.Imports {
	return {
		rhodonite_ecs_mass_cubes_host: {
			now_ms: () => performance.now(),
			initialize_demo_state: (perSide: number, transformStride: number) => {
				demoState.perSide = perSide;
				demoState.transformStride = transformStride;
			},
			write_initial_global_transforms: (perSide: number, waveTime: number) => {
				writeMassCubesFullTransformData(demoState, perSide, waveTime);
				uploadGlobalTransformBytes(
					demoState.queue,
					demoState.transformStorage,
					demoState.transformBytes,
					demoState.transformWordUploadFirst * 4,
				);
			},
			write_global_transform_y: (waveTime: number) => {
				writeMassCubesYTransformData(demoState, waveTime);
				uploadGlobalTransformBytes(
					demoState.queue,
					demoState.transformStorage,
					demoState.transformBytes,
					demoState.transformWordUploadFirst * 4,
				);
			},
			write_initial_global_transform_bytes: (ptr: number, byteLength: number) => {
				writeTransformBytesFromWasmMemory(demoState, getMemory(), ptr, byteLength);
			},
			write_global_transform_bytes: (ptr: number, byteLength: number) => {
				writeTransformBytesFromWasmMemory(demoState, getMemory(), ptr, byteLength);
			},
			begin_input_frame: () => {
				demoState.input.beginFrame();
			},
			input_mouse_down: (button: number) =>
				demoState.input.mouseDown(button === 1 ? MouseButton.Middle : MouseButton.Left),
			input_mouse_pressed: (button: number) =>
				demoState.input.mousePressed(button === 1 ? MouseButton.Middle : MouseButton.Left),
			input_pointer_delta_x: () => demoState.input.pointerDeltaX(),
			input_pointer_delta_y: () => demoState.input.pointerDeltaY(),
			input_wheel_delta_y: () => demoState.input.wheelDeltaY(),
			write_camera_word: (wordIndex: number, word: number) => {
				if (wordIndex < 0 || wordIndex >= demoState.cameraWords.length) {
					throw new RangeError(`camera word index out of range: ${wordIndex}`);
				}
				demoState.cameraWords[wordIndex] = word >>> 0;
			},
			upload_camera_words: () => {
				demoState.queue.writeBuffer(
					demoState.render.cameraBuffer,
					0,
					demoState.cameraBytes,
				);
			},
			render_demo_frame: (fps: number, cpuMs: number) => {
				const colorView =
					demoState.snapshotColorView ??
					demoState.context.getCurrentTexture().createView();
				renderMassCubesScene({
					device: demoState.device,
					queue: demoState.queue,
					render: demoState.render,
					colorView,
					depthView: demoState.snapshotDepthView,
				});
				updatePerfOverlay(label, fps, cpuMs);
			},
		},
	};
}

function runWasmRenderFrame(wasm: WasmExports): void {
	wasm.ecs_mass_cubes_wasm_update_tick();
	wasm.ecs_mass_cubes_wasm_render_extract();
	wasm.ecs_mass_cubes_wasm_render();
}

async function instantiateWasm(
	demoState: DemoState,
	wasmUrl: string,
	label: string,
): Promise<WasmExports> {
	const bytes = await fetch(wasmUrl).then((response) => {
		if (!response.ok) {
			throw new Error(`Failed to fetch WASM module: ${response.status}`);
		}
		return response.arrayBuffer();
	});
	let memory: WebAssembly.Memory | undefined;
	const { instance } = await WebAssembly.instantiate(
		bytes,
		createHostImports(demoState, label, () => memory),
	);
	const exports = instance.exports as unknown as WasmExports;
	memory = exports.memory;
	return exports;
}

export function runEcsMassCubesWasmDemo(wasmUrl: string, label: string): void {
	if (!navigator.gpu) {
		document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
		return;
	}

	window.addEventListener("load", () => {
		const canvas = document.getElementById("webgpu-canvas");
		if (!(canvas instanceof HTMLCanvasElement)) {
			document.body.innerHTML = "<h1>Missing WebGPU canvas.</h1>";
			return;
		}
		void createDemoState(canvas)
			.then(async (demoState) => {
				installBrowserInputState(demoState.input, canvas);
				const wasm = await instantiateWasm(demoState, wasmUrl, label);
				wasm._start?.();
				wasm.create_wasm_demo_state();
				const loop = () => {
					runWasmRenderFrame(wasm);
					requestAnimationFrame(loop);
				};
				requestAnimationFrame(loop);
			})
			.catch((error: unknown) => {
				console.error("Failed to initialize WebGPU/WASM:", error);
				document.body.innerHTML =
					"<h1>Failed to initialize WebGPU/WASM. Check the console for errors.</h1>";
			});
	});
}

export async function renderEcsMassCubesWasmSnapshot(
	wasmUrl: string,
	label: string,
): Promise<Uint8Array> {
	if (!navigator.gpu) {
		throw new Error("WebGPU is not supported in this browser.");
	}
	const canvas = document.createElement("canvas");
	canvas.width = MASS_CUBES_CANVAS_WIDTH;
	canvas.height = MASS_CUBES_CANVAS_HEIGHT;
	const demoState = await createDemoState(canvas, "rgba8unorm");
	const target = createRgba8ReadbackTarget(demoState.device, MASS_CUBES_CANVAS_WIDTH, MASS_CUBES_CANVAS_HEIGHT);
	try {
		const wasm = await instantiateWasm(demoState, wasmUrl, label);
		wasm._start?.();
		wasm.create_wasm_demo_state();
		demoState.snapshotColorView = target.view;
		demoState.snapshotDepthView = target.depthView;
		runWasmRenderFrame(wasm);
		demoState.snapshotColorView = undefined;
		demoState.snapshotDepthView = undefined;
		return await readRgba8Texture(
			demoState.device,
			demoState.queue,
			target.texture,
			MASS_CUBES_CANVAS_WIDTH,
			MASS_CUBES_CANVAS_HEIGHT,
		);
	} finally {
		demoState.snapshotColorView = undefined;
		demoState.snapshotDepthView = undefined;
		destroyReadbackTarget(target);
	}
}
