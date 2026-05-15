///|
/// Defines `WebGPUTexture`.
pub struct WebGPUTexture {
  texture : GPUTexture
}

///|
/// Implements `WebGPUTexture::new`.
pub fn WebGPUTexture::new(texture : GPUTexture) -> WebGPUTexture {
  { texture, }
}

///|
/// Implements `webgpu_texture_create_view`.
pub fn webgpu_texture_create_view(texture : WebGPUTexture) -> GPUTextureView {
  GPUTextureView::{ raw: texture.texture.raw.create_view() }
}

///|
/// Implements `webgpu_texture_release`.
pub fn webgpu_texture_release(texture : WebGPUTexture) -> Unit {
  texture.texture.raw.release()
}
