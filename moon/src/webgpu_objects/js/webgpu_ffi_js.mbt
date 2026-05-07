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
extern "js" fn gpu_requestAdapter(gpu : GPU) -> @js_async.Promise[GPUAdapter] =
  #| (gpu) =>
  #|   gpu.requestAdapter().then((a) => {
  #|     if (a) return a;
  #|     throw new Error("No WebGPU adapter (requestAdapter returned null)");
  #|   })

///|
extern "js" fn gpu_requestDevice(
  adapter : GPUAdapter,
) -> @js_async.Promise[GPUDevice] =
  #| (adapter) => adapter.requestDevice()

// Synchronous getter methods (these are called after async init in JS)

///|
extern "js" fn gpu_getPreferredCanvasFormat(gpu : GPU) -> String =
  #| (gpu) => gpu.getPreferredCanvasFormat()

// GPUDevice methods

///|
extern "js" fn device_getQueue(device : GPUDevice) -> GPUQueue =
  #| (device) => device.queue

///|
extern "js" fn device_createShaderModule(
  device : GPUDevice,
  code : String,
) -> GPUShaderModule =
  #| (device, code) => device.createShaderModule({ code })

///|
pub(all) struct VertexAttributeFFI {
  formatTag : Int
  offset : Int
  shaderLocation : UInt
}

///|
pub(all) struct VertexBufferLayoutFFI {
  arrayStride : Int
  stepModeTag : Int
  attributes : Array[VertexAttributeFFI]
}

///|
extern "js" fn device_createRenderPipeline(
  device : GPUDevice,
  vertex : GPUShaderModule,
  fragment : GPUShaderModule,
  topologyTag : Int,
  formats : Array[String],
  vertexBuffers : Array[VertexBufferLayoutFFI],
) -> GPURenderPipeline =
  #| (device, vertex, fragment, topologyTag, formats, vertexBuffers) => {
  #|   const TOPOLOGY_NAMES = [
  #|     'point-list', 'line-list', 'line-strip', 'triangle-list', 'triangle-strip',
  #|   ];
  #|   const VERTEX_FORMAT_NAMES = ['float32x2', 'float32x3', 'float32x4'];
  #|   const STEP_NAMES = ['vertex', 'instance'];
  #|   const vbuf = vertexBuffers.map((b) => ({
  #|     arrayStride: b.arrayStride,
  #|     stepMode: STEP_NAMES[b.stepModeTag] ?? 'vertex',
  #|     attributes: b.attributes.map((a) => ({
  #|       format: VERTEX_FORMAT_NAMES[a.formatTag] ?? 'float32x2',
  #|       offset: a.offset,
  #|       shaderLocation: a.shaderLocation,
  #|     })),
  #|   }));
  #|   return device.createRenderPipeline({
  #|     layout: 'auto',
  #|     vertex: {
  #|       module: vertex,
  #|       entryPoint: 'vertexMain',
  #|       buffers: vbuf,
  #|     },
  #|     fragment: {
  #|       module: fragment,
  #|       entryPoint: 'fragmentMain',
  #|       targets: formats.map(format => ({ format }))
  #|     },
  #|     primitive: {
  #|       topology: TOPOLOGY_NAMES[topologyTag]
  #|     }
  #|   });
  #| }

///|
extern "js" fn device_createBuffer(
  device : GPUDevice,
  size : Double,
  usage : Double,
) -> GPUBuffer =
  #| (device, size, usage) =>
  #|   device.createBuffer({ size, usage: usage >>> 0 })

///|
extern "js" fn device_createCommandEncoder(
  device : GPUDevice,
) -> GPUCommandEncoder =
  #| (device) => device.createCommandEncoder()

// Canvas context methods

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
  #|     alphaMode: 'opaque'
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
  descriptor : WebGPURenderPassDescriptor,
) -> GPURenderPassEncoder =
  #| (encoder, descriptor) => {
  #|   const LOAD_LOAD = 0;
  #|   const LOAD_CLEAR = 1;
  #|   const STORE_STORE = 0;
  #|   const STORE_DISCARD = 1;
  #|   const mapLoad = (x) => (x === LOAD_CLEAR ? 'clear' : 'load');
  #|   const mapStore = (x) => (x === STORE_DISCARD ? 'discard' : 'store');
  #|   const colorAttachments = descriptor.colorAttachments.map((a) => {
  #|     if (!a) return a;
  #|     return {
  #|       view: a.view,
  #|       clearValue: a.clearValue,
  #|       loadOp: mapLoad(a.loadOp),
  #|       storeOp: mapStore(a.storeOp),
  #|     };
  #|   });
  #|   return encoder.beginRenderPass({
  #|     ...descriptor,
  #|     colorAttachments,
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
extern "js" fn renderPass_setVertexBuffer(
  pass : GPURenderPassEncoder,
  slot : Int,
  buffer : GPUBuffer,
  offset : Double,
  size : Double,
) -> Unit =
  #| (pass, slot, buffer, offset, size) =>
  #|   pass.setVertexBuffer(slot, buffer, offset, size)

///|
extern "js" fn renderPass_end(pass : GPURenderPassEncoder) -> Unit =
  #| (pass) => pass.end()

// Queue methods

///|
extern "js" fn queue_writeBuffer(
  queue : GPUQueue,
  buffer : GPUBuffer,
  offset : Double,
  data : Array[Byte],
) -> Unit =
  #| (queue, buffer, offset, data) =>
  #|   queue.writeBuffer(buffer, offset, new Uint8Array(data))

///|
extern "js" fn queue_submit(
  queue : GPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit =
  #| (queue, commandBuffer) => queue.submit([commandBuffer])
