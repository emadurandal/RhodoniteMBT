// WebGPU command encoder implementation

///|
pub struct JsWebGPUCommandEncoder {
  encoder : GPUCommandEncoder
}

///|
pub fn JsWebGPUCommandEncoder::new(
  encoder : GPUCommandEncoder,
) -> JsWebGPUCommandEncoder {
  { encoder, }
}

///|
pub fn JsWebGPUCommandEncoder::get(
  self : JsWebGPUCommandEncoder,
) -> GPUCommandEncoder {
  self.encoder
}

///|
pub fn JsWebGPUCommandEncoder::beginRenderPass(
  self : JsWebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> JsWebGPURenderPassEncoder {
  JsWebGPURenderPassEncoder::new(
    encoder_beginRenderPass(self.encoder, descriptor),
  )
}

///|
pub fn JsWebGPUCommandEncoder::finish(
  self : JsWebGPUCommandEncoder,
) -> GPUCommandBuffer {
  encoder_finish(self.encoder)
}

///|
pub fn JsWebGPUCommandEncoder::release(self : JsWebGPUCommandEncoder) -> Unit {
  ignore(self)
}

///|
pub impl @traits.WebGPUCommandEncoder for JsWebGPUCommandEncoder with release(
  self,
) {
  self.release()
}
