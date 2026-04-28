///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn WebGPUInstance::create() -> WebGPUInstance raise Error {
  { instance: GPU::{ raw: @wgpu.Instance::create() } }
}

///|
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  WebGPUInstance::create()
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
  ignore(self)
  "bgra8unorm"
}

///|
pub fn webgpu_instance_get_preferred_canvas_format(
  instance : WebGPUInstance,
) -> String {
  instance.getPreferredCanvasFormat()
}

///|
fn request_native_webgpu_adapter(
  webgpu_instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  WebGPUAdapter::new(GPUAdapter::{
    raw: webgpu_instance.instance.raw.request_adapter_sync(),
    instance: webgpu_instance.instance.raw,
  })
}

///|
pub fn WebGPUInstance::requestAdapter(
  self : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  request_native_webgpu_adapter(self)
}

///|
pub async fn webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  instance.requestAdapter()
}

///|
pub fn native_webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  instance.requestAdapter()
}

///|
pub fn WebGPUInstance::processEvents(self : WebGPUInstance) -> Unit {
  self.instance.raw.process_events()
}

///|
pub fn webgpu_instance_process_events(instance : WebGPUInstance) -> Unit {
  instance.processEvents()
}

///|
pub fn WebGPUInstance::release(self : WebGPUInstance) -> Unit {
  self.instance.raw.release()
}

///|
pub fn webgpu_instance_release(instance : WebGPUInstance) -> Unit {
  instance.release()
}
