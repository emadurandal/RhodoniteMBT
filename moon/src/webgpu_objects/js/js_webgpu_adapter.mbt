// WebGPU adapter implementation

///|
pub struct JsWebGPUAdapter {
  adapter : GPUAdapter
}

///|
pub impl @traits.WebGPUAdapter for JsWebGPUAdapter

///|
pub fn JsWebGPUAdapter::new(adapter : GPUAdapter) -> JsWebGPUAdapter {
  { adapter, }
}

///|
pub fn JsWebGPUAdapter::get(self : JsWebGPUAdapter) -> GPUAdapter {
  self.adapter
}

///|
pub async fn JsWebGPUAdapter::requestDevice(
  self : JsWebGPUAdapter,
) -> JsWebGPUDevice {
  let device = @js_async.Promise::wait(gpu_requestDevice(self.adapter))
  JsWebGPUDevice::new(device)
}
