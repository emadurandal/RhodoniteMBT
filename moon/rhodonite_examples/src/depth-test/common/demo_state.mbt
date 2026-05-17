///|
/// Canvas resolution (matches demo HTML).
let canvas_width : UInt = 800U

///|
let canvas_height : UInt = 600U

///|
/// Half the distance between cube centers (world units).
let half_separation : Double = 1.25

///|
let vertex_stride_bytes : Int = 32

///|
let verts_per_cube : Int = 8

///|
let vertex_bytes_per_cube : UInt64 = 256UL

///|
let index_u16_count : Int = 36

///|
let index_buffer_byte_length : UInt64 = (index_u16_count * 2).to_uint64()

///|
/// Slight elevation so depth reads clearly (not a pure side view); radians (~22°).
let camera_elevation_rad : Double = 0.38

///|
/// Implements `cube_local_corners`.
fn cube_local_corners() -> Array[(Double, Double, Double)] {
  [
    (-1.0, -1.0, -1.0),
    (1.0, -1.0, -1.0),
    (1.0, 1.0, -1.0),
    (-1.0, 1.0, -1.0),
    (-1.0, -1.0, 1.0),
    (1.0, -1.0, 1.0),
    (1.0, 1.0, 1.0),
    (-1.0, 1.0, 1.0),
  ]
}

///|
/// Implements `index_cube_u16_bytes`.
fn index_cube_u16_bytes() -> FixedArray[Byte] {
  let buf = FixedArray::make(72, (0 : Byte))
  let idx : Array[UInt] = [
    0U, 1U, 2U, 2U, 3U, 0U, 4U, 5U, 6U, 6U, 7U, 4U, 0U, 4U, 7U, 7U, 3U, 0U, 1U, 5U,
    6U, 6U, 2U, 1U, 0U, 1U, 5U, 5U, 4U, 0U, 3U, 2U, 6U, 6U, 7U, 3U,
  ]
  for i = 0; i < index_u16_count; i = i + 1 {
    @writes.put_u16_le(buf, i * 2, idx[i])
  }
  buf
}

///|
/// Implements `write_cube_interleaved`.
fn write_cube_interleaved(
  buf : FixedArray[Byte],
  mvp : @m44.Matrix44D,
  color_r : Double,
  color_g : Double,
  color_b : Double,
) -> Unit {
  let corners = cube_local_corners()
  for vi = 0; vi < verts_per_cube; vi = vi + 1 {
    let (lx, ly, lz) = corners[vi]
    let clip = mvp.mul_vec4(@v4.Vector4::new(lx, ly, lz, 1.0))
    let base = vi * vertex_stride_bytes
    @writes.put_f32_le(buf, base + 0, clip.x())
    @writes.put_f32_le(buf, base + 4, clip.y())
    @writes.put_f32_le(buf, base + 8, clip.z())
    @writes.put_f32_le(buf, base + 12, clip.w())
    @writes.put_f32_le(buf, base + 16, color_r)
    @writes.put_f32_le(buf, base + 20, color_g)
    @writes.put_f32_le(buf, base + 24, color_b)
  }
}

///|
/// Defines `DemoState`.
pub(all) struct DemoState {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  depth_texture : @wgpu.GPUTexture
  depth_view : @wgpu.GPUTextureView
  vertex_buffer_a : @wgpu.GPUBuffer
  vertex_buffer_b : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
  frame : @ref.Ref[Int]
}

///|
/// Implements `create_demo_state`.
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
/// Implements `create_demo_state_for_engine`.
pub fn create_demo_state_for_engine(engine : @app.Engine) -> DemoState? {
  create_demo_state(engine.gpu_context())
}

