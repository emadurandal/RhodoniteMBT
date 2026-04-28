///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn WebGPUInstance::create() -> WebGPUInstance raise Error {
  { instance: GPU::{ raw: @wgpu.Instance::create() } }
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
  ignore(self)
  "bgra8unorm"
}

///|
pub fn WebGPUInstance::requestAdapter(
  self : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  WebGPUAdapter::new(GPUAdapter::{
    raw: self.instance.raw.request_adapter_sync(),
    instance: self.instance.raw,
  })
}

///|
pub fn WebGPUInstance::processEvents(self : WebGPUInstance) -> Unit {
  self.instance.raw.process_events()
}

///|
pub fn WebGPUInstance::release(self : WebGPUInstance) -> Unit {
  self.instance.raw.release()
}
