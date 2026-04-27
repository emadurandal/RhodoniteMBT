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
pub fn WebGPURenderPassEncoder::get(
  self : WebGPURenderPassEncoder,
) -> GPURenderPassEncoder {
  self.encoder
}

///|
pub fn WebGPURenderPassEncoder::setPipeline(
  self : WebGPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  renderPass_setPipeline(self.encoder, pipeline)
}

///|
pub fn WebGPURenderPassEncoder::draw(
  self : WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  renderPass_draw(self.encoder, vertexCount)
}

///|
pub fn WebGPURenderPassEncoder::end(self : WebGPURenderPassEncoder) -> Unit {
  renderPass_end(self.encoder)
}

///|
pub fn WebGPURenderPassEncoder::release(self : WebGPURenderPassEncoder) -> Unit {
  ignore(self)
}
