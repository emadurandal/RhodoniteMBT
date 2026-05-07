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
pub fn webgpu_texture_create_view(texture : WebGPUTexture) -> GPUTextureView {
  texture_createView(texture.texture)
}

///|
pub fn textureView_release(view : GPUTextureView) -> Unit {
  ignore(view)
}

///|
pub fn webgpu_texture_release(texture : WebGPUTexture) -> Unit {
  ignore(texture)
}
