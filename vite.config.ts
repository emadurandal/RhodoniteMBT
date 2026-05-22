// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";

const root = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
	resolve: {
		alias: {
			"@moon/rhodonite_core/ecs/js_bridge": path.join(
				root,
				"_build/js/release/build/emadurandal/rhodonite_core/ecs/js_bridge/js_bridge.js",
			),
		},
	},
	build: {
		rollupOptions: {
			input: {
				basicTriangle: "samples/html/basic-triangle.html",
				ecsMassCubes: "samples/html/ecs-mass-cubes.html",
				ecsSceneGraph: "samples/html/ecs-scene-graph.html",
				ondemandTriangle: "samples/html/ondemand-triangle.html",
				tsEcsMassCubes: "samples/html/ts-ecs-mass-cubes.html",
				tsMultiSurfaceIndependentInput:
					"samples/html/ts-multi-surface-independent-input.html",
				tsOndemandTriangle: "samples/html/ts-ondemand-triangle.html",
				wasmEcsMassCubes: "samples/html/wasm-ecs-mass-cubes.html",
				wasmGcEcsMassCubes: "samples/html/wasm-gc-ecs-mass-cubes.html",
			},
		},
	},
});
