///|
pub const BUFFER_USAGE_VERTEX : Int = 0x0020

///|
pub const BUFFER_USAGE_COPY_DST : Int = 0x0008

///|
pub struct GPU {
  raw : @wgpu.Instance
}

///|
pub struct GPUAdapter {
  raw : @wgpu.Adapter
  instance : @wgpu.Instance
}

///|
pub struct GPUDevice {
  raw : @wgpu.Device
  adapter : @wgpu.Adapter
  instance : @wgpu.Instance
}

///|
pub struct GPUQueue {
  raw : @wgpu.Queue
}

///|
pub struct GPUCanvasContext {
  surface : @wgpu.Surface
  width : UInt
  height : UInt
  format : Ref[String]
  currentTexture : Ref[@wgpu.Texture?]
}

///|
pub struct GPUTexture {
  raw : @wgpu.Texture
}

///|
pub struct GPUTextureView {
  raw : @wgpu.TextureView
}

///|
pub struct GPUBuffer {
  raw : @wgpu.Buffer
}

///|
pub struct GPUShaderModule {
  raw : @wgpu.ShaderModule
}

///|
pub struct GPURenderPipeline {
  raw : @wgpu.RenderPipeline
}

///|
pub struct GPUCommandEncoder {
  raw : @wgpu.CommandEncoder
}

///|
pub struct GPURenderPassEncoder {
  raw : @wgpu.RenderPass
}

///|
pub struct GPUCommandBuffer {
  raw : @wgpu.CommandBuffer
}

///|
pub struct WebGPUColor {
  r : Double
  g : Double
  b : Double
  a : Double
}

///|
pub fn WebGPUColor::new(
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> WebGPUColor {
  { r, g, b, a }
}

///|
pub fn WebGPUColor::get(self : WebGPUColor) -> (Double, Double, Double, Double) {
  (self.r, self.g, self.b, self.a)
}

///|
pub struct WebGPURenderPassColorAttachment {
  view : GPUTextureView
  clearValue : WebGPUColor?
  loadOp : String
  storeOp : String
}

///|
pub fn WebGPURenderPassColorAttachment::new(
  view~ : GPUTextureView,
  clearValue? : WebGPUColor,
  loadOp~ : String,
  storeOp~ : String,
) -> WebGPURenderPassColorAttachment {
  { view, clearValue, loadOp, storeOp }
}

///|
pub fn WebGPURenderPassColorAttachment::get(
  self : WebGPURenderPassColorAttachment,
) -> (GPUTextureView, WebGPUColor?, String, String) {
  (self.view, self.clearValue, self.loadOp, self.storeOp)
}

///|
pub struct WebGPURenderPassDepthStencilAttachment {
  view : GPUTextureView
}

///|
pub fn WebGPURenderPassDepthStencilAttachment::new(
  view~ : GPUTextureView,
) -> WebGPURenderPassDepthStencilAttachment {
  { view, }
}

///|
pub struct WebGPURenderPassDescriptor {
  colorAttachments : Array[WebGPURenderPassColorAttachment?]
  depthStencilAttachment : WebGPURenderPassDepthStencilAttachment?
}

///|
pub fn WebGPURenderPassDescriptor::new(
  colorAttachments~ : Array[WebGPURenderPassColorAttachment?],
  depthStencilAttachment? : WebGPURenderPassDepthStencilAttachment,
) -> WebGPURenderPassDescriptor {
  { colorAttachments, depthStencilAttachment }
}

///|
pub fn WebGPURenderPassDescriptor::get(
  self : WebGPURenderPassDescriptor,
) -> (
  Array[WebGPURenderPassColorAttachment?],
  WebGPURenderPassDepthStencilAttachment?,
) {
  (self.colorAttachments, self.depthStencilAttachment)
}

///|
pub struct WebGPURenderPipelineDescriptor {
  vertex : GPUShaderModule
  fragment : GPUShaderModule
  topology : String
  formats : Array[String]
}

///|
pub fn WebGPURenderPipelineDescriptor::new(
  vertex~ : GPUShaderModule,
  fragment~ : GPUShaderModule,
  topology~ : String,
  formats~ : Array[String],
) -> WebGPURenderPipelineDescriptor {
  { vertex, fragment, topology, formats }
}

///|
pub fn WebGPURenderPipelineDescriptor::get(
  self : WebGPURenderPipelineDescriptor,
) -> (GPUShaderModule, GPUShaderModule, String, Array[String]) {
  (self.vertex, self.fragment, self.topology, self.formats)
}

///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn WebGPUInstance::create() -> WebGPUInstance raise Error {
  { instance: GPU::{ raw: @wgpu.Instance::create() } }
}

