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
/// Maps [`GPUPrimitiveTopology`] to wgpu `PRIMITIVE_TOPOLOGY_*`.
fn topology_to_primitive_u32(
  topology : @webgpu_enums.GPUPrimitiveTopology,
) -> UInt {
  match topology {
    PointList => @wgpu.PRIMITIVE_TOPOLOGY_POINT_LIST
    LineList => @wgpu.PRIMITIVE_TOPOLOGY_LINE_LIST
    LineStrip => @wgpu.PRIMITIVE_TOPOLOGY_LINE_STRIP
    TriangleList => @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    TriangleStrip => @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP
  }
}

///|
fn vertex_step_to_u32(mode : @webgpu_enums.GPUVertexStepMode) -> UInt {
  match mode {
    Vertex => @wgpu.VERTEX_STEP_MODE_VERTEX
    Instance => @wgpu.VERTEX_STEP_MODE_INSTANCE
  }
}

///|
fn vertex_format_to_u32(f : @webgpu_enums.GPUVertexFormat) -> UInt {
  match f {
    Float32x2 => @wgpu.VERTEX_FORMAT_FLOAT32X2
    Float32x3 => @wgpu.VERTEX_FORMAT_FLOAT32X3
    Float32x4 => @wgpu.VERTEX_FORMAT_FLOAT32X4
    Uint32x2 => @wgpu.VERTEX_FORMAT_UINT32X2
  }
}

///|
/// Native builds pipelines only via `Milky2018/wgpu_mbt` `RenderPipelineDescBuilder`;
/// there is no API to assign **distinct ShaderModule handles** for vertex vs fragment.
/// Separate WGSL modules need an extension in wgpu_mbt or descriptor setup from C.
pub fn webgpu_device_create_render_pipeline(
  device : WebGPUDevice,
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
  vertex_buffers~ : Array[@webgpu_enums.GPUVertexBufferLayout],
  depth_stencil_format~ : String,
) -> GPURenderPipeline {
  if !physical_equal(vertex.raw, fragment.raw) {
    abort(
      "native WebGPU: different ShaderModule handles for vertex and fragment are not supported with the current wgpu_mbt wrapper. For a single WGSL source, call `create_shader_module` once and pass the same module to vertex and fragment in the descriptor.",
    )
  }
  let format = if formats.length() > 0 {
    texture_format_from_string(formats[0])
  } else {
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
  let topology_u = topology_to_primitive_u32(topology)
  try {
    let builder = @wgpu.RenderPipelineDescBuilder::new(vertex.raw)
    let pipeline = try {
      let _ = builder.set_entry_points("vertexMain", "fragmentMain")
      let _ = builder.set_color_target_format(format)
      let _ = builder.set_topology_u32(topology_u)
      if vertex_buffers.length() > 0 {
        for i = 0; i < vertex_buffers.length(); i = i + 1 {
          let vb = vertex_buffers[i]
          let step_u = vertex_step_to_u32(vb.step_mode)
          if i == 0 {
            let _ = builder.set_vertex_buffer_layout(vb.array_stride, step_u)
          } else {
            ignore(builder.add_vertex_buffer_layout(vb.array_stride, step_u))
          }
          for j = 0; j < vb.attributes.length(); j = j + 1 {
            let a = vb.attributes[j]
            let fmt_u = vertex_format_to_u32(a.format)
            let _ = builder.add_vertex_attribute(
              fmt_u,
              a.offset,
              a.shader_location,
            )
          }
        }
      }
      if depth_stencil_format != "" {
        let df = texture_format_from_string(depth_stencil_format)
        let _ = builder.set_depth_stencil(df)
      }
      let desc = builder.finish_descriptor_ptr()
      let raw = device.device.raw.create_render_pipeline_ptr(desc)
      @c.render_pipeline_descriptor_free(desc)
      builder.free()
      GPURenderPipeline::{ raw, }
    } catch {
      _ => {
        builder.free()
        abort("native WebGPU: render pipeline descriptor setup failed")
      }
    }
    pipeline
  } catch {
    _ => abort("native WebGPU: render pipeline builder allocation failed")
  }
}

///|
pub fn webgpu_device_create_buffer(
  device : WebGPUDevice,
  size : UInt64,
  usage : UInt64,
) -> GPUBuffer {
  let usage_flags = @wgpu.BufferUsage::from_u64(usage)
  GPUBuffer::{ raw: device.device.raw.create_buffer(size~, usage=usage_flags) }
}

///|
pub fn webgpu_device_create_texture(
  device : WebGPUDevice,
  width : UInt,
  height : UInt,
  format : String,
  usage : UInt64,
) -> WebGPUTexture {
  if format == "depth24plus" {
    let tex = device.device.raw.create_texture_depth24plus_2d(width, height)
    return WebGPUTexture::new(GPUTexture::{ raw: tex })
  }
  let fmt = texture_format_from_string(format)
  if fmt.to_u32() != @wgpu.TEXTURE_FORMAT_RGBA8_UNORM {
    abort(
      "native WebGPU: create_texture currently supports rgba8unorm and depth24plus",
    )
  }
  let tex = device.device.raw.create_texture_rgba8_2d_with_usage(
    width,
    height,
    @wgpu.TextureUsage::from_u64(usage),
  )
  WebGPUTexture::new(GPUTexture::{ raw: tex })
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
pub fn webgpu_render_pipeline_get_bind_group_layout(
  pipeline : GPURenderPipeline,
  group_index : UInt,
) -> GPUBindGroupLayout {
  GPUBindGroupLayout::{
    raw: pipeline.raw.get_bind_group_layout_raw(group_index),
  }
}

///|
pub fn webgpu_device_create_bind_group(
  device : WebGPUDevice,
  layout : GPUBindGroupLayout,
  entries : Array[GPUBindGroupEntry],
) -> GPUBindGroup {
  let n = entries.length()
  let builder = @wgpu.BindGroupBuilder::new(max_entries=n.to_uint64())
  for i = 0; i < n; i = i + 1 {
    let ok = match entries[i].inner {
      Buffer(b, buf) =>
        builder.add_buffer(b, buf.raw, offset=0UL, size=@wgpu.WHOLE_SIZE)
      BufferBinding(b, buf, off, sz) =>
        builder.add_buffer(b, buf.raw, offset=off, size=sz)
      TextureView(b, view) => builder.add_texture_view(b, view.raw)
      Texture(b, wt) => {
        let gv = webgpu_texture_create_view(wt)
        builder.add_texture_view(b, gv.raw)
      }
      Sampler(b, sam) => builder.add_sampler(b, sam.raw)
      ExternalTexture(_) =>
        abort(
          "native WebGPU: GPUExternalTexture bind group entries are not implemented",
        )
    }
    if !ok {
      abort("native WebGPU: bind group builder failed")
    }
  }
  let bg = builder.finish(device.device.raw, layout.raw)
  GPUBindGroup::{ raw: bg }
}

///|
pub fn webgpu_device_poll(device : WebGPUDevice, wait? : Bool = false) -> Bool {
  device.device.raw.poll(wait~)
}

///|
pub fn webgpu_device_release(device : WebGPUDevice) -> Unit {
  device.device.raw.release()
}
