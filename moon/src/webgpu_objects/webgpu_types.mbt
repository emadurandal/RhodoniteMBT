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

///|
pub type HTMLCanvasElement

// Navigator GPU access

///|
pub extern "js" fn navigatorGPU() -> GPU =
  #| () => navigator.gpu

///|
pub extern "js" fn canvas_getContext(
  canvas : HTMLCanvasElement,
) -> GPUCanvasContext =
  #| (canvas) => {
  #|   const context = canvas.getContext("webgpu");
  #|   if (!context) {
  #|     throw new Error("Failed to get WebGPU context");
  #|   }
  #|   return context;
  #| }

///|
/// Use `Promise[GPUAdapter]` (not optional): `GPUAdapter?` in the Promise layer
/// can mis-classify valid handles as [None] at the JS boundary. On `null`, reject
/// so [Promise::wait] fails instead of returning a bogus [None].
pub extern "js" fn gpu_requestAdapter(
  gpu : GPU,
) -> @js_async.Promise[GPUAdapter] =
  #| (gpu) =>
  #|   gpu.requestAdapter().then((a) => {
  #|     if (a) return a;
  #|     throw new Error("No WebGPU adapter (requestAdapter returned null)");
  #|   })

///|
pub extern "js" fn gpu_requestDevice(
  adapter : GPUAdapter,
) -> @js_async.Promise[GPUDevice] =
  #| (adapter) => adapter.requestDevice()

// Synchronous getter methods (these are called after async init in JS)

///|
pub extern "js" fn gpu_getPreferredCanvasFormat(gpu : GPU) -> String =
  #| (gpu) => gpu.getPreferredCanvasFormat()

// GPUDevice methods

///|
pub extern "js" fn device_getQueue(device : GPUDevice) -> GPUQueue =
  #| (device) => device.queue

///|
pub extern "js" fn device_createBuffer(
  device : GPUDevice,
  size : Int,
  usage : Int,
) -> GPUBuffer =
  #| (device, size, usage) => device.createBuffer({ size, usage })

///|
pub extern "js" fn device_createShaderModule(
  device : GPUDevice,
  code : String,
) -> GPUShaderModule =
  #| (device, code) => device.createShaderModule({ code })

///|
pub extern "js" fn device_createRenderPipeline(
  device : GPUDevice,
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topology : String,
  formats : Array[String],
) -> GPURenderPipeline =
  #| (device, vertex, fragment, topology, formats) => {
  #|   return device.createRenderPipeline({
  #|     layout: 'auto',
  #|     vertex: {
  #|       module: vertex,
  #|       entryPoint: 'vertexMain'
  #|     },
  #|     fragment: {
  #|       module: fragment,
  #|       entryPoint: 'fragmentMain',
  #|       targets: formats.map(format => ({ format }))
  #|     },
  #|     primitive: {
  #|       topology
  #|     }
  #|   });
  #| }

///|
pub extern "js" fn device_createCommandEncoder(
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
pub extern "js" fn context_configure(
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
pub extern "js" fn context_getCurrentTexture(
  context : GPUCanvasContext,
) -> GPUTexture =
  #| (context) => context.getCurrentTexture()

// GPUTexture methods

///|
pub extern "js" fn texture_createView(texture : GPUTexture) -> GPUTextureView =
  #| (texture) => texture.createView()

// Command encoder methods

///|
pub extern "js" fn encoder_beginRenderPass(
  encoder : GPUCommandEncoder,
  attachments : Array[WebGPUColorAttachment],
) -> GPURenderPassEncoder =
  #| (encoder, attachments) => {
  #|   return encoder.beginRenderPass({
  #|     colorAttachments: 
  #|       attachments.map(attachment => {
  #|         return {
  #|           view: attachment.view,
  #|           clearValue: attachment.clearValue,
  #|           loadOp: attachment.loadOp,
  #|           storeOp: attachment.storeOp
  #|         };
  #|       }),
  #|   });
  #| }

///|
pub extern "js" fn encoder_finish(
  encoder : GPUCommandEncoder,
) -> GPUCommandBuffer =
  #| (encoder) => encoder.finish()

// Render pass encoder methods

///|
pub extern "js" fn renderPass_setPipeline(
  pass : GPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit =
  #| (pass, pipeline) => pass.setPipeline(pipeline)

///|
pub extern "js" fn renderPass_draw(
  pass : GPURenderPassEncoder,
  vertexCount : Int,
) -> Unit =
  #| (pass, vertexCount) => pass.draw(vertexCount)

///|
pub extern "js" fn renderPass_end(pass : GPURenderPassEncoder) -> Unit =
  #| (pass) => pass.end()

// Queue methods

///|
pub extern "js" fn queue_submit(
  queue : GPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit =
  #| (queue, commandBuffer) => queue.submit([commandBuffer])

// Buffer usage flags

///|
pub const BUFFER_USAGE_VERTEX : Int = 0x0020

///|
pub const BUFFER_USAGE_COPY_DST : Int = 0x0008
