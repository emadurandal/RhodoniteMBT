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
pub fn webgpu_queue_release(queue : WebGPUQueue) -> Unit {
  queue.queue.raw.release()
}
