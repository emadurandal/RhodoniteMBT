///|
pub type WebGPUColor

///|
pub fn WebGPUColor::new(Double, Double, Double, Double) -> WebGPUColor

///|
pub type WebGPURenderPassDepthStencilAttachment

///|
pub type WebGPURenderPassColorAttachment

///|
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : WebGPUColor,
  loadOp~ : String,
  storeOp~ : String,
) -> WebGPURenderPassColorAttachment

///|
pub type WebGPURenderPassDescriptor

///|
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor

///|
pub type WebGPURenderPipelineDescriptor

///|
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor

///|
pub fn shaderModule_release(GPUShaderModule) -> Unit

///|
pub fn renderPipeline_release(GPURenderPipeline) -> Unit

///|
pub fn textureView_release(GPUTextureView) -> Unit
