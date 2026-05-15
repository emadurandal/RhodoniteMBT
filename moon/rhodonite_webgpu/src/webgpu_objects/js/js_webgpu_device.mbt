// WebGPU device implementation

///|
/// Implements `vertex_layout_to_ffi`.
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
/// Defines `WebGPUDevice`.
pub struct WebGPUDevice {
  device : GPUDevice
}

///|
/// Implements `WebGPUDevice::new`.
pub fn WebGPUDevice::new(device : GPUDevice) -> WebGPUDevice {
  { device, }
}

///|
/// Implements `webgpu_device_get`.
pub fn webgpu_device_get(device : WebGPUDevice) -> GPUDevice {
  device.device
}

///|
/// Implements `webgpu_device_get_queue`.
pub fn webgpu_device_get_queue(device : WebGPUDevice) -> WebGPUQueue {
  WebGPUQueue::new(device_getQueue(device.device))
}

///|
/// Implements `webgpu_device_create_shader_module`.
pub fn webgpu_device_create_shader_module(
  device : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  device_createShaderModule(device.device, code)
}

///|
/// Implements `webgpu_device_create_render_pipeline`.
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
/// Implements `webgpu_device_create_texture`.
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
/// Implements `webgpu_device_create_buffer`.
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
/// Implements `webgpu_device_create_command_encoder`.
pub fn webgpu_device_create_command_encoder(
  device : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(device_createCommandEncoder(device.device))
}

///|
/// Implements `webgpu_render_pipeline_get_bind_group_layout`.
pub fn webgpu_render_pipeline_get_bind_group_layout(
  pipeline : GPURenderPipeline,
  group_index : UInt,
) -> GPUBindGroupLayout {
  renderPipeline_getBindGroupLayout(pipeline, group_index)
}

///|
/// Implements `bind_group_entry_resolved_js`.
fn bind_group_entry_resolved_js(
  entry : GPUBindGroupEntry,
) -> BindGroupEntryResolvedJs {
  let whole_u64 : UInt64 = 0xFFFFFFFFFFFFFFFFUL
  match entry.inner {
    Buffer(b, buf) =>
      BindGroupEntryResolvedJs::{
        binding: b,
        resource: bind_group_resource_buffer(buf),
      }
    BufferBinding(b, buf, off, sz) => {
      let whole = sz == whole_u64
      BindGroupEntryResolvedJs::{
        binding: b,
        resource: bind_group_resource_buffer_binding(
          buf,
          js_u64_to_double(off),
          js_u64_to_double(sz),
          whole,
        ),
      }
    }
    TextureView(b, view) =>
      BindGroupEntryResolvedJs::{
        binding: b,
        resource: bind_group_resource_texture_view(view),
      }
    Texture(b, wt) =>
      BindGroupEntryResolvedJs::{
        binding: b,
        resource: bind_group_resource_texture(wt.texture),
      }
    Sampler(b, sam) =>
      BindGroupEntryResolvedJs::{
        binding: b,
        resource: bind_group_resource_sampler(sam),
      }
    ExternalTexture(b, ext) =>
      BindGroupEntryResolvedJs::{
        binding: b,
        resource: bind_group_resource_external(ext),
      }
  }
}

///|
/// Implements `webgpu_device_create_bind_group`.
pub fn webgpu_device_create_bind_group(
  device : WebGPUDevice,
  layout : GPUBindGroupLayout,
  entries : Array[GPUBindGroupEntry],
) -> GPUBindGroup {
  let js_entries = entries.map(fn(e) { bind_group_entry_resolved_js(e) })
  device_createBindGroup(device.device, layout, js_entries)
}
