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
  let surface = instance.instance.raw.create_surface(desc)
  @wgpu.surface_descriptor_free(desc)
  WebGPUCanvasContext::new(GPUCanvasContext::{
    surface,
    width: width.reinterpret_as_uint(),
    height: height.reinterpret_as_uint(),
    format: @ref.new(webgpu_instance_get_preferred_canvas_format(instance)),
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
  let surface = instance.instance.raw.create_surface(desc)
  @wgpu.surface_descriptor_free(desc)
  WebGPUCanvasContext::new(GPUCanvasContext::{
    surface,
    width: width.reinterpret_as_uint(),
    height: height.reinterpret_as_uint(),
    format: @ref.new(webgpu_instance_get_preferred_canvas_format(instance)),
    currentTexture: @ref.new(None),
  })
}

///|
pub fn webgpu_canvas_context_configure(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let configured_format = context.context.surface.configure_default(
    device.adapter,
    device.raw,
    context.context.width,
    context.context.height,
    usage,
  )
  context.context.format.val = texture_format_to_string(configured_format)
  if context.context.format.val == "" {
    context.context.format.val = format
  }
}

///|
pub fn webgpu_canvas_context_get_format(
  context : WebGPUCanvasContext,
) -> String {
  context.context.format.val
}

///|
pub fn webgpu_canvas_context_get_current_texture(
  context : WebGPUCanvasContext,
) -> WebGPUTexture {
  let surface_texture = context.context.surface.get_current_texture_or_raise() catch {
    _ => abort("failed to acquire native WebGPU surface texture")
  }
  let texture = surface_texture.take_texture()
  surface_texture.release()
  context.context.currentTexture.val = Some(texture)
  WebGPUTexture::new(GPUTexture::{ raw: texture })
}

///|
pub fn webgpu_canvas_context_present(context : WebGPUCanvasContext) -> Unit {
  context.context.surface.present_or_raise() catch {
    _ => ()
  }
  match context.context.currentTexture.val {
    Some(texture) => {
      texture.release()
      context.context.currentTexture.val = None
    }
    None => ()
  }
}

///|
pub fn webgpu_canvas_context_release(context : WebGPUCanvasContext) -> Unit {
  context.context.surface.unconfigure()
  context.context.surface.release()
}
