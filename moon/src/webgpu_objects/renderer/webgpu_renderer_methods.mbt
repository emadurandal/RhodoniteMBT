///|
fn @w.WebGPUContext::get(
  self : @w.WebGPUContext,
) -> (@w.WebGPUDevice, @w.WebGPUCanvasContext, String, @w.WebGPUQueue) {
  @w.webgpu_context_get(self)
}

///|
fn @w.WebGPUDevice::createShaderModule(
  self : @w.WebGPUDevice,
  code : String,
) -> @w.GPUShaderModule {
  @w.webgpu_device_create_shader_module(self, code)
}

///|
fn @w.WebGPUDevice::createRenderPipeline(
  self : @w.WebGPUDevice,
  vertex : @w.GPUShaderModule,
  fragment : @w.GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> @w.GPURenderPipeline {
  @w.webgpu_device_create_render_pipeline(
    self,
    vertex,
    fragment,
    topology~,
    formats~,
  )
}

///|
fn @w.WebGPUDevice::createCommandEncoder(
  self : @w.WebGPUDevice,
) -> @w.WebGPUCommandEncoder {
  @w.webgpu_device_create_command_encoder(self)
}

///|
fn @w.WebGPUCanvasContext::getCurrentTexture(
  self : @w.WebGPUCanvasContext,
) -> @w.WebGPUTexture {
  @w.webgpu_canvas_context_get_current_texture(self)
}

///|
fn @w.WebGPUCanvasContext::present(self : @w.WebGPUCanvasContext) -> Unit {
  @w.webgpu_canvas_context_present(self)
}

///|
fn @w.WebGPUTexture::createView(self : @w.WebGPUTexture) -> @w.GPUTextureView {
  @w.webgpu_texture_create_view(self)
}

///|
fn @w.WebGPUCommandEncoder::beginRenderPass(
  self : @w.WebGPUCommandEncoder,
  descriptor : @w.WebGPURenderPassDescriptor,
) -> @w.WebGPURenderPassEncoder {
  @w.webgpu_command_encoder_begin_render_pass(self, descriptor)
}

///|
fn @w.WebGPUCommandEncoder::finish(
  self : @w.WebGPUCommandEncoder,
) -> @w.GPUCommandBuffer {
  @w.webgpu_command_encoder_finish(self)
}

///|
fn @w.WebGPUCommandEncoder::release(self : @w.WebGPUCommandEncoder) -> Unit {
  @w.webgpu_command_encoder_release(self)
}

///|
fn @w.WebGPUQueue::submit(
  self : @w.WebGPUQueue,
  commandBuffer : @w.GPUCommandBuffer,
) -> Unit {
  @w.webgpu_queue_submit(self, commandBuffer)
}

///|
fn @w.WebGPURenderPassEncoder::setPipeline(
  self : @w.WebGPURenderPassEncoder,
  pipeline : @w.GPURenderPipeline,
) -> Unit {
  @w.webgpu_render_pass_encoder_set_pipeline(self, pipeline)
}

///|
fn @w.WebGPURenderPassEncoder::draw(
  self : @w.WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  @w.webgpu_render_pass_encoder_draw(self, vertexCount)
}

///|
fn @w.WebGPURenderPassEncoder::end(self : @w.WebGPURenderPassEncoder) -> Unit {
  @w.webgpu_render_pass_encoder_end(self)
}

///|
fn @w.WebGPURenderPassEncoder::release(
  self : @w.WebGPURenderPassEncoder,
) -> Unit {
  @w.webgpu_render_pass_encoder_release(self)
}
