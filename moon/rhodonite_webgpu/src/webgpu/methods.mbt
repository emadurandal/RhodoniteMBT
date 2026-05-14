///|
pub fn GPUInstance::get_preferred_canvas_format(self : GPUInstance) -> String {
  @raw.webgpu_instance_get_preferred_canvas_format(self.raw)
}

///|
pub fn GPUInstance::get_preferred_canvas_format_for_surface(
  self : GPUInstance,
  adapter : GPUAdapter,
  canvas : GPUCanvasContext,
) -> String {
  @raw.webgpu_instance_get_preferred_canvas_format_for_surface(
    self.raw,
    adapter.raw,
    canvas.raw,
  )
}

///|
pub async fn GPUInstance::request_adapter(self : GPUInstance) -> GPUAdapter {
  { raw: @raw.webgpu_instance_request_adapter(self.raw) }
}

///|
#cfg(target="native")
pub fn GPUInstance::request_adapter_sync(
  self : GPUInstance,
) -> GPUAdapter raise Error {
  { raw: @raw.native_webgpu_instance_request_adapter(self.raw) }
}

///|
pub fn GPUInstance::process_events(self : GPUInstance) -> Unit {
  webgpu_instance_process_events(self)
}

///|
pub fn GPUInstance::release(self : GPUInstance) -> Unit {
  webgpu_instance_release(self)
}

///|
pub async fn GPUAdapter::request_device(self : GPUAdapter) -> GPUDevice {
  { raw: @raw.webgpu_adapter_request_device(self.raw) }
}

///|
#cfg(target="native")
pub fn GPUAdapter::request_device_sync(
  self : GPUAdapter,
) -> GPUDevice raise Error {
  { raw: @raw.native_webgpu_adapter_request_device(self.raw) }
}

///|
pub fn GPUAdapter::release(self : GPUAdapter) -> Unit {
  webgpu_adapter_release(self)
}

///|
pub fn GPUDevice::get(self : GPUDevice) -> @raw.GPUDevice {
  @raw.webgpu_device_get(self.raw)
}

///|
pub fn GPUDevice::get_queue(self : GPUDevice) -> GPUQueue {
  { raw: @raw.webgpu_device_get_queue(self.raw) }
}

///|
pub fn GPUDevice::create_shader_module(
  self : GPUDevice,
  code : String,
) -> GPUShaderModule {
  @raw.webgpu_device_create_shader_module(self.raw, code)
}

///|
pub fn GPUDevice::create_render_pipeline(
  self : GPUDevice,
  descriptor : GPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  {
    raw: @raw.webgpu_device_create_render_pipeline(
      self.raw,
      descriptor.vertex,
      descriptor.fragment,
      topology=descriptor.topology,
      formats=descriptor.formats,
      vertex_buffers=descriptor.vertex_buffers,
      depth_stencil_format=match descriptor.depth_stencil_format {
        Some(s) => s
        None => ""
      },
    ),
  }
}

///|
/// Vertex attribute for the builtin ECS GlobalTransform ref: `vec2<u32>`
/// containing `{ format, word_offset }`.
pub fn global_transform_ref_vertex_attribute(
  shader_location : UInt,
  offset : UInt64,
) -> GPUVertexAttribute {
  { format: GPUVertexFormat::Uint32x2, offset, shader_location }
}

///|
/// Instance vertex-buffer layout that starts with the builtin ECS GlobalTransform
/// ref and appends any caller-owned per-instance attributes.
pub fn global_transform_ref_instance_vertex_buffer_layout(
  array_stride : UInt64,
  shader_location : UInt,
  offset : UInt64,
  extra_attributes : Array[GPUVertexAttribute],
) -> GPUVertexBufferLayout {
  let attrs : Array[GPUVertexAttribute] = [
    global_transform_ref_vertex_attribute(shader_location, offset),
  ]
  for i = 0; i < extra_attributes.length(); i = i + 1 {
    attrs.push(extra_attributes[i])
  }
  { array_stride, step_mode: GPUVertexStepMode::Instance, attributes: attrs }
}

///|
/// WebGPU `GPUTextureUsage.RENDER_ATTACHMENT`（0x10）。
pub const GPU_TEXTURE_USAGE_RENDER_ATTACHMENT : UInt64 = 16UL

