///|
pub using @enums {type GPULoadOp, type GPUStoreOp, type GPUColor}

///|
pub using @raw {
  type GPU,
  type GPUAdapter,
  type GPUDevice,
  type GPUQueue,
  type GPUCanvasContext,
  type GPUTexture,
  type GPUTextureView,
  type GPUShaderModule,
  type GPUCommandEncoder,
  type GPURenderPassEncoder,
  type GPUCommandBuffer,
  type HTMLCanvasElement,
  type WebGPURenderPassDepthStencilAttachment,
  type WebGPURenderPipelineDescriptor,
}

///|
pub(all) struct WebGPURenderPassColorAttachment {
  view : GPUTextureView
  clear_value : GPUColor?
  load_op : GPULoadOp
  store_op : GPUStoreOp
}

///|
pub(all) struct WebGPURenderPassDescriptor {
  color_attachments : Array[WebGPURenderPassColorAttachment?]
  depth_stencil_attachment : WebGPURenderPassDepthStencilAttachment?
}

///|
pub(all) struct WebGPUInstance {
  raw : @raw.WebGPUInstance
}

///|
pub(all) struct WebGPUAdapter {
  raw : @raw.WebGPUAdapter
}

///|
pub(all) struct WebGPUDevice {
  raw : @raw.WebGPUDevice
}

///|
pub(all) struct WebGPUQueue {
  raw : @raw.WebGPUQueue
}

///|
pub(all) struct WebGPUCanvasContext {
  raw : @raw.WebGPUCanvasContext
}

///|
pub(all) struct WebGPUTexture {
  raw : @raw.WebGPUTexture
}

///|
pub(all) struct GPURenderPipeline {
  raw : @raw.GPURenderPipeline
}

///|
pub(all) struct WebGPUCommandEncoder {
  raw : @raw.WebGPUCommandEncoder
}

///|
pub(all) struct WebGPURenderPassEncoder {
  raw : @raw.WebGPURenderPassEncoder
}

///|
pub(all) struct WebGPUContext {
  raw : @raw.WebGPUContext
}
