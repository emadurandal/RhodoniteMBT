///|
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  shaderModule.raw.release()
}
