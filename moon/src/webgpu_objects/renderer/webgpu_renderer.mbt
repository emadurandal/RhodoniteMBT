///|
pub(all) struct WebGPURenderer {
  context : @w.WebGPUCanvasContext
  device : @w.WebGPUDevice
  queue : @w.WebGPUQueue
  pipeline : @w.GPURenderPipeline
}

///|
pub fn create_renderer(context : @w.WebGPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = @w.webgpu_context_get(context)
  let pipeline = create_pipeline(device, format)
  Some({ context: canvas_context, device, queue, pipeline })
}

///|
fn create_pipeline(
  device : @w.WebGPUDevice,
  format : String,
) -> @w.GPURenderPipeline {
  let vertex_shader = @w.webgpu_device_create_shader_module(
    device, triangle_shader_code,
  )
  let fragment_shader = @w.webgpu_device_create_shader_module(
    device, triangle_shader_code,
  )
  let pipeline = @w.webgpu_device_create_render_pipeline(
    device,
    @w.create_render_pipeline_descriptor(
      vertex=vertex_shader,
      fragment=fragment_shader,
      topology="triangle-list",
      formats=[format],
    ),
  )
  @w.shaderModule_release(vertex_shader)
  @w.shaderModule_release(fragment_shader)
  pipeline
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  render_frame_with_options(
    renderer,
    clearColor=(0.0, 0.0, 0.2, 1.0),
    vertexCount=3,
  )
}

///|
pub fn render_frame_with_options(
  renderer : WebGPURenderer,
  clearColor~ : (Double, Double, Double, Double),
  vertexCount~ : Int,
) -> Unit {
  let (r, g, b, a) = clearColor
  let texture = @w.webgpu_canvas_context_get_current_texture(renderer.context)
  let view = @w.webgpu_texture_create_view(texture)
  let encoder = @w.webgpu_device_create_command_encoder(renderer.device)
  let render_pass = @w.webgpu_command_encoder_begin_render_pass(
    encoder,
    @w.create_render_pass_descriptor(colorAttachments=[
      Some(
        @w.create_render_pass_color_attachment(
          view~,
          clearValue=@w.create_webgpu_color(r, g, b, a),
          loadOp="clear",
          storeOp="store",
        ),
      ),
    ]),
  )
  @w.webgpu_render_pass_encoder_set_pipeline(render_pass, renderer.pipeline)
  @w.webgpu_render_pass_encoder_draw(render_pass, vertexCount)
  @w.webgpu_render_pass_encoder_end(render_pass)
  @w.webgpu_render_pass_encoder_release(render_pass)
  let command_buffer = @w.webgpu_command_encoder_finish(encoder)
  @w.webgpu_queue_submit(renderer.queue, command_buffer)
  @w.webgpu_command_encoder_release(encoder)
  @w.textureView_release(view)
  @w.webgpu_canvas_context_present(renderer.context)
}

///|
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  @w.renderPipeline_release(self.pipeline)
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
