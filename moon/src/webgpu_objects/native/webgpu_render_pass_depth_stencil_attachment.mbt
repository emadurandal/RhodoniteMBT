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
