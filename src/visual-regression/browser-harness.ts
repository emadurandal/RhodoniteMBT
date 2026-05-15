const width = 800;
const height = 600;
const manifestPath =
	"/moon/rhodonite_examples/src/visual_regression/visual_samples.tsv";
const snapshotDir =
	"/moon/rhodonite_examples/src/visual_regression/__image_snapshots__/";
const resultEndpoint =
	new URLSearchParams(window.location.search).get("result") ??
	"/__rhodonite_visual_regression_browser__";

type VisualSampleManifestEntry = {
	target: string;
	id: string;
	name: string;
	filename: string;
	maxMismatchRate: number;
	perceptualThreshold: number;
};

type BrowserSnapshotSample = {
	name: string;
	filename: string;
	maxMismatchRate: number;
	perceptualThreshold: number;
	render: () => Promise<Uint8Array>;
};

type SampleResult = {
	name: string;
	filename: string;
	mismatches: number;
	mismatchRate: number;
};

type SampleFailure = {
	name: string;
	filename?: string;
	message: string;
};

type SnapshotUpdate = {
	filename: string;
	pngBase64: string;
};

type SnapshotModule = {
	render_basic_triangle_browser_snapshot: () => Promise<unknown>;
	render_triangle_with_buffer_browser_snapshot: () => Promise<unknown>;
	render_depth_test_browser_snapshot: () => Promise<unknown>;
	render_ecs_scene_graph_browser_snapshot: () => Promise<unknown>;
	render_ecs_mass_cubes_browser_snapshot: () => Promise<unknown>;
};

type TsMassCubesModule = {
	renderTsEcsMassCubesBrowserSnapshot: () => Promise<unknown>;
};

type WasmMassCubesModule = {
	renderEcsMassCubesWasmSnapshot: (
		wasmUrl: string,
		label: string,
	) => Promise<unknown>;
};

void main();

window.addEventListener("error", (event) => {
	void postResultPayload({
		ok: false,
		skipped: false,
		results: [],
		failures: [{ name: "browser harness", message: event.message }],
		updates: [],
	});
});

window.addEventListener("unhandledrejection", (event) => {
	const reason = event.reason;
	const message = reason instanceof Error ? reason.message : String(reason);
	void postResultPayload({
		ok: false,
		skipped: false,
		results: [],
		failures: [{ name: "browser harness", message }],
		updates: [],
	});
});

async function main(): Promise<void> {
	const update = new URLSearchParams(window.location.search).get("update") === "1";
	await postStatus("loaded");
	if (!navigator.gpu) {
		await postResultPayload({
			ok: true,
			skipped: true,
			reason: "Browser WebGPU is unavailable",
			results: [],
			failures: [],
			updates: [],
		});
		return;
	}

	let snapshotModule: SnapshotModule;
	try {
		await postStatus("importing MoonBit visual snapshot module");
		snapshotModule = await withTimeout(
			import(
				"../../_build/js/debug/build/emadurandal/rhodonite_examples/visual_regression_browser/js/main/main.js"
			) as Promise<SnapshotModule>,
			10000,
			"MoonBit browser visual snapshot module import timed out",
		);
		await postStatus("imported MoonBit visual snapshot module");
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		await postResultPayload({
			ok: false,
			skipped: false,
			results: [],
			failures: [{ name: "browser harness", message }],
			updates: [],
		});
		return;
	}

	const manifest = await loadVisualManifest("browser");
	const renderers = await createRendererRegistry(snapshotModule);
	const samples = createSamples(manifest, renderers);

	const results: SampleResult[] = [];
	const failures: SampleFailure[] = [];
	const updates: SnapshotUpdate[] = [];

	for (const sample of samples) {
		try {
			await postStatus(`rendering ${sample.name}`);
			const actual = await withTimeout(
				sample.render(),
				15000,
				`${sample.name} WebGPU readback timed out`,
			);
			await postStatus(`read back ${sample.name}`);
			if (actual.length !== width * height * 4) {
				throw new Error(
					`actual RGBA length ${actual.length} does not match ${width}x${height}`,
				);
			}

			if (update) {
				updates.push({
					filename: sample.filename,
					pngBase64: await rgbaToPngBase64(actual),
				});
				continue;
			}

			const expected = await loadExpectedRgba(sample.filename);
			const mismatches = countPerceptualMismatches(
				actual,
				expected,
				sample.perceptualThreshold,
			);
			const mismatchRate = mismatches / (width * height);
			results.push({
				name: sample.name,
				filename: sample.filename,
				mismatches,
				mismatchRate,
			});
			if (mismatchRate > sample.maxMismatchRate) {
				failures.push({
					name: sample.name,
					filename: sample.filename,
					message: `mismatch rate ${mismatchRate} exceeds ${sample.maxMismatchRate}: ${mismatches}/${width * height} pixels differ`,
				});
			}
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			if (isWebGpuUnavailableError(message)) {
				await postResultPayload({
					ok: true,
					skipped: true,
					reason: message,
					results,
					failures: [],
					updates,
				});
				return;
			}
			failures.push({ name: sample.name, filename: sample.filename, message });
		}
	}

	await postResultPayload({
		ok: failures.length === 0,
		skipped: false,
		results,
		failures,
		updates,
	});
}

