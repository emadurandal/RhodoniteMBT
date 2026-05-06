///|
pub fn GPUInstance::get_preferred_canvas_format(self : GPUInstance) -> String {
  @raw.webgpu_instance_get_preferred_canvas_format(self.raw)
}

///|
pub async fn GPUInstance::request_adapter(self : GPUInstance) -> GPUAdapter {
  { raw: @raw.webgpu_instance_request_adapter(self.raw) }
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
    ),
  }
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
pub fn GPURenderPassEncoder::end(self : GPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_end(self.raw)
}

///|
pub fn GPURenderPassEncoder::release(self : GPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_release(self.raw)
}
