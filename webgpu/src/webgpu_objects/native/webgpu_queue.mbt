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
  data : Array[Byte],
) -> Unit {
  let len = data.length()
  let bs = Bytes::makei(len, fn(i) { data[i] })
  queue.queue.raw.write_buffer(buffer.raw, offset, bs)
}

///|
pub fn webgpu_queue_release(queue : WebGPUQueue) -> Unit {
  queue.queue.raw.release()
}
