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
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topology : String,
  formats : Array[String],
) -> GPURenderPipeline {
  device_createRenderPipeline(self.device, vertex, fragment, topology, formats)
}
