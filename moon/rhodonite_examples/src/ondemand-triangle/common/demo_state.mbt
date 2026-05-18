///|
/// Defines state for the on-demand triangle sample.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  mut color_step : Int
}

///|
/// Implements `create_demo_state` for a browser GPU context.
pub fn create_demo_state(context : @wgpu.GPUContext) -> DemoState? {
  let (device, canvas_context, format, queue) = context.get()
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
/// Implements `create_demo_state_for_engine` for platform-managed engines.
pub fn create_demo_state_for_engine(engine : @app.Engine) -> DemoState? {
  create_demo_state(engine.gpu_context())
}

///|
/// Builds sample state for a concrete device and target format.
pub fn create_demo_state_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let pipeline = create_pipeline(device, format)
  { context, device, queue, pipeline, color_step: 0 }
}

///|
/// Creates the render pipeline used by the triangle sample.
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
/// Returns the current clear color for the sample state.
fn current_clear_color(demo_state : DemoState) -> @wgpu.GPUColor {
  match demo_state.color_step % 4 {
    0 => { r: 0.02, g: 0.03, b: 0.18, a: 1.0 }
    1 => { r: 0.16, g: 0.04, b: 0.08, a: 1.0 }
    2 => { r: 0.02, g: 0.13, b: 0.10, a: 1.0 }
    _ => { r: 0.12, g: 0.10, b: 0.02, a: 1.0 }
  }
}

///|
/// Advances the visible state after an input event reaches the on-demand frame.
fn advance_on_input(demo_state : DemoState) -> Unit {
  demo_state.color_step = demo_state.color_step + 1
}

///|
/// Applies per-frame input and mutates the sample only when interaction occurred.
fn update_from_input(demo_state : DemoState, input : @input.InputState) -> Unit {
  let dragging = input.mouse_down(Left) &&
    (
      input.pointer_delta_x() != (0.0 : Float) ||
      input.pointer_delta_y() != (0.0 : Float)
    )
  if input.mouse_pressed(Left) ||
    dragging ||
    input.key_pressed(@input.KeyCode::space()) ||
    input.key_pressed(@input.KeyCode::enter()) ||
    input.key_pressed(@input.KeyCode::arrow_left()) ||
    input.key_pressed(@input.KeyCode::arrow_right()) ||
    input.wheel_delta_x() != (0.0 : Float) ||
    input.wheel_delta_y() != (0.0 : Float) {
    advance_on_input(demo_state)
  }
}

///|
/// Renders one swapchain frame for the current on-demand state.
pub fn render_frame(demo_state : DemoState) -> Unit {
  render_frame_with_options(
    demo_state,
    clearColor=current_clear_color(demo_state),
    vertex_count=3,
  )
}

///|
/// Renders the current sample frame without advancing app time.
pub fn render_current_frame(demo_state : DemoState) -> Unit {
  render_frame(demo_state)
}

///|
/// Renders one canvas-backed frame with explicit options.
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
/// Renders the sample into an externally supplied texture view.
pub fn render_frame_to_view(
  demo_state : DemoState,
  view : @wgpu.GPUTextureView,
  clearColor? : @wgpu.GPUColor = { r: 0.02, g: 0.03, b: 0.18, a: 1.0 },
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
/// Registers input, render, and shutdown handlers for an on-demand engine.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.add_phase_handler(
    @app.phase_input(),
    fn(engine, _frame) { update_from_input(demo_state, engine.input()) },
    slot=@app.PhaseSlot::AfterSystems,
  )
  engine.add_phase_handler(
    @app.phase_render(),
    fn(_engine, _frame) { render_current_frame(demo_state) },
    slot=@app.PhaseSlot::AfterSystems,
  )
  engine.add_phase_handler(@app.phase_shutdown(), fn(_engine, _frame) {
    demo_state.release()
  })
}

///|
/// Releases GPU resources owned by the sample state.
pub fn DemoState::release(self : DemoState) -> Unit {
  self.pipeline.release()
}

///|
/// Releases GPU resources through a free function for JS bridge symmetry.
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
  #|    vec2<f32>(0.0, 0.58),
  #|    vec2<f32>(-0.58, -0.48),
  #|    vec2<f32>(0.58, -0.48),
  #|  );
  #|  var colors = array<vec3<f32>, 3>(
  #|    vec3<f32>(1.0, 0.78, 0.18),
  #|    vec3<f32>(0.08, 0.86, 0.72),
  #|    vec3<f32>(0.96, 0.22, 0.38),
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
