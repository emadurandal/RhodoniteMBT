// Shared WebGPU renderer implementation.

///|
pub(all) struct WebGPURendererOps[Context, Device, Queue, Pipeline, Texture, TextureView, CommandEncoder, RenderPassEncoder, CommandBuffer, ShaderModule] {
  getCurrentTexture : (Context) -> Texture
  present : (Context) -> Unit
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
  let pipeline = create_pipeline_common(device, format, ops)
  Some({ context, device, queue, pipeline, ops })
}

///|
fn[
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
] create_pipeline_common(
  device : Device,
  format : String,
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
) -> Pipeline {
  let vertex_shader = (ops.createShaderModule)(device, triangle_shader_code)
  let fragment_shader = (ops.createShaderModule)(device, triangle_shader_code)
  let pipeline = (ops.createRenderPipeline)(
    device,
    vertex_shader,
    fragment_shader,
    "triangle-list",
    [format],
  )
  (ops.releaseShaderModule)(vertex_shader)
  (ops.releaseShaderModule)(fragment_shader)
  pipeline
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
  let texture = (renderer.ops.getCurrentTexture)(renderer.context)
  let view = (renderer.ops.createTextureView)(texture)
  let encoder = (renderer.ops.createCommandEncoder)(renderer.device)
  let render_pass = begin_clear_pass_common(renderer, encoder, view, r, g, b, a)
  (renderer.ops.setPipeline)(render_pass, renderer.pipeline)
  (renderer.ops.draw)(render_pass, vertexCount)
  (renderer.ops.endRenderPass)(render_pass)
  (renderer.ops.releaseRenderPass)(render_pass)
  let command_buffer = (renderer.ops.finishCommandEncoder)(encoder)
  (renderer.ops.submit)(renderer.queue, command_buffer)
  (renderer.ops.releaseCommandEncoder)(encoder)
  (renderer.ops.releaseTextureView)(view)
  (renderer.ops.present)(renderer.context)
}

///|
fn[
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
] begin_clear_pass_common(
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
  encoder : CommandEncoder,
  view : TextureView,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> RenderPassEncoder {
  (renderer.ops.beginRenderPass)(encoder, view, r, g, b, a)
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
