// WebGPU command encoder implementation

///|
/// Defines `WebGPUCommandEncoder`.
pub struct WebGPUCommandEncoder {
  encoder : GPUCommandEncoder
}

///|
/// Implements `WebGPUCommandEncoder::new`.
pub fn WebGPUCommandEncoder::new(
  encoder : GPUCommandEncoder,
) -> WebGPUCommandEncoder {
  { encoder, }
}

///|
/// Implements `webgpu_command_encoder_begin_render_pass`.
pub fn webgpu_command_encoder_begin_render_pass(
  encoder : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  WebGPURenderPassEncoder::new(
    encoder_beginRenderPass(encoder.encoder, descriptor),
  )
}

///|
/// Implements `webgpu_command_encoder_finish`.
pub fn webgpu_command_encoder_finish(
  encoder : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  encoder_finish(encoder.encoder)
}

///|
/// Implements `webgpu_command_encoder_copy_texture_to_buffer_rgba8`.
pub fn webgpu_command_encoder_copy_texture_to_buffer_rgba8(
  encoder : WebGPUCommandEncoder,
  texture : WebGPUTexture,
  buffer : GPUBuffer,
  width : UInt,
  height : UInt,
) -> Unit {
  encoder_copyTextureToBuffer_rgba8(
    encoder.encoder,
    texture.texture,
    buffer,
    width.reinterpret_as_int(),
    height.reinterpret_as_int(),
  )
}

///|
/// Implements `webgpu_command_encoder_release`.
pub fn webgpu_command_encoder_release(encoder : WebGPUCommandEncoder) -> Unit {
  ignore(encoder)
}

///|
extern "js" fn encoder_copyTextureToBuffer_rgba8(
  encoder : GPUCommandEncoder,
  texture : GPUTexture,
  buffer : GPUBuffer,
  width : Int,
  height : Int,
) -> Unit =
  #| (encoder, texture, buffer, width, height) => {
  #|   const bytesPerRow = Math.ceil((width * 4) / 256) * 256;
  #|   encoder.copyTextureToBuffer(
  #|     { texture },
  #|     { buffer, bytesPerRow, rowsPerImage: height },
  #|     { width, height, depthOrArrayLayers: 1 },
  #|   );
  #| }
