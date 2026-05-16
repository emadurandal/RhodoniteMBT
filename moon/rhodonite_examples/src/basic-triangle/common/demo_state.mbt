///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
}

///|
/// Implements `create_demo_state`.
pub fn create_demo_state(context : @wgpu.GPUContext) -> DemoState? {
  let engine = @app.Engine::new(context)
  create_demo_state_for_engine(engine)
}

///|
/// Implements `create_demo_state_for_engine`.
pub fn create_demo_state_for_engine(engine : @app.Engine) -> DemoState? {
  let (device, canvas_context, format, queue) = engine.gpu_context().get()
  Some(
    create_demo_state_for_device(
      device,
      queue,
      format,
      context=Some(canvas_context),
    ),
  )
}

///|
/// Implements `create_demo_state_for_device`.
pub fn create_demo_state_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
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
pub fn render_frame(demo_state : DemoState) -> Unit {
  render_frame_with_options(
    demo_state,
    clearColor={ r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
    vertex_count=3,
  )
}

///|
/// Renders the current sample frame without advancing app time.
pub fn render_current_frame(demo_state : DemoState) -> Unit {
  render_frame(demo_state)
}

///|
/// Implements `render_frame_with_options`.
fn render_frame_with_options(
  demo_state : DemoState,
  clearColor~ : @wgpu.GPUColor,
  vertex_count~ : Int,
) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let view = texture.create_view()
  render_frame_to_view(demo_state, view, clearColor~, vertex_count~)
  @wgpu.textureView_release(view)
  canvas_context.present()
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  demo_state : DemoState,
  view : @wgpu.GPUTextureView,
  clearColor? : @wgpu.GPUColor = { r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
  vertex_count? : Int = 3,
) -> Unit {
  let encoder = demo_state.device.create_command_encoder()
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
  render_pass.set_pipeline(demo_state.pipeline)
  render_pass.draw(vertex_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  demo_state.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Builds an app lifecycle that drives this DemoState from an engine tick.
pub fn create_app(demo_state : DemoState) -> @app.App {
  let app = @app.App::new()
  app.register_phase(
    @app.AppPhase::Render,
    fn(_engine, _frame) { render_current_frame(demo_state) },
    slot=@app.PhaseSlot::AfterSchedule,
  )
  app.register_phase(@app.AppPhase::Shutdown, fn(_engine, _frame) {
    demo_state.release()
  })
  app
}

///|
/// Implements `DemoState::release`.
pub fn DemoState::release(self : DemoState) -> Unit {
  self.pipeline.release()
}

///|
/// Implements `demo_state_release`.
pub fn demo_state_release(demo_state : DemoState) -> Unit {
  demo_state.release()
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
