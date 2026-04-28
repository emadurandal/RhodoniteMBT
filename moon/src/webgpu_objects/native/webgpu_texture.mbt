///|
pub struct WebGPUTexture {
  texture : GPUTexture
}

///|
pub fn WebGPUTexture::new(texture : GPUTexture) -> WebGPUTexture {
  { texture, }
}

///|
pub fn WebGPUTexture::createView(self : WebGPUTexture) -> GPUTextureView {
  GPUTextureView::{ raw: self.texture.raw.create_view() }
}

///|
pub fn webgpu_texture_create_view(texture : WebGPUTexture) -> GPUTextureView {
  texture.createView()
}
