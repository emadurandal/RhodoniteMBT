///

///|
/// Defines `WebGPUInstance`.
pub struct WebGPUInstance {
  instance : GPU
}

///|
/// Implements `WebGPUInstance::new`.
pub fn WebGPUInstance::new(instance : GPU) -> WebGPUInstance {
  { instance, }
}

///|
/// Implements `create_webgpu_instance`.
pub fn create_webgpu_instance(instance : GPU) -> WebGPUInstance {
  WebGPUInstance::new(instance)
}

///|
/// Implements `webgpu_instance_get_preferred_canvas_format`.
pub fn webgpu_instance_get_preferred_canvas_format(
  instance : WebGPUInstance,
) -> String {
  gpu_getPreferredCanvasFormat(instance.instance)
}

///|
/// Implements `webgpu_instance_get_preferred_canvas_format_for_surface`.
pub fn webgpu_instance_get_preferred_canvas_format_for_surface(
  instance : WebGPUInstance,
  adapter : WebGPUAdapter,
  canvas : WebGPUCanvasContext,
) -> String {
  ignore(adapter)
  ignore(canvas)
  gpu_getPreferredCanvasFormat(instance.instance)
}

///|
pub async fn webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter {
  let adapter = @js_async.Promise::wait(gpu_requestAdapter(instance.instance))
  WebGPUAdapter::new(adapter)
}
