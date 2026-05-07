import { defineConfig } from "vite";

export default defineConfig({
	build: {
		rollupOptions: {
			input: {
				index: "index.html",
				basicTriangle: "basic-triangle.html",
				triangleWithVertexBuffer: "triangle-with-vertexbuffer.html",
			},
		},
	},
});
