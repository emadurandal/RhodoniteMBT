///|
pub type WebGPUCommandEncoder

///|
/// Implements `webgpu_command_encoder_release`.
pub fn webgpu_command_encoder_release(WebGPUCommandEncoder) -> Unit

///|

///|
/// Implements `webgpu_command_encoder_copy_texture_to_buffer_rgba8`.
#cfg(any(target="js", target="native"))
pub fn webgpu_command_encoder_copy_texture_to_buffer_rgba8(
  WebGPUCommandEncoder,
  WebGPUTexture,
  GPUBuffer,
  UInt,
  UInt,
) -> Unit
