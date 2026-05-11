///|
pub(all) struct GPUBindGroupBufferBinding {
  binding : UInt
  buffer : GPUBuffer
  offset : UInt64
  size : UInt64
}

///|
pub fn gp_bind_group_buffer_binding(
  binding : UInt,
  buffer : GPUBuffer,
  offset : UInt64,
  size : UInt64,
) -> GPUBindGroupBufferBinding {
  GPUBindGroupBufferBinding::{ binding, buffer, offset, size }
}
