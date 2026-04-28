///|
pub struct WebGPUAdapter {
  adapter : GPUAdapter
}

///|
pub fn WebGPUAdapter::new(adapter : GPUAdapter) -> WebGPUAdapter {
  { adapter, }
}

///|
pub async fn webgpu_adapter_request_device(
  adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  native_webgpu_adapter_request_device(adapter)
}

///|
pub fn native_webgpu_adapter_request_device(
  adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  WebGPUDevice::new(GPUDevice::{
    raw: adapter.adapter.raw.request_device_sync(adapter.adapter.instance),
    adapter: adapter.adapter.raw,
    instance: adapter.adapter.instance,
  })
}

///|
pub fn webgpu_adapter_release(adapter : WebGPUAdapter) -> Unit {
  adapter.adapter.raw.release()
}
