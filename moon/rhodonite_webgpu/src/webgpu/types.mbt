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
}

///|
/// Defines `GPUBuffer`.
pub(all) struct GPUBuffer {
  raw : @raw.GPUBuffer
}

///|
/// Defines `GPUTexture`.
pub(all) struct GPUTexture {
  raw : @raw.WebGPUTexture
}

///|
/// Defines `GPUBindGroupLayout`.
pub(all) struct GPUBindGroupLayout {
  raw : @raw.GPUBindGroupLayout
}

///|
/// Defines `GPUBindGroup`.
pub(all) struct GPUBindGroup {
  raw : @raw.GPUBindGroup
}

///|
/// Whole-buffer bind range (matches WebGPU / `wgpu` `WGPU_WHOLE_SIZE`).
pub const GPU_BUFFER_BINDING_WHOLE_SIZE : UInt64 = 0xFFFFFFFFFFFFFFFFUL

///|
/// WebGPU `GPUBufferBinding`.
pub(all) struct GPUBufferBinding {
  buffer : GPUBuffer
  offset : UInt64
  size : UInt64
}

///|
/// WebGPU `GPUBindingResource`.
pub(all) enum GPUBindingResource {
  Sampler(GPUSampler)
  Texture(GPUTexture)
  TextureView(GPUTextureView)
  Buffer(GPUBuffer)
  BufferBinding(GPUBufferBinding)
  ExternalTexture(GPUExternalTexture)
}

///|
/// WebGPU `GPUBindGroupEntry`.
pub(all) struct GPUBindGroupEntry {
  binding : UInt
  resource : GPUBindingResource
}

///|
/// WebGPU `GPUBindGroupDescriptor`.
pub(all) struct GPUBindGroupDescriptor {
  layout : GPUBindGroupLayout
  entries : Array[GPUBindGroupEntry]
}

///|
/// Defines `GPUSampler`.
pub(all) struct GPUSampler {
  raw : @raw.GPUSampler
}

///|
/// Defines `GPUExternalTexture`.
pub(all) struct GPUExternalTexture {
  raw : @raw.GPUExternalTexture
}

///|
/// Defines `GPURenderPassColorAttachment`.
pub(all) struct GPURenderPassColorAttachment {
  view : GPUTextureView
  clear_value : GPUColor?
  load_op : GPULoadOp
  store_op : GPUStoreOp
}

///|
/// Defines `GPURenderPassDepthStencilAttachment`.
pub(all) struct GPURenderPassDepthStencilAttachment {
  view : GPUTextureView
  depth_clear_value : Double?
  depth_load_op : GPULoadOp
  depth_store_op : GPUStoreOp
}

///|
/// Defines `GPURenderPassDescriptor`.
pub(all) struct GPURenderPassDescriptor {
  color_attachments : Array[GPURenderPassColorAttachment?]
  depth_stencil_attachment : GPURenderPassDepthStencilAttachment?
}

///|
/// Defines `GPUInstance`.
pub(all) struct GPUInstance {
  raw : @raw.WebGPUInstance
}

///|
/// Defines `GPUAdapter`.
pub(all) struct GPUAdapter {
  raw : @raw.WebGPUAdapter
}

///|
/// Defines `GPUDevice`.
pub(all) struct GPUDevice {
  raw : @raw.WebGPUDevice
}

///|
/// Defines `GPUQueue`.
pub(all) struct GPUQueue {
  raw : @raw.WebGPUQueue
}

///|
/// Defines `GPUCanvasContext`.
pub(all) struct GPUCanvasContext {
  raw : @raw.WebGPUCanvasContext
}

///|
/// Defines `GPURenderPipelineDescriptor`.
pub(all) struct GPURenderPipelineDescriptor {
  vertex : GPUShaderModule
  fragment : GPUShaderModule
  topology : GPUPrimitiveTopology
  formats : Array[String]
  vertex_buffers : Array[GPUVertexBufferLayout]
  /// When `Some("depth24plus")`, depth testing is enabled; `None` keeps legacy behavior.
  depth_stencil_format : String?
}

///|
/// Defines `GPURenderPipeline`.
pub(all) struct GPURenderPipeline {
  raw : @raw.GPURenderPipeline
}

///|
/// Defines `GPUCommandEncoder`.
pub(all) struct GPUCommandEncoder {
  raw : @raw.WebGPUCommandEncoder
}

///|
/// Defines `GPURenderPassEncoder`.
pub(all) struct GPURenderPassEncoder {
  raw : @raw.WebGPURenderPassEncoder
}

///|
/// Defines `GPUContext`.
pub(all) struct GPUContext {
  raw : @raw.WebGPUContext
}

///|
/// Shared WebGPU device state that can be used by multiple presentation surfaces.
pub(all) struct GPUDeviceContext {
  instance : GPUInstance
  adapter : GPUAdapter
  device : GPUDevice
  queue : GPUQueue
}

///|
/// Presentation surface backed by one browser canvas or native window swapchain.
pub(all) struct GPUSurface {
  context : GPUCanvasContext
  mut format : String
  mut width : Int
  mut height : Int
  mut active : Bool
  mut generation : Int
}
