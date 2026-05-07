import { defineConfig } from "vite";

export default defineConfig({
	build: {
		rollupOptions: {
			input: {
				basicTriangle: "demos/basic-triangle.html",
				triangleWithBuffer: "demos/triangle-with-buffer.html",
			},
		},
	},
});
