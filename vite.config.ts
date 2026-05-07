import { defineConfig } from "vite";

export default defineConfig({
	build: {
		rollupOptions: {
			input: {
				basicTriangle: "demos/basic-triangle.html",
				triangleWithVertexBuffer: "demos/triangle-with-vertexbuffer.html",
			},
		},
	},
});
