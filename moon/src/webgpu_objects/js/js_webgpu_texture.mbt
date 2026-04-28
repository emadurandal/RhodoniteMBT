// WebGPU texture implementation

///|
pub struct WebGPUTexture {
  texture : GPUTexture
}

///|
pub fn WebGPUTexture::new(texture : GPUTexture) -> WebGPUTexture {
  { texture, }
}

///|
pub fn WebGPUTexture::get(self : WebGPUTexture) -> GPUTexture {
  self.texture
}

///|
pub fn WebGPUTexture::createView(self : WebGPUTexture) -> GPUTextureView {
  texture_createView(self.texture)
}

///|
fn textureView_release(view : GPUTextureView) -> Unit {
  ignore(view)
}
