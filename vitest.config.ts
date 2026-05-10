import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

const root = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
	resolve: {
		alias: {
			"@moon/rhodonite_core/math/js_bridge": path.join(
				root,
				"_build/js/release/build/emadurandal/rhodonite_core/math/js_bridge/js_bridge.js",
			),
		},
	},
	test: {
		environment: "node",
		include: ["moon/rhodonite_core/math/ts/**/*.test.ts"],
	},
});
