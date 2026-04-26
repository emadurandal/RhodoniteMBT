// WebGPU renderer implementation

///|
pub struct Renderer {
  context : WebGPUCanvasContext
  device : WebGPUDevice
  pipeline : GPURenderPipeline
  queue : WebGPUQueue
}

///|
pub fn create_renderer(context : WebGPUContext) -> Renderer? {

  // Create shader modules
  let vertex_module = context.device.createShaderModule(vertex_shader_code)
  let fragment_module = context.device.createShaderModule(fragment_shader_code)

  // Create render pipeline
  let pipeline = context.device.createRenderPipeline(
    WebGPURenderPipelineDescriptor::new(
      vertex=vertex_module,
      fragment=fragment_module,
      topology="triangle-list",
      formats=[context.format],
    ),
  )

  Some({
    context: context.context,
    device: context.device,
    pipeline,
    queue: context.queue,
  })
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  // Get current texture from canvas context
  let texture = renderer.context.getCurrentTexture()
  let view = texture.createView()

  // Create command encoder
  let encoder = renderer.device.createCommandEncoder()

  // Begin render pass with dark blue background
  let render_pass = encoder.beginRenderPass(
    WebGPURenderPassDescriptor::new(colorAttachments=[
      Some(
        WebGPUColorAttachment::new(
          view~,
          // clearValue=Some(WebGPUColor::new(0.0, 0.0, 1.2, 1.0)),
          clearValue=None,
          loadOp="clear",
          storeOp="store",
        ),
      ),
    ]),
  )

  // Set pipeline
  render_pass.setPipeline(renderer.pipeline)

  // Draw triangle
  render_pass.draw(get_vertex_count())

  // End render pass
  render_pass.end()

  // Finish encoding and submit
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
}
