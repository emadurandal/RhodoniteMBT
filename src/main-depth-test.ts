import "./style.css";
import {
	create_webgpu_demo_state,
	depth_test_render_tick,
} from "../_build/js/debug/build/emadurandal/rhodonite_examples/depth-test/js/main/main.js";

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", async () => {
		try {
			const canvas = document.getElementById(
				"webgpu-canvas",
			) as HTMLCanvasElement;

			await create_webgpu_demo_state(canvas);

			let previousTimestamp: number | null = null;
			const loop = (timestamp: number) => {
				const deltaSeconds =
					previousTimestamp === null
						? 0
						: (timestamp - previousTimestamp) / 1000;
				previousTimestamp = timestamp;
				depth_test_render_tick(deltaSeconds);
				requestAnimationFrame(loop);
			};
			requestAnimationFrame(loop);
		} catch (error) {
			console.error("Failed to initialize WebGPU:", error);
			document.body.innerHTML =
				"<h1>Failed to initialize WebGPU. Check the console for errors.</h1>";
		}
	});
}
