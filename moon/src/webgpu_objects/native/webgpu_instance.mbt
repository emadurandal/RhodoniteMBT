///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  { instance: GPU::{ raw: @wgpu.Instance::create() } }
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
  ignore(instance)
  "bgra8unorm"
}

///|
pub async fn webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  native_webgpu_instance_request_adapter(instance)
}

///|
pub fn native_webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  WebGPUAdapter::new(GPUAdapter::{
    raw: instance.instance.raw.request_adapter_sync(),
    instance: instance.instance.raw,
  })
}

///|
pub fn webgpu_instance_process_events(instance : WebGPUInstance) -> Unit {
  instance.instance.raw.process_events()
}

///|
pub fn webgpu_instance_release(instance : WebGPUInstance) -> Unit {
  instance.instance.raw.release()
}
