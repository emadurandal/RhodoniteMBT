///|
pub type WebGPUAdapter

///|
pub fn WebGPUAdapter::new(GPUAdapter) -> WebGPUAdapter

///|
pub fn WebGPUAdapter::get(Self) -> GPUAdapter

///|
pub async fn WebGPUAdapter::requestDevice(Self) -> WebGPUDevice

///|
pub async fn webgpu_adapter_request_device(WebGPUAdapter) -> WebGPUDevice

///|
pub fn native_webgpu_adapter_request_device(WebGPUAdapter) -> WebGPUDevice raise Error
