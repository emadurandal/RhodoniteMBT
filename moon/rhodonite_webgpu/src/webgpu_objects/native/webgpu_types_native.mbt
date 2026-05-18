///|
/// Defines `GPU`.
pub struct GPU {
  raw : @wgpu.Instance
}

///|
/// Defines `GPUAdapter`.
pub struct GPUAdapter {
  raw : @wgpu.Adapter
  instance : @wgpu.Instance
}

///|
/// Defines `GPUDevice`.
pub struct GPUDevice {
  raw : @wgpu.Device
  adapter : @wgpu.Adapter
  instance : @wgpu.Instance
}

///|
/// Defines `GPUQueue`.
pub struct GPUQueue {
  raw : @wgpu.Queue
}

///|
/// Defines `GPUCanvasContext`.
pub struct GPUCanvasContext {
  surface : @wgpu.Surface
  mut width : UInt
  mut height : UInt
  /// Color format reported to the engine.
  format : Ref[String]
  /// Configured swapchain format used by the native surface.
  swapFormat : Ref[String]
  /// True when rendering should go through the offscreen swapchain relay.
  relayEnabled : Bool
  currentTexture : Ref[@wgpu.Texture?]
  relay : Ref[LinuxSwapchainRelay?]
  relayDevice : Ref[GPUDevice?]
}

///|
/// Defines `GPUTexture`.
pub struct GPUTexture {
  raw : @wgpu.Texture
}

///|
/// Defines `GPUTextureView`.
pub struct GPUTextureView {
  raw : @wgpu.TextureView
}

///|
/// Defines `GPUShaderModule`.
pub struct GPUShaderModule {
  raw : @wgpu.ShaderModule
}

///|
/// Defines `GPURenderPipeline`.
pub struct GPURenderPipeline {
  raw : @wgpu.RenderPipeline
}

///|
/// Defines `GPUCommandEncoder`.
pub struct GPUCommandEncoder {
  raw : @wgpu.CommandEncoder
}

///|
/// Defines `GPURenderPassEncoder`.
pub struct GPURenderPassEncoder {
  raw : @wgpu.RenderPass
}

///|
/// Defines `GPUCommandBuffer`.
pub struct GPUCommandBuffer {
  raw : @wgpu.CommandBuffer
}

///|
/// Defines `GPUBuffer`.
pub struct GPUBuffer {
  raw : @wgpu.Buffer
}

///|
/// Defines `GPUBindGroupLayout`.
pub struct GPUBindGroupLayout {
  raw : @wgpu.BindGroupLayout
}

///|
/// Defines `GPUBindGroup`.
pub struct GPUBindGroup {
  raw : @wgpu.BindGroup
}

///|
/// Defines `GPUSampler`.
pub struct GPUSampler {
  raw : @wgpu.Sampler
}

///|
/// Defines `GPUExternalTexture`.
pub struct GPUExternalTexture {
  raw : UInt
}
