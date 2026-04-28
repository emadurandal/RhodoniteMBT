///|
pub struct Renderer {
  context : WebGPUCanvasContext
  device : WebGPUDevice
  pipeline : GPURenderPipeline
  queue : WebGPUQueue
}

///|
pub fn create_renderer(context : WebGPUContext) -> Renderer? {
  let shader_module = context.device.createShaderModule(
    native_triangle_shader_code,
  )
  let pipeline = context.device.createRenderPipeline(
    WebGPURenderPipelineDescriptor::new(
      vertex=shader_module,
      fragment=shader_module,
      topology="triangle-list",
      formats=[context.format],
    ),
  )
  shader_module.raw.release()
  Some({
    context: context.context,
    device: context.device,
    pipeline,
    queue: context.queue,
  })
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  let texture = renderer.context.getCurrentTexture()
  let view = texture.createView()
  let encoder = renderer.device.createCommandEncoder()
  let render_pass = encoder.beginRenderPass(
    WebGPURenderPassDescriptor::new(colorAttachments=[
      Some(
        WebGPURenderPassColorAttachment::new(
          view~,
          clearValue=WebGPUColor::new(0.0, 0.0, 0.2, 1.0),
          loadOp="clear",
          storeOp="store",
        ),
      ),
    ]),
  )
  render_pass.setPipeline(renderer.pipeline)
  render_pass.draw(3)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
  textureView_release(view)
  renderer.context.present()
}

///|
pub fn Renderer::release(self : Renderer) -> Unit {
  renderPipeline_release(self.pipeline)
}

///|
let native_triangle_shader_code : String =
  #|struct VertexOutput {
  #|  @builtin(position) position: vec4<f32>,
  #|  @location(0) color: vec3<f32>,
  #|};
  #|
  #|@vertex
  #|fn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
  #|  var pos = array<vec2<f32>, 3>(
  #|    vec2<f32>(0.0, 0.5),
  #|    vec2<f32>(-0.5, -0.5),
  #|    vec2<f32>(0.5, -0.5),
  #|  );
  #|  var colors = array<vec3<f32>, 3>(
  #|    vec3<f32>(1.0, 0.0, 0.0),
  #|    vec3<f32>(0.0, 1.0, 0.0),
  #|    vec3<f32>(0.0, 0.0, 1.0),
  #|  );
  #|  var output: VertexOutput;
  #|  output.position = vec4<f32>(pos[vertexIndex], 0.0, 1.0);
  #|  output.color = colors[vertexIndex];
  #|  return output;
  #|}
  #|
  #|@fragment
  #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  #|  return vec4<f32>(color, 1.0);
  #|}
  #|
