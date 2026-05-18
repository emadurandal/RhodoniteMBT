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
    swapFormat: @ref.new(""),
    relayEnabled: false,
    currentTexture: @ref.new(None),
    relay: @ref.new(None),
    relayDevice: @ref.new(None),
  })
}

///|
/// Returns whether the native wgpu swapchain surface handle is null.
pub fn webgpu_canvas_context_surface_is_null(
  context : WebGPUCanvasContext,
) -> Bool {
  @c.surface_is_null(context.context.surface.raw)
}

///|
/// Creates a Wayland-backed native canvas context for Linux Vulkan surfaces.
pub fn create_wayland_canvas_context(
  instance : WebGPUInstance,
  display : OpaquePtr,
  wl_surface : OpaquePtr,
  width : Int,
  height : Int,
) -> WebGPUCanvasContext {
  let surface = instance.instance.raw.create_surface_wayland(
    opaque_ptr_to_c(display),
    opaque_ptr_to_c(wl_surface),
  )
  WebGPUCanvasContext::new(GPUCanvasContext::{
    surface,
    width: width.reinterpret_as_uint(),
    height: height.reinterpret_as_uint(),
    format: @ref.new(webgpu_instance_get_preferred_canvas_format(instance)),
    swapFormat: @ref.new(""),
    relayEnabled: false,
    currentTexture: @ref.new(None),
    relay: @ref.new(None),
    relayDevice: @ref.new(None),
  })
}

///|
/// Creates an Xlib-backed native canvas context for Linux Vulkan surfaces.
pub fn create_xlib_canvas_context(
  instance : WebGPUInstance,
  display : OpaquePtr,
  window : UInt64,
  width : Int,
  height : Int,
) -> WebGPUCanvasContext {
  let surface = instance.instance.raw.create_surface_xlib(
    opaque_ptr_to_c(display),
    window,
  )
  WebGPUCanvasContext::new(GPUCanvasContext::{
    surface,
    width: width.reinterpret_as_uint(),
    height: height.reinterpret_as_uint(),
    format: @ref.new(webgpu_instance_get_preferred_canvas_format(instance)),
    swapFormat: @ref.new(""),
    relayEnabled: false,
    currentTexture: @ref.new(None),
    relay: @ref.new(None),
    relayDevice: @ref.new(None),
  })
}

///|
/// Implements `webgpu_canvas_context_configure`.
pub fn webgpu_canvas_context_configure(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  let usage_flags = if context.context.relayEnabled {
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
    @wgpu.TEXTURE_USAGE_COPY_SRC |
    @wgpu.TEXTURE_USAGE_COPY_DST
  } else {
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC
  }
  let usage = @wgpu.TextureUsage::from_u64(usage_flags)
  let prefer_srgb = webgpu_instance_surface_hint_prefers_srgb(format)
  let configured_format = if @wgpu.platform_is_linux() {
    webgpu_canvas_context_configure_linux_rgba_first(
      context, device, usage, prefer_srgb,
    )
  } else {
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
      let chosen = webgpu_instance_surface_pick_texture_format(
        fmts, prefer_srgb,
      )
      Some(texture_format_to_string(chosen))
    } else {
      None
    }
  }
  match configured_format {
    Some(format) => context.context.format.val = format
    None => {
      let configured_format = context.context.surface.configure_default(
        device.adapter,
        device.raw,
        context.context.width,
        context.context.height,
        usage,
      )
      context.context.format.val = texture_format_to_string(configured_format)
    }
  }
  if context.context.format.val == "" {
    context.context.format.val = format
  }
  context.context.swapFormat.val = context.context.format.val
  if context.context.relayEnabled {
    // Engine-visible `format` stays the swapchain format; the relay texture is
    // created with the same format in `linux_swapchain_relay_ensure`.
    let webgpu_device = WebGPUDevice::new(device)
    linux_swapchain_relay_ensure(
      context.context.relay,
      webgpu_device,
      context.context.width,
      context.context.height,
      context.context.swapFormat.val,
    )
    context.context.relayDevice.val = Some(device)
  } else {
    context.context.relay.val = None
    context.context.relayDevice.val = None
  }
}

