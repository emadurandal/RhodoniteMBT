// WebGPU color attachment implementation

///|
/// Defines `WebGPURenderPassColorAttachment`.
pub struct WebGPURenderPassColorAttachment {
  view : GPUTextureView
  clearValue : @webgpu_enums.GPUColor?
  loadOp : @webgpu_enums.GPULoadOp
  storeOp : @webgpu_enums.GPUStoreOp
}

///|
/// Implements `WebGPURenderPassColorAttachment::new`.
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment {
  { view, clearValue, loadOp, storeOp }
}

///|
/// Implements `create_render_pass_color_attachment`.
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment {
  WebGPURenderPassColorAttachment::new(view~, clearValue?, loadOp~, storeOp~)
}

///|
/// Implements `WebGPURenderPassColorAttachment::get`.
pub fn WebGPURenderPassColorAttachment::get(
  self : WebGPURenderPassColorAttachment,
) -> (
  GPUTextureView,
  @webgpu_enums.GPUColor?,
  @webgpu_enums.GPULoadOp,
  @webgpu_enums.GPUStoreOp,
) {
  (self.view, self.clearValue, self.loadOp, self.storeOp)
}
