///|
pub struct Renderer {
  renderer : @traits.WebGPURenderer[
    WebGPUCanvasContext,
    WebGPUDevice,
    WebGPUQueue,
    GPURenderPipeline,
    WebGPUTexture,
    GPUTextureView,
    WebGPUCommandEncoder,
    WebGPURenderPassEncoder,
    GPUCommandBuffer,
    GPUShaderModule,
  ]
}

///|
pub fn create_renderer(context : WebGPUContext) -> Renderer? {
  match
    @traits.create_renderer_common(
      context.context,
      context.device,
      context.format,
      context.queue,
      native_renderer_ops(),
    ) {
    Some(renderer) => Some({ renderer, })
    None => None
  }
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  @traits.render_frame_common(renderer.renderer, (0.0, 0.0, 0.2, 1.0), 3)
}

///|
pub fn Renderer::release(self : Renderer) -> Unit {
  self.renderer.release()
}

///|
fn native_renderer_ops() -> @traits.WebGPURendererOps[
  WebGPUCanvasContext,
  WebGPUDevice,
  WebGPUQueue,
  GPURenderPipeline,
  WebGPUTexture,
  GPUTextureView,
  WebGPUCommandEncoder,
  WebGPURenderPassEncoder,
  GPUCommandBuffer,
  GPUShaderModule,
] {
  {
    createShaderModule: fn(device, code) { device.createShaderModule(code) },
    releaseShaderModule: fn(shaderModule) { shaderModule_release(shaderModule) },
    createRenderPipeline: fn(device, vertex, fragment, topology, formats) {
      device.createRenderPipeline(
        WebGPURenderPipelineDescriptor::new(
          vertex~,
          fragment~,
          topology~,
          formats~,
        ),
      )
    },
    releaseRenderPipeline: fn(pipeline) { renderPipeline_release(pipeline) },
    getCurrentTexture: fn(context) { context.getCurrentTexture() },
    createTextureView: fn(texture) { texture.createView() },
    releaseTextureView: fn(view) { textureView_release(view) },
    createCommandEncoder: fn(device) { device.createCommandEncoder() },
    beginRenderPass: fn(encoder, view, r, g, b, a) {
      encoder.beginRenderPass(
        WebGPURenderPassDescriptor::new(colorAttachments=[
          Some(
            WebGPURenderPassColorAttachment::new(
              view~,
              clearValue=WebGPUColor::new(r, g, b, a),
              loadOp="clear",
              storeOp="store",
            ),
          ),
        ]),
      )
    },
    setPipeline: fn(renderPass, pipeline) { renderPass.setPipeline(pipeline) },
    draw: fn(renderPass, vertexCount) { renderPass.draw(vertexCount) },
    endRenderPass: fn(renderPass) { renderPass.end() },
    releaseRenderPass: fn(renderPass) { renderPass.release() },
    finishCommandEncoder: fn(encoder) { encoder.finish() },
    releaseCommandEncoder: fn(encoder) { encoder.release() },
    submit: fn(queue, commandBuffer) { queue.submit(commandBuffer) },
    present: fn(context) { context.present() },
  }
}
