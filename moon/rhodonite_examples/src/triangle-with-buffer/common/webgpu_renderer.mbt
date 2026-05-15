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
/// Defines `WebGPURenderer`.
pub(all) struct WebGPURenderer {
  context : @wgpu.GPUCanvasContext?
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  pipeline : @wgpu.GPURenderPipeline
  vertex_buffer : @wgpu.GPUBuffer
  index_buffer : @wgpu.GPUBuffer
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
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  render_frame_with_options(
    renderer,
    clearColor={ r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
    index_count=3,
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
  index_count~ : Int,
) -> Unit {
  let canvas_context = match renderer.context {
    Some(c) => c
    None => abort("render_frame requires a canvas context")
  }
  let texture = canvas_context.get_current_texture()
  let view = texture.create_view()
  render_frame_to_view(renderer, view, clearColor~, index_count~)
  @wgpu.textureView_release(view)
  canvas_context.present()
}

///|
/// Implements `render_frame_to_view`.
pub fn render_frame_to_view(
  renderer : WebGPURenderer,
  view : @wgpu.GPUTextureView,
  clearColor? : @wgpu.GPUColor = { r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
  index_count? : Int = 3,
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
  render_pass.set_vertex_buffer(
    0,
    renderer.vertex_buffer,
    0UL,
    vertex_buffer_byte_length,
  )
  render_pass.set_index_buffer(
    renderer.index_buffer,
    @wgpu.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_index_range_byte_length,
  )
  render_pass.draw_indexed(index_count)
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
  self.index_buffer.release()
  self.vertex_buffer.release()
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
