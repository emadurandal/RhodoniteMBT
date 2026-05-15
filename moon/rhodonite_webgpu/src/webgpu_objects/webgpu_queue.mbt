///|
pub type WebGPUQueue

///|
/// Implements `webgpu_queue_write_buffer_array_view`.
pub fn webgpu_queue_write_buffer_array_view(
  WebGPUQueue,
  GPUBuffer,
  UInt64,
  ArrayView[Byte],
) -> Unit

///|
///|
/// Implements `webgpu_queue_write_buffer_bytes_range`.
#cfg(target="native")
pub fn webgpu_queue_write_buffer_bytes_range(
  WebGPUQueue,
  GPUBuffer,
  UInt64,
  Bytes,
  UInt64,
  UInt64,
) -> Unit
