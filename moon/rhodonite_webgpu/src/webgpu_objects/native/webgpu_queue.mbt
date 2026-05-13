///|
pub struct WebGPUQueue {
  queue : GPUQueue
}

///|
pub fn WebGPUQueue::new(queue : GPUQueue) -> WebGPUQueue {
  { queue, }
}

///|
pub fn webgpu_queue_submit(
  queue : WebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  queue.queue.raw.submit_one(commandBuffer.raw)
  commandBuffer.raw.release()
}

///|
pub fn webgpu_queue_write_buffer(
  queue : WebGPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : Bytes,
) -> Unit {
  queue.queue.raw.write_buffer(buffer.raw, offset, data)
}

///|
#borrow(data)
extern "C" fn queue_write_buffer_array_view(
  queue : @c.WGPUQueue,
  buffer : @c.WGPUBuffer,
  buffer_offset : UInt64,
  data : ArrayView[Byte],
) -> Unit = "rhodonite_wgpu_queue_write_buffer_array_view"

///|
pub fn webgpu_queue_write_buffer_array_view(
  queue : WebGPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : ArrayView[Byte],
) -> Unit {
  queue_write_buffer_array_view(
    queue.queue.raw.raw,
    buffer.raw.raw,
    offset,
    data,
  )
}

///|
#borrow(data)
extern "C" fn queue_write_buffer_bytes_range(
  queue : @c.WGPUQueue,
  buffer : @c.WGPUBuffer,
  buffer_offset : UInt64,
  data : Bytes,
  data_offset : UInt64,
  size : UInt64,
) -> Unit = "rhodonite_wgpu_queue_write_buffer_bytes_range"

///|
pub fn webgpu_queue_write_buffer_bytes_range(
  queue : WebGPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : Bytes,
  data_offset : UInt64,
  size : UInt64,
) -> Unit {
  queue_write_buffer_bytes_range(
    queue.queue.raw.raw,
    buffer.raw.raw,
    offset,
    data,
    data_offset,
    size,
  )
}

///|
pub fn webgpu_queue_release(queue : WebGPUQueue) -> Unit {
  queue.queue.raw.release()
}
