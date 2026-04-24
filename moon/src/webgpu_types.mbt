// WebGPU FFI type definitions for MoonBit

// Core WebGPU types
///|
pub type GPU

///|
pub type GPUAdapter

///|
pub type GPUDevice

///|
pub type GPUQueue

///|
pub type GPUCanvasContext

///|
pub type GPUTexture

///|
pub type GPUTextureView

///|
pub type GPUBuffer

///|
pub type GPUShaderModule

///|
pub type GPURenderPipeline

///|
pub type GPUCommandEncoder

///|
pub type GPURenderPassEncoder

///|
pub type GPUCommandBuffer

// Navigator GPU access

///|
extern "js" fn navigatorGPU() -> GPU =
  #| () => navigator.gpu

// Synchronous getter methods (these are called after async init in JS)

///|
extern "js" fn gpu_getPreferredCanvasFormat(gpu : GPU) -> String =
  #| (gpu) => gpu.getPreferredCanvasFormat()

// GPUDevice methods

///|
pub extern "js" fn device_getQueue(device : GPUDevice) -> GPUQueue =
  #| (device) => device.queue

///|
extern "js" fn device_createBuffer(
  device : GPUDevice,
  size : Int,
  usage : Int,
) -> GPUBuffer =
  #| (device, size, usage) => device.createBuffer({ size, usage })

///|
extern "js" fn device_createShaderModule(
  device : GPUDevice,
  code : String,
) -> GPUShaderModule =
  #| (device, code) => device.createShaderModule({ code })

///|
extern "js" fn device_createRenderPipeline(
  device : GPUDevice,
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topology : String,
  format : String,
) -> GPURenderPipeline =
  #| (device, vertex, fragment, topology, format) => {
  #|   return device.createRenderPipeline({
  #|     layout: 'auto',
  #|     vertex: {
  #|       module: vertex,
  #|       entryPoint: 'vertexMain'
  #|     },
  #|     fragment: {
  #|       module: fragment,
  #|       entryPoint: 'fragmentMain',
  #|       targets: [{ format }]
  #|     },
  #|     primitive: {
  #|       topology
  #|     }
  #|   });
  #| }

///|
extern "js" fn device_createCommandEncoder(
  device : GPUDevice,
) -> GPUCommandEncoder =
  #| (device) => device.createCommandEncoder()

// Canvas context methods

///|
extern "js" fn getCanvasContext(canvasId : String) -> GPUCanvasContext =
  #| (canvasId) => {
  #|   const canvas = document.getElementById(canvasId);
  #|   return canvas.getContext('webgpu');
  #| }

///|
extern "js" fn context_configure(
  context : GPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit =
  #| (context, device, format) => {
  #|   context.configure({
  #|     device,
  #|     format,
  #|     alphaMode: 'premultiplied'
  #|   });
  #| }

///|
extern "js" fn context_getCurrentTexture(
  context : GPUCanvasContext,
) -> GPUTexture =
  #| (context) => context.getCurrentTexture()

// GPUTexture methods

///|
extern "js" fn texture_createView(texture : GPUTexture) -> GPUTextureView =
  #| (texture) => texture.createView()

// Command encoder methods

///|
extern "js" fn encoder_beginRenderPass(
  encoder : GPUCommandEncoder,
  view : GPUTextureView,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> GPURenderPassEncoder =
  #| (encoder, view, r, g, b, a) => {
  #|   return encoder.beginRenderPass({
  #|     colorAttachments: [{
  #|       view,
  #|       clearValue: { r, g, b, a },
  #|       loadOp: 'clear',
  #|       storeOp: 'store'
  #|     }]
  #|   });
  #| }

///|
extern "js" fn encoder_finish(encoder : GPUCommandEncoder) -> GPUCommandBuffer =
  #| (encoder) => encoder.finish()

// Render pass encoder methods

///|
extern "js" fn renderPass_setPipeline(
  pass : GPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit =
  #| (pass, pipeline) => pass.setPipeline(pipeline)

///|
extern "js" fn renderPass_draw(
  pass : GPURenderPassEncoder,
  vertexCount : Int,
) -> Unit =
  #| (pass, vertexCount) => pass.draw(vertexCount)

///|
extern "js" fn renderPass_end(pass : GPURenderPassEncoder) -> Unit =
  #| (pass) => pass.end()

// Queue methods

///|
extern "js" fn queue_submit(
  queue : GPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit =
  #| (queue, commandBuffer) => queue.submit([commandBuffer])

// Buffer usage flags

///|
pub const BUFFER_USAGE_VERTEX : Int = 0x0020

///|
pub const BUFFER_USAGE_COPY_DST : Int = 0x0008
