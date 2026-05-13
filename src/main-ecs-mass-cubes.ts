import "./style.css";
import {
	create_webgpu_renderer,
	ecs_mass_cubes_render_tick,
} from "../_build/js/debug/build/emadurandal/rhodonite_examples/ecs-mass-cubes/js/main/main.js";

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", async () => {
		try {
			const canvas = document.getElementById(
				"webgpu-canvas",
			) as HTMLCanvasElement;

			await create_webgpu_renderer(canvas);

			const loop = () => {
				ecs_mass_cubes_render_tick();
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
