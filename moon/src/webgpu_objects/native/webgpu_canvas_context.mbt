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
pub fn create_canvas_context(context : GPUCanvasContext) -> WebGPUCanvasContext {
  WebGPUCanvasContext::new(context)
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
#borrow(layer)
extern "C" fn surface_descriptor_metal_layer_new_html(
  layer : HTMLCanvasElement,
) -> @c.WGPUSurfaceDescriptorPtr = "mbt_wgpu_surface_descriptor_metal_layer_new"

///|
pub fn create_metal_canvas_context(
  instance : WebGPUInstance,
  layer : HTMLCanvasElement,
  width : Int,
  height : Int,
) -> WebGPUCanvasContext {
  let desc = surface_descriptor_metal_layer_new_html(layer)
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
pub fn webgpu_canvas_context_configure(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  context.configure(device, format)
}

///|
pub fn WebGPUCanvasContext::getFormat(self : WebGPUCanvasContext) -> String {
  self.context.format.val
}

///|
pub fn webgpu_canvas_context_get_format(
  context : WebGPUCanvasContext,
) -> String {
  context.getFormat()
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
pub fn webgpu_canvas_context_release(context : WebGPUCanvasContext) -> Unit {
  context.release()
}
