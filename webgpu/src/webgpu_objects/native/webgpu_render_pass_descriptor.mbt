///|
pub struct WebGPURenderPassDescriptor {
  colorAttachments : Array[WebGPURenderPassColorAttachment?]
  depthStencilAttachment : WebGPURenderPassDepthStencilAttachment?
}

///|
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  { colorAttachments, depthStencilAttachment }
}

///|
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  WebGPURenderPassDescriptor::new(colorAttachments~, depthStencilAttachment?)
}

///|
pub fn WebGPURenderPassDescriptor::get(
  self : WebGPURenderPassDescriptor,
) -> (
  Array[WebGPURenderPassColorAttachment?],
  WebGPURenderPassDepthStencilAttachment?,
) {
  (self.colorAttachments, self.depthStencilAttachment)
}
