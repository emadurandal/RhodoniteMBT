// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
// SPDX-License-Identifier: Apache-2.0

import wasmUrl from "../_build/wasm/release/build/emadurandal/rhodonite_examples/ecs-mass-cubes/wasm/main/main.wasm?url";
import { runEcsMassCubesWasmDemo } from "./ecs-mass-cubes-wasm-host";

runEcsMassCubesWasmDemo(wasmUrl, "WASM CPU");
