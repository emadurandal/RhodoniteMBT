/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Defines `WebGPUCanvasContext`.
pub struct WebGPUCanvasContext {
  context : GPUCanvasContext
}

///|
/// Pending native canvas capture request used by visual regression platform runs.
let native_canvas_capture_requested : Ref[Bool] = @ref.new(false)

///|
/// Last captured native canvas pixel bytes, stored as tightly packed RGBA8.
let native_canvas_capture_bytes : Ref[Bytes?] = @ref.new(None)

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
    configuredDevice: @ref.new(None),
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
    currentTexture: @ref.new(None),
    configuredDevice: @ref.new(None),
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
    currentTexture: @ref.new(None),
    configuredDevice: @ref.new(None),
  })
}

///|
/// Implements `webgpu_canvas_context_configure`.
pub fn webgpu_canvas_context_configure(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  context.context.configuredDevice.val = Some(device)
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
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
  WebGPUTexture::new(GPUTexture::{ raw: texture })
}

///|
/// Computes WebGPU's 256-byte-aligned RGBA8 copy row pitch.
fn native_rgba8_copy_bytes_per_row(width : UInt) -> UInt64 {
  let unpadded = width.to_uint64() * 4UL
  let align = 256UL
  let rem = unpadded % align
  if rem == 0UL {
    unpadded
  } else {
    unpadded + (align - rem)
  }
}

///|
/// Copies a padded RGBA8 readback buffer into tightly packed RGBA rows.
fn native_pack_rgba8_readback(
  raw : Bytes,
  width : Int,
  height : Int,
  padded_row : Int,
  source_is_bgra : Bool,
) -> Bytes {
  Bytes::makei(width * height * 4, fn(i) {
    let pixel = i / 4
    let x = pixel % width
    let y = pixel / width
    let channel = i % 4
    let src_channel = if source_is_bgra {
      match channel {
        0 => 2
        2 => 0
        _ => channel
      }
    } else {
      channel
    }
    raw[y * padded_row + x * 4 + src_channel]
  })
}

///|
/// Captures the current native canvas texture before presentation when requested.
fn webgpu_canvas_context_capture_current_texture(
  context : WebGPUCanvasContext,
  texture : @wgpu.Texture,
) -> Unit {
  if !native_canvas_capture_requested.val {
    return
  }
  native_canvas_capture_requested.val = false
  native_canvas_capture_bytes.val = None
  let device = match context.context.configuredDevice.val {
    Some(device) => device
    None => return
  }
  let width = context.context.width
  let height = context.context.height
  if width == 0U || height == 0U {
    return
  }
  let padded_row = native_rgba8_copy_bytes_per_row(width)
  let byte_length = padded_row * height.to_uint64()
  let readback = device.raw.create_buffer(
    size=byte_length,
    usage=@wgpu.BufferUsage::from_u64(
      @wgpu.BUFFER_USAGE_MAP_READ | @wgpu.BUFFER_USAGE_COPY_DST,
    ),
  )
  let encoder = device.raw.create_command_encoder()
  encoder.copy_texture_to_buffer_rgba8(texture, readback, width, height)
  device.raw.queue().submit_one(encoder.finish())
  encoder.release()
  ignore(device.raw.poll(wait=true))
  let raw = readback.readback(device.instance, 0UL, byte_length)
  let packed = native_pack_rgba8_readback(
    raw,
    width.reinterpret_as_int(),
    height.reinterpret_as_int(),
    padded_row.to_int(),
    context.context.format.val == "bgra8unorm" ||
    context.context.format.val == "bgra8unorm-srgb",
  )
  readback.release()
  native_canvas_capture_bytes.val = Some(packed)
}

///|
/// Requests a tightly packed RGBA8 capture on the next native canvas present.
pub fn native_canvas_present_capture_begin() -> Unit {
  native_canvas_capture_requested.val = true
  native_canvas_capture_bytes.val = None
}

///|
/// Takes the most recent native canvas present capture, or empty bytes if none.
pub fn native_canvas_present_capture_take() -> Bytes {
  let bytes = match native_canvas_capture_bytes.val {
    Some(bytes) => bytes
    None => []
  }
  native_canvas_capture_bytes.val = None
  bytes
}

///|
/// Implements `webgpu_canvas_context_present`.
pub fn webgpu_canvas_context_present(context : WebGPUCanvasContext) -> Unit {
  match context.context.currentTexture.val {
    Some(texture) =>
      webgpu_canvas_context_capture_current_texture(context, texture)
    None => ()
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
  context.context.surface.unconfigure()
  context.context.surface.release()
}
