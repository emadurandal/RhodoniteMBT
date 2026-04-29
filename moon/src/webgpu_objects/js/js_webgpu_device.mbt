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
pub fn webgpu_device_get(device : WebGPUDevice) -> GPUDevice {
  device.device
}

///|
pub fn webgpu_device_get_queue(device : WebGPUDevice) -> WebGPUQueue {
  WebGPUQueue::new(device_getQueue(device.device))
}

///|
pub fn webgpu_device_create_shader_module(
  device : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  device_createShaderModule(device.device, code)
}

///|
pub fn webgpu_device_create_render_pipeline(
  device : WebGPUDevice,
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> GPURenderPipeline {
  device_createRenderPipeline(
    device.device,
    vertex,
    fragment,
    topology,
    formats,
  )
}

///|
pub fn webgpu_device_create_command_encoder(
  device : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(device_createCommandEncoder(device.device))
}
