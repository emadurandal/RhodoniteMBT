///|
pub type WebGPURenderPassDepthStencilAttachment

///|
pub type WebGPURenderPassColorAttachment

///|
/// Implements `WebGPURenderPassColorAttachment::new`.
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment

///|
/// Implements `create_render_pass_color_attachment`.
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : @webgpu_enums.GPUColor,
  loadOp~ : @webgpu_enums.GPULoadOp,
  storeOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassColorAttachment

///|
pub type WebGPURenderPassDescriptor

///|
/// Implements `WebGPURenderPassDescriptor::new`.
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor

///|
/// Implements `create_render_pass_depth_stencil_attachment`.
pub fn create_render_pass_depth_stencil_attachment(
  view~ : GPUTextureView,
  depthClearValue~ : Double?,
  depthLoadOp~ : @webgpu_enums.GPULoadOp,
  depthStoreOp~ : @webgpu_enums.GPUStoreOp,
) -> WebGPURenderPassDepthStencilAttachment

///|
/// Implements `create_render_pass_descriptor`.
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor

///|
pub type WebGPURenderPipelineDescriptor

///|
/// Implements `WebGPURenderPipelineDescriptor::new`.
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : @webgpu_enums.GPUPrimitiveTopology,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor

///|
/// Implements `shaderModule_release`.
pub fn shaderModule_release(GPUShaderModule) -> Unit

///|
/// Implements `renderPipeline_release`.
pub fn renderPipeline_release(GPURenderPipeline) -> Unit

///|
/// Implements `textureView_release`.
pub fn textureView_release(GPUTextureView) -> Unit
