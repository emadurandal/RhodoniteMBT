// WebGPU color attachment implementation

///|
pub struct WebGPURenderPassColorAttachment {
  view : GPUTextureView
  clearValue : GPUColorDict?
  loadOp : String
  storeOp : String
}

///|
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : GPUColorDict,
  loadOp~ : String,
  storeOp~ : String,
) -> WebGPURenderPassColorAttachment {
  { view, clearValue, loadOp, storeOp }
}

///|
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : GPUColorDict,
  loadOp~ : String,
  storeOp~ : String,
) -> WebGPURenderPassColorAttachment {
  WebGPURenderPassColorAttachment::new(view~, clearValue?, loadOp~, storeOp~)
}

///|
pub fn WebGPURenderPassColorAttachment::get(
  self : WebGPURenderPassColorAttachment,
) -> (GPUTextureView, GPUColorDict?, String, String) {
  (self.view, self.clearValue, self.loadOp, self.storeOp)
}
