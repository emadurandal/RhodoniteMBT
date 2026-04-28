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
  WebGPUQueue::new(GPUQueue::{ raw: self.device.raw.queue() })
}

///|
pub fn webgpu_device_get_queue(device : WebGPUDevice) -> WebGPUQueue {
  device.getQueue()
}

///|
pub fn WebGPUDevice::createShaderModule(
  self : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  GPUShaderModule::{ raw: self.device.raw.create_shader_module_wgsl(code) }
}

///|
pub fn WebGPUDevice::createBuffer(
  self : WebGPUDevice,
  size : Int,
  usage : Int,
) -> GPUBuffer {
  GPUBuffer::{
    raw: self.device.raw.create_buffer(
      size=size.to_uint64(),
      usage=@wgpu.BufferUsage::from_u64(usage.to_uint64()),
    ),
  }
}

///|
pub fn WebGPUDevice::createRenderPipeline(
  self : WebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  let (vertex, _fragment, _topology, formats) = descriptor.get()
  let format = if formats.length() > 0 {
    texture_format_from_string(formats[0])
  } else {
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
  GPURenderPipeline::{
    raw: self.device.raw.create_render_pipeline_color_format_entries(
      vertex.raw,
      format,
      vs_entry="vertexMain",
      fs_entry="fragmentMain",
    ),
  }
}

///|
pub fn WebGPUDevice::createCommandEncoder(
  self : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(GPUCommandEncoder::{
    raw: self.device.raw.create_command_encoder(),
  })
}

///|
pub fn WebGPUDevice::poll(self : WebGPUDevice, wait? : Bool = false) -> Bool {
  self.device.raw.poll(wait~)
}

///|
pub fn webgpu_device_poll(device : WebGPUDevice, wait? : Bool = false) -> Bool {
  device.poll(wait~)
}

///|
pub fn WebGPUDevice::release(self : WebGPUDevice) -> Unit {
  self.device.raw.release()
}

///|
pub fn webgpu_device_release(device : WebGPUDevice) -> Unit {
  device.release()
}