///|
/// WebGPU `GPUTextureUsage.COPY_SRC`（0x1）。
pub const GPU_TEXTURE_USAGE_COPY_SRC : UInt64 = 1UL

///|
/// WebGPU `GPUTextureUsage.COPY_DST`（0x2）。
pub const GPU_TEXTURE_USAGE_COPY_DST : UInt64 = 2UL

///|
/// WebGPU `GPUBufferUsage.VERTEX`（0x20）。
pub const GPU_BUFFER_USAGE_VERTEX : UInt64 = 32UL

///|
/// WebGPU `GPUBufferUsage.MAP_READ`（0x1）。
pub const GPU_BUFFER_USAGE_MAP_READ : UInt64 = 1UL

///|
/// WebGPU `GPUBufferUsage.COPY_SRC`（0x4）。
pub const GPU_BUFFER_USAGE_COPY_SRC : UInt64 = 4UL

///|
/// WebGPU `GPUBufferUsage.COPY_DST`（0x8）。
pub const GPU_BUFFER_USAGE_COPY_DST : UInt64 = 8UL

///|
/// WebGPU `GPUBufferUsage.INDEX`（0x10）。
pub const GPU_BUFFER_USAGE_INDEX : UInt64 = 16UL

///|
/// WebGPU `GPUBufferUsage.STORAGE`（0x80）。
pub const GPU_BUFFER_USAGE_STORAGE : UInt64 = 128UL

///|
/// WebGPU `GPUBufferUsage.UNIFORM`（0x40）。
pub const GPU_BUFFER_USAGE_UNIFORM : UInt64 = 64UL

///|
pub fn GPUDevice::create_buffer(
  self : GPUDevice,
  size : UInt64,
  usage : UInt64,
) -> GPUBuffer {
  { raw: @raw.webgpu_device_create_buffer(self.raw, size, usage) }
}

///|
/// Byte size for the builtin ECS GlobalTransform packed-word storage buffer.
///
/// WebGPU buffers cannot be zero-sized, so an empty world still reserves 4 bytes.
pub fn global_transform_words_buffer_byte_size(word_capacity : Int) -> UInt64 {
  if word_capacity <= 0 {
    4UL
  } else {
    (word_capacity * 4).to_uint64()
  }
}

///|
/// Creates a storage buffer for the builtin ECS GlobalTransform packed-word blob.
pub fn GPUDevice::create_global_transform_words_buffer(
  self : GPUDevice,
  world : @ecs.World,
) -> GPUBuffer {
  self.create_buffer(
    global_transform_words_buffer_byte_size(
      world.global_transform_blob_word_capacity(),
    ),
    GPU_BUFFER_USAGE_STORAGE | GPU_BUFFER_USAGE_COPY_DST,
  )
}

///|
pub fn GPUDevice::create_texture(
  self : GPUDevice,
  width : UInt,
  height : UInt,
  format : String,
  usage : UInt64,
) -> GPUTexture {
  {
    raw: @raw.webgpu_device_create_texture(
      self.raw,
      width,
      height,
      format,
      usage,
    ),
  }
}

///|
pub fn rgba8_copy_bytes_per_row(width : UInt) -> UInt64 {
  let unpadded = width.to_uint64() * 4UL
  let align = 256UL
  let rem = unpadded % align
  if rem == 0UL {
    unpadded
  } else {
    unpadded + (align - rem)
  }
}

///|
pub fn rgba8_copy_padded_byte_length(width : UInt, height : UInt) -> UInt64 {
  rgba8_copy_bytes_per_row(width) * height.to_uint64()
}

///|
pub fn GPUDevice::create_rgba8_render_texture(
  self : GPUDevice,
  width : UInt,
  height : UInt,
) -> GPUTexture {
  self.create_texture(
    width,
    height,
    "rgba8unorm",
    GPU_TEXTURE_USAGE_RENDER_ATTACHMENT | GPU_TEXTURE_USAGE_COPY_SRC,
  )
}

///|
pub fn GPUQueue::write_buffer(
  self : GPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : Bytes,
) -> Unit {
  @raw.webgpu_queue_write_buffer(self.raw, buffer.raw, offset, data)
}

