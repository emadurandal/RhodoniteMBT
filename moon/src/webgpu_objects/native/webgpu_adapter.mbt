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
pub async fn webgpu_adapter_request_device(
  adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  adapter.requestDevice()
}

///|
pub fn native_webgpu_adapter_request_device(
  adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  adapter.requestDevice()
}

///|
pub fn WebGPUAdapter::release(self : WebGPUAdapter) -> Unit {
  self.adapter.raw.release()
}

///|
pub fn webgpu_adapter_release(adapter : WebGPUAdapter) -> Unit {
  adapter.release()
}
