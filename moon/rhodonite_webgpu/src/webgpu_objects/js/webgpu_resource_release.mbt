///|
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  ignore(shaderModule)
}

///|
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  ignore(pipeline)
}

///|
pub fn bindGroupLayout_release(layout : GPUBindGroupLayout) -> Unit {
  ignore(layout)
}

///|
pub fn bindGroup_release(group : GPUBindGroup) -> Unit {
  ignore(group)
}

///|
extern "js" fn gpu_buffer_destroy(buffer : GPUBuffer) -> Unit =
  #| (b) => b.destroy()

///|
pub fn buffer_release(buffer : GPUBuffer) -> Unit {
  gpu_buffer_destroy(buffer)
}