///|
/// Pass `FixedArray[Byte]` to `write_buffer` as `Bytes` without a heap copy.
///
/// `FixedArray::unsafe_reinterpret_as_bytes` only reinterprets the same storage as `Bytes`,
/// so there is no full-buffer copy like `Bytes::from_array`.
///
/// # Notes for callers
///
/// - **What unsafe means**: same as the standard library’s `#internal` reinterpret; `Bytes`
///   aliases the original bytes (changes through `Bytes` affect the same memory as `FixedArray`).
///   This function takes the `FixedArray` by move, converts to `Bytes` internally, and forwards it—
///   **do not keep other references to the buffer after passing it in**.
/// - **Lifetime**: `webgpu_queue_write_buffer` borrows data across FFI; the buffer must stay valid
///   until the call returns (usually satisfied within the function scope).
/// - **Native (wgpu)**: `wgpu_mbt` `Queue::write_buffer` may copy into a padding buffer when the
///   length is not a multiple of 4; pad lengths to multiples of 4 to avoid extra copies.
/// - **JS**: `Bytes` maps to `Uint8Array` in JS FFI and goes straight to `GPUQueue.writeBuffer`.
///
pub fn GPUQueue::write_buffer_from_fixed_array(
  self : GPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  arr : FixedArray[Byte],
) -> Unit {
  let data = FixedArray::unsafe_reinterpret_as_bytes(arr)
  @raw.webgpu_queue_write_buffer(self.raw, buffer.raw, offset, data)
}

///|
/// Writes a borrowed byte view to a GPU buffer.
///
/// JS forwards the view as a `Uint8Array.subarray` without copying. Native forwards the
/// `ArrayView[Byte]` backing bytes plus source offset to `wgpuQueueWriteBuffer` without first
/// compacting the view into a new `Bytes`.
pub fn GPUQueue::write_buffer_from_array_view(
  self : GPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  view : ArrayView[Byte],
) -> Unit {
  @raw.webgpu_queue_write_buffer_array_view(self.raw, buffer.raw, offset, view)
}

///|
/// Uploads borrowed ECS GlobalTransform packed-blob write views into a storage buffer.
pub fn GPUQueue::upload_global_transform_writes(
  self : GPUQueue,
  buffer : GPUBuffer,
  writes : Array[@ecs.GpuWriteView],
) -> Unit {
  for i = 0; i < writes.length(); i = i + 1 {
    let write = writes[i]
    self.write_buffer_from_array_view(
      buffer,
      write.byte_offset.to_uint64(),
      write.bytes,
    )
  }
}

///|
/// Drains dirty ECS GlobalTransform packed-blob views and uploads them immediately.
pub fn GPUQueue::drain_and_upload_global_transform_writes(
  self : GPUQueue,
  buffer : GPUBuffer,
  world : @ecs.World,
) -> Unit {
  self.upload_global_transform_writes(
    buffer,
    world.drain_global_transform_blob_write_views(),
  )
}

///|
/// Writes a borrowed subrange of `Bytes` to a GPU buffer without compacting the payload.
#cfg(target="native")
pub fn GPUQueue::write_buffer_from_bytes_range(
  self : GPUQueue,
  buffer : GPUBuffer,
  offset : UInt64,
  data : Bytes,
  data_offset : UInt64,
  byte_length : UInt64,
) -> Unit {
  @raw.webgpu_queue_write_buffer_bytes_range(
    self.raw,
    buffer.raw,
    offset,
    data,
    data_offset,
    byte_length,
  )
}

///|
pub fn GPUBuffer::release(self : GPUBuffer) -> Unit {
  buffer_release(self)
}

///|
/// Reads a native GPU buffer range and returns a borrowed view of the staging bytes.
///
/// WebGPU native mapping requires aligned offset/size. This helper reads the aligned range into a
/// staging `Bytes`, then returns the requested subrange as `BytesView` without compacting it into a
/// second `Bytes`. Use `BytesView::to_owned` only when an owned, exact-length `Bytes` is required.
#cfg(target="native")
pub fn GPUBuffer::readback_view(
  self : GPUBuffer,
  instance : GPUInstance,
  offset : UInt64,
  size : UInt64,
) -> BytesView {
  @raw.webgpu_buffer_readback_view(self.raw, instance.raw, offset, size)
}

