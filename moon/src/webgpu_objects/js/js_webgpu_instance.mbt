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
pub fn create_webgpu_instance(instance : GPU) -> WebGPUInstance {
  WebGPUInstance::new(instance)
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
pub fn webgpu_instance_get_preferred_canvas_format(
  instance : WebGPUInstance,
) -> String {
  instance.getPreferredCanvasFormat()
}

///|
async fn request_js_webgpu_adapter(
  webgpu_instance : WebGPUInstance,
) -> WebGPUAdapter {
  let adapter = @js_async.Promise::wait(
    gpu_requestAdapter(webgpu_instance.instance),
  )
  WebGPUAdapter::new(adapter)
}

///|
pub async fn WebGPUInstance::requestAdapter(
  self : WebGPUInstance,
) -> WebGPUAdapter {
  request_js_webgpu_adapter(self)
}

///|
pub async fn webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter {
  instance.requestAdapter()
}
