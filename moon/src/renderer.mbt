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
  let texture = renderer.context.getCurrentTexture()
  let view = texture.createView()

  // Create command encoder
  let encoder = renderer.device.createCommandEncoder()

  // Begin render pass with dark blue background
  let render_pass = encoder.beginRenderPass(view, 0.0, 0.0, 0.2, 1.0)

  // Set pipeline
  render_pass.setPipeline(renderer.pipeline)

  // Draw triangle
  render_pass.draw(get_vertex_count())

  // End render pass
  render_pass.end()

  // Finish encoding and submit
  let command_buffer = encoder.finish()
  queue_submit(renderer.queue, command_buffer)
}
