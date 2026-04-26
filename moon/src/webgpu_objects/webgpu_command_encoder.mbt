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
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  WebGPURenderPassEncoder::new(
    encoder_beginRenderPass(self.encoder, descriptor),
  )
}

///|
pub fn WebGPUCommandEncoder::finish(
  self : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  encoder_finish(self.encoder)
}
