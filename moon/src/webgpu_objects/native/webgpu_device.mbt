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
  WebGPUQueue::new(GPUQueue::{ raw: device.device.raw.queue() })
}

///|
pub fn webgpu_device_create_shader_module(
  device : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  GPUShaderModule::{ raw: device.device.raw.create_shader_module_wgsl(code) }
}

///|
pub fn webgpu_device_create_render_pipeline(
  device : WebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  let (vertex, _fragment, _topology, formats) = descriptor.get()
  let format = if formats.length() > 0 {
    texture_format_from_string(formats[0])
  } else {
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
  GPURenderPipeline::{
    raw: device.device.raw.create_render_pipeline_color_format_entries(
      vertex.raw,
      format,
      vs_entry="vertexMain",
      fs_entry="fragmentMain",
    ),
  }
}

///|
pub fn webgpu_device_create_command_encoder(
  device : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(GPUCommandEncoder::{
    raw: device.device.raw.create_command_encoder(),
  })
}

///|
pub fn webgpu_device_poll(device : WebGPUDevice, wait? : Bool = false) -> Bool {
  device.device.raw.poll(wait~)
}

///|
pub fn webgpu_device_release(device : WebGPUDevice) -> Unit {
  device.device.raw.release()
}
