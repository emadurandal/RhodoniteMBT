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
async fn request_js_webgpu_adapter(
  webgpu_instance : JsWebGPUInstance,
) -> JsWebGPUAdapter {
  let adapter = @js_async.Promise::wait(
    gpu_requestAdapter(webgpu_instance.instance),
  )
  JsWebGPUAdapter::new(adapter)
}

///|
pub async fn JsWebGPUInstance::requestAdapter(
  self : JsWebGPUInstance,
) -> JsWebGPUAdapter {
  request_js_webgpu_adapter(self)
}

///|
pub impl @traits.WebGPUInstance for JsWebGPUInstance with requestAdapter(self) {
  request_js_webgpu_adapter(self) as &@traits.WebGPUAdapter
}
