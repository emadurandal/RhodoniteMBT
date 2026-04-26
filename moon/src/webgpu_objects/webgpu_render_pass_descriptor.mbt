// WebGPU render pass descriptor implementation

///|
pub struct WebGPURenderPassDescriptor {
  colorAttachments : Array[WebGPUColorAttachment?]
}

///|
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPUColorAttachment?],
) -> WebGPURenderPassDescriptor {
  { colorAttachments, }
}

///|
pub fn WebGPURenderPassDescriptor::get(
  self : WebGPURenderPassDescriptor,
) -> Array[WebGPUColorAttachment?] {
  self.colorAttachments
}
