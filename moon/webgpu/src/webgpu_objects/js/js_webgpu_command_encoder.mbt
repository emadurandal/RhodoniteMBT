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
pub fn webgpu_command_encoder_begin_render_pass(
  encoder : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  WebGPURenderPassEncoder::new(
    encoder_beginRenderPass(encoder.encoder, descriptor),
  )
}

///|
pub fn webgpu_command_encoder_finish(
  encoder : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  encoder_finish(encoder.encoder)
}

///|
pub fn webgpu_command_encoder_release(encoder : WebGPUCommandEncoder) -> Unit {
  ignore(encoder)
}
