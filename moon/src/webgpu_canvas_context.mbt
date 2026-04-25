///|
pub struct WebGPUCanvasContext {
  context : GPUCanvasContext
}

///|
pub fn WebGPUCanvasContext::new(
  context : GPUCanvasContext,
) -> WebGPUCanvasContext {
  { context, }
}

///|
pub fn WebGPUCanvasContext::get(self : WebGPUCanvasContext) -> GPUCanvasContext {
  self.context
}

///|
pub fn WebGPUCanvasContext::configure(
  self : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  context_configure(self.context, device, format)
}
