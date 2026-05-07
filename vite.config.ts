import { defineConfig } from "vite";

export default defineConfig({
	build: {
		rollupOptions: {
			input: {
				basicTriangle: "basic-triangle.html",
				triangleWithVertexBuffer: "triangle-with-vertexbuffer.html",
			},
		},
	},
});
