// WebGPU device implementation

///|
pub struct JsWebGPUDevice {
  device : GPUDevice
}

///|
pub fn JsWebGPUDevice::new(device : GPUDevice) -> JsWebGPUDevice {
  { device, }
}

///|
pub fn JsWebGPUDevice::get(self : JsWebGPUDevice) -> GPUDevice {
  self.device
}

///|
pub fn JsWebGPUDevice::getQueue(self : JsWebGPUDevice) -> JsWebGPUQueue {
  JsWebGPUQueue::new(device_getQueue(self.device))
}

///|
pub fn JsWebGPUDevice::createBuffer(
  self : JsWebGPUDevice,
  size : Int,
  usage : Int,
) -> GPUBuffer {
  device_createBuffer(self.device, size, usage)
}

///|
pub fn JsWebGPUDevice::createShaderModule(
  self : JsWebGPUDevice,
  code : String,
) -> GPUShaderModule {
  device_createShaderModule(self.device, code)
}

///|
pub fn JsWebGPUDevice::createRenderPipeline(
  self : JsWebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  let (vertex, fragment, topology, formats) = descriptor.get()
  device_createRenderPipeline(self.device, vertex, fragment, topology, formats)
}

///|
pub fn JsWebGPUDevice::createCommandEncoder(
  self : JsWebGPUDevice,
) -> JsWebGPUCommandEncoder {
  JsWebGPUCommandEncoder::new(device_createCommandEncoder(self.device))
}
