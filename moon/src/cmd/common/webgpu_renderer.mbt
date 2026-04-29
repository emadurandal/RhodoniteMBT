///|
pub(all) struct WebGPURenderer {
  context : @w.WebGPUCanvasContext
  device : @w.WebGPUDevice
  queue : @w.WebGPUQueue
  pipeline : @w.GPURenderPipeline
}

///|
pub fn create_renderer(context : @w.WebGPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
  let pipeline = create_pipeline(device, format)
  Some({ context: canvas_context, device, queue, pipeline })
}

///|
fn create_pipeline(
  device : @w.WebGPUDevice,
  format : String,
) -> @w.GPURenderPipeline {
  let shader = device.create_shader_module(triangle_shader_code)
  let pipeline = device.create_render_pipeline(
    @w.create_render_pipeline_descriptor(
      vertex=shader,
      fragment=shader,
      topology="triangle-list",
      formats=[format],
    ),
  )
  @w.shaderModule_release(shader)
  pipeline
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  render_frame_with_options(
    renderer,
    clearColor=(0.0, 0.0, 0.2, 1.0),
    vertex_count=3,
  )
}

///|
fn render_frame_with_options(
  renderer : WebGPURenderer,
  clearColor~ : (Double, Double, Double, Double),
  vertex_count~ : Int,
) -> Unit {
  let (r, g, b, a) = clearColor
  let texture = renderer.context.get_current_texture()
  let view = texture.create_view()
  let encoder = renderer.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass(
    @w.create_render_pass_descriptor(colorAttachments=[
      Some(
        @w.create_render_pass_color_attachment(
          view~,
          clearValue=@w.webgpu_color_new(r, g, b, a),
          loadOp="clear",
          storeOp="store",
        ),
      ),
    ]),
  )
  render_pass.set_pipeline(renderer.pipeline)
  render_pass.draw(vertex_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
  @w.textureView_release(view)
  renderer.context.present()
}

///|
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  self.pipeline.release()
}

///|
pub fn webgpu_renderer_release(renderer : WebGPURenderer) -> Unit {
  renderer.release()
}

///|
let triangle_shader_code : String =
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
