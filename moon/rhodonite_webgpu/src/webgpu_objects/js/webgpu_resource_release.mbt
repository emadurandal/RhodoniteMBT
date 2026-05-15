///|
/// Implements `shaderModule_release`.
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  ignore(shaderModule)
}

///|
/// Implements `renderPipeline_release`.
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  ignore(pipeline)
}

///|
/// Implements `bindGroupLayout_release`.
pub fn bindGroupLayout_release(layout : GPUBindGroupLayout) -> Unit {
  ignore(layout)
}

///|
/// Implements `bindGroup_release`.
pub fn bindGroup_release(group : GPUBindGroup) -> Unit {
  ignore(group)
}

///|
extern "js" fn gpu_buffer_destroy(buffer : GPUBuffer) -> Unit =
  #| (b) => b.destroy()

///|
/// Implements `buffer_release`.
pub fn buffer_release(buffer : GPUBuffer) -> Unit {
  gpu_buffer_destroy(buffer)
}
