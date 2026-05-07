///|
pub struct WebGPURenderPassDepthStencilAttachment {
  view : GPUTextureView
}

///|
pub fn WebGPURenderPassDepthStencilAttachment::new(
  view~ : GPUTextureView,
) -> WebGPURenderPassDepthStencilAttachment {
  { view, }
}

///|
pub fn create_render_pass_depth_stencil_attachment(
  view~ : GPUTextureView,
) -> WebGPURenderPassDepthStencilAttachment {
  WebGPURenderPassDepthStencilAttachment::new(view~)
}
