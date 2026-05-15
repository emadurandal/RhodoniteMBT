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
/// Defines `WebGPURenderer`.
pub(all) struct WebGPURenderer {
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
/// Implements `create_renderer`.
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
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
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  let canvas_context = match renderer.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let color_view = texture.create_view()
  render_frame_to_view(renderer, color_view)
  @wgpu.textureView_release(color_view)
  canvas_context.present()
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  renderer : WebGPURenderer,
  color_view : @wgpu.GPUTextureView,
) -> Unit {
  renderer.frame.val = renderer.frame.val + 1
  let t = renderer.frame.val.to_double() * 0.03
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
  renderer.queue.write_buffer_from_fixed_array(
    renderer.vertex_buffer_a,
    0UL,
    bytes_a,
  )
  renderer.queue.write_buffer_from_fixed_array(
    renderer.vertex_buffer_b,
    0UL,
    bytes_b,
  )
  let encoder = renderer.device.create_command_encoder()
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
      view: renderer.depth_view,
      depth_clear_value: Some(1.0),
      depth_load_op: @wgpu.GPULoadOp::Clear,
      depth_store_op: @wgpu.GPUStoreOp::Store,
    }),
  })
  render_pass.set_pipeline(renderer.pipeline)
  render_pass.set_index_buffer(
    renderer.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_byte_length,
  )
  render_pass.set_vertex_buffer(
    0,
    renderer.vertex_buffer_a,
    0UL,
    vertex_bytes_per_cube,
  )
  render_pass.draw_indexed(index_u16_count)
  render_pass.set_vertex_buffer(
    0,
    renderer.vertex_buffer_b,
    0UL,
    vertex_bytes_per_cube,
  )
  render_pass.draw_indexed(index_u16_count)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
}

///|
/// Implements `WebGPURenderer::release`.
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  self.index_buffer.release()
  self.vertex_buffer_a.release()
  self.vertex_buffer_b.release()
  @wgpu.textureView_release(self.depth_view)
  self.depth_texture.release()
  self.pipeline.release()
}

///|
/// Implements `webgpu_renderer_release`.
pub fn webgpu_renderer_release(renderer : WebGPURenderer) -> Unit {
  renderer.release()
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
