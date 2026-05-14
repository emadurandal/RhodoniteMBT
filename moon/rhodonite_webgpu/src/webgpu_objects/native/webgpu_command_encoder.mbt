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
  let (color_attachments, depth_stencil_attachment) = descriptor.get()
  let attachment = match color_attachments[0] {
    Some(attachment) => attachment
    None => abort("native render pass requires a color attachment")
  }
  let (color_view, clear_value, load_op, store_op) = attachment.get()
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
  let pass = match depth_stencil_attachment {
    Some(ds) => {
      let depth_view = ds.view
      match (load_op, store_op) {
        (_, @webgpu_enums.GPUStoreOp::Discard) =>
          abort(
            "native WebGPU: GPUStoreOp::Discard for a color attachment is not implemented yet",
          )
        (@webgpu_enums.GPULoadOp::Load, @webgpu_enums.GPUStoreOp::Store) =>
          encoder.encoder.raw.begin_render_pass_color_depth_u32(
            color_view.raw,
            depth_view.raw,
            color_load_op_u32=@wgpu.LOAD_OP_LOAD,
            color_store_op_u32=@wgpu.STORE_OP_STORE,
            color_clear_r_f32=r,
            color_clear_g_f32=g,
            color_clear_b_f32=b,
            color_clear_a_f32=a,
            depth_load_op_u32=@wgpu.LOAD_OP_CLEAR,
            depth_store_op_u32=@wgpu.STORE_OP_STORE,
            depth_clear_value_f32=1.0,
            depth_read_only=false,
          )
        (@webgpu_enums.GPULoadOp::Clear, @webgpu_enums.GPUStoreOp::Store) =>
          encoder.encoder.raw.begin_render_pass_color_depth_u32(
            color_view.raw,
            depth_view.raw,
            color_load_op_u32=@wgpu.LOAD_OP_CLEAR,
            color_store_op_u32=@wgpu.STORE_OP_STORE,
            color_clear_r_f32=r,
            color_clear_g_f32=g,
            color_clear_b_f32=b,
            color_clear_a_f32=a,
            depth_load_op_u32=@wgpu.LOAD_OP_CLEAR,
            depth_store_op_u32=@wgpu.STORE_OP_STORE,
            depth_clear_value_f32=1.0,
            depth_read_only=false,
          )
      }
    }
    None =>
      match (load_op, store_op) {
        (@webgpu_enums.GPULoadOp::Load, @webgpu_enums.GPUStoreOp::Store) =>
          encoder.encoder.raw.begin_render_pass_color_load(color_view.raw)
        (@webgpu_enums.GPULoadOp::Clear, @webgpu_enums.GPUStoreOp::Store) =>
          encoder.encoder.raw.begin_render_pass_color_clear(
            color_view.raw,
            r,
            g,
            b,
            a,
          )
        (_, @webgpu_enums.GPUStoreOp::Discard) =>
          abort(
            "native WebGPU: GPUStoreOp::Discard for a color attachment is not implemented yet",
          )
      }
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
pub fn webgpu_command_encoder_copy_texture_to_buffer_rgba8(
  encoder : WebGPUCommandEncoder,
  texture : WebGPUTexture,
  buffer : GPUBuffer,
  width : UInt,
  height : UInt,
) -> Unit {
  encoder.encoder.raw.copy_texture_to_buffer_rgba8(
    texture.texture.raw,
    buffer.raw,
    width,
    height,
  )
}

///|
pub fn webgpu_command_encoder_release(encoder : WebGPUCommandEncoder) -> Unit {
  encoder.encoder.raw.release()
}
