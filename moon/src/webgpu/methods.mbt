///|
pub fn WebGPUInstance::get_preferred_canvas_format(
  self : WebGPUInstance,
) -> String {
  @raw.webgpu_instance_get_preferred_canvas_format(self.raw)
}

///|
pub async fn WebGPUInstance::request_adapter(
  self : WebGPUInstance,
) -> WebGPUAdapter {
  { raw: @raw.webgpu_instance_request_adapter(self.raw) }
}

///|
pub fn WebGPUInstance::process_events(self : WebGPUInstance) -> Unit {
  webgpu_instance_process_events(self)
}

///|
pub fn WebGPUInstance::release(self : WebGPUInstance) -> Unit {
  webgpu_instance_release(self)
}

///|
pub async fn WebGPUAdapter::request_device(
  self : WebGPUAdapter,
) -> WebGPUDevice {
  { raw: @raw.webgpu_adapter_request_device(self.raw) }
}

///|
pub fn WebGPUAdapter::release(self : WebGPUAdapter) -> Unit {
  webgpu_adapter_release(self)
}

///|
pub fn WebGPUDevice::get(self : WebGPUDevice) -> GPUDevice {
  @raw.webgpu_device_get(self.raw)
}

///|
pub fn WebGPUDevice::get_queue(self : WebGPUDevice) -> WebGPUQueue {
  { raw: @raw.webgpu_device_get_queue(self.raw) }
}

///|
pub fn WebGPUDevice::create_shader_module(
  self : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  @raw.webgpu_device_create_shader_module(self.raw, code)
}

///|
pub fn WebGPUDevice::create_render_pipeline(
  self : WebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> WebGPURenderPipeline {
  let (vertex, fragment, topology, formats) = @raw.webgpu_render_pipeline_descriptor_get(
    descriptor,
  )
  {
    raw: @raw.webgpu_device_create_render_pipeline(
      self.raw,
      vertex,
      fragment,
      topology~,
      formats~,
    ),
  }
}

///|
pub fn WebGPUDevice::create_command_encoder(
  self : WebGPUDevice,
) -> WebGPUCommandEncoder {
  { raw: @raw.webgpu_device_create_command_encoder(self.raw) }
}

///|
pub fn WebGPUDevice::poll(self : WebGPUDevice, wait? : Bool = false) -> Bool {
  webgpu_device_poll(self, wait~)
}

///|
pub fn WebGPUDevice::release(self : WebGPUDevice) -> Unit {
  webgpu_device_release(self)
}

///|
pub fn WebGPUCanvasContext::configure(
  self : WebGPUCanvasContext,
  device : WebGPUDevice,
  format : String,
) -> Unit {
  @raw.webgpu_canvas_context_configure(
    self.raw,
    @raw.webgpu_device_get(device.raw),
    format,
  )
}

///|
pub fn WebGPUCanvasContext::get_format(self : WebGPUCanvasContext) -> String {
  webgpu_canvas_context_get_format(self)
}

///|
pub fn WebGPUCanvasContext::get_current_texture(
  self : WebGPUCanvasContext,
) -> WebGPUTexture {
  { raw: @raw.webgpu_canvas_context_get_current_texture(self.raw) }
}

///|
pub fn WebGPUCanvasContext::present(self : WebGPUCanvasContext) -> Unit {
  @raw.webgpu_canvas_context_present(self.raw)
}

///|
pub fn WebGPUCanvasContext::release(self : WebGPUCanvasContext) -> Unit {
  webgpu_canvas_context_release(self)
}

///|
pub fn WebGPUContext::get(
  self : WebGPUContext,
) -> (WebGPUDevice, WebGPUCanvasContext, String, WebGPUQueue) {
  let (device, context, format, queue) = @raw.webgpu_context_get(self.raw)
  ({ raw: device }, { raw: context }, format, { raw: queue })
}

///|
pub fn WebGPUTexture::create_view(self : WebGPUTexture) -> GPUTextureView {
  @raw.webgpu_texture_create_view(self.raw)
}

///|
pub fn WebGPUCommandEncoder::begin_render_pass(
  self : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  let raw_desc = render_pass_descriptor_to_raw(descriptor)
  { raw: @raw.webgpu_command_encoder_begin_render_pass(self.raw, raw_desc) }
}

///|
pub fn WebGPUCommandEncoder::finish(
  self : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  @raw.webgpu_command_encoder_finish(self.raw)
}

///|
pub fn WebGPUCommandEncoder::release(self : WebGPUCommandEncoder) -> Unit {
  @raw.webgpu_command_encoder_release(self.raw)
}

///|
pub fn WebGPUQueue::submit(
  self : WebGPUQueue,
  command_buffer : GPUCommandBuffer,
) -> Unit {
  @raw.webgpu_queue_submit(self.raw, command_buffer)
}

///|
pub fn WebGPUQueue::release(self : WebGPUQueue) -> Unit {
  webgpu_queue_release(self)
}

///|
pub fn WebGPURenderPassEncoder::set_pipeline(
  self : WebGPURenderPassEncoder,
  pipeline : WebGPURenderPipeline,
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_pipeline(self.raw, pipeline.raw)
}

///|
pub fn WebGPURenderPipeline::release(self : WebGPURenderPipeline) -> Unit {
  renderPipeline_release(self)
}

///|
pub fn WebGPURenderPassEncoder::draw(
  self : WebGPURenderPassEncoder,
  vertex_count : Int,
) -> Unit {
  @raw.webgpu_render_pass_encoder_draw(self.raw, vertex_count)
}

///|
pub fn WebGPURenderPassEncoder::end(self : WebGPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_end(self.raw)
}

///|
pub fn WebGPURenderPassEncoder::release(self : WebGPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_release(self.raw)
}
