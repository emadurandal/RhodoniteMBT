/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `shaderModule_release`.
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  shaderModule.raw.release()
}
