///|
pub struct WebGPUAdapter {
  adapter : GPUAdapter
}

///|
pub fn WebGPUAdapter::new(adapter : GPUAdapter) -> WebGPUAdapter {
  { adapter, }
}

///|
pub fn WebGPUAdapter::get(self : WebGPUAdapter) -> GPUAdapter {
  self.adapter
}

///|
pub fn WebGPUAdapter::requestDevice(
  self : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  WebGPUDevice::new(GPUDevice::{
    raw: self.adapter.raw.request_device_sync(self.adapter.instance),
    adapter: self.adapter.raw,
    instance: self.adapter.instance,
  })
}

///|
pub impl @traits.WebGPUAdapter for WebGPUAdapter with requestDevice(self) {
  let device = self.requestDevice() catch {
    _ => abort("failed to request native WebGPU device")
  }
  device as &@traits.WebGPUDevice
}

///|
pub fn WebGPUAdapter::release(self : WebGPUAdapter) -> Unit {
  self.adapter.raw.release()
}
