// WebGPU render pass encoder implementation

///|
pub struct JsWebGPURenderPassEncoder {
  encoder : GPURenderPassEncoder
}

///|
pub fn JsWebGPURenderPassEncoder::new(
  encoder : GPURenderPassEncoder,
) -> JsWebGPURenderPassEncoder {
  { encoder, }
}

///|
pub fn JsWebGPURenderPassEncoder::get(
  self : JsWebGPURenderPassEncoder,
) -> GPURenderPassEncoder {
  self.encoder
}

///|
pub fn JsWebGPURenderPassEncoder::setPipeline(
  self : JsWebGPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  renderPass_setPipeline(self.encoder, pipeline)
}

///|
pub fn JsWebGPURenderPassEncoder::draw(
  self : JsWebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  renderPass_draw(self.encoder, vertexCount)
}

///|
pub impl @traits.WebGPURenderPassEncoder for JsWebGPURenderPassEncoder with draw(
  self,
  vertexCount,
) {
  self.draw(vertexCount)
}

///|
pub fn JsWebGPURenderPassEncoder::end(self : JsWebGPURenderPassEncoder) -> Unit {
  renderPass_end(self.encoder)
}

///|
pub impl @traits.WebGPURenderPassEncoder for JsWebGPURenderPassEncoder with end(
  self,
) {
  self.end()
}

///|
pub fn JsWebGPURenderPassEncoder::release(
  self : JsWebGPURenderPassEncoder,
) -> Unit {
  ignore(self)
}

///|
pub impl @traits.WebGPURenderPassEncoder for JsWebGPURenderPassEncoder with release(
  self,
) {
  self.release()
}
