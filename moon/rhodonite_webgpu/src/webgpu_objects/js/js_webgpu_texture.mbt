// WebGPU texture implementation

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
  texture_createView(texture.texture)
}

///|
/// Implements `textureView_release`.
pub fn textureView_release(view : GPUTextureView) -> Unit {
  ignore(view)
}

///|
/// Implements `webgpu_texture_release`.
pub fn webgpu_texture_release(texture : WebGPUTexture) -> Unit {
  ignore(texture)
}