///|
pub fn WebGPUInstance::new(instance : GPU) -> WebGPUInstance {
  { instance, }
}

///|
pub fn WebGPUInstance::get(self : WebGPUInstance) -> GPU {
  self.instance
}

///|
pub fn WebGPUInstance::getPreferredCanvasFormat(
  self : WebGPUInstance,
) -> String {
  ignore(self)
  "bgra8unorm"
}

///|
pub fn WebGPUInstance::requestAdapter(
  self : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  WebGPUAdapter::new(GPUAdapter::{
    raw: self.instance.raw.request_adapter_sync(),
    instance: self.instance.raw,
  })
}

///|
pub fn WebGPUInstance::processEvents(self : WebGPUInstance) -> Unit {
  self.instance.raw.process_events()
}

///|
pub fn WebGPUInstance::release(self : WebGPUInstance) -> Unit {
  self.instance.raw.release()
}

///|
pub struct WebGPUContext {
  device : WebGPUDevice
  context : WebGPUCanvasContext
  format : String
  queue : WebGPUQueue
}

///|
pub fn WebGPUContext::new(
  device : WebGPUDevice,
  context : WebGPUCanvasContext,
  format : String,
  queue : WebGPUQueue,
) -> WebGPUContext {
  { device, context, format, queue }
}

///|
pub struct WebGPUAdapter {
  adapter : GPUAdapter
}

///|
pub fn WebGPUAdapter::new(adapter : GPUAdapter) -> WebGPUAdapter {
  { adapter, }
}

///|
pub fn WebGPUAdapter::get(self : WebGPUAdapter) -> GPUAdapter {
  self.adapter
}

///|
pub fn WebGPUAdapter::requestDevice(
  self : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  WebGPUDevice::new(GPUDevice::{
    raw: self.adapter.raw.request_device_sync(self.adapter.instance),
    adapter: self.adapter.raw,
    instance: self.adapter.instance,
  })
}

///|
pub fn WebGPUAdapter::release(self : WebGPUAdapter) -> Unit {
  self.adapter.raw.release()
}

///|
pub struct WebGPUDevice {
  device : GPUDevice
}

///|
pub fn WebGPUDevice::new(device : GPUDevice) -> WebGPUDevice {
  { device, }
}

///|
pub fn WebGPUDevice::get(self : WebGPUDevice) -> GPUDevice {
  self.device
}

///|
pub fn WebGPUDevice::getQueue(self : WebGPUDevice) -> WebGPUQueue {
  WebGPUQueue::new(GPUQueue::{ raw: self.device.raw.queue() })
}

///|
pub fn WebGPUDevice::createShaderModule(
  self : WebGPUDevice,
  code : String,
) -> GPUShaderModule {
  GPUShaderModule::{ raw: self.device.raw.create_shader_module_wgsl(code) }
}

///|
pub fn WebGPUDevice::createBuffer(
  self : WebGPUDevice,
  size : Int,
  usage : Int,
) -> GPUBuffer {
  GPUBuffer::{
    raw: self.device.raw.create_buffer(
      size=size.to_uint64(),
      usage=@wgpu.BufferUsage::from_u64(usage.to_uint64()),
    ),
  }
}

