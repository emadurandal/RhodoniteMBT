///|
pub fn webgpu_buffer_readback_view(
  GPUBuffer,
  WebGPUInstance,
  UInt64,
  UInt64,
) -> BytesView

///|
#cfg(target="native")
pub fn webgpu_buffer_readback(
  GPUBuffer,
  WebGPUInstance,
  UInt64,
  UInt64,
) -> Bytes