///|
/// Configures Linux Vulkan surfaces with an RGBA format when the compositor supports it.
fn webgpu_canvas_context_configure_linux_rgba_first(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  usage : @wgpu.TextureUsage,
  prefer_srgb : Bool,
) -> String? {
  let formats = context.context.surface.capabilities_formats(device.adapter)
  let chosen = webgpu_instance_surface_pick_texture_format(formats, prefer_srgb)
  let present_mode = webgpu_canvas_context_pick_supported_u32(
    context.context.surface.capabilities_present_modes(device.adapter),
    [@wgpu.PRESENT_MODE_FIFO, @wgpu.PRESENT_MODE_FIFO_RELAXED],
    @wgpu.PRESENT_MODE_FIFO,
  )
  let alpha_mode = webgpu_canvas_context_pick_supported_u32(
    context.context.surface.capabilities_alpha_modes(device.adapter),
    [
      @wgpu.COMPOSITE_ALPHA_MODE_AUTO,
      @wgpu.COMPOSITE_ALPHA_MODE_OPAQUE,
      @wgpu.COMPOSITE_ALPHA_MODE_PREMULTIPLIED,
      @wgpu.COMPOSITE_ALPHA_MODE_UNPREMULTIPLIED,
      @wgpu.COMPOSITE_ALPHA_MODE_INHERIT,
    ],
    @wgpu.COMPOSITE_ALPHA_MODE_AUTO,
  )
  let ok = context.context.surface.configure_u32(
    device.adapter,
    device.raw,
    context.context.width,
    context.context.height,
    usage,
    chosen,
    present_mode,
    alpha_mode,
  )
  if ok {
    Some(texture_format_to_string(chosen))
  } else {
    None
  }
}

///|
/// Picks the first preferred integer capability supported by a native surface.
fn webgpu_canvas_context_pick_supported_u32(
  supported : Array[UInt],
  prefs : Array[UInt],
  fallback : UInt,
) -> UInt {
  for pi = 0; pi < prefs.length(); pi = pi + 1 {
    for si = 0; si < supported.length(); si = si + 1 {
      if supported[si] == prefs[pi] {
        return prefs[pi]
      }
    }
  }
  if supported.length() > 0 {
    supported[0]
  } else {
    fallback
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
  match context.context.relay.val {
    Some(_) => {
      match context.context.relayDevice.val {
        Some(device) =>
          linux_swapchain_relay_ensure_for_swap_texture(
            context.context.relay,
            texture,
            WebGPUDevice::new(device),
            context.context.width,
            context.context.height,
          )
        None => abort("linux swapchain relay: missing device before acquire")
      }
      let relay = match context.context.relay.val {
        Some(r) => r
        None =>
          abort("linux swapchain relay: missing relay after acquire ensure")
      }
      linux_swapchain_relay_render_texture(relay)
    }
    None => WebGPUTexture::new(GPUTexture::{ raw: texture })
  }
}

///|
/// Implements `webgpu_canvas_context_present`.
pub fn webgpu_canvas_context_present(context : WebGPUCanvasContext) -> Unit {
  match
    (
      context.context.relay.val,
      context.context.currentTexture.val,
      context.context.relayDevice.val,
    ) {
    (Some(relay), Some(swap_texture), Some(device)) => {
      let queue = WebGPUQueue::new(GPUQueue::{ raw: device.raw.queue() })
      linux_swapchain_relay_blit_to_swapchain(
        relay,
        swap_texture,
        WebGPUDevice::new(device),
        queue,
      )
    }
    _ => ()
  }
  context.context.surface.present_or_raise() catch {
    _ => println("native: WebGPU surface present failed")
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
  match context.context.relay.val {
    Some(relay) => linux_swapchain_relay_release(relay)
    None => ()
  }
  context.context.relay.val = None
  context.context.relayDevice.val = None
  context.context.surface.unconfigure()
  context.context.surface.release()
}
