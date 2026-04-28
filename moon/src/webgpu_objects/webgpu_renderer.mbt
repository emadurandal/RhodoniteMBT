// Shared WebGPU renderer implementation.

///|
pub(all) struct WebGPURendererOps[Context, Device, Queue, Pipeline, Texture, TextureView, CommandEncoder, RenderPassEncoder, CommandBuffer, ShaderModule] {
  createShaderModule : (Device, String) -> ShaderModule
  releaseShaderModule : (ShaderModule) -> Unit
  createRenderPipeline : (
    Device,
    ShaderModule,
    ShaderModule,
    String,
    Array[String],
  ) -> Pipeline
  releaseRenderPipeline : (Pipeline) -> Unit
  getCurrentTexture : (Context) -> Texture
  createTextureView : (Texture) -> TextureView
  releaseTextureView : (TextureView) -> Unit
  createCommandEncoder : (Device) -> CommandEncoder
  beginRenderPass : (
    CommandEncoder,
    TextureView,
    Double,
    Double,
    Double,
    Double,
  ) -> RenderPassEncoder
  setPipeline : (RenderPassEncoder, Pipeline) -> Unit
  draw : (RenderPassEncoder, Int) -> Unit
  endRenderPass : (RenderPassEncoder) -> Unit
  releaseRenderPass : (RenderPassEncoder) -> Unit
  finishCommandEncoder : (CommandEncoder) -> CommandBuffer
  releaseCommandEncoder : (CommandEncoder) -> Unit
  submit : (Queue, CommandBuffer) -> Unit
  present : (Context) -> Unit
}

///|
pub(all) struct WebGPURenderer[Context, Device, Queue, Pipeline, Texture, TextureView, CommandEncoder, RenderPassEncoder, CommandBuffer, ShaderModule] {
  context : Context
  device : Device
  queue : Queue
  pipeline : Pipeline
  ops : WebGPURendererOps[
    Context,
    Device,
    Queue,
    Pipeline,
    Texture,
    TextureView,
    CommandEncoder,
    RenderPassEncoder,
    CommandBuffer,
    ShaderModule,
  ]
}

///|
pub fn[
  Context : WebGPUCanvasContext,
  Device : WebGPUDevice,
  Queue : WebGPUQueue,
  Pipeline : WebGPURenderPipeline,
  Texture,
  TextureView,
  CommandEncoder,
  RenderPassEncoder,
  CommandBuffer,
  ShaderModule : WebGPUShaderModule,
] create_renderer_common(
  context : Context,
  device : Device,
  format : String,
  queue : Queue,
  ops : WebGPURendererOps[
    Context,
    Device,
    Queue,
    Pipeline,
    Texture,
    TextureView,
    CommandEncoder,
    RenderPassEncoder,
    CommandBuffer,
    ShaderModule,
  ],
) -> WebGPURenderer[
  Context,
  Device,
  Queue,
  Pipeline,
  Texture,
  TextureView,
  CommandEncoder,
  RenderPassEncoder,
  CommandBuffer,
  ShaderModule,
]? {
  ignore(context as &WebGPUCanvasContext)
  ignore(device as &WebGPUDevice)
  ignore(queue as &WebGPUQueue)
  let vertex_module = (ops.createShaderModule)(device, triangle_shader_code)
  let fragment_module = (ops.createShaderModule)(device, triangle_shader_code)
  ignore(vertex_module as &WebGPUShaderModule)
  ignore(fragment_module as &WebGPUShaderModule)
  let pipeline = (ops.createRenderPipeline)(
    device,
    vertex_module,
    fragment_module,
    "triangle-list",
    [format],
  )
  ignore(pipeline as &WebGPURenderPipeline)
  (ops.releaseShaderModule)(vertex_module)
  (ops.releaseShaderModule)(fragment_module)
  Some({ context, device, queue, pipeline, ops })
}

