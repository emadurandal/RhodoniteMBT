// WebGPU render pass descriptor implementation

///|
pub struct WebGPURenderPassDescriptor {
  colorAttachments : Array[WebGPURenderPassColorAttachment?]
}

///|
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
) -> WebGPURenderPassDescriptor {
  { colorAttachments, }
}

///|
pub fn WebGPURenderPassDescriptor::get(
  self : WebGPURenderPassDescriptor,
) -> Array[WebGPURenderPassColorAttachment?] {
  self.colorAttachments
}