function createSamples(
	manifest: VisualSampleManifestEntry[],
	renderers: Map<string, () => Promise<Uint8Array>>,
): BrowserSnapshotSample[] {
	return manifest.map((entry) => {
		const render = renderers.get(entry.id);
		if (!render) {
			throw new Error(`unknown browser visual regression sample id: ${entry.id}`);
		}
		return {
			name: entry.name,
			filename: entry.filename,
			maxMismatchRate: entry.maxMismatchRate,
			perceptualThreshold: entry.perceptualThreshold,
			render,
		};
	});
}

async function createRendererRegistry(
	snapshotModule: SnapshotModule,
): Promise<Map<string, () => Promise<Uint8Array>>> {
	const [tsModule, wasmHost, wasmModule, wasmGcModule] = await Promise.all([
		import("../main-ts-ecs-mass-cubes") as Promise<TsMassCubesModule>,
		import("../ecs-mass-cubes-wasm-host") as Promise<WasmMassCubesModule>,
		import(
			"../../_build/wasm/release/build/emadurandal/rhodonite_examples/ecs-mass-cubes/wasm/main/main.wasm?url"
		) as Promise<{ default: string }>,
		import(
			"../../_build/wasm-gc/release/build/emadurandal/rhodonite_examples/ecs-mass-cubes/wasm/main/main.wasm?url"
		) as Promise<{ default: string }>,
	]);
	return new Map<string, () => Promise<Uint8Array>>([
		[
			"basic-triangle",
			async () =>
				toUint8Array(await snapshotModule.render_basic_triangle_browser_snapshot()),
		],
		[
			"triangle-with-buffer",
			async () =>
				toUint8Array(
					await snapshotModule.render_triangle_with_buffer_browser_snapshot(),
				),
		],
		[
			"depth-test",
			async () =>
				toUint8Array(await snapshotModule.render_depth_test_browser_snapshot()),
		],
		[
			"ecs-scene-graph",
			async () =>
				toUint8Array(
					await snapshotModule.render_ecs_scene_graph_browser_snapshot(),
				),
		],
		[
			"ecs-mass-cubes",
			async () =>
				toUint8Array(await snapshotModule.render_ecs_mass_cubes_browser_snapshot()),
		],
		[
			"ts-ecs-mass-cubes",
			async () =>
				toUint8Array(await tsModule.renderTsEcsMassCubesBrowserSnapshot()),
		],
		[
			"wasm-ecs-mass-cubes",
			async () =>
				toUint8Array(
					await wasmHost.renderEcsMassCubesWasmSnapshot(
						wasmModule.default,
						"WASM",
					),
				),
		],
		[
			"wasm-gc-ecs-mass-cubes",
			async () =>
				toUint8Array(
					await wasmHost.renderEcsMassCubesWasmSnapshot(
						wasmGcModule.default,
						"WASM-GC",
					),
				),
		],
	]);
}

async function loadVisualManifest(
	target: string,
): Promise<VisualSampleManifestEntry[]> {
	const response = await fetch(`${manifestPath}?t=${Date.now()}`);
	if (!response.ok) {
		throw new Error(`visual regression manifest is missing: ${manifestPath}`);
	}
	const manifest = await response.text();
	const samples = parseVisualManifest(manifest, target);
	if (samples.length === 0) {
		throw new Error(`visual regression manifest has no samples for ${target}`);
	}
	return samples;
}

function parseVisualManifest(
	manifest: string,
	target: string,
): VisualSampleManifestEntry[] {
	return manifest
		.split("\n")
		.map((line) => line.trim())
		.filter((line) => line.length > 0 && !line.startsWith("#"))
		.map((line, index) => {
			const fields = line.split("\t");
			if (fields.length !== 6) {
				throw new Error(
					`visual regression manifest line ${index + 1} must have 6 TSV fields`,
				);
			}
			const [
				sampleTarget,
				id,
				name,
				filename,
				maxMismatchRate,
				perceptualThreshold,
			] = fields.map((field) => field.trim());
			return {
				target: sampleTarget,
				id,
				name,
				filename,
				maxMismatchRate: parseManifestNumber(
					maxMismatchRate,
					"max_mismatch_rate",
				),
				perceptualThreshold: parseManifestNumber(
					perceptualThreshold,
					"perceptual_threshold",
				),
			};
		})
		.filter((entry) => entry.target === target);
}

function parseManifestNumber(value: string, field: string): number {
	const parsed = Number(value);
	if (!Number.isFinite(parsed)) {
		throw new Error(`visual regression manifest ${field} is not a number: ${value}`);
	}
	return parsed;
}

