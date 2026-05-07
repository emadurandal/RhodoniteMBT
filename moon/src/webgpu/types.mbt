///|
pub using @enums {
  type GPULoadOp,
  type GPUStoreOp,
  type GPUColor,
  type GPUPrimitiveTopology,
  type GPUIndexFormat,
  type GPUVertexAttribute,
  type GPUVertexBufferLayout,
  type GPUVertexFormat,
  type GPUVertexStepMode,
}

///|
pub using @raw {
  type GPU,
  type GPUTextureView,
  type GPUShaderModule,
  type GPUCommandBuffer,
  type HTMLCanvasElement,
  type WebGPURenderPassDepthStencilAttachment,
}

///|
pub(all) struct GPUBuffer {
  raw : @raw.GPUBuffer
}

///|
pub(all) struct GPURenderPassColorAttachment {
  view : GPUTextureView
  clear_value : GPUColor?
  load_op : GPULoadOp
  store_op : GPUStoreOp
}

///|
pub(all) struct GPURenderPassDescriptor {
  color_attachments : Array[GPURenderPassColorAttachment?]
  depth_stencil_attachment : WebGPURenderPassDepthStencilAttachment?
}

///|
pub(all) struct GPUInstance {
  raw : @raw.WebGPUInstance
}

///|
pub(all) struct GPUAdapter {
  raw : @raw.WebGPUAdapter
}

///|
pub(all) struct GPUDevice {
  raw : @raw.WebGPUDevice
}

///|
pub(all) struct GPUQueue {
  raw : @raw.WebGPUQueue
}

///|
pub(all) struct GPUCanvasContext {
  raw : @raw.WebGPUCanvasContext
}

///|
pub(all) struct GPUTexture {
  raw : @raw.WebGPUTexture
}

///|
pub(all) struct GPURenderPipelineDescriptor {
  vertex : GPUShaderModule
  fragment : GPUShaderModule
  topology : GPUPrimitiveTopology
  formats : Array[String]
  vertex_buffers : Array[GPUVertexBufferLayout]
}

///|
pub(all) struct GPURenderPipeline {
  raw : @raw.GPURenderPipeline
}

///|
pub(all) struct GPUCommandEncoder {
  raw : @raw.WebGPUCommandEncoder
}

///|
pub(all) struct GPURenderPassEncoder {
  raw : @raw.WebGPURenderPassEncoder
}

///|
pub(all) struct GPUContext {
  raw : @raw.WebGPUContext
}
