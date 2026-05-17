import "./style.css";
import { runBrowserWebGpuCanvasDemo } from "./app-runtime";
import { create_webgpu_demo_state } from "../_build/js/debug/build/emadurandal/rhodonite_examples/basic-triangle/js/main/main.js";

runBrowserWebGpuCanvasDemo({ initialize: create_webgpu_demo_state });
