///|
pub type WebGPUQueue

///|
pub fn webgpu_queue_write_buffer_array_view(
  WebGPUQueue,
  GPUBuffer,
  UInt64,
  ArrayView[Byte],
) -> Unit

///|
#cfg(target="native")
pub fn webgpu_queue_write_buffer_bytes_range(
  WebGPUQueue,
  GPUBuffer,
  UInt64,
  Bytes,
  UInt64,
  UInt64,
) -> Unit
