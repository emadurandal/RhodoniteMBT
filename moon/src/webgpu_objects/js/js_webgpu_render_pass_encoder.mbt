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
pub fn JsWebGPURenderPassEncoder::end(self : JsWebGPURenderPassEncoder) -> Unit {
  renderPass_end(self.encoder)
}

///|
pub fn JsWebGPURenderPassEncoder::release(
  self : JsWebGPURenderPassEncoder,
) -> Unit {
  ignore(self)
}
