// WebGPU device implementation

///|
pub struct WebGPUDevice {
  device : GPUDevice
}

///|
pub fn WebGPUDevice::new(device : GPUDevice) -> WebGPUDevice {
  { device, }
}

///|
pub fn WebGPUDevice::get(self : WebGPUDevice) -> GPUDevice {
  self.device
}

///|
pub fn webgpu_device_get(device : WebGPUDevice) -> GPUDevice {
  device.get()
}

///|
pub fn WebGPUDevice::getQueue(self : WebGPUDevice) -> WebGPUQueue {
  WebGPUQueue::new(device_getQueue(self.device))
}

///|
pub fn webgpu_device_get_queue(device : WebGPUDevice) -> WebGPUQueue {
  device.getQueue()
}

///|
pub fn WebGPUDevice::createBuffer(
  self : WebGPUDevice,
  size : Int,
  usage : Int,
) -> GPUBuffer {
  device_createBuffer(self.device, size, usage)
}

///|
pub fn WebGPUDevice::createShaderModule(
  self : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  device_createShaderModule(self.device, code)
}

///|
pub fn WebGPUDevice::createRenderPipeline(
  self : WebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  let (vertex, fragment, topology, formats) = descriptor.get()
  device_createRenderPipeline(self.device, vertex, fragment, topology, formats)
}

///|
pub fn WebGPUDevice::createCommandEncoder(
  self : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(device_createCommandEncoder(self.device))
}
