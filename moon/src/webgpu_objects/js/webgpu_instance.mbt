///

///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn WebGPUInstance::new(instance : GPU) -> WebGPUInstance {
  { instance, }
}

///|
pub fn WebGPUInstance::get(self : WebGPUInstance) -> GPU {
  self.instance
}

///|
pub fn WebGPUInstance::getPreferredCanvasFormat(
  self : WebGPUInstance,
) -> String {
  gpu_getPreferredCanvasFormat(self.instance)
}

///|
pub async fn WebGPUInstance::requestAdapter(
  self : WebGPUInstance,
) -> JsWebGPUAdapter {
  let adapter = @js_async.Promise::wait(gpu_requestAdapter(self.instance))
  JsWebGPUAdapter::new(adapter)
}
