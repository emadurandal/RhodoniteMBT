import "./style.css";
import { create_webgpu_demo_state } from "../_build/js/debug/build/emadurandal/rhodonite_examples/multi-surface-independent-input/js/main/main.js";

function requireCanvas(id: string): HTMLCanvasElement {
	const element = document.getElementById(id);
	if (!(element instanceof HTMLCanvasElement)) {
		throw new Error(`Missing canvas '${id}'.`);
	}
	return element;
}

window.addEventListener("load", () => {
	if (!navigator.gpu) {
		document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
		return;
	}
	const first = requireCanvas("webgpu-canvas-a");
	const second = requireCanvas("webgpu-canvas-b");
	Promise.resolve(create_webgpu_demo_state(first, second)).catch((error: unknown) => {
		console.error("Failed to initialize multi-surface demo:", error);
		document.body.innerHTML = "<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
	});
});
