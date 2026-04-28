///|
pub struct WebGPUQueue {
  queue : GPUQueue
}

///|
pub impl @traits.WebGPUQueue for WebGPUQueue

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
pub fn WebGPUQueue::release(self : WebGPUQueue) -> Unit {
  self.queue.raw.release()
}
