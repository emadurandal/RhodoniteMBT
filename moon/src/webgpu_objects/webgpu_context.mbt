///|
pub type WebGPUContext

///|
pub fn create_webgpu_context(
  WebGPUDevice,
  WebGPUCanvasContext,
  String,
  WebGPUQueue,
) -> WebGPUContext

///|
pub fn WebGPUContext::get(
  Self,
) -> (WebGPUDevice, WebGPUCanvasContext, String, WebGPUQueue)
