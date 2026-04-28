///|
pub struct WebGPUTexture {
  texture : GPUTexture
}

///|
pub impl @traits.WebGPUTexture for WebGPUTexture

///|
pub fn WebGPUTexture::new(texture : GPUTexture) -> WebGPUTexture {
  { texture, }
}

///|
pub fn WebGPUTexture::createView(self : WebGPUTexture) -> GPUTextureView {
  GPUTextureView::{ raw: self.texture.raw.create_view() }
}
