///|
pub struct WebGPUContext {
  device : WebGPUDevice
  context : WebGPUCanvasContext
  format : String
  queue : WebGPUQueue
}

///|
pub fn WebGPUContext::new(
  device : WebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  { device, context, format, queue }
}

///|
pub fn create_webgpu_context(
  device : WebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  WebGPUContext::new(device, context, format, queue)
}

///|
pub fn WebGPUContext::get(
  self : WebGPUContext,
) -> (WebGPUDevice, WebGPUCanvasContext, String, WebGPUQueue) {
  (self.device, self.context, self.format, self.queue)
}
