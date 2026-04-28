///|
pub type WebGPURenderPassDepthStencilAttachment

///|
pub type WebGPURenderPassColorAttachment

///|
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : GPUColorDict,
  loadOp~ : String,
  storeOp~ : String,
) -> WebGPURenderPassColorAttachment

///|
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : GPUColorDict,
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
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor

///|
pub type WebGPURenderPipelineDescriptor

///|
pub fn create_render_pipeline_descriptor(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor

///|
pub fn webgpu_render_pipeline_descriptor_get(
  WebGPURenderPipelineDescriptor,
) -> (GPUShaderModule, GPUShaderModule, String, Array[String])

///|
pub fn shaderModule_release(GPUShaderModule) -> Unit

///|
pub fn renderPipeline_release(GPURenderPipeline) -> Unit

///|
pub fn textureView_release(GPUTextureView) -> Unit
