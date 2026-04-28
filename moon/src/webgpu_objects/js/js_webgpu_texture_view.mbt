// WebGPU texture view implementation

///|
pub struct JsWebGPUTextureView {
  view : GPUTextureView
}

///|
pub fn JsWebGPUTextureView::new(view : GPUTextureView) -> JsWebGPUTextureView {
  { view, }
}

///|
pub fn JsWebGPUTextureView::get(self : JsWebGPUTextureView) -> GPUTextureView {
  self.view
}
