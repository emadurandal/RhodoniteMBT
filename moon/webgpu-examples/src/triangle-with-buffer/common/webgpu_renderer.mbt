///|
/// 頂点1つあたり 32 バイト × 3 頂点。
let vertex_buffer_byte_length : UInt64 = 96UL

///|
/// インデックス uint16 × 3（0, 1, 2）＝ 6 バイト。`GPUQueue.writeBuffer` は
/// ブラウザ実装でコピー長が 4 の倍数であることが求められるため、GPU 上は 8 バイト確保し末尾をパディングする。
let index_buffer_allocation_byte_length : UInt64 = 8UL

///|
/// `setIndexBuffer` に渡すインデックス領域のバイト数（実データのみ）。
let index_buffer_index_range_byte_length : UInt64 = 6UL

///|
/// インターリーブ頂点: `vec2 pos` @ offset 0, `vec3 color` @ offset 8, stride 32。
fn vertex_triangle_interleaved_bytes() -> FixedArray[Byte] {
  let stride = 32
  let n = 3
  let total = stride * n
  let buf = FixedArray::make(total, (0 : Byte))
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
/// 6 バイトのインデックス + 2 バイトパディング（`writeBuffer` の 4 バイト境界用）。
fn index_triangle_u16_bytes() -> FixedArray[Byte] {
  let buf = FixedArray::make(8, (0 : Byte))
  @writes.put_u16_le(buf, 0, 0U)
  @writes.put_u16_le(buf, 2, 1U)
  @writes.put_u16_le(buf, 4, 2U)
  buf
}

///|
pub(all) struct WebGPURenderer {
  context : @w.GPUCanvasContext
  device : @w.GPUDevice
  queue : @w.GPUQueue
  pipeline : @w.GPURenderPipeline
  vertex_buffer : @w.GPUBuffer
  index_buffer : @w.GPUBuffer
}

///|
pub fn create_renderer(context : @w.GPUContext) -> WebGPURenderer? {
  let (device, canvas_context, format, queue) = context.get()
  let vertex_bytes = vertex_triangle_interleaved_bytes()
  let vusage = @w.GPU_BUFFER_USAGE_VERTEX | @w.GPU_BUFFER_USAGE_COPY_DST
  let vbuf = device.create_buffer(vertex_buffer_byte_length, vusage)
  queue.write_buffer_from_fixed_array(vbuf, 0UL, vertex_bytes)
  let index_bytes = index_triangle_u16_bytes()
  let iusage = @w.GPU_BUFFER_USAGE_INDEX | @w.GPU_BUFFER_USAGE_COPY_DST
  let ibuf = device.create_buffer(index_buffer_allocation_byte_length, iusage)
  queue.write_buffer_from_fixed_array(ibuf, 0UL, index_bytes)
  let pipeline = create_pipeline(device, format)
  Some({
    context: canvas_context,
    device,
    queue,
    pipeline,
    vertex_buffer: vbuf,
    index_buffer: ibuf,
  })
}

///|
fn create_pipeline(
  device : @w.GPUDevice,
  format : String,
) -> @w.GPURenderPipeline {
  let shader = device.create_shader_module(triangle_shader_code)
  let vertex_layout : @w.GPUVertexBufferLayout = {
    array_stride: 32UL,
    step_mode: @w.GPUVertexStepMode::Vertex,
    attributes: [
      {
        format: @w.GPUVertexFormat::Float32x2,
        offset: 0UL,
        shader_location: 0U,
      },
      {
        format: @w.GPUVertexFormat::Float32x3,
        offset: 8UL,
        shader_location: 1U,
      },
    ],
  }
  let pipeline_descriptor : @w.GPURenderPipelineDescriptor = {
    vertex: shader,
    fragment: shader,
    topology: @w.GPUPrimitiveTopology::TriangleList,
    formats: [format],
    vertex_buffers: [vertex_layout],
    depth_stencil_format: None,
  }
  let pipeline = device.create_render_pipeline(pipeline_descriptor)
  @w.shaderModule_release(shader)
  pipeline
}

///|
pub fn render_frame(renderer : WebGPURenderer) -> Unit {
  render_frame_with_options(
    renderer,
    clearColor={ r: 0.0, g: 0.0, b: 0.2, a: 1.0 },
    index_count=3,
  )
}

///|
fn render_frame_with_options(
  renderer : WebGPURenderer,
  clearColor~ : @w.GPUColor,
  index_count~ : Int,
) -> Unit {
  let texture = renderer.context.get_current_texture()
  let view = texture.create_view()
  let encoder = renderer.device.create_command_encoder()
  let render_pass = encoder.begin_render_pass({
    color_attachments: [
      Some({
        view,
        clear_value: Some(clearColor),
        load_op: @w.GPULoadOp::Clear,
        store_op: @w.GPUStoreOp::Store,
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
    @w.GPUIndexFormat::Uint16,
    0UL,
    index_buffer_index_range_byte_length,
  )
  render_pass.draw_indexed(index_count)
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
  self.index_buffer.release()
  self.vertex_buffer.release()
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
