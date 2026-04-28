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
pub fn WebGPURenderPassEncoder::setPipeline(
  self : WebGPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  self.encoder.raw.set_pipeline(pipeline.raw)
}

///|
pub fn WebGPURenderPassEncoder::draw(
  self : WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  self.encoder.raw.draw(vertexCount.reinterpret_as_uint(), 1U, 0U, 0U)
}

///|
pub impl @traits.WebGPURenderPassEncoder for WebGPURenderPassEncoder with draw(
  self,
  vertexCount,
) {
  self.draw(vertexCount)
}

///|
pub fn WebGPURenderPassEncoder::end(self : WebGPURenderPassEncoder) -> Unit {
  self.encoder.raw.end()
}

///|
pub impl @traits.WebGPURenderPassEncoder for WebGPURenderPassEncoder with end(
  self,
) {
  self.end()
}

///|
pub fn WebGPURenderPassEncoder::release(self : WebGPURenderPassEncoder) -> Unit {
  self.encoder.raw.release()
}

///|
pub impl @traits.WebGPURenderPassEncoder for WebGPURenderPassEncoder with release(
  self,
) {
  self.release()
}
