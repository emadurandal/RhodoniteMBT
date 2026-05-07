// WebGPU device implementation

///|
fn vertex_layout_to_ffi(
  lb : @webgpu_enums.GPUVertexBufferLayout,
) -> VertexBufferLayoutFFI {
  let attrs = lb.attributes.map(fn(a) {
    VertexAttributeFFI::{
      formatTag: a.format.to_js_tag(),
      offset: a.offset.to_uint().to_int(),
      shaderLocation: a.shader_location,
    }
  })
  VertexBufferLayoutFFI::{
    arrayStride: lb.array_stride.to_uint().to_int(),
    stepModeTag: lb.step_mode.to_js_tag(),
    attributes: attrs,
  }
}

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
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
  vertex_buffers~ : Array[@webgpu_enums.GPUVertexBufferLayout],
  depth_stencil_format~ : String,
) -> GPURenderPipeline {
  let vffi = vertex_buffers.map(fn(lb) { vertex_layout_to_ffi(lb) })
  device_createRenderPipeline(
    device.device,
    vertex,
    fragment,
    topology.to_js_tag(),
    formats,
    vffi,
    depth_stencil_format,
  )
}

///|
pub fn webgpu_device_create_texture(
  device : WebGPUDevice,
  width : UInt,
  height : UInt,
  format : String,
  usage : UInt64,
) -> WebGPUTexture {
  WebGPUTexture::new(
    device_createTexture(
      device.device,
      width.reinterpret_as_int(),
      height.reinterpret_as_int(),
      format,
      js_u64_to_double(usage),
    ),
  )
}

///|
pub fn webgpu_device_create_buffer(
  device : WebGPUDevice,
  size : UInt64,
  usage : UInt64,
) -> GPUBuffer {
  device_createBuffer(
    device.device,
    js_u64_to_double(size),
    js_u64_to_double(usage),
  )
}

///|
pub fn webgpu_device_create_command_encoder(
  device : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(device_createCommandEncoder(device.device))
}
