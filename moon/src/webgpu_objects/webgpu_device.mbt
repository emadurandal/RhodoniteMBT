///|
pub type WebGPUDevice

///|
pub fn WebGPUDevice::new(GPUDevice) -> WebGPUDevice

///|
pub fn WebGPUDevice::get(Self) -> GPUDevice

///|
pub fn WebGPUDevice::getQueue(Self) -> WebGPUQueue

///|
pub fn webgpu_device_get(WebGPUDevice) -> GPUDevice

///|
pub fn webgpu_device_get_queue(WebGPUDevice) -> WebGPUQueue

///|
pub fn WebGPUDevice::createShaderModule(Self, String) -> GPUShaderModule

///|
pub fn WebGPUDevice::createRenderPipeline(Self, WebGPURenderPipelineDescriptor) -> GPURenderPipeline

///|
pub fn WebGPUDevice::createCommandEncoder(Self) -> WebGPUCommandEncoder