///|
pub fn[
  Context : WebGPUCanvasContext,
  Device : WebGPUDevice,
  Queue : WebGPUQueue,
  Pipeline : WebGPURenderPipeline,
  Texture : WebGPUTexture,
  TextureView : WebGPUTextureView,
  CommandEncoder : WebGPUCommandEncoder,
  RenderPassEncoder : WebGPURenderPassEncoder,
  CommandBuffer : WebGPUCommandBuffer,
  ShaderModule,
] render_frame_common(
  renderer : WebGPURenderer[
    Context,
    Device,
    Queue,
    Pipeline,
    Texture,
    TextureView,
    CommandEncoder,
    RenderPassEncoder,
    CommandBuffer,
    ShaderModule,
  ],
  clearColor : (Double, Double, Double, Double),
  vertexCount : Int,
) -> Unit {
  let (r, g, b, a) = clearColor
  ignore(renderer.context as &WebGPUCanvasContext)
  ignore(renderer.device as &WebGPUDevice)
  ignore(renderer.queue as &WebGPUQueue)
  ignore(renderer.pipeline as &WebGPURenderPipeline)
  let texture = (renderer.ops.getCurrentTexture)(renderer.context)
  ignore(texture as &WebGPUTexture)
  let view = (renderer.ops.createTextureView)(texture)
  ignore(view as &WebGPUTextureView)
  let encoder = (renderer.ops.createCommandEncoder)(renderer.device)
  ignore(encoder as &WebGPUCommandEncoder)
  let render_pass = (renderer.ops.beginRenderPass)(encoder, view, r, g, b, a)
  ignore(render_pass as &WebGPURenderPassEncoder)
  (renderer.ops.setPipeline)(render_pass, renderer.pipeline)
  (renderer.ops.draw)(render_pass, vertexCount)
  (renderer.ops.endRenderPass)(render_pass)
  (renderer.ops.releaseRenderPass)(render_pass)
  let command_buffer = (renderer.ops.finishCommandEncoder)(encoder)
  ignore(command_buffer as &WebGPUCommandBuffer)
  (renderer.ops.submit)(renderer.queue, command_buffer)
  (renderer.ops.releaseCommandEncoder)(encoder)
  (renderer.ops.releaseTextureView)(view)
  (renderer.ops.present)(renderer.context)
}

///|
pub fn[
  Context,
  Device,
  Queue,
  Pipeline,
  Texture,
  TextureView,
  CommandEncoder,
  RenderPassEncoder,
  CommandBuffer,
  ShaderModule,
] WebGPURenderer::release(
  self : WebGPURenderer[
    Context,
    Device,
    Queue,
    Pipeline,
    Texture,
    TextureView,
    CommandEncoder,
    RenderPassEncoder,
    CommandBuffer,
    ShaderModule,
  ],
) -> Unit {
  (self.ops.releaseRenderPipeline)(self.pipeline)
}

///|
let triangle_shader_code : String =
  #|struct VertexOutput {
  #|  @builtin(position) position: vec4<f32>,
  #|  @location(0) color: vec3<f32>,
  #|};
  #|
  #|@vertex
  #|fn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
  #|  var pos = array<vec2<f32>, 3>(
  #|    vec2<f32>(0.0, 0.5),
  #|    vec2<f32>(-0.5, -0.5),
  #|    vec2<f32>(0.5, -0.5),
  #|  );
  #|  var colors = array<vec3<f32>, 3>(
  #|    vec3<f32>(1.0, 0.0, 0.0),
  #|    vec3<f32>(0.0, 1.0, 0.0),
  #|    vec3<f32>(0.0, 0.0, 1.0),
  #|  );
  #|  var output: VertexOutput;
  #|  output.position = vec4<f32>(pos[vertexIndex], 0.0, 1.0);
  #|  output.color = colors[vertexIndex];
  #|  return output;
  #|}
  #|
  #|@fragment
  #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
  #|  return vec4<f32>(color, 1.0);
  #|}
  #|
