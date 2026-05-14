import wasmUrl from "../_build/wasm/debug/build/emadurandal/rhodonite_examples/ecs-mass-cubes/wasm/main/main.wasm?url";
import { runEcsMassCubesWasmDemo } from "./ecs-mass-cubes-wasm-host";

runEcsMassCubesWasmDemo(wasmUrl, "WASM CPU");
