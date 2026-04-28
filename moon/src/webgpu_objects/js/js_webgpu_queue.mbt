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
pub fn WebGPUQueue::get(self : WebGPUQueue) -> GPUQueue {
  self.queue
}

///|
pub fn WebGPUQueue::submit(
  self : WebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  queue_submit(self.queue, commandBuffer)
}

///|
pub fn webgpu_queue_submit(
  queue : WebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  queue.submit(commandBuffer)
}
