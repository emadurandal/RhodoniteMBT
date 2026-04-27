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
pub fn WebGPUAdapter::get(self : WebGPUAdapter) -> GPUAdapter {
  self.adapter
}

///|
pub async fn WebGPUAdapter::requestDevice(
  self : WebGPUAdapter,
) -> JsWebGPUDevice {
  let device = @js_async.Promise::wait(gpu_requestDevice(self.adapter))
  JsWebGPUDevice::new(device)
}
