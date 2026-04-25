// WebGPU command encoder implementation

///|
pub struct WebGPUCommandEncoder {
  encoder : GPUCommandEncoder
}

///|
pub fn WebGPUCommandEncoder::new(
  encoder : GPUCommandEncoder,
) -> WebGPUCommandEncoder {
  { encoder, }
}

///|
pub fn WebGPUCommandEncoder::get(
  self : WebGPUCommandEncoder,
) -> GPUCommandEncoder {
  self.encoder
}

///|
pub fn WebGPUCommandEncoder::beginRenderPass(
  self : WebGPUCommandEncoder,
  view : GPUTextureView,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> WebGPURenderPassEncoder {
  WebGPURenderPassEncoder::new(
    encoder_beginRenderPass(self.encoder, view, r, g, b, a),
  )
}

///|
pub fn WebGPUCommandEncoder::finish(
  self : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  encoder_finish(self.encoder)
}
