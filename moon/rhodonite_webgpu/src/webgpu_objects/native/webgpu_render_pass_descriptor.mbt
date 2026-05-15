///|
/// Defines `WebGPURenderPassDescriptor`.
pub struct WebGPURenderPassDescriptor {
  colorAttachments : Array[WebGPURenderPassColorAttachment?]
  depthStencilAttachment : WebGPURenderPassDepthStencilAttachment?
}

///|
/// Implements `WebGPURenderPassDescriptor::new`.
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  { colorAttachments, depthStencilAttachment }
}

///|
/// Implements `create_render_pass_descriptor`.
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  WebGPURenderPassDescriptor::new(colorAttachments~, depthStencilAttachment?)
}

///|
/// Implements `WebGPURenderPassDescriptor::get`.
pub fn WebGPURenderPassDescriptor::get(
  self : WebGPURenderPassDescriptor,
) -> (
  Array[WebGPURenderPassColorAttachment?],
  WebGPURenderPassDepthStencilAttachment?,
) {
  (self.colorAttachments, self.depthStencilAttachment)
}
