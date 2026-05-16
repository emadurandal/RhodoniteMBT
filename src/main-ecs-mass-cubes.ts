import "./style.css";
import {
	create_webgpu_demo_state,
	ecs_mass_cubes_input_focus_lost,
	ecs_mass_cubes_input_mouse_down,
	ecs_mass_cubes_input_mouse_up,
	ecs_mass_cubes_input_pointer_move,
	ecs_mass_cubes_input_wheel,
	ecs_mass_cubes_render_tick,
} from "../_build/js/debug/build/emadurandal/rhodonite_examples/ecs-mass-cubes/js/main/main.js";

function canvasPoint(canvas: HTMLCanvasElement, event: PointerEvent) {
	const rect = canvas.getBoundingClientRect();
	return {
		x: ((event.clientX - rect.left) * canvas.width) / rect.width,
		y: ((event.clientY - rect.top) * canvas.height) / rect.height,
	};
}

function installOrbitPointerInput(canvas: HTMLCanvasElement) {
	canvas.addEventListener("pointermove", (event) => {
		const point = canvasPoint(canvas, event);
		ecs_mass_cubes_input_pointer_move(point.x, point.y);
	});
	canvas.addEventListener("pointerdown", (event) => {
		event.preventDefault();
		canvas.setPointerCapture(event.pointerId);
		const point = canvasPoint(canvas, event);
		ecs_mass_cubes_input_mouse_down(event.button, point.x, point.y);
	});
	canvas.addEventListener("pointerup", (event) => {
		const point = canvasPoint(canvas, event);
		ecs_mass_cubes_input_mouse_up(event.button, point.x, point.y);
	});
	canvas.addEventListener("wheel", (event) => {
		event.preventDefault();
		ecs_mass_cubes_input_wheel(event.deltaX, event.deltaY);
	}, { passive: false });
	window.addEventListener("blur", () => {
		ecs_mass_cubes_input_focus_lost();
	});
}

if (!navigator.gpu) {
	document.body.innerHTML = "<h1>WebGPU is not supported in this browser.</h1>";
} else {
	window.addEventListener("load", async () => {
		try {
			const canvas = document.getElementById(
				"webgpu-canvas",
			) as HTMLCanvasElement;

			await create_webgpu_demo_state(canvas);
			installOrbitPointerInput(canvas);

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
