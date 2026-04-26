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

///|
pub fn WebGPUCanvasContext::getCurrentTexture(
  self : WebGPUCanvasContext,
) -> WebGPUTexture {
  WebGPUTexture::new(context_getCurrentTexture(self.context))
}

///|
pub fn WebGPUCanvasContext::present(self : WebGPUCanvasContext) -> Unit {
  ignore(self)
}
