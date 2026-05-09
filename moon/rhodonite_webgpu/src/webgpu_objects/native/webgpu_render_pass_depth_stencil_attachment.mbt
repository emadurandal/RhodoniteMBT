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
  depthClearValue~ : Double?,
  depthLoadOp~ : @webgpu_enums.GPULoadOp,
  depthStoreOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassDepthStencilAttachment {
  ignore(depthClearValue)
  ignore(depthLoadOp)
  ignore(depthStoreOp)
  WebGPURenderPassDepthStencilAttachment::new(view~)
}
