/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Browser / JS target: access the global `navigator.gpu` handle via the WebGPU stack.
pub fn navigatorGPU() -> @wgpu.GPU {
  @wgpu.navigatorGPU()
}
