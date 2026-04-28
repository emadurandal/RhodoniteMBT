// WebGPU texture view implementation

///|
pub struct WebGPUTextureView {
  view : GPUTextureView
}

///|
pub fn WebGPUTextureView::new(view : GPUTextureView) -> WebGPUTextureView {
  { view, }
}

///|
pub fn WebGPUTextureView::get(self : WebGPUTextureView) -> GPUTextureView {
  self.view
}
