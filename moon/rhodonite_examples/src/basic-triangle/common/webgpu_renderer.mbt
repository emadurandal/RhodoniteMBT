///|
/// Defines `WebGPURenderer`.
pub(all) struct WebGPURenderer {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
}

///|
/// Implements `create_renderer`.
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let engine = @app.Engine::new(context)
  create_renderer_for_engine(engine)
}

///|
/// Implements `create_renderer_for_engine`.
pub fn create_renderer_for_engine(engine : @app.Engine) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = engine.gpu_context().get()
  Some(
    create_renderer_for_device(
      device,
      queue,
      format,
      context=Some(canvas_context),
    ),
  )
}

///|
/// Implements `create_renderer_for_device`.
pub fn create_renderer_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> WebGPURenderer {
  let pipeline = create_pipeline(device, format)
  { context, device, queue, pipeline }
}

///|
/// Implements `create_pipeline`.
fn create_pipeline(
  device : @wgpu.GPUDevice,
  format : String,
) -> @wgpu.GPURenderPipeline {
  let shader = device.create_shader_module(triangle_shader_code)
  let pipeline_descriptor : @wgpu.GPURenderPipelineDescriptor = {
    vertex: shader,
    fragment: shader,
    topology: @wgpu.GPUPrimitiveTopology::TriangleList,
    formats: [format],
    vertex_buffers: [],
    depth_stencil_format: None,
  }
  let pipeline = device.create_render_pipeline(pipeline_descriptor)
  @wgpu.shaderModule_release(shader)
  pipeline
}

///|
/// Implements `render_frame`.
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  render_frame_with_options(
    renderer,
    clearColor={ r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
    vertex_count=3,
  )
}

///|
/// Renders the current sample frame without advancing app time.
pub fn render_current_frame(renderer : WebGPURenderer) -> Unit {
  render_frame(renderer)
}

///|
/// Implements `render_frame_with_options`.
fn render_frame_with_options(
  renderer : WebGPURenderer,
  clearColor~ : @wgpu.GPUColor,
  vertex_count~ : Int,
) -> Unit {
  let canvas_context = match renderer.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let view = texture.create_view()
  render_frame_to_view(renderer, view, clearColor~, vertex_count~)
  @wgpu.textureView_release(view)
  canvas_context.present()
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  renderer : WebGPURenderer,
  view : @wgpu.GPUTextureView,
  clearColor? : @wgpu.GPUColor = { r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
  vertex_count? : Int = 3,
) -> Unit {
  let encoder = renderer.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view,
        clear_value: Some(clearColor),
        load_op: @wgpu.GPULoadOp::Clear,
        store_op: @wgpu.GPUStoreOp::Store,
      }),
    ],
    depth_stencil_attachment: None,
  })
  render_pass.set_pipeline(renderer.pipeline)
  render_pass.draw(vertex_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Builds an app lifecycle that drives this renderer from an engine tick.
pub fn create_app(renderer : WebGPURenderer) -> @app.App {
  @app.App::new(
    fn(_engine) { () },
    fn(_engine, _frame) { () },
    fn(_engine, _frame) { render_current_frame(renderer) },
    fn(_engine) { renderer.release() },
  )
}

///|
/// Implements `WebGPURenderer::release`.
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  self.pipeline.release()
}

///|
/// Implements `webgpu_renderer_release`.
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
