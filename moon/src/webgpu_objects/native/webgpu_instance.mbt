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
pub impl @traits.WebGPUInstance for WebGPUInstance with getPreferredCanvasFormat(
  self,
) {
  self.getPreferredCanvasFormat()
}

///|
pub impl @traits.WebGPUInstance for WebGPUInstance with requestAdapter(self) {
  let adapter = request_native_webgpu_adapter(self) catch {
    _ => abort("failed to request native WebGPU adapter")
  }
  adapter as &@traits.WebGPUAdapter
}

///|
pub fn WebGPUInstance::processEvents(self : WebGPUInstance) -> Unit {
  self.instance.raw.process_events()
}

///|
pub fn WebGPUInstance::release(self : WebGPUInstance) -> Unit {
  self.instance.raw.release()
}
