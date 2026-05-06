///|
pub fn navigatorGPU() -> GPU {
  @raw.navigatorGPU()
}

///|
pub fn canvas_getContext(canvas : HTMLCanvasElement) -> @raw.GPUCanvasContext {
  @raw.canvas_getContext(canvas)
}

///|
pub fn create_webgpu_instance(gpu : GPU) -> GPUInstance {
  { raw: @raw.create_webgpu_instance(gpu) }
}

///|
pub fn create_native_webgpu_instance() -> GPUInstance raise Error {
  { raw: @raw.create_native_webgpu_instance() }
}

///|
pub fn create_canvas_context(
  context : @raw.GPUCanvasContext,
) -> GPUCanvasContext {
  { raw: @raw.create_canvas_context(context) }
}

///|
pub fn create_metal_canvas_context(
  instance : GPUInstance,
  layer : HTMLCanvasElement,
  width : Int,
  height : Int,
) -> GPUCanvasContext {
  { raw: @raw.create_metal_canvas_context(instance.raw, layer, width, height) }
}

///|
pub fn create_webgpu_context(
  device : GPUDevice,
  context : GPUCanvasContext,
  format : String,
  queue : GPUQueue,
) -> GPUContext {
  {
    raw: @raw.create_webgpu_context(device.raw, context.raw, format, queue.raw),
  }
}

///|
pub fn webgpu_device_poll(device : GPUDevice, wait? : Bool = false) -> Bool {
  @raw.webgpu_device_poll(device.raw, wait~)
}

///|
pub fn webgpu_device_release(device : GPUDevice) -> Unit {
  @raw.webgpu_device_release(device.raw)
}

///|
pub fn webgpu_canvas_context_get_format(context : GPUCanvasContext) -> String {
  @raw.webgpu_canvas_context_get_format(context.raw)
}

///|
pub fn webgpu_canvas_context_release(context : GPUCanvasContext) -> Unit {
  @raw.webgpu_canvas_context_release(context.raw)
}

///|
pub fn webgpu_queue_release(queue : GPUQueue) -> Unit {
  @raw.webgpu_queue_release(queue.raw)
}

///|
pub fn webgpu_adapter_release(adapter : GPUAdapter) -> Unit {
  @raw.webgpu_adapter_release(adapter.raw)
}

///|
pub fn webgpu_instance_process_events(instance : GPUInstance) -> Unit {
  @raw.webgpu_instance_process_events(instance.raw)
}

///|
pub fn webgpu_instance_release(instance : GPUInstance) -> Unit {
  @raw.webgpu_instance_release(instance.raw)
}

///|
fn render_pass_color_attachment_from_desc(
  att : GPURenderPassColorAttachment,
) -> @raw.WebGPURenderPassColorAttachment {
  match att.clear_value {
    Some(c) =>
      @raw.create_render_pass_color_attachment(
        view=att.view,
        clearValue=c,
        loadOp=att.load_op,
        storeOp=att.store_op,
      )
    None =>
      @raw.create_render_pass_color_attachment(
        view=att.view,
        loadOp=att.load_op,
        storeOp=att.store_op,
      )
  }
}

///|
fn render_pass_descriptor_to_raw(
  desc : GPURenderPassDescriptor,
) -> @raw.WebGPURenderPassDescriptor {
  let mapped = desc.color_attachments.map(fn(opt) {
    match opt {
      Some(att) => Some(render_pass_color_attachment_from_desc(att))
      None => None
    }
  })
  match desc.depth_stencil_attachment {
    Some(ds) =>
      @raw.create_render_pass_descriptor(
        colorAttachments=mapped,
        depthStencilAttachment=ds,
      )
    None => @raw.create_render_pass_descriptor(colorAttachments=mapped)
  }
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
