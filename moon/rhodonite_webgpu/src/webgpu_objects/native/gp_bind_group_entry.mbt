///|
pub(all) enum ImplBindGroupEntry {
  Buffer(UInt, GPUBuffer)
  BufferBinding(UInt, GPUBuffer, UInt64, UInt64)
  TextureView(UInt, GPUTextureView)
  Texture(UInt, WebGPUTexture)
  Sampler(UInt, GPUSampler)
  ExternalTexture(UInt, GPUExternalTexture)
}

///|
pub(all) struct GPUBindGroupEntry {
  inner : ImplBindGroupEntry
}

///|
pub fn gp_bind_group_entry_buffer(
  binding : UInt,
  buffer : GPUBuffer,
) -> GPUBindGroupEntry {
  GPUBindGroupEntry::{ inner: Buffer(binding, buffer) }
}

///|
pub fn gp_bind_group_entry_buffer_binding(
  binding : UInt,
  buffer : GPUBuffer,
  offset : UInt64,
  size : UInt64,
) -> GPUBindGroupEntry {
  GPUBindGroupEntry::{ inner: BufferBinding(binding, buffer, offset, size) }
}

///|
pub fn gp_bind_group_entry_texture_view(
  binding : UInt,
  view : GPUTextureView,
) -> GPUBindGroupEntry {
  GPUBindGroupEntry::{ inner: TextureView(binding, view) }
}

///|
pub fn gp_bind_group_entry_texture(
  binding : UInt,
  texture : WebGPUTexture,
) -> GPUBindGroupEntry {
  GPUBindGroupEntry::{ inner: Texture(binding, texture) }
}

///|
pub fn gp_bind_group_entry_sampler(
  binding : UInt,
  sampler : GPUSampler,
) -> GPUBindGroupEntry {
  GPUBindGroupEntry::{ inner: Sampler(binding, sampler) }
}

///|
pub fn gp_bind_group_entry_external_texture(
  binding : UInt,
  tex : GPUExternalTexture,
) -> GPUBindGroupEntry {
  GPUBindGroupEntry::{ inner: ExternalTexture(binding, tex) }
}
