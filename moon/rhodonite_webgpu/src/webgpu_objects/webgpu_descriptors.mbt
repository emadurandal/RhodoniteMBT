///|
pub type WebGPURenderPassDepthStencilAttachment

///|
pub type WebGPURenderPassColorAttachment

///|
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment

///|
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment

///|
pub type WebGPURenderPassDescriptor

///|
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor

///|
pub fn create_render_pass_depth_stencil_attachment(
  view~ : GPUTextureView,
  depthClearValue~ : Double?,
  depthLoadOp~ : @webgpu_enums.GPULoadOp,
  depthStoreOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassDepthStencilAttachment

///|
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor

///|
pub type WebGPURenderPipelineDescriptor

///|
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor

///|
pub fn shaderModule_release(GPUShaderModule) -> Unit

///|
pub fn renderPipeline_release(GPURenderPipeline) -> Unit

///|
pub fn textureView_release(GPUTextureView) -> Unit
