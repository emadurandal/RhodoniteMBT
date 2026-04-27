// WebGPU texture implementation

///|
pub struct JsWebGPUTexture {
  texture : GPUTexture
}

///|
pub fn JsWebGPUTexture::new(texture : GPUTexture) -> JsWebGPUTexture {
  { texture, }
}

///|
pub fn JsWebGPUTexture::get(self : JsWebGPUTexture) -> GPUTexture {
  self.texture
}

///|
pub fn JsWebGPUTexture::createView(self : JsWebGPUTexture) -> GPUTextureView {
  texture_createView(self.texture)
}

///|
pub fn textureView_release(view : GPUTextureView) -> Unit {
  ignore(view)
}
