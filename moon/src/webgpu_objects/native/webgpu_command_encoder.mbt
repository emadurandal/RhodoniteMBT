///|
pub struct WebGPUCommandEncoder {
  encoder : GPUCommandEncoder
}

///|
pub fn WebGPUCommandEncoder::new(
  encoder : GPUCommandEncoder,
) -> WebGPUCommandEncoder {
  { encoder, }
}

///|
pub fn WebGPUCommandEncoder::beginRenderPass(
  self : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  let (color_attachments, _depth_stencil_attachment) = descriptor.get()
  let attachment = match color_attachments[0] {
    Some(attachment) => attachment
    None => abort("native render pass requires a color attachment")
  }
  let (view, clear_value, _load_op, _store_op) = attachment.get()
  let pass = match clear_value {
    Some(color) => {
      let (r, g, b, a) = color.get()
      self.encoder.raw.begin_render_pass_color_clear(
        view.raw,
        Float::from_double(r),
        Float::from_double(g),
        Float::from_double(b),
        Float::from_double(a),
      )
    }
    None => self.encoder.raw.begin_render_pass_color_load(view.raw)
  }
  WebGPURenderPassEncoder::new(GPURenderPassEncoder::{ raw: pass })
}

///|
pub fn WebGPUCommandEncoder::finish(
  self : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  GPUCommandBuffer::{ raw: self.encoder.raw.finish() }
}

///|
pub fn WebGPUCommandEncoder::release(self : WebGPUCommandEncoder) -> Unit {
  self.encoder.raw.release()
}

///|
pub impl @traits.WebGPUCommandEncoder for WebGPUCommandEncoder with release(
  self,
) {
  self.release()
}
