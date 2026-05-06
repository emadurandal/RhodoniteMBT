///|
pub struct WebGPURenderPassColorAttachment {
  view : GPUTextureView
  clearValue : WebGPUColor?
  loadOp : GPULoadOp
  storeOp : GPUStoreOp
}

///|
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : WebGPUColor,
  loadOp~ : GPULoadOp,
  storeOp~ : GPUStoreOp,
) -> WebGPURenderPassColorAttachment {
  { view, clearValue, loadOp, storeOp }
}

///|
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : WebGPUColor,
  loadOp~ : GPULoadOp,
  storeOp~ : GPUStoreOp,
) -> WebGPURenderPassColorAttachment {
  WebGPURenderPassColorAttachment::new(view~, clearValue?, loadOp~, storeOp~)
}

///|
pub fn WebGPURenderPassColorAttachment::get(
  self : WebGPURenderPassColorAttachment,
) -> (GPUTextureView, WebGPUColor?, GPULoadOp, GPUStoreOp) {
  (self.view, self.clearValue, self.loadOp, self.storeOp)
}
