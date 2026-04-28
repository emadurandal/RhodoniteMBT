// WebGPU renderer implementation

///|
pub struct Renderer {
  renderer : @traits.WebGPURenderer[
    JsWebGPUCanvasContext,
    JsWebGPUDevice,
    JsWebGPUQueue,
    GPURenderPipeline,
    JsWebGPUTexture,
    GPUTextureView,
    JsWebGPUCommandEncoder,
    JsWebGPURenderPassEncoder,
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
      js_renderer_ops(),
    ) {
    Some(renderer) => Some({ renderer, })
    None => None
  }
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  @traits.render_frame_common(
    renderer.renderer,
    (1.0, 0.0, 0.2, 1.0),
    get_vertex_count(),
  )
}

///|
fn js_renderer_ops() -> @traits.WebGPURendererOps[
  JsWebGPUCanvasContext,
  JsWebGPUDevice,
  JsWebGPUQueue,
  GPURenderPipeline,
  JsWebGPUTexture,
  GPUTextureView,
  JsWebGPUCommandEncoder,
  JsWebGPURenderPassEncoder,
  GPUCommandBuffer,
  GPUShaderModule,
] {
  {
    createShaderModule: fn(device, code) { device.createShaderModule(code) },
    releaseShaderModule: fn(shaderModule) { ignore(shaderModule) },
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
    releaseRenderPipeline: fn(pipeline) { ignore(pipeline) },
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

///|
pub fn Renderer::release(self : Renderer) -> Unit {
  self.renderer.release()
}
