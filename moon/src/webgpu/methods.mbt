///|
pub fn WebGPUInstance::getPreferredCanvasFormat(
  self : WebGPUInstance,
) -> String {
  webgpu_instance_get_preferred_canvas_format(self)
}

///|
pub async fn WebGPUInstance::requestAdapter(
  self : WebGPUInstance,
) -> WebGPUAdapter {
  webgpu_instance_request_adapter(self)
}

///|
pub fn WebGPUInstance::requestNativeAdapter(
  self : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  native_webgpu_instance_request_adapter(self)
}

///|
pub fn WebGPUInstance::processEvents(self : WebGPUInstance) -> Unit {
  webgpu_instance_process_events(self)
}

///|
pub fn WebGPUInstance::release(self : WebGPUInstance) -> Unit {
  webgpu_instance_release(self)
}

///|
pub async fn WebGPUAdapter::requestDevice(self : WebGPUAdapter) -> WebGPUDevice {
  webgpu_adapter_request_device(self)
}

///|
pub fn WebGPUAdapter::requestNativeDevice(
  self : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  native_webgpu_adapter_request_device(self)
}

///|
pub fn WebGPUAdapter::release(self : WebGPUAdapter) -> Unit {
  webgpu_adapter_release(self)
}

///|
pub fn WebGPUDevice::get(self : WebGPUDevice) -> GPUDevice {
  webgpu_device_get(self)
}

///|
pub fn WebGPUDevice::getQueue(self : WebGPUDevice) -> WebGPUQueue {
  webgpu_device_get_queue(self)
}

///|
pub fn WebGPUDevice::createShaderModule(
  self : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  @raw.webgpu_device_create_shader_module(self.raw, code)
}

///|
pub fn WebGPUDevice::createRenderPipeline(
  self : WebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  let (vertex, fragment, topology, formats) = @raw.webgpu_render_pipeline_descriptor_get(
    descriptor,
  )
  @raw.webgpu_device_create_render_pipeline(
    self.raw,
    vertex,
    fragment,
    topology~,
    formats~,
  )
}

///|
pub fn WebGPUDevice::createCommandEncoder(
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
  webgpu_canvas_context_configure(self, device.get(), format)
}

///|
pub fn WebGPUCanvasContext::getFormat(self : WebGPUCanvasContext) -> String {
  webgpu_canvas_context_get_format(self)
}

///|
pub fn WebGPUCanvasContext::getCurrentTexture(
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
pub fn WebGPUTexture::createView(self : WebGPUTexture) -> GPUTextureView {
  @raw.webgpu_texture_create_view(self.raw)
}

///|
pub fn WebGPUCommandEncoder::beginRenderPass(
  self : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  { raw: @raw.webgpu_command_encoder_begin_render_pass(self.raw, descriptor) }
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
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  @raw.webgpu_queue_submit(self.raw, commandBuffer)
}

///|
pub fn WebGPUQueue::release(self : WebGPUQueue) -> Unit {
  webgpu_queue_release(self)
}

///|
pub fn WebGPURenderPassEncoder::setPipeline(
  self : WebGPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  @raw.webgpu_render_pass_encoder_set_pipeline(self.raw, pipeline)
}

///|
pub fn WebGPURenderPassEncoder::draw(
  self : WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  @raw.webgpu_render_pass_encoder_draw(self.raw, vertexCount)
}

///|
pub fn WebGPURenderPassEncoder::end(self : WebGPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_end(self.raw)
}

///|
pub fn WebGPURenderPassEncoder::release(self : WebGPURenderPassEncoder) -> Unit {
  @raw.webgpu_render_pass_encoder_release(self.raw)
}
