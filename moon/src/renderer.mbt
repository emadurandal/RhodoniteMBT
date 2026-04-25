// WebGPU renderer implementation

///|
pub struct Renderer {
  context : WebGPUCanvasContext
  device : WebGPUDevice
  pipeline : GPURenderPipeline
  queue : GPUQueue
}

///|
pub fn create_renderer(context : WebGPUContext) -> Renderer? {
  let device = WebGPUDevice::new(context.device)
  let webgpu_context = WebGPUCanvasContext::new(context.context)

  // Create shader modules
  let vertex_module = device.createShaderModule(vertex_shader_code)
  let fragment_module = device.createShaderModule(fragment_shader_code)

  // Create render pipeline
  let pipeline = device.createRenderPipeline(
    vertex_module,
    fragment_module,
    "triangle-list",
    [context.format],
  )

  Some({ context: webgpu_context, device, pipeline, queue: context.queue })
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  // Get current texture from canvas context
  let texture = context_getCurrentTexture(renderer.context.get())
  let view = texture_createView(texture)

  // Create command encoder
  let encoder = device_createCommandEncoder(renderer.device.get())

  // Begin render pass with dark blue background
  let render_pass = encoder_beginRenderPass(encoder, view, 0.0, 0.0, 0.2, 1.0)

  // Set pipeline
  renderPass_setPipeline(render_pass, renderer.pipeline)

  // Draw triangle
  renderPass_draw(render_pass, get_vertex_count())

  // End render pass
  renderPass_end(render_pass)

  // Finish encoding and submit
  let command_buffer = encoder_finish(encoder)
  queue_submit(renderer.queue, command_buffer)
}
