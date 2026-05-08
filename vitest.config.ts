import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

const root = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
	resolve: {
		alias: {
			"@moon/math/js_bridge": path.join(
				root,
				"moon/math/_build/js/release/build/js_bridge/js_bridge.js",
			),
		},
	},
	test: {
		environment: "node",
		include: ["moon/math/ts/**/*.test.ts"],
	},
});
