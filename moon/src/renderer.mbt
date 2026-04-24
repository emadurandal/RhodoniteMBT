// WebGPU renderer implementation

///|
pub struct Renderer {
  context : WebGPUContext
  pipeline : GPURenderPipeline
}

///|
pub fn create_renderer(context : WebGPUContext) -> Renderer? {
  // Create shader modules
  let vertex_module = device_createShaderModule(
    context.device,
    vertex_shader_code,
  )
  let fragment_module = device_createShaderModule(
    context.device,
    fragment_shader_code,
  )

  // Create render pipeline
  let pipeline = device_createRenderPipeline(
    context.device,
    vertex_module,
    fragment_module,
    "triangle-list",
    context.format,
  )

  Some({ context, pipeline })
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  // Get current texture from canvas context
  let texture = context_getCurrentTexture(renderer.context.context)
  let view = texture_createView(texture)

  // Create command encoder
  let encoder = device_createCommandEncoder(renderer.context.device)

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
  queue_submit(renderer.context.queue, command_buffer)
}
