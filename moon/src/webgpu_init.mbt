// WebGPU initialization functions

///|
pub struct WebGPUContext {
  device : JsWebGPUDevice
  context : JsWebGPUCanvasContext
  format : String
  queue : JsWebGPUQueue
}

///|
pub fn WebGPUContext::new(
  device : JsWebGPUDevice,
  context : JsWebGPUCanvasContext,
  format : String,
  queue : JsWebGPUQueue,
) -> WebGPUContext {
  { device, context, format, queue }
}
