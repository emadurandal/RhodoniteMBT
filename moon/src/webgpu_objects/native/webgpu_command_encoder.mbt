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
  let (view, clear_value, load_op, store_op) = attachment.get()
  let pass = match (load_op, store_op) {
    (@webgpu_enums.GPULoadOp::Load, @webgpu_enums.GPUStoreOp::Store) =>
      encoder.encoder.raw.begin_render_pass_color_load(view.raw)
    (@webgpu_enums.GPULoadOp::Clear, @webgpu_enums.GPUStoreOp::Store) => {
      let (r, g, b, a) = match clear_value {
        Some(c) =>
          (
            Float::from_double(c.r),
            Float::from_double(c.g),
            Float::from_double(c.b),
            Float::from_double(c.a),
          )
        None => (0.0, 0.0, 0.0, 1.0)
      }
      encoder.encoder.raw.begin_render_pass_color_clear(view.raw, r, g, b, a)
    }
    (_, @webgpu_enums.GPUStoreOp::Discard) =>
      abort(
        "native WebGPU: GPUStoreOp::Discard for a color attachment is not implemented yet",
      )
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
