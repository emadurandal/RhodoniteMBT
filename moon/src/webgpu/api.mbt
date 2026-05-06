///|
pub fn navigatorGPU() -> GPU {
  @raw.navigatorGPU()
}

///|
pub fn canvas_getContext(canvas : HTMLCanvasElement) -> GPUCanvasContext {
  @raw.canvas_getContext(canvas)
}

///|
pub fn create_webgpu_instance(gpu : GPU) -> WebGPUInstance {
  { raw: @raw.create_webgpu_instance(gpu) }
}

///|
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  { raw: @raw.create_native_webgpu_instance() }
}

///|
pub fn create_canvas_context(context : GPUCanvasContext) -> WebGPUCanvasContext {
  { raw: @raw.create_canvas_context(context) }
}

///|
pub fn create_metal_canvas_context(
  instance : WebGPUInstance,
  layer : HTMLCanvasElement,
  width : Int,
  height : Int,
) -> WebGPUCanvasContext {
  { raw: @raw.create_metal_canvas_context(instance.raw, layer, width, height) }
}

///|
pub fn create_webgpu_context(
  device : WebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  {
    raw: @raw.create_webgpu_context(device.raw, context.raw, format, queue.raw),
  }
}

///|
pub fn webgpu_device_poll(device : WebGPUDevice, wait? : Bool = false) -> Bool {
  @raw.webgpu_device_poll(device.raw, wait~)
}

///|
pub fn webgpu_device_release(device : WebGPUDevice) -> Unit {
  @raw.webgpu_device_release(device.raw)
}

///|
pub fn webgpu_canvas_context_get_format(
  context : WebGPUCanvasContext,
) -> String {
  @raw.webgpu_canvas_context_get_format(context.raw)
}

///|
pub fn webgpu_canvas_context_release(context : WebGPUCanvasContext) -> Unit {
  @raw.webgpu_canvas_context_release(context.raw)
}

///|
pub fn webgpu_queue_release(queue : WebGPUQueue) -> Unit {
  @raw.webgpu_queue_release(queue.raw)
}

///|
pub fn webgpu_adapter_release(adapter : WebGPUAdapter) -> Unit {
  @raw.webgpu_adapter_release(adapter.raw)
}

///|
pub fn webgpu_instance_process_events(instance : WebGPUInstance) -> Unit {
  @raw.webgpu_instance_process_events(instance.raw)
}

///|
pub fn webgpu_instance_release(instance : WebGPUInstance) -> Unit {
  @raw.webgpu_instance_release(instance.raw)
}

///|
pub fn create_render_pass_color_attachment(
  view~ : GPUTextureView,
  clearValue? : GPUColor,
  loadOp~ : GPULoadOp,
  storeOp~ : GPUStoreOp,
) -> WebGPURenderPassColorAttachment {
  @raw.create_render_pass_color_attachment(
    view~,
    clearValue?,
    loadOp~,
    storeOp~,
  )
}

///|
pub fn create_render_pass_descriptor(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  @raw.create_render_pass_descriptor(colorAttachments~, depthStencilAttachment?)
}

///|
pub fn create_render_pipeline_descriptor(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor {
  @raw.create_render_pipeline_descriptor(
    vertex~,
    fragment~,
    topology~,
    formats~,
  )
}

///|
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  @raw.shaderModule_release(shaderModule)
}

///|
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  @raw.renderPipeline_release(pipeline.raw)
}

///|
pub fn textureView_release(view : GPUTextureView) -> Unit {
  @raw.textureView_release(view)
}
