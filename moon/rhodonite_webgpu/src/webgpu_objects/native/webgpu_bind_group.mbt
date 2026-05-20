/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `bindGroupLayout_release`.
pub fn bindGroupLayout_release(layout : GPUBindGroupLayout) -> Unit {
  layout.raw.release_raw()
}

///|
/// Implements `bindGroup_release`.
pub fn bindGroup_release(group : GPUBindGroup) -> Unit {
  group.raw.release_raw()
}