///|
pub fn WebGPUDevice::createRenderPipeline(
  self : WebGPUDevice,
  descriptor : WebGPURenderPipelineDescriptor,
) -> GPURenderPipeline {
  let (vertex, _fragment, _topology, formats) = descriptor.get()
  let format = if formats.length() > 0 {
    texture_format_from_string(formats[0])
  } else {
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
  GPURenderPipeline::{
    raw: self.device.raw.create_render_pipeline_color_format_entries(
      vertex.raw,
      format,
      vs_entry="vertexMain",
      fs_entry="fragmentMain",
    ),
  }
}

///|
pub fn WebGPUDevice::createCommandEncoder(
  self : WebGPUDevice,
) -> WebGPUCommandEncoder {
  WebGPUCommandEncoder::new(GPUCommandEncoder::{
    raw: self.device.raw.create_command_encoder(),
  })
}

///|
pub fn WebGPUDevice::poll(self : WebGPUDevice, wait? : Bool = false) -> Bool {
  self.device.raw.poll(wait~)
}

///|
pub fn WebGPUDevice::release(self : WebGPUDevice) -> Unit {
  self.device.raw.release()
}

///|
pub struct WebGPUCanvasContext {
  context : GPUCanvasContext
}

///|
pub fn WebGPUCanvasContext::new(
  context : GPUCanvasContext,
) -> WebGPUCanvasContext {
  { context, }
}

///|
pub fn WebGPUCanvasContext::newMetalLayer(
  instance : WebGPUInstance,
  layer : @c.OpaquePtr,
  width : Int,
  height : Int,
) -> WebGPUCanvasContext {
  let desc = @wgpu.surface_descriptor_metal_layer_new(layer)
  let surface = instance.get().raw.create_surface(desc)
  @wgpu.surface_descriptor_free(desc)
  WebGPUCanvasContext::new(GPUCanvasContext::{
    surface,
    width: width.reinterpret_as_uint(),
    height: height.reinterpret_as_uint(),
    format: @ref.new(instance.getPreferredCanvasFormat()),
    currentTexture: @ref.new(None),
  })
}

///|
pub fn WebGPUCanvasContext::get(self : WebGPUCanvasContext) -> GPUCanvasContext {
  self.context
}

///|
pub fn WebGPUCanvasContext::configure(
  self : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let configured_format = self.context.surface.configure_default(
    device.adapter,
    device.raw,
    self.context.width,
    self.context.height,
    usage,
  )
  self.context.format.val = texture_format_to_string(configured_format)
  if self.context.format.val == "" {
    self.context.format.val = format
  }
}

///|
pub fn WebGPUCanvasContext::getFormat(self : WebGPUCanvasContext) -> String {
  self.context.format.val
}

///|
pub fn WebGPUCanvasContext::getCurrentTexture(
  self : WebGPUCanvasContext,
) -> WebGPUTexture {
  let surface_texture = self.context.surface.get_current_texture_or_raise() catch {
    _ => abort("failed to acquire native WebGPU surface texture")
  }
  let texture = surface_texture.take_texture()
  surface_texture.release()
  self.context.currentTexture.val = Some(texture)
  WebGPUTexture::new(GPUTexture::{ raw: texture })
}

///|
pub fn WebGPUCanvasContext::present(self : WebGPUCanvasContext) -> Unit {
  self.context.surface.present_or_raise() catch {
    _ => ()
  }
  match self.context.currentTexture.val {
    Some(texture) => {
      texture.release()
      self.context.currentTexture.val = None
    }
    None => ()
  }
}

///|
pub fn WebGPUCanvasContext::release(self : WebGPUCanvasContext) -> Unit {
  self.context.surface.unconfigure()
  self.context.surface.release()
}

///|
pub struct WebGPUQueue {
  queue : GPUQueue
}

///|
pub fn WebGPUQueue::new(queue : GPUQueue) -> WebGPUQueue {
  { queue, }
}

///|
pub fn WebGPUQueue::submit(
  self : WebGPUQueue,
  commandBuffer : GPUCommandBuffer,
) -> Unit {
  self.queue.raw.submit_one(commandBuffer.raw)
  commandBuffer.raw.release()
}

///|
pub fn WebGPUQueue::release(self : WebGPUQueue) -> Unit {
  self.queue.raw.release()
}

///|
pub struct WebGPUTexture {
  texture : GPUTexture
}

///|
pub fn WebGPUTexture::new(texture : GPUTexture) -> WebGPUTexture {
  { texture, }
}

///|
pub fn WebGPUTexture::createView(self : WebGPUTexture) -> GPUTextureView {
  GPUTextureView::{ raw: self.texture.raw.create_view() }
}

///|
pub fn textureView_release(view : GPUTextureView) -> Unit {
  view.raw.release()
}

///|
pub struct WebGPUCommandEncoder {
  encoder : GPUCommandEncoder
}

///|
pub fn WebGPUCommandEncoder::new(
  encoder : GPUCommandEncoder,
) -> WebGPUCommandEncoder {
  { encoder, }
}

///|
pub fn WebGPUCommandEncoder::beginRenderPass(
  self : WebGPUCommandEncoder,
  descriptor : WebGPURenderPassDescriptor,
) -> WebGPURenderPassEncoder {
  let (color_attachments, _depth_stencil_attachment) = descriptor.get()
  let attachment = match color_attachments[0] {
    Some(attachment) => attachment
    None => abort("native render pass requires a color attachment")
  }
  let (view, clear_value, _load_op, _store_op) = attachment.get()
  let pass = match clear_value {
    Some(color) => {
      let (r, g, b, a) = color.get()
      self.encoder.raw.begin_render_pass_color_clear(
        view.raw,
        Float::from_double(r),
        Float::from_double(g),
        Float::from_double(b),
        Float::from_double(a),
      )
    }
    None => self.encoder.raw.begin_render_pass_color_load(view.raw)
  }
  WebGPURenderPassEncoder::new(GPURenderPassEncoder::{ raw: pass })
}

///|
pub fn WebGPUCommandEncoder::finish(
  self : WebGPUCommandEncoder,
) -> GPUCommandBuffer {
  GPUCommandBuffer::{ raw: self.encoder.raw.finish() }
}

///|
pub fn WebGPUCommandEncoder::release(self : WebGPUCommandEncoder) -> Unit {
  self.encoder.raw.release()
}

///|
pub struct WebGPURenderPassEncoder {
  encoder : GPURenderPassEncoder
}

///|
pub fn WebGPURenderPassEncoder::new(
  encoder : GPURenderPassEncoder,
) -> WebGPURenderPassEncoder {
  { encoder, }
}

///|
pub fn WebGPURenderPassEncoder::setPipeline(
  self : WebGPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  self.encoder.raw.set_pipeline(pipeline.raw)
}

///|
pub fn WebGPURenderPassEncoder::draw(
  self : WebGPURenderPassEncoder,
  vertexCount : Int,
) -> Unit {
  self.encoder.raw.draw(vertexCount.reinterpret_as_uint(), 1U, 0U, 0U)
}

///|
pub fn WebGPURenderPassEncoder::end(self : WebGPURenderPassEncoder) -> Unit {
  self.encoder.raw.end()
}

///|
pub fn WebGPURenderPassEncoder::release(self : WebGPURenderPassEncoder) -> Unit {
  self.encoder.raw.release()
}

///|
pub fn renderPipeline_release(pipeline : GPURenderPipeline) -> Unit {
  pipeline.raw.release()
}

///|
pub fn shaderModule_release(shaderModule : GPUShaderModule) -> Unit {
  shaderModule.raw.release()
}

///|
pub struct Renderer {
  context : WebGPUCanvasContext
  device : WebGPUDevice
  pipeline : GPURenderPipeline
  queue : WebGPUQueue
}

///|
pub fn create_renderer(context : WebGPUContext) -> Renderer? {
  let shader_module = context.device.createShaderModule(
    native_triangle_shader_code,
  )
  let pipeline = context.device.createRenderPipeline(
    WebGPURenderPipelineDescriptor::new(
      vertex=shader_module,
      fragment=shader_module,
      topology="triangle-list",
      formats=[context.format],
    ),
  )
  shader_module.raw.release()
  Some({
    context: context.context,
    device: context.device,
    pipeline,
    queue: context.queue,
  })
}

///|
pub fn render_frame(renderer : Renderer) -> Unit {
  let texture = renderer.context.getCurrentTexture()
  let view = texture.createView()
  let encoder = renderer.device.createCommandEncoder()
  let render_pass = encoder.beginRenderPass(
    WebGPURenderPassDescriptor::new(colorAttachments=[
      Some(
        WebGPURenderPassColorAttachment::new(
          view~,
          clearValue=WebGPUColor::new(0.0, 0.0, 0.2, 1.0),
          loadOp="clear",
          storeOp="store",
        ),
      ),
    ]),
  )
  render_pass.setPipeline(renderer.pipeline)
  render_pass.draw(3)
  render_pass.end()
  render_pass.release()
  let command_buffer = encoder.finish()
  renderer.queue.submit(command_buffer)
  encoder.release()
  textureView_release(view)
  renderer.context.present()
}

///|
pub fn Renderer::release(self : Renderer) -> Unit {
  renderPipeline_release(self.pipeline)
}

///|
let native_triangle_shader_code : String =
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

///|
fn texture_format_from_string(format : String) -> @wgpu.TextureFormat {
  match format {
    "rgba8unorm" | "rgba8-unorm" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
    "bgra8unorm-srgb" | "bgra8-unorm-srgb" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB)
    "rgba8unorm-srgb" | "rgba8-unorm-srgb" =>
      @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB)
    _ => @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  }
}

///|
fn texture_format_to_string(format : @wgpu.TextureFormat) -> String {
  match format.to_u32() {
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM => "bgra8unorm"
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB => "bgra8unorm-srgb"
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM => "rgba8unorm"
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB => "rgba8unorm-srgb"
    _ => ""
  }
}
