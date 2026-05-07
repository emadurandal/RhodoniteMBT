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
/// `configure` に渡す形式ヒント（多くはブラウザの `getPreferredCanvasFormat()` と同じ文字列）に合わせ、
/// 能力から選ぶときの sRGB 優先を切り替える。ヒントが線形 `bgra8unorm` のときに
/// ネイティブだけ `bgra8unorm-srgb` を選ぶとガンマがズレる。
fn native_surface_configure_prefer_srgb_from_hint(hint : String) -> Bool {
  match hint {
    "bgra8unorm-srgb" | "bgra8-unorm-srgb" | "rgba8unorm-srgb" | "rgba8-unorm-srgb" => true
    _ => false
  }
}

///|
fn pick_native_surface_format(
  formats : Array[@wgpu.TextureFormat],
  prefer_srgb : Bool,
) -> @wgpu.TextureFormat {
  let srgb_bgra = @wgpu.TextureFormat::from_u32(
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB,
  )
  let srgb_rgba = @wgpu.TextureFormat::from_u32(
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  )
  let lin_bgra = @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_BGRA8_UNORM)
  let lin_rgba = @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  let prefs = if prefer_srgb {
    [srgb_bgra, srgb_rgba, lin_bgra, lin_rgba]
  } else {
    [lin_bgra, lin_rgba, srgb_bgra, srgb_rgba]
  }
  for pi = 0; pi < prefs.length(); pi = pi + 1 {
    let pu = prefs[pi].to_u32()
    for fi = 0; fi < formats.length(); fi = fi + 1 {
      if formats[fi].to_u32() == pu {
        return formats[fi]
      }
    }
  }
  if formats.length() > 0 {
    formats[0]
  } else {
    lin_bgra
  }
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
  let prefer_srgb = native_surface_configure_prefer_srgb_from_hint(format)
  let ok = context.context.surface.configure_best_effort(
    device.adapter,
    device.raw,
    context.context.width,
    context.context.height,
    usage,
    prefer_srgb=prefer_srgb,
    vsync=true,
  )
  if ok {
    let fmts = context.context.surface.capabilities_formats(device.adapter)
    let chosen = pick_native_surface_format(fmts, prefer_srgb)
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
