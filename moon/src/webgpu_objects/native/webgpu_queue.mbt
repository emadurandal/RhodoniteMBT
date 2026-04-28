///|
pub struct WebGPUQueue {
  queue : GPUQueue
}

///|
pub fn WebGPUQueue::new(queue : GPUQueue) -> WebGPUQueue {
  { queue, }
}

///|
pub fn WebGPUQueue::submit(
  self : WebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  self.queue.raw.submit_one(commandBuffer.raw)
  commandBuffer.raw.release()
}

///|
pub fn webgpu_queue_submit(
  queue : WebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  queue.submit(commandBuffer)
}

///|
pub fn WebGPUQueue::release(self : WebGPUQueue) -> Unit {
  self.queue.raw.release()
}

///|
pub fn webgpu_queue_release(queue : WebGPUQueue) -> Unit {
  queue.release()
}
