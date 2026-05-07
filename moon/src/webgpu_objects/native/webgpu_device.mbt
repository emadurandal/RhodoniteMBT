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
  }
}

///|
/// Native は `Milky2018/wgpu_mbt` の `RenderPipelineDescBuilder` 経由のみ組み立て可能で、
/// 頂点・フラグメントで **別ハンドルの ShaderModule** を正しく割り当てる API が無い。
/// 別 WGSL モジュールが必要な場合は wgpu_mbt 側の拡張か C からの記述子構築が必要。
pub fn webgpu_device_create_render_pipeline(
  device : WebGPUDevice,
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
  vertex_buffers~ : Array[@webgpu_enums.GPUVertexBufferLayout],
) -> GPURenderPipeline {
  if !physical_equal(vertex.raw, fragment.raw) {
    abort(
      "native WebGPU: 頂点用とフラグメント用に異なる ShaderModule を渡すことは、現在の wgpu_mbt ラッパだけではサポートしていません。同一 WGSL なら `create_shader_module` を1回だけ呼び、descriptor の vertex/fragment に同じモジュールを渡してください。",
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