///|
/// Reads a native GPU buffer range into an owned `Bytes`.
#cfg(target="native")
pub fn GPUBuffer::readback(
  self : GPUBuffer,
  instance : GPUInstance,
  offset : UInt64,
  size : UInt64,
) -> Bytes {
  @raw.webgpu_buffer_readback(self.raw, instance.raw, offset, size)
}

///|
pub fn GPURenderPassEncoder::set_vertex_buffer(
  self : GPURenderPassEncoder,
  slot : Int,
  buffer : GPUBuffer,
  offset : UInt64,
  size : UInt64,
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_vertex_buffer(
    self.raw,
    slot,
    buffer.raw,
    offset,
    size,
  )
}

///|
pub fn GPURenderPassEncoder::set_index_buffer(
  self : GPURenderPassEncoder,
  buffer : GPUBuffer,
  format : GPUIndexFormat,
  offset : UInt64,
  size : UInt64,
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_index_buffer(
    self.raw,
    buffer.raw,
    format,
    offset,
    size,
  )
}

///|
pub fn GPUDevice::create_command_encoder(self : GPUDevice) -> GPUCommandEncoder {
  { raw: @raw.webgpu_device_create_command_encoder(self.raw) }
}

///|
pub fn GPUDevice::poll(self : GPUDevice, wait? : Bool = false) -> Bool {
  webgpu_device_poll(self, wait~)
}

///|
pub fn GPUDevice::release(self : GPUDevice) -> Unit {
  webgpu_device_release(self)
}

///|
pub fn GPUCanvasContext::configure(
  self : GPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  @raw.webgpu_canvas_context_configure(
    self.raw,
    @raw.webgpu_device_get(device.raw),
    format,
  )
}

///|
pub fn GPUCanvasContext::get_format(self : GPUCanvasContext) -> String {
  webgpu_canvas_context_get_format(self)
}

///|
pub fn GPUCanvasContext::get_current_texture(
  self : GPUCanvasContext,
) -> GPUTexture {
  { raw: @raw.webgpu_canvas_context_get_current_texture(self.raw) }
}

///|
pub fn GPUCanvasContext::present(self : GPUCanvasContext) -> Unit {
  @raw.webgpu_canvas_context_present(self.raw)
}

///|
pub fn GPUCanvasContext::release(self : GPUCanvasContext) -> Unit {
  webgpu_canvas_context_release(self)
}

///|
pub fn GPUContext::get(
  self : GPUContext,
) -> (GPUDevice, GPUCanvasContext, String, GPUQueue) {
  let (device, context, format, queue) = @raw.webgpu_context_get(self.raw)
  ({ raw: device }, { raw: context }, format, { raw: queue })
}

///|
pub fn GPUTexture::create_view(self : GPUTexture) -> GPUTextureView {
  @raw.webgpu_texture_create_view(self.raw)
}

///|
pub fn GPUTexture::release(self : GPUTexture) -> Unit {
  @raw.webgpu_texture_release(self.raw)
}

///|
pub fn GPUCommandEncoder::begin_render_pass(
  self : GPUCommandEncoder,
  descriptor : GPURenderPassDescriptor,
) -> GPURenderPassEncoder {
  let raw_desc = render_pass_descriptor_to_raw(descriptor)
  { raw: @raw.webgpu_command_encoder_begin_render_pass(self.raw, raw_desc) }
}

///|
pub fn GPUCommandEncoder::finish(self : GPUCommandEncoder) -> GPUCommandBuffer {
  @raw.webgpu_command_encoder_finish(self.raw)
}

///|
/// Copies an RGBA8 texture into a buffer using WebGPU's padded row layout.
///
/// The destination buffer must be at least `rgba8_copy_padded_byte_length(width, height)` bytes.
#cfg(any(target="js", target="native"))
pub fn GPUCommandEncoder::copy_texture_to_buffer_rgba8(
  self : GPUCommandEncoder,
  texture : GPUTexture,
  buffer : GPUBuffer,
  width : UInt,
  height : UInt,
) -> Unit {
  @raw.webgpu_command_encoder_copy_texture_to_buffer_rgba8(
    self.raw,
    texture.raw,
    buffer.raw,
    width,
    height,
  )
}

