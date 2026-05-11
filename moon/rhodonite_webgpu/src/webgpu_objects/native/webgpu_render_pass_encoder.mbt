///|
pub struct WebGPURenderPassEncoder {
  encoder : GPURenderPassEncoder
}

///|
pub fn WebGPURenderPassEncoder::new(
  encoder : GPURenderPassEncoder,
) -> WebGPURenderPassEncoder {
  { encoder, }
}

///|
pub fn webgpu_render_pass_encoder_set_pipeline(
  renderPass : WebGPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  renderPass.encoder.raw.set_pipeline(pipeline.raw)
}

///|
pub fn webgpu_render_pass_encoder_draw(
  renderPass : WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  renderPass.encoder.raw.draw(vertexCount.reinterpret_as_uint(), 1U, 0U, 0U)
}

///|
pub fn webgpu_render_pass_encoder_set_vertex_buffer(
  renderPass : WebGPURenderPassEncoder,
  slot : Int,
  buffer : GPUBuffer,
  offset : UInt64,
  size : UInt64,
) -> Unit {
  renderPass.encoder.raw.set_vertex_buffer(
    slot.reinterpret_as_uint(),
    buffer.raw,
    offset,
    size,
  )
}

///|
pub fn webgpu_render_pass_encoder_set_index_buffer(
  renderPass : WebGPURenderPassEncoder,
  buffer : GPUBuffer,
  format : @webgpu_enums.GPUIndexFormat,
  offset : UInt64,
  size : UInt64,
) -> Unit {
  match format {
    @webgpu_enums.GPUIndexFormat::Uint16 =>
      renderPass.encoder.raw.set_index_buffer_u16(buffer.raw, offset, size)
    @webgpu_enums.GPUIndexFormat::Uint32 =>
      renderPass.encoder.raw.set_index_buffer_u32(buffer.raw, offset, size)
  }
}

///|
pub fn webgpu_render_pass_encoder_draw_indexed(
  renderPass : WebGPURenderPassEncoder,
  indexCount : Int,
  instanceCount : Int,
  firstIndex : Int,
  baseVertex : Int,
  firstInstance : Int,
) -> Unit {
  renderPass.encoder.raw.draw_indexed(
    indexCount.reinterpret_as_uint(),
    instanceCount.reinterpret_as_uint(),
    firstIndex.reinterpret_as_uint(),
    baseVertex,
    firstInstance.reinterpret_as_uint(),
  )
}

///|
pub fn webgpu_render_pass_encoder_set_bind_group(
  renderPass : WebGPURenderPassEncoder,
  index : UInt,
  group : GPUBindGroup,
  dynamic_offsets : Array[UInt],
) -> Unit {
  renderPass.encoder.raw.set_bind_group(index, group.raw, dynamic_offsets)
}

///|
pub fn webgpu_render_pass_encoder_end(
  renderPass : WebGPURenderPassEncoder,
) -> Unit {
  renderPass.encoder.raw.end()
}

///|
pub fn webgpu_render_pass_encoder_release(
  renderPass : WebGPURenderPassEncoder,
) -> Unit {
  renderPass.encoder.raw.release()
}
