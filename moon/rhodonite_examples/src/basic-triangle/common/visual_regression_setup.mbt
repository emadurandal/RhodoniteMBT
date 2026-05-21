/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds basic-triangle state for visual regression render targets.
pub fn create_demo_state_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let pipeline = create_pipeline(device, format)
  { context, device, queue, pipeline }
}
