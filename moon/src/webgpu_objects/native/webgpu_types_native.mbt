///|
pub const BUFFER_USAGE_VERTEX : Int = 0x0020

///|
pub const BUFFER_USAGE_COPY_DST : Int = 0x0008

///|
pub struct GPU {
  raw : @wgpu.Instance
}

///|
pub struct GPUAdapter {
  raw : @wgpu.Adapter
  instance : @wgpu.Instance
}

///|
pub struct GPUDevice {
  raw : @wgpu.Device
  adapter : @wgpu.Adapter
  instance : @wgpu.Instance
}

///|
pub struct GPUQueue {
  raw : @wgpu.Queue
}

///|
pub struct GPUCanvasContext {
  surface : @wgpu.Surface
  width : UInt
  height : UInt
  format : Ref[String]
  currentTexture : Ref[@wgpu.Texture?]
}

///|
pub struct GPUTexture {
  raw : @wgpu.Texture
}

///|
pub struct GPUTextureView {
  raw : @wgpu.TextureView
}

///|
pub impl @traits.WebGPUTextureView for GPUTextureView

///|
pub struct GPUBuffer {
  raw : @wgpu.Buffer
}

///|
pub struct GPUShaderModule {
  raw : @wgpu.ShaderModule
}

///|
pub impl @traits.WebGPUShaderModule for GPUShaderModule

///|
pub struct GPURenderPipeline {
  raw : @wgpu.RenderPipeline
}

///|
pub impl @traits.WebGPURenderPipeline for GPURenderPipeline

///|
pub struct GPUCommandEncoder {
  raw : @wgpu.CommandEncoder
}

///|
pub struct GPURenderPassEncoder {
  raw : @wgpu.RenderPass
}

///|
pub struct GPUCommandBuffer {
  raw : @wgpu.CommandBuffer
}

///|
pub impl @traits.WebGPUCommandBuffer for GPUCommandBuffer
