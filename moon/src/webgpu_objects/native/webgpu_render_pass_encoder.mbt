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
