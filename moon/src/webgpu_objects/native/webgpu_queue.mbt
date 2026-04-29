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
pub fn webgpu_queue_release(queue : WebGPUQueue) -> Unit {
  queue.queue.raw.release()
}
