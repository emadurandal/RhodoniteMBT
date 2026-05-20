/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// WebGPU `GPUPrimitiveTopology` (matches `primitive.topology`).
pub(all) enum GPUPrimitiveTopology {
  PointList
  LineList
  LineStrip
  TriangleList
  TriangleStrip
} derive(Eq)

///|
/// Tag for JS FFI `device_createRenderPipeline` (must match `TOPOLOGY_NAMES` indices).
pub fn GPUPrimitiveTopology::to_js_tag(self : GPUPrimitiveTopology) -> Int {
  match self {
    PointList => 0
    LineList => 1
    LineStrip => 2
    TriangleList => 3
    TriangleStrip => 4
  }
}
