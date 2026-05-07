///|
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  ignore(shaderModule)
}

///|
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  ignore(pipeline)
}

///|
extern "js" fn gpu_buffer_destroy(buffer : GPUBuffer) -> Unit =
  #| (b) => b.destroy()

///|
pub fn buffer_release(buffer : GPUBuffer) -> Unit {
  gpu_buffer_destroy(buffer)
}
