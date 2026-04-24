import "./style.css";
import { create_webgpu_renderer } from "../moon/_build/js/debug/build/cmd/main/main.js";

// Check for WebGPU support
if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	// Initialize the WebGPU renderer when the page loads
	window.addEventListener("load", async () => {
		try {
			// Get GPU
			const gpu = navigator.gpu;

			// Request adapter
			const adapter = await gpu.requestAdapter();
			if (!adapter) {
				throw new Error("No appropriate GPUAdapter found");
			}

			// Request device
			const device = await adapter.requestDevice();

			// Get canvas and context
			const canvas = document.getElementById(
				"webgpu-canvas",
			) as HTMLCanvasElement;
			const context = canvas.getContext("webgpu");
			if (!context) {
				throw new Error("Failed to get WebGPU context");
			}

			// Get preferred canvas format
			const format = gpu.getPreferredCanvasFormat();

			// Configure the context
			context.configure({
				device,
				format,
				alphaMode: "premultiplied",
			});

			// Call MoonBit renderer with initialized WebGPU objects
			create_webgpu_renderer(device, context, format);
		} catch (error) {
			console.error("Failed to initialize WebGPU:", error);
			document.body.innerHTML =
				"<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
		}
	});
}
