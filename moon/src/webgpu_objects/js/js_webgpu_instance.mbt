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
pub fn webgpu_instance_get_preferred_canvas_format(
  instance : WebGPUInstance,
) -> String {
  gpu_getPreferredCanvasFormat(instance.instance)
}

///|
pub async fn webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter {
  let adapter = @js_async.Promise::wait(gpu_requestAdapter(instance.instance))
  WebGPUAdapter::new(adapter)
}
