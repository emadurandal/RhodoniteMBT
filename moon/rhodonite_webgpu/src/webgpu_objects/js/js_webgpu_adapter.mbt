// WebGPU adapter implementation

///|
pub struct WebGPUAdapter {
  adapter : GPUAdapter
}

///|
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
