///|
/// 32 bytes per vertex × 3 vertices.
let vertex_buffer_byte_length : UInt64 = 96UL

///|
/// Index uint16 × 3 (0, 1, 2) = 6 bytes. Some browser `GPUQueue.writeBuffer`
/// implementations require copy sizes aligned to 4 bytes; allocate 8 bytes on-GPU and pad the tail.
let index_buffer_allocation_byte_length : UInt64 = 8UL

///|
/// Byte length of index data passed to `setIndexBuffer` (payload only).
let index_buffer_index_range_byte_length : UInt64 = 6UL

///|
/// Interleaved vertices: `vec2 pos` @ offset 0, `vec3 color` @ offset 8, stride 32.
fn vertex_triangle_interleaved_bytes() -> FixedArray[Byte] {
  let stride = 32
  let n = 3
  let total = stride * n
  let buf = FixedArray::make(total, (0 : Byte))
  ///|
  /// Implements `put_vertex`.
  fn put_vertex(
    base : Int,
    px : Double,
    py : Double,
    cr : Double,
    cg : Double,
    cb : Double,
  ) -> Unit {
    @writes.put_f32_le(buf, base + 0, px)
    @writes.put_f32_le(buf, base + 4, py)
    @writes.put_f32_le(buf, base + 8, cr)
    @writes.put_f32_le(buf, base + 12, cg)
    @writes.put_f32_le(buf, base + 16, cb)
  }
  put_vertex(0, 0.0, 0.5, 1.0, 0.0, 0.0)
  put_vertex(stride, -0.5, -0.5, 0.0, 1.0, 0.0)
  put_vertex(stride * 2, 0.5, -0.5, 0.0, 0.0, 1.0)
  buf
}

///|
/// 6 bytes of indices + 2 bytes padding (for `writeBuffer` 4-byte alignment).
fn index_triangle_u16_bytes() -> FixedArray[Byte] {
  let buf = FixedArray::make(8, (0 : Byte))
  @writes.put_u16_le(buf, 0, 0U)
  @writes.put_u16_le(buf, 2, 1U)
  @writes.put_u16_le(buf, 4, 2U)
  buf
}

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  vertex_buffer : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
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
  let vertex_bytes = vertex_triangle_interleaved_bytes()
  let vusage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let vbuf = device.create_buffer(vertex_buffer_byte_length, vusage)
  queue.write_buffer_from_fixed_array(vbuf, 0UL, vertex_bytes)
  let index_bytes = index_triangle_u16_bytes()
  let iusage = @wgpu.GPU_BUFFER_USAGE_INDEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let ibuf = device.create_buffer(index_buffer_allocation_byte_length, iusage)
  queue.write_buffer_from_fixed_array(ibuf, 0UL, index_bytes)
  let pipeline = create_pipeline(device, format)
  { context, device, queue, pipeline, vertex_buffer: vbuf, index_buffer: ibuf }
}

///|
/// Implements `create_pipeline`.
fn create_pipeline(
  device : @wgpu.GPUDevice,
  format : String,
) -> @wgpu.GPURenderPipeline {
  let shader = device.create_shader_module(triangle_shader_code)
  let vertex_layout : @wgpu.GPUVertexBufferLayout = {
    array_stride: 32UL,
    step_mode: @wgpu.GPUVertexStepMode::Vertex,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Float32x2,
        offset: 0UL,
        shader_location: 0U,
      },
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 8UL,
        shader_location: 1U,
      },
    ],
  }
  let pipeline_descriptor : @wgpu.GPURenderPipelineDescriptor = {
    vertex: shader,
    fragment: shader,
    topology: @wgpu.GPUPrimitiveTopology::TriangleList,
    formats: [format],
    vertex_buffers: [vertex_layout],
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
    index_count=3,
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
  index_count~ : Int,
) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let view = texture.create_view()
  render_frame_to_view(demo_state, view, clearColor~, index_count~)
  @wgpu.textureView_release(view)
  canvas_context.present()
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  demo_state : DemoState,
  view : @wgpu.GPUTextureView,
  clearColor? : @wgpu.GPUColor = { r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
  index_count? : Int = 3,
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
  render_pass.set_vertex_buffer(
    0,
    demo_state.vertex_buffer,
    0UL,
    vertex_buffer_byte_length,
  )
  render_pass.set_index_buffer(
    demo_state.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_index_range_byte_length,
  )
  render_pass.draw_indexed(index_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  demo_state.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Registers engine phase handlers that drive this DemoState.
pub fn register_engine_handlers(
  engine : @app.Engine,
  demo_state : DemoState,
) -> Unit {
  engine.on_phase(
    @app.phase_render(),
    fn(_engine, _frame) { render_current_frame(demo_state) },
    slot=@app.PhaseSlot::AfterSchedule,
  )
  engine.on_phase(@app.phase_shutdown(), fn(_engine, _frame) {
    demo_state.release()
  })
}

///|
/// Implements `DemoState::release`.
pub fn DemoState::release(self : DemoState) -> Unit {
  self.index_buffer.release()
  self.vertex_buffer.release()
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
  #|fn vertexMain(
  #|  @location(0) pos: vec2<f32>,
  #|  @location(1) color: vec3<f32>,
  #|) -> VertexOutput {
  #|  var out: VertexOutput;
  #|  out.position = vec4<f32>(pos, 0.0, 1.0);
  #|  out.color = color;
  #|  return out;
  #|}
  #|
  #|@fragment
  #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  #|  return vec4<f32>(color, 1.0);
  #|}
  #|
