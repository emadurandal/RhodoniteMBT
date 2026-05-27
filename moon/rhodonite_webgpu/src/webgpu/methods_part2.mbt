/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `GPUDevice::create_bind_group`.
pub fn GPUDevice::create_bind_group(
  self : GPUDevice,
  descriptor : GPUBindGroupDescriptor,
) -> GPUBindGroup {
  let raw_entries : Array[@raw.GPUBindGroupEntry] = descriptor.entries.map(fn(
    entry,
  ) {
    match entry.resource {
      Buffer(buf) => @raw.gp_bind_group_entry_buffer(entry.binding, buf.raw)
      BufferBinding(bb) =>
        @raw.gp_bind_group_entry_buffer_binding(
          entry.binding,
          bb.buffer.raw,
          bb.offset,
          bb.size,
        )
      TextureView(view) =>
        @raw.gp_bind_group_entry_texture_view(entry.binding, view)
      Texture(tex) => @raw.gp_bind_group_entry_texture(entry.binding, tex.raw)
      Sampler(sam) => @raw.gp_bind_group_entry_sampler(entry.binding, sam.raw)
      ExternalTexture(ext) =>
        @raw.gp_bind_group_entry_external_texture(entry.binding, ext.raw)
    }
  })
  {
    raw: @raw.webgpu_device_create_bind_group(
      self.raw,
      descriptor.layout.raw,
      raw_entries,
    ),
  }
}

///|
/// Creates a bind group for the builtin ECS GlobalTransform packed word storage buffer.
pub fn GPUDevice::create_global_transform_words_bind_group(
  self : GPUDevice,
  layout : GPUBindGroupLayout,
  buffer : GPUBuffer,
  binding : UInt,
) -> GPUBindGroup {
  self.create_bind_group({
    layout,
    entries: [{ binding, resource: GPUBindingResource::Buffer(buffer) }],
  })
}

///|
/// Creates a bind group for the builtin ECS Camera packed word storage buffer.
pub fn GPUDevice::create_camera_words_bind_group(
  self : GPUDevice,
  layout : GPUBindGroupLayout,
  buffer : GPUBuffer,
  binding : UInt,
) -> GPUBindGroup {
  self.create_bind_group({
    layout,
    entries: [{ binding, resource: GPUBindingResource::Buffer(buffer) }],
  })
}

///|
/// Implements `GPURenderPipeline::release`.
pub fn GPURenderPipeline::release(self : GPURenderPipeline) -> Unit {
  renderPipeline_release(self)
}

///|
/// Implements `GPUPipelineLayout::release`.
pub fn GPUPipelineLayout::release(self : GPUPipelineLayout) -> Unit {
  @raw.pipelineLayout_release(self.raw)
}

///|
/// Implements `GPURenderPassEncoder::draw`.
pub fn GPURenderPassEncoder::draw(
  self : GPURenderPassEncoder,
  vertex_count : Int,
) -> Unit {
  @raw.webgpu_render_pass_encoder_draw(self.raw, vertex_count)
}

///|
/// Implements `GPURenderPassEncoder::draw_indexed`.
pub fn GPURenderPassEncoder::draw_indexed(
  self : GPURenderPassEncoder,
  index_count : Int,
  instance_count? : Int = 1,
  first_index? : Int = 0,
  base_vertex? : Int = 0,
  first_instance? : Int = 0,
) -> Unit {
  @raw.webgpu_render_pass_encoder_draw_indexed(
    self.raw,
    index_count,
    instance_count,
    first_index,
    base_vertex,
    first_instance,
  )
}

///|
/// Implements `GPURenderPassEncoder::set_bind_group`.
pub fn GPURenderPassEncoder::set_bind_group(
  self : GPURenderPassEncoder,
  index : UInt,
  group : GPUBindGroup,
  dynamic_offsets : Array[UInt],
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_bind_group(
    self.raw,
    index,
    group.raw,
    dynamic_offsets,
  )
}

///|
/// Implements `GPURenderPassEncoder::end`.
pub fn GPURenderPassEncoder::end(self : GPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_end(self.raw)
}

///|
/// Implements `GPURenderPassEncoder::release`.
pub fn GPURenderPassEncoder::release(self : GPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_release(self.raw)
}
