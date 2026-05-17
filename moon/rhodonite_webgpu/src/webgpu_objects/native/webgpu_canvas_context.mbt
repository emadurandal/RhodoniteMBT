///|
/// Defines `WebGPUCanvasContext`.
pub struct WebGPUCanvasContext {
  context : GPUCanvasContext
}

///|
/// Implements `WebGPUCanvasContext::new`.
pub fn WebGPUCanvasContext::new(
  context : GPUCanvasContext,
) -> WebGPUCanvasContext {
  { context, }
}

///|
/// Implements `create_canvas_context`.
pub fn create_canvas_context(context : GPUCanvasContext) -> WebGPUCanvasContext {
  WebGPUCanvasContext::new(context)
}

///|
#borrow(layer)
extern "C" fn surface_descriptor_metal_layer_new_html(
  layer : HTMLCanvasElement,
) -> @c.WGPUSurfaceDescriptorPtr = "mbt_wgpu_surface_descriptor_metal_layer_new"

///|
/// Implements `create_metal_canvas_context`.
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
/// Implements `webgpu_canvas_context_configure`.
pub fn webgpu_canvas_context_configure(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let prefer_srgb = webgpu_instance_surface_hint_prefers_srgb(format)
  let ok = context.context.surface.configure_best_effort(
    device.adapter,
    device.raw,
    context.context.width,
    context.context.height,
    usage,
    prefer_srgb~,
    vsync=true,
  )
  if ok {
    let fmts = context.context.surface.capabilities_formats(device.adapter)
    let chosen = webgpu_instance_surface_pick_texture_format(fmts, prefer_srgb)
    context.context.format.val = texture_format_to_string(chosen)
  } else {
    let configured_format = context.context.surface.configure_default(
      device.adapter,
      device.raw,
      context.context.width,
      context.context.height,
      usage,
    )
    context.context.format.val = texture_format_to_string(configured_format)
  }
  if context.context.format.val == "" {
    context.context.format.val = format
  }
}

///|
/// Resizes the native surface and reconfigures it with the supplied device and format hint.
pub fn webgpu_canvas_context_resize(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
  width : Int,
  height : Int,
) -> Unit {
  if width <= 0 || height <= 0 {
    return
  }
  let new_width = width.reinterpret_as_uint()
  let new_height = height.reinterpret_as_uint()
  if context.context.width == new_width && context.context.height == new_height {
    return
  }
  match context.context.currentTexture.val {
    Some(texture) => {
      texture.release()
      context.context.currentTexture.val = None
    }
    None => ()
  }
  context.context.surface.unconfigure()
  context.context.width = new_width
  context.context.height = new_height
  webgpu_canvas_context_configure(context, device, format)
}

///|
/// Implements `webgpu_canvas_context_get_format`.
pub fn webgpu_canvas_context_get_format(
  context : WebGPUCanvasContext,
) -> String {
  context.context.format.val
}

///|
/// Implements `webgpu_canvas_context_get_current_texture`.
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
/// Implements `webgpu_canvas_context_present`.
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
/// Implements `webgpu_canvas_context_release`.
pub fn webgpu_canvas_context_release(context : WebGPUCanvasContext) -> Unit {
  context.context.surface.unconfigure()
  context.context.surface.release()
}
