///|
pub struct WebGPUTexture {
  texture : GPUTexture
}

///|
pub fn WebGPUTexture::new(texture : GPUTexture) -> WebGPUTexture {
  { texture, }
}

///|
pub fn webgpu_texture_create_view(texture : WebGPUTexture) -> GPUTextureView {
  GPUTextureView::{ raw: texture.texture.raw.create_view() }
}
