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
/// Taylor approximation for \([-π, π]\).
fn sin_approx(a : Double) -> Double {
  let two_pi = 6.283185307179586
  let mut x = a
  while x > two_pi {
    x = x - two_pi
  }
  while x < 0.0 {
    x = x + two_pi
  }
  let pi = 3.141592653589793
  if x > pi {
    x = x - two_pi
  }
  let x2 = x * x
  let x3 = x2 * x
  let x5 = x3 * x2
  let x7 = x5 * x2
  x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0
}

///|
fn cos_approx(a : Double) -> Double {
  sin_approx(a + 1.5707963267948966)
}

///|
fn mat4_mul(a : Array[Double], b : Array[Double]) -> Array[Double] {
  let o = Array::make(16, 0.0)
  for j = 0; j < 4; j = j + 1 {
    for i = 0; i < 4; i = i + 1 {
      let mut s = 0.0
      for k = 0; k < 4; k = k + 1 {
        s = s + a[k * 4 + i] * b[j * 4 + k]
      }
      o[j * 4 + i] = s
    }
  }
  o
}

///|
fn mat4_translate(tx : Double, ty : Double, tz : Double) -> Array[Double] {
  let m = Array::make(16, 0.0)
  m[0] = 1.0
  m[5] = 1.0
  m[10] = 1.0
  m[12] = tx
  m[13] = ty
  m[14] = tz
  m[15] = 1.0
  m
}

///|
/// Right-handed, +X axis rotation (`c = cos θ`, `s = sin θ`).
fn mat4_rotate_x(c : Double, s : Double) -> Array[Double] {
  let m = Array::make(16, 0.0)
  m[0] = 1.0
  m[1] = 0.0
  m[2] = 0.0
  m[3] = 0.0
  m[4] = 0.0
  m[5] = c
  m[6] = s
  m[7] = 0.0
  m[8] = 0.0
  m[9] = -s
  m[10] = c
  m[11] = 0.0
  m[12] = 0.0
  m[13] = 0.0
  m[14] = 0.0
  m[15] = 1.0
  m
}

///|
fn mat4_rotate_y(c : Double, s : Double) -> Array[Double] {
  let m = Array::make(16, 0.0)
  m[0] = c
  m[1] = 0.0
  m[2] = -s
  m[3] = 0.0
  m[4] = 0.0
  m[5] = 1.0
  m[6] = 0.0
  m[7] = 0.0
  m[8] = s
  m[9] = 0.0
  m[10] = c
  m[11] = 0.0
  m[12] = 0.0
  m[13] = 0.0
  m[14] = 0.0
  m[15] = 1.0
  m
}

///|
/// Right-handed orthographic projection with OpenGL-style clip Z ∈ [-1,1] (XY matches WebGPU usage).
fn mat4_ortho(
  l : Double,
  r : Double,
  b : Double,
  t : Double,
  n : Double,
  f : Double,
) -> Array[Double] {
  let m = Array::make(16, 0.0)
  m[0] = 2.0 / (r - l)
  m[5] = 2.0 / (t - b)
  m[10] = -2.0 / (f - n)
  m[12] = -(r + l) / (r - l)
  m[13] = -(t + b) / (t - b)
  m[14] = -(f + n) / (f - n)
  m[15] = 1.0
  m
}

///|
/// Map GL-style clip Z to WebGPU NDC Z ∈ [0,1] (`z' = 0.5*z + 0.5*w`).
fn mat4_clip_gl_depth_to_webgpu() -> Array[Double] {
  let m = Array::make(16, 0.0)
  m[0] = 1.0
  m[5] = 1.0
  m[10] = 0.5
  m[14] = 0.5
  m[15] = 1.0
  m
}

///|
fn transform_hom(
  m : Array[Double],
  x : Double,
  y : Double,
  z : Double,
) -> (Double, Double, Double, Double) {
  let w = 1.0
  let ox = m[0] * x + m[4] * y + m[8] * z + m[12] * w
  let oy = m[1] * x + m[5] * y + m[9] * z + m[13] * w
  let oz = m[2] * x + m[6] * y + m[10] * z + m[14] * w
  let ow = m[3] * x + m[7] * y + m[11] * z + m[15] * w
  (ox, oy, oz, ow)
}

///|
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
fn write_cube_interleaved(
  buf : FixedArray[Byte],
  mvp : Array[Double],
  color_r : Double,
  color_g : Double,
  color_b : Double,
) -> Unit {
  let corners = cube_local_corners()
  for vi = 0; vi < verts_per_cube; vi = vi + 1 {
    let (lx, ly, lz) = corners[vi]
    let (cx, cy, cz, cw) = transform_hom(mvp, lx, ly, lz)
    let base = vi * vertex_stride_bytes
    @writes.put_f32_le(buf, base + 0, cx)
    @writes.put_f32_le(buf, base + 4, cy)
    @writes.put_f32_le(buf, base + 8, cz)
    @writes.put_f32_le(buf, base + 12, cw)
    @writes.put_f32_le(buf, base + 16, color_r)
    @writes.put_f32_le(buf, base + 20, color_g)
    @writes.put_f32_le(buf, base + 24, color_b)
  }
}

///|
pub(all) struct WebGPURenderer {
  context : @wgpu.GPUCanvasContext
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
pub fn create_renderer(context : @wgpu.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
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
  Some({
    context: canvas_context,
    device,
    queue,
    pipeline,
    depth_texture,
    depth_view,
    vertex_buffer_a,
    vertex_buffer_b,
    index_buffer,
    frame: @ref.new(0),
  })
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  renderer.frame.val = renderer.frame.val + 1
  let t = renderer.frame.val.to_double() * 0.03
  let c = cos_approx(t)
  let s = sin_approx(t)
  let r = mat4_rotate_y(c, s)
  let ta = mat4_translate(-half_separation, 0.0, 0.0)
  let tb = mat4_translate(half_separation, 0.0, 0.0)
  let ma = mat4_mul(r, ta)
  let mb = mat4_mul(r, tb)
  let v_cos = cos_approx(camera_elevation_rad)
  let v_sin = sin_approx(camera_elevation_rad)
  let view = mat4_mul(
    mat4_rotate_x(v_cos, v_sin),
    mat4_translate(0.0, 0.0, -8.0),
  )
  let proj = mat4_ortho(-5.0, 5.0, -5.0, 5.0, 0.1, 50.0)
  let pv = mat4_mul(proj, view)
  let z_ndc_webgpu = mat4_clip_gl_depth_to_webgpu()
  let mvp_a = mat4_mul(z_ndc_webgpu, mat4_mul(pv, ma))
  let mvp_b = mat4_mul(z_ndc_webgpu, mat4_mul(pv, mb))
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
  let texture = renderer.context.get_current_texture()
  let color_view = texture.create_view()
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
  @wgpu.textureView_release(color_view)
  renderer.context.present()
}

///|
pub fn WebGPURenderer::release(self : WebGPURenderer) -> Unit {
  self.index_buffer.release()
  self.vertex_buffer_a.release()
  self.vertex_buffer_b.release()
  @wgpu.textureView_release(self.depth_view)
  self.depth_texture.release()
  self.pipeline.release()
}

///|
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
