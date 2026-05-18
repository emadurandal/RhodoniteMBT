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
				basicTriangle: "demos/basic-triangle.html",
				ecsMassCubes: "demos/ecs-mass-cubes.html",
				ecsSceneGraph: "demos/ecs-scene-graph.html",
				tsEcsMassCubes: "demos/ts-ecs-mass-cubes.html",
				triangleWithBuffer: "demos/triangle-with-buffer.html",
				wasmEcsMassCubes: "demos/wasm-ecs-mass-cubes.html",
				wasmGcEcsMassCubes: "demos/wasm-gc-ecs-mass-cubes.html",
			},
		},
	},
});
