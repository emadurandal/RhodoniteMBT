// WebGPU render pass encoder implementation

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
  renderPass_setPipeline(renderPass.encoder, pipeline)
}

///|
pub fn webgpu_render_pass_encoder_draw(
  renderPass : WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  renderPass_draw(renderPass.encoder, vertexCount)
}

///|
pub fn webgpu_render_pass_encoder_set_vertex_buffer(
  renderPass : WebGPURenderPassEncoder,
  slot : Int,
  buffer : GPUBuffer,
  offset : UInt64,
  size : UInt64,
) -> Unit {
  renderPass_setVertexBuffer(
    renderPass.encoder,
    slot,
    buffer,
    js_u64_to_double(offset),
    js_u64_to_double(size),
  )
}

///|
pub fn webgpu_render_pass_encoder_end(
  renderPass : WebGPURenderPassEncoder,
) -> Unit {
  renderPass_end(renderPass.encoder)
}

///|
pub fn webgpu_render_pass_encoder_release(
  renderPass : WebGPURenderPassEncoder,
) -> Unit {
  ignore(renderPass)
}