function toUint8Array(value: unknown): Uint8Array {
	if (value instanceof Uint8Array) {
		return value;
	}
	if (value instanceof ArrayBuffer) {
		return new Uint8Array(value);
	}
	if (ArrayBuffer.isView(value)) {
		return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
	}
	throw new Error("MoonBit snapshot renderer did not return bytes");
}

async function loadExpectedRgba(filename: string): Promise<Uint8Array> {
	const response = await fetch(`${snapshotDir}${filename}?t=${Date.now()}`);
	if (!response.ok) {
		throw new Error(
			`PNG visual snapshot ${filename} is missing. Run pnpm run test:examples:visual:update:browser on a WebGPU-capable browser machine to generate it.`,
		);
	}
	const blob = await response.blob();
	const bitmap = await createImageBitmap(blob);
	if (bitmap.width !== width || bitmap.height !== height) {
		throw new Error(
			`PNG visual snapshot dimensions differ for ${filename}: expected ${bitmap.width}x${bitmap.height}, actual ${width}x${height}`,
		);
	}
	const canvas = new OffscreenCanvas(width, height);
	const ctx = canvas.getContext("2d");
	if (!ctx) {
		throw new Error("2D canvas context is unavailable");
	}
	ctx.drawImage(bitmap, 0, 0);
	return new Uint8Array(ctx.getImageData(0, 0, width, height).data);
}

async function rgbaToPngBase64(data: Uint8Array): Promise<string> {
	const canvas = new OffscreenCanvas(width, height);
	const ctx = canvas.getContext("2d");
	if (!ctx) {
		throw new Error("2D canvas context is unavailable");
	}
	ctx.putImageData(new ImageData(new Uint8ClampedArray(data), width, height), 0, 0);
	const blob = await canvas.convertToBlob({ type: "image/png" });
	const bytes = new Uint8Array(await blob.arrayBuffer());
	let binary = "";
	for (const byte of bytes) {
		binary += String.fromCharCode(byte);
	}
	return btoa(binary);
}

function countPerceptualMismatches(
	actual: Uint8Array,
	expected: Uint8Array,
	threshold: number,
): number {
	const maxDelta = 35215 * threshold * threshold;
	let mismatches = 0;
	for (let i = 0; i < actual.length; i += 4) {
		if (colorDelta(actual, expected, i) > maxDelta) {
			mismatches++;
		}
	}
	return mismatches;
}

function colorDelta(a: Uint8Array, b: Uint8Array, i: number): number {
	const r1 = a[i];
	const g1 = a[i + 1];
	const b1 = a[i + 2];
	const a1 = a[i + 3];
	const r2 = b[i];
	const g2 = b[i + 1];
	const b2 = b[i + 2];
	const a2 = b[i + 3];

	if (a1 !== a2) {
		return rgbaDeltaWithAlpha(r1, g1, b1, a1, r2, g2, b2, a2);
	}
	const dr = r1 - r2;
	const dg = g1 - g2;
	const db = b1 - b2;
	return yiqDelta(dr, dg, db);
}

function rgbaDeltaWithAlpha(
	r1: number,
	g1: number,
	b1: number,
	a1: number,
	r2: number,
	g2: number,
	b2: number,
	a2: number,
): number {
	const blend = (v: number, a: number) => 255 + (v - 255) * (a / 255);
	return yiqDelta(
		blend(r1, a1) - blend(r2, a2),
		blend(g1, a1) - blend(g2, a2),
		blend(b1, a1) - blend(b2, a2),
	);
}

function yiqDelta(dr: number, dg: number, db: number): number {
	const y = dr * 0.29889531 + dg * 0.58662247 + db * 0.11448223;
	const i = dr * 0.59597799 - dg * 0.2741761 - db * 0.32180189;
	const q = dr * 0.21147017 - dg * 0.52261711 + db * 0.31114694;
	return y * y * 0.5053 + i * i * 0.299 + q * q * 0.1957;
}

function isWebGpuUnavailableError(message: string): boolean {
	return /WebGPU|requestAdapter|No WebGPU adapter|navigator\.gpu|timed out/i.test(
		message,
	);
}

function withTimeout<T>(
	promise: Promise<T>,
	ms: number,
	message: string,
): Promise<T> {
	return new Promise((resolve, reject) => {
		const timer = window.setTimeout(() => reject(new Error(message)), ms);
		promise.then(
			(value) => {
				window.clearTimeout(timer);
				resolve(value);
			},
			(error) => {
				window.clearTimeout(timer);
				reject(error);
			},
		);
	});
}

async function postResult(body: unknown): Promise<void> {
	await fetch(resultEndpoint, {
		method: "POST",
		headers: { "content-type": "application/json" },
		body: JSON.stringify(body),
	});
}

async function postStatus(message: string): Promise<void> {
	await postResult({ type: "status", message });
}

async function postResultPayload(payload: Record<string, unknown>): Promise<void> {
	await postResult({ type: "result", ...payload });
}
