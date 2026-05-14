// WebGPU queue implementation

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
  queue_submit(queue.queue, commandBuffer)
}

///|
pub fn webgpu_queue_write_buffer(
  queue : WebGPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : Bytes,
) -> Unit {
  queue_writeBuffer(queue.queue, buffer, js_u64_to_double(offset), data)
}

///|
pub fn webgpu_queue_write_buffer_array_view(
  queue : WebGPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : ArrayView[Byte],
) -> Unit {
  queue_writeBuffer_array_view(
    queue.queue,
    buffer,
    js_u64_to_double(offset),
    data,
  )
}

///|
extern "js" fn queue_writeBuffer_bytes_range(
  queue : GPUQueue,
  buffer : GPUBuffer,
  offset : Double,
  data : Bytes,
  data_offset : Double,
  size : Double,
) -> Unit =
  #| (queue, buffer, offset, data, dataOffset, size) => {
  #|   queue.writeBuffer(buffer, offset, data, dataOffset, size);
  #| }

///|
pub fn webgpu_queue_write_buffer_bytes_range(
  queue : WebGPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : Bytes,
  data_offset : UInt64,
  size : UInt64,
) -> Unit {
  queue_writeBuffer_bytes_range(
    queue.queue,
    buffer,
    js_u64_to_double(offset),
    data,
    js_u64_to_double(data_offset),
    js_u64_to_double(size),
  )
}
