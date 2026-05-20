/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

// WebGPU adapter implementation

///|
/// Defines `WebGPUAdapter`.
pub struct WebGPUAdapter {
  adapter : GPUAdapter
}

///|
/// Implements `WebGPUAdapter::new`.
pub fn WebGPUAdapter::new(adapter : GPUAdapter) -> WebGPUAdapter {
  { adapter, }
}

///|
pub async fn webgpu_adapter_request_device(
  adapter : WebGPUAdapter,
) -> WebGPUDevice {
  let device = @js_async.Promise::wait(gpu_requestDevice(adapter.adapter))
  WebGPUDevice::new(device)
}
