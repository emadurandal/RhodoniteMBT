// WebGPU initialization functions

///|
pub struct WebGPUContext {
  device : JsWebGPUDevice
  context : WebGPUCanvasContext
  format : String
  queue : WebGPUQueue
}

///|
pub fn WebGPUContext::new(
  device : JsWebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  { device, context, format, queue }
}
