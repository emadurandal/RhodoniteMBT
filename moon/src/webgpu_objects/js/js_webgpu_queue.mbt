// WebGPU queue implementation

///|
pub struct JsWebGPUQueue {
  queue : GPUQueue
}

///|
pub impl @traits.WebGPUQueue for JsWebGPUQueue

///|
pub fn JsWebGPUQueue::new(queue : GPUQueue) -> JsWebGPUQueue {
  { queue, }
}

///|
pub fn JsWebGPUQueue::get(self : JsWebGPUQueue) -> GPUQueue {
  self.queue
}

///|
pub fn JsWebGPUQueue::submit(
  self : JsWebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  queue_submit(self.queue, commandBuffer)
}
