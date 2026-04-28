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
pub struct GPUBuffer {
  raw : @wgpu.Buffer
}

///|
pub struct GPUShaderModule {
  raw : @wgpu.ShaderModule
}

///|
pub struct GPURenderPipeline {
  raw : @wgpu.RenderPipeline
}

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
