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
  type GPURenderPipeline,
  type GPUCommandEncoder,
  type GPURenderPassEncoder,
  type GPUCommandBuffer,
  type HTMLCanvasElement,
  type WebGPUColor,
  type WebGPURenderPassDepthStencilAttachment,
  type WebGPURenderPassColorAttachment,
  type WebGPURenderPassDescriptor,
  type WebGPURenderPipelineDescriptor,
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
