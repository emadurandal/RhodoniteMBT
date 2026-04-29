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
pub fn webgpu_command_encoder_begin_render_pass(
  encoder : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  let (color_attachments, _depth_stencil_attachment) = descriptor.get()
  let attachment = match color_attachments[0] {
    Some(attachment) => attachment
    None => abort("native render pass requires a color attachment")
  }
  let (view, clear_value, _load_op, _store_op) = attachment.get()
  let pass = match clear_value {
    Some(c) =>
      encoder.encoder.raw.begin_render_pass_color_clear(
        view.raw,
        Float::from_double(c.r),
        Float::from_double(c.g),
        Float::from_double(c.b),
        Float::from_double(c.a),
      )
    None => encoder.encoder.raw.begin_render_pass_color_load(view.raw)
  }
  WebGPURenderPassEncoder::new(GPURenderPassEncoder::{ raw: pass })
}

///|
pub fn webgpu_command_encoder_finish(
  encoder : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  GPUCommandBuffer::{ raw: encoder.encoder.raw.finish() }
}

///|
pub fn webgpu_command_encoder_release(encoder : WebGPUCommandEncoder) -> Unit {
  encoder.encoder.raw.release()
}
