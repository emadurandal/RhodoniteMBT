///

///|
pub struct JsWebGPUInstance {
  instance : GPU
}

///|
pub fn JsWebGPUInstance::new(instance : GPU) -> JsWebGPUInstance {
  { instance, }
}

///|
pub fn JsWebGPUInstance::get(self : JsWebGPUInstance) -> GPU {
  self.instance
}

///|
pub impl @traits.WebGPUInstance for JsWebGPUInstance with getPreferredCanvasFormat(
  self,
) {
  gpu_getPreferredCanvasFormat(self.instance)
}

///|
pub async fn JsWebGPUInstance::requestAdapter(
  self : JsWebGPUInstance,
) -> JsWebGPUAdapter {
  let adapter = @js_async.Promise::wait(gpu_requestAdapter(self.instance))
  JsWebGPUAdapter::new(adapter)
}
