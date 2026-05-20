/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// WebGPU `GPULoadOp` (`"load"` \| `"clear"`).
pub(all) enum GPULoadOp {
  Load
  Clear
} derive(Eq)

///|
/// WebGPU `GPUStoreOp` (`"store"` \| `"discard"`).
pub(all) enum GPUStoreOp {
  Store
  Discard
} derive(Eq)
