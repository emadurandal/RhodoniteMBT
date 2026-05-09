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
