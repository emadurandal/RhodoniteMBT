///|
/// Implements `navigatorGPU`.
pub fn navigatorGPU() -> GPU {
  @raw.navigatorGPU()
}

///|
/// Implements `canvas_getContext`.
pub fn canvas_getContext(canvas : HTMLCanvasElement) -> @raw.GPUCanvasContext {
  @raw.canvas_getContext(canvas)
}

///|
/// Implements `create_webgpu_instance`.
pub fn create_webgpu_instance(gpu : GPU) -> GPUInstance {
  { raw: @raw.create_webgpu_instance(gpu) }
}

///|
/// Implements `create_native_webgpu_instance`.
pub fn create_native_webgpu_instance() -> GPUInstance raise Error {
  { raw: @raw.create_native_webgpu_instance() }
}

///|
/// Implements `create_canvas_context`.
pub fn create_canvas_context(
  context : @raw.GPUCanvasContext,
) -> GPUCanvasContext {
  { raw: @raw.create_canvas_context(context) }
}

///|
/// Implements `create_metal_canvas_context`.
pub fn create_metal_canvas_context(
  instance : GPUInstance,
  layer : HTMLCanvasElement,
  width : Int,
  height : Int,
) -> GPUCanvasContext {
  { raw: @raw.create_metal_canvas_context(instance.raw, layer, width, height) }
}

///|
/// Implements `create_webgpu_context`.
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
/// Builds shared WebGPU device state for platform runtimes with multiple surfaces.
pub fn create_gpu_device_context(
  instance : GPUInstance,
  adapter : GPUAdapter,
  device : GPUDevice,
  queue : GPUQueue,
) -> GPUDeviceContext {
  { instance, adapter, device, queue }
}

///|
/// Builds an active presentation surface from an already configured canvas context.
pub fn create_gpu_surface(
  context : GPUCanvasContext,
  format : String,
  width : Int,
  height : Int,
) -> GPUSurface {
  {
    context,
    format,
    width,
    height,
    active: width > 0 && height > 0,
    generation: 0,
  }
}

///|
/// Implements `webgpu_device_poll`.
pub fn webgpu_device_poll(device : GPUDevice, wait? : Bool = false) -> Bool {
  @raw.webgpu_device_poll(device.raw, wait~)
}

///|
/// Implements `webgpu_device_release`.
pub fn webgpu_device_release(device : GPUDevice) -> Unit {
  @raw.webgpu_device_release(device.raw)
}

///|
/// Implements `webgpu_canvas_context_get_format`.
pub fn webgpu_canvas_context_get_format(context : GPUCanvasContext) -> String {
  @raw.webgpu_canvas_context_get_format(context.raw)
}

///|
/// Resizes and reconfigures a canvas context when the platform surface size changes.
pub fn webgpu_canvas_context_resize(
  context : GPUCanvasContext,
  device : GPUDevice,
  format : String,
  width : Int,
  height : Int,
) -> Unit {
  @raw.webgpu_canvas_context_resize(
    context.raw,
    @raw.webgpu_device_get(device.raw),
    format,
    width,
    height,
  )
}

///|
/// Implements `webgpu_canvas_context_release`.
pub fn webgpu_canvas_context_release(context : GPUCanvasContext) -> Unit {
  @raw.webgpu_canvas_context_release(context.raw)
}

///|
/// Implements `webgpu_queue_release`.
pub fn webgpu_queue_release(queue : GPUQueue) -> Unit {
  @raw.webgpu_queue_release(queue.raw)
}

///|
/// Implements `webgpu_adapter_release`.
pub fn webgpu_adapter_release(adapter : GPUAdapter) -> Unit {
  @raw.webgpu_adapter_release(adapter.raw)
}

///|
/// Implements `webgpu_instance_process_events`.
pub fn webgpu_instance_process_events(instance : GPUInstance) -> Unit {
  @raw.webgpu_instance_process_events(instance.raw)
}

///|
/// Implements `webgpu_instance_release`.
pub fn webgpu_instance_release(instance : GPUInstance) -> Unit {
  @raw.webgpu_instance_release(instance.raw)
}

///|
/// Implements `render_pass_color_attachment_from_desc`.
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
/// Implements `render_pass_depth_stencil_attachment_from_desc`.
fn render_pass_depth_stencil_attachment_from_desc(
  att : GPURenderPassDepthStencilAttachment,
) -> @raw.WebGPURenderPassDepthStencilAttachment {
  @raw.create_render_pass_depth_stencil_attachment(
    view=att.view,
    depthClearValue=att.depth_clear_value,
    depthLoadOp=att.depth_load_op,
    depthStoreOp=att.depth_store_op,
  )
}

///|
/// Implements `render_pass_descriptor_to_raw`.
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
        depthStencilAttachment=render_pass_depth_stencil_attachment_from_desc(
          ds,
        ),
      )
    None => @raw.create_render_pass_descriptor(colorAttachments=mapped)
  }
}

///|
/// Implements `shaderModule_release`.
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  @raw.shaderModule_release(shaderModule)
}

///|
/// Implements `renderPipeline_release`.
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  @raw.renderPipeline_release(pipeline.raw)
}

///|
/// Implements `bindGroupLayout_release`.
pub fn bindGroupLayout_release(layout : GPUBindGroupLayout) -> Unit {
  @raw.bindGroupLayout_release(layout.raw)
}

///|
/// Implements `bindGroup_release`.
pub fn bindGroup_release(group : GPUBindGroup) -> Unit {
  @raw.bindGroup_release(group.raw)
}

///|
/// Implements `buffer_release`.
pub fn buffer_release(buffer : GPUBuffer) -> Unit {
  @raw.buffer_release(buffer.raw)
}

///|
/// Implements `textureView_release`.
pub fn textureView_release(view : GPUTextureView) -> Unit {
  @raw.textureView_release(view)
}

///|
/// Implements `texture_release`.
pub fn texture_release(texture : GPUTexture) -> Unit {
  @raw.webgpu_texture_release(texture.raw)
}