///|
/// Implements `create_demo_state_for_device`.
pub fn create_demo_state_for_device(
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  context? : @wgpu.GPUCanvasContext? = None,
) -> DemoState {
  let shader = device.create_shader_module(depth_shader_code)
  let vertex_layout : @wgpu.GPUVertexBufferLayout = {
    array_stride: 32UL,
    step_mode: @wgpu.GPUVertexStepMode::Vertex,
    attributes: [
      {
        format: @wgpu.GPUVertexFormat::Float32x4,
        offset: 0UL,
        shader_location: 0U,
      },
      {
        format: @wgpu.GPUVertexFormat::Float32x3,
        offset: 16UL,
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
    depth_stencil_format: Some("depth24plus"),
  }
  let pipeline = device.create_render_pipeline(pipeline_descriptor)
  @wgpu.shaderModule_release(shader)
  let vusage = @wgpu.GPU_BUFFER_USAGE_VERTEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let vertex_buffer_a = device.create_buffer(vertex_bytes_per_cube, vusage)
  let vertex_buffer_b = device.create_buffer(vertex_bytes_per_cube, vusage)
  let iusage = @wgpu.GPU_BUFFER_USAGE_INDEX | @wgpu.GPU_BUFFER_USAGE_COPY_DST
  let index_buffer = device.create_buffer(index_buffer_byte_length, iusage)
  let index_bytes = index_cube_u16_bytes()
  queue.write_buffer_from_fixed_array(index_buffer, 0UL, index_bytes)
  let depth_texture = device.create_texture(
    canvas_width,
    canvas_height,
    "depth24plus",
    @wgpu.GPU_TEXTURE_USAGE_RENDER_ATTACHMENT,
  )
  let depth_view = depth_texture.create_view()
  {
    context,
    device,
    queue,
    pipeline,
    depth_texture,
    depth_view,
    vertex_buffer_a,
    vertex_buffer_b,
    index_buffer,
    frame: @ref.new(0),
  }
}

///|
/// Implements `render_frame`.
pub fn render_frame(demo_state : DemoState) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_frame_to_view(demo_state, color_view)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Renders the current scene state without advancing app time.
pub fn render_current_frame(demo_state : DemoState) -> Unit {
  let canvas_context = match demo_state.context {
    Some(c) => c
    None => abort("render_current_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_current_frame_to_view(demo_state, color_view)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Updates cube transforms for the current engine frame.
pub fn DemoState::update_scene(
  self : DemoState,
  frame : @app.FrameState,
) -> Unit {
  self.frame.val = frame.frame_index()
  update_frame_vertices(self, self.frame.val)
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  demo_state : DemoState,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  demo_state.frame.val = demo_state.frame.val + 1
  update_frame_vertices(demo_state, demo_state.frame.val)
  render_current_frame_to_view(demo_state, color_view)
}

///|
/// Uploads animated cube vertices for a frame index.
fn update_frame_vertices(demo_state : DemoState, frame_index : Int) -> Unit {
  let t = frame_index.to_double() * 0.03
  let r = @m44.Matrix44::rotation_y(t)
  let ta = @m44.Matrix44::translation(-half_separation, 0.0, 0.0, 1.0, 0.0)
  let tb = @m44.Matrix44::translation(half_separation, 0.0, 0.0, 1.0, 0.0)
  let ma = r.mat_mul(ta)
  let mb = r.mat_mul(tb)
  let view = @m44.Matrix44::rotation_x(camera_elevation_rad).mat_mul(
    @m44.Matrix44::translation(0.0, 0.0, -8.0, 1.0, 0.0),
  )
  let proj = @m44.Matrix44::ortho(-5.0, 5.0, -5.0, 5.0, 0.1, 50.0)
  let pv = proj.mat_mul(view)
  let mvp_a = pv.mat_mul(ma)
  let mvp_b = pv.mat_mul(mb)
  let bytes_a = FixedArray::make(
    verts_per_cube * vertex_stride_bytes,
    (0 : Byte),
  )
  let bytes_b = FixedArray::make(
    verts_per_cube * vertex_stride_bytes,
    (0 : Byte),
  )
  write_cube_interleaved(bytes_a, mvp_a, 0.85, 0.35, 0.25)
  write_cube_interleaved(bytes_b, mvp_b, 0.25, 0.55, 0.95)
  demo_state.queue.write_buffer_from_fixed_array(
    demo_state.vertex_buffer_a,
    0UL,
    bytes_a,
  )
  demo_state.queue.write_buffer_from_fixed_array(
    demo_state.vertex_buffer_b,
    0UL,
    bytes_b,
  )
}

///|
/// Renders the already-updated scene state to a target view.
pub fn render_current_frame_to_view(
  demo_state : DemoState,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  let encoder = demo_state.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view: color_view,
        clear_value: Some({ r: 0.08, g: 0.08, b: 0.12, a: 1.0 }),
        load_op: @wgpu.GPULoadOp::Clear,
        store_op: @wgpu.GPUStoreOp::Store,
      }),
    ],
    depth_stencil_attachment: Some({
      view: demo_state.depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(demo_state.pipeline)
  render_pass.set_index_buffer(
    demo_state.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_byte_length,
  )
  render_pass.set_vertex_buffer(
    0,
    demo_state.vertex_buffer_a,
    0UL,
    vertex_bytes_per_cube,
  )
  render_pass.draw_indexed(index_u16_count)
  render_pass.set_vertex_buffer(
    0,
    demo_state.vertex_buffer_b,
    0UL,
    vertex_bytes_per_cube,
  )
  render_pass.draw_indexed(index_u16_count)
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
  engine.add_phase_handler(@app.phase_update(), fn(_engine, frame) {
    demo_state.update_scene(frame)
  })
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
/// Implements `DemoState::release`.
pub fn DemoState::release(self : DemoState) -> Unit {
  self.index_buffer.release()
  self.vertex_buffer_a.release()
  self.vertex_buffer_b.release()
  @wgpu.textureView_release(self.depth_view)
  self.depth_texture.release()
  self.pipeline.release()
}

///|
/// Implements `demo_state_release`.
pub fn demo_state_release(demo_state : DemoState) -> Unit {
  demo_state.release()
}

///|
let depth_shader_code : String =
  #|struct VertexOut {
  #|  @builtin(position) position: vec4<f32>,
  #|  @location(0) color: vec3<f32>,
  #|};
  #|
  #|@vertex
  #|fn vertexMain(
  #|  @location(0) clip_pos: vec4<f32>,
  #|  @location(1) color: vec3<f32>,
  #|) -> VertexOut {
  #|  var o: VertexOut;
  #|  o.position = clip_pos;
  #|  o.color = color;
  #|  return o;
  #|}
  #|
  #|@fragment
  #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  #|  return vec4<f32>(color, 1.0);
  #|}
  #|
