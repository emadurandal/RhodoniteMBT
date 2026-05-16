import "./style.css";
import {
	create_webgpu_demo_state,
	ecs_scene_graph_render_tick,
} from "../_build/js/debug/build/emadurandal/rhodonite_examples/ecs-scene-graph/js/main/main.js";

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", async () => {
		try {
			const canvas = document.getElementById(
				"webgpu-canvas",
			) as HTMLCanvasElement;

			await create_webgpu_demo_state(canvas);

			const loop = () => {
				ecs_scene_graph_render_tick();
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
