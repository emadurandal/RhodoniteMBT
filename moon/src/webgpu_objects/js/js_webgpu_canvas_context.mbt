///|
pub struct JsWebGPUCanvasContext {
  context : GPUCanvasContext
}

///|
pub fn JsWebGPUCanvasContext::new(
  context : GPUCanvasContext,
) -> JsWebGPUCanvasContext {
  { context, }
}

///|
pub fn JsWebGPUCanvasContext::get(
  self : JsWebGPUCanvasContext,
) -> GPUCanvasContext {
  self.context
}

///|
pub fn JsWebGPUCanvasContext::configure(
  self : JsWebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  context_configure(self.context, device, format)
}

///|
pub fn JsWebGPUCanvasContext::getCurrentTexture(
  self : JsWebGPUCanvasContext,
) -> JsWebGPUTexture {
  JsWebGPUTexture::new(context_getCurrentTexture(self.context))
}

///|
pub impl @traits.WebGPUCanvasContext for JsWebGPUCanvasContext with getCurrentTexture(
  self,
) {
  self.getCurrentTexture() as &@traits.WebGPUTexture
}

///|
pub fn JsWebGPUCanvasContext::present(self : JsWebGPUCanvasContext) -> Unit {
  ignore(self)
}

///|
pub impl @traits.WebGPUCanvasContext for JsWebGPUCanvasContext with present(
  self,
) {
  self.present()
}