///|
pub fn GPUCommandEncoder::release(self : GPUCommandEncoder) -> Unit {
  @raw.webgpu_command_encoder_release(self.raw)
}

///|
pub fn GPUQueue::submit(
  self : GPUQueue,
  command_buffer : GPUCommandBuffer,
) -> Unit {
  @raw.webgpu_queue_submit(self.raw, command_buffer)
}

///|
pub fn GPUQueue::release(self : GPUQueue) -> Unit {
  webgpu_queue_release(self)
}

///|
pub fn GPURenderPassEncoder::set_pipeline(
  self : GPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_pipeline(self.raw, pipeline.raw)
}

///|
pub fn GPURenderPipeline::get_bind_group_layout(
  self : GPURenderPipeline,
  group_index : UInt,
) -> GPUBindGroupLayout {
  {
    raw: @raw.webgpu_render_pipeline_get_bind_group_layout(
      self.raw,
      group_index,
    ),
  }
}

///|
pub fn GPUDevice::create_bind_group(
  self : GPUDevice,
  descriptor : GPUBindGroupDescriptor,
) -> GPUBindGroup {
  let raw_entries : Array[@raw.GPUBindGroupEntry] = descriptor.entries.map(fn(
    entry,
  ) {
    match entry.resource {
      Buffer(buf) => @raw.gp_bind_group_entry_buffer(entry.binding, buf.raw)
      BufferBinding(bb) =>
        @raw.gp_bind_group_entry_buffer_binding(
          entry.binding,
          bb.buffer.raw,
          bb.offset,
          bb.size,
        )
      TextureView(view) =>
        @raw.gp_bind_group_entry_texture_view(entry.binding, view)
      Texture(tex) => @raw.gp_bind_group_entry_texture(entry.binding, tex.raw)
      Sampler(sam) => @raw.gp_bind_group_entry_sampler(entry.binding, sam.raw)
      ExternalTexture(ext) =>
        @raw.gp_bind_group_entry_external_texture(entry.binding, ext.raw)
    }
  })
  {
    raw: @raw.webgpu_device_create_bind_group(
      self.raw,
      descriptor.layout.raw,
      raw_entries,
    ),
  }
}

///|
/// Creates a bind group for the builtin ECS GlobalTransform packed word storage buffer.
pub fn GPUDevice::create_global_transform_words_bind_group(
  self : GPUDevice,
  pipeline : GPURenderPipeline,
  buffer : GPUBuffer,
  group_index : UInt,
  binding : UInt,
) -> GPUBindGroup {
  self.create_bind_group({
    layout: pipeline.get_bind_group_layout(group_index),
    entries: [{ binding, resource: GPUBindingResource::Buffer(buffer) }],
  })
}

///|
pub fn GPURenderPipeline::release(self : GPURenderPipeline) -> Unit {
  renderPipeline_release(self)
}

///|
pub fn GPURenderPassEncoder::draw(
  self : GPURenderPassEncoder,
  vertex_count : Int,
) -> Unit {
  @raw.webgpu_render_pass_encoder_draw(self.raw, vertex_count)
}

///|
pub fn GPURenderPassEncoder::draw_indexed(
  self : GPURenderPassEncoder,
  index_count : Int,
  instance_count? : Int = 1,
  first_index? : Int = 0,
  base_vertex? : Int = 0,
  first_instance? : Int = 0,
) -> Unit {
  @raw.webgpu_render_pass_encoder_draw_indexed(
    self.raw,
    index_count,
    instance_count,
    first_index,
    base_vertex,
    first_instance,
  )
}

///|
pub fn GPURenderPassEncoder::set_bind_group(
  self : GPURenderPassEncoder,
  index : UInt,
  group : GPUBindGroup,
  dynamic_offsets : Array[UInt],
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_bind_group(
    self.raw,
    index,
    group.raw,
    dynamic_offsets,
  )
}

///|
pub fn GPURenderPassEncoder::end(self : GPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_end(self.raw)
}

///|
pub fn GPURenderPassEncoder::release(self : GPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_release(self.raw)
}
