///|
/// Defines `WebGPUContext`.
pub struct WebGPUContext {
  device : WebGPUDevice
  context : WebGPUCanvasContext
  format : String
  queue : WebGPUQueue
}

///|
/// Implements `WebGPUContext::new`.
pub fn WebGPUContext::new(
  device : WebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  { device, context, format, queue }
}

///|
/// Implements `create_webgpu_context`.
pub fn create_webgpu_context(
  device : WebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  WebGPUContext::new(device, context, format, queue)
}

///|
/// Implements `webgpu_context_get`.
pub fn webgpu_context_get(
  context : WebGPUContext,
) -> (WebGPUDevice, WebGPUCanvasContext, String, WebGPUQueue) {
  (context.device, context.context, context.format, context.queue)
}
