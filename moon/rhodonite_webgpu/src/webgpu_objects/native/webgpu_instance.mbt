///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  { instance: GPU::{ raw: @wgpu.Instance::create() } }
}

///|
pub fn WebGPUInstance::new(instance : GPU) -> WebGPUInstance {
  { instance, }
}

///|
pub fn create_webgpu_instance(instance : GPU) -> WebGPUInstance {
  WebGPUInstance::new(instance)
}

///|
pub fn webgpu_instance_get_preferred_canvas_format(
  instance : WebGPUInstance,
) -> String {
  ignore(instance)
  // Default hint aligned with browsers where getPreferredCanvasFormat returns linear.
  // Actual swap format is resolved in webgpu_instance_get_preferred_canvas_format_for_surface.
  "bgra8unorm"
}

///|
/// Given the hint from webgpu_instance_get_preferred_canvas_format, whether to prefer sRGB
/// formats for the swap chain (matches Surface::configure_best_effort ordering).
fn webgpu_instance_surface_hint_prefers_srgb(hint : String) -> Bool {
  match hint {
    "bgra8unorm-srgb"
    | "bgra8-unorm-srgb"
    | "rgba8unorm-srgb"
    | "rgba8-unorm-srgb" => true
    _ => false
  }
}

///|
/// Pick one supported surface format based on `prefer_srgb`.
fn webgpu_instance_surface_pick_texture_format(
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
pub fn webgpu_instance_get_preferred_canvas_format_for_surface(
  instance : WebGPUInstance,
  adapter : WebGPUAdapter,
  canvas : WebGPUCanvasContext,
) -> String {
  let hint = webgpu_instance_get_preferred_canvas_format(instance)
  let prefer_srgb = webgpu_instance_surface_hint_prefers_srgb(hint)
  let fmts = canvas.context.surface.capabilities_formats(adapter.adapter.raw)
  let chosen = webgpu_instance_surface_pick_texture_format(fmts, prefer_srgb)
  texture_format_to_string(chosen)
}

///|
pub async fn webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  native_webgpu_instance_request_adapter(instance)
}

///|
pub fn native_webgpu_instance_request_adapter(
  instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  WebGPUAdapter::new(GPUAdapter::{
    raw: instance.instance.raw.request_adapter_sync(),
    instance: instance.instance.raw,
  })
}

///|
pub fn webgpu_instance_process_events(instance : WebGPUInstance) -> Unit {
  instance.instance.raw.process_events()
}

///|
pub fn webgpu_instance_release(instance : WebGPUInstance) -> Unit {
  instance.instance.raw.release()
}
