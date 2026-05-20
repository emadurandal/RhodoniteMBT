/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `textureView_release`.
pub fn textureView_release(view : GPUTextureView) -> Unit {
  view.raw.release()
}
