///|
/// Implements `webgpu_buffer_readback_view`.
pub fn webgpu_buffer_readback_view(
  GPUBuffer,
  WebGPUInstance,
  UInt64,
  UInt64,
) -> BytesView

///|
///|
/// Implements `webgpu_buffer_readback`.
#cfg(target="native")
pub fn webgpu_buffer_readback(
  GPUBuffer,
  WebGPUInstance,
  UInt64,
  UInt64,
) -> Bytes

///|
#cfg(target="js")
pub async fn webgpu_buffer_readback_async(GPUBuffer, UInt64, UInt64) -> Bytes
