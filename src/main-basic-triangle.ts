import "./style.css";
import { create_webgpu_renderer } from "../moon/webgpu-examples/_build/js/debug/build/basic-triangle/js/main/main.js";

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", async () => {
		try {
			const canvas = document.getElementById(
				"webgpu-canvas",
			) as HTMLCanvasElement;

			// `Promise::from_async` in MoonBit returns a JS Promise; await here
			// (adapter / device / configure run inside MoonBit with a valid coroutine)
			await create_webgpu_renderer(canvas);
		} catch (error) {
			console.error("Failed to initialize WebGPU:", error);
			document.body.innerHTML =
				"<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
		}
	});
}
