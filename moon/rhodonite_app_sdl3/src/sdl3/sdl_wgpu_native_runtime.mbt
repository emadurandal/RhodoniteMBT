/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| Shared SDL3 + native wgpu app bootstrap (macOS Metal, Linux Wayland/X11 Vulkan).

///|
/// Initialization and runtime failures reported by the SDL3 native app adapter.
pub(all) suberror Sdl3AppError {
  CreateContextFailed
  InvalidSurfaceSize(Int, Int)
  CreateWindowFailed(String)
  CreateMetalViewFailed(String)
  GetMetalLayerFailed(String)
  CreateNativeSurfaceFailed(String)
  UnsupportedNativePlatform
  CreateWebGpuInstanceFailed
  RequestAdapterFailed
  RequestDeviceFailed
  QueryWindowSizeInPixelsFailed(String)
} derive(Eq, Debug)

///|
/// Owns native SDL3, Metal, WebGPU surface, device, and Rhodonite GPU context resources.
pub struct SdlMetalWebGpuNativeSession {
  priv ctx : @sdl3_pkg.Context
  priv sdl_win : @lib.SDL_Window
  priv metal_view : @wgpu_objects.OpaquePtr
  priv instance : @wgpu.GPUInstance
  priv webgpu_canvas_context : @wgpu.GPUCanvasContext
  priv adapter : @wgpu.GPUAdapter
  priv device : @wgpu.GPUDevice
  priv queue : @wgpu.GPUQueue
  priv gpu_context : @wgpu.GPUContext
  priv mut surface_active : Bool
  priv mut surface_width : Int
  priv mut surface_height : Int
  priv mut surface_format : String
}

///|
/// Mirrors the SDL mouse motion event layout needed by the native input adapter.
priv struct SdlMouseMotionEvent {
  event_type : @lib.SDL_EventType
  reserved : UInt
  timestamp : UInt64
  windowID : @lib.SDL_WindowID
  which : @lib.SDL_MouseID
  state : UInt
  x : Float
  y : Float
  xrel : Float
  yrel : Float
}

///|
/// Mirrors the SDL mouse button event layout needed by the native input adapter.
priv struct SdlMouseButtonEvent {
  event_type : @lib.SDL_EventType
  reserved : UInt
  timestamp : UInt64
  windowID : @lib.SDL_WindowID
  which : @lib.SDL_MouseID
  button : Byte
  down : Bool
  clicks : Byte
  padding : Byte
  x : Float
  y : Float
}

///|
/// Mirrors the SDL mouse wheel event layout needed by the native input adapter.
priv struct SdlMouseWheelEvent {
  event_type : @lib.SDL_EventType
  reserved : UInt
  timestamp : UInt64
  windowID : @lib.SDL_WindowID
  which : @lib.SDL_MouseID
  x : Float
  y : Float
  direction : @lib.SDL_MouseWheelDirection
  mouse_x : Float
  mouse_y : Float
}

///|
/// Mirrors the SDL window event layout needed for resize handling.
priv struct SdlWindowEvent {
  event_type : @lib.SDL_EventType
  reserved : UInt
  timestamp : UInt64
  windowID : @lib.SDL_WindowID
  data1 : Int
  data2 : Int
}

///|
/// Mirrors the common SDL event prefix for events that carry a window id.
priv struct SdlWindowScopedEvent {
  event_type : @lib.SDL_EventType
  reserved : UInt
  timestamp : UInt64
  windowID : @lib.SDL_WindowID
}

///|
/// One native window and WebGPU presentation surface owned by a multi-window platform.
pub(all) struct SdlMultiWindowSurface {
  priv window_id : @lib.SDL_WindowID
  priv sdl_win : @lib.SDL_Window
  priv metal_view : @wgpu_objects.OpaquePtr
  priv webgpu_canvas_context : @wgpu.GPUCanvasContext
  priv gpu_surface : @wgpu.GPUSurface
  priv mut engine_surface_id : @app.SurfaceId?
}

///|
/// Owns SDL3, one shared WebGPU device, and multiple native window surfaces.
pub struct SdlMultiWindowPlatformSession {
  priv ctx : @sdl3_pkg.Context
  priv instance : @wgpu.GPUInstance
  priv adapter : @wgpu.GPUAdapter
  priv device : @wgpu.GPUDevice
  priv queue : @wgpu.GPUQueue
  priv gpu_context : @wgpu.GPUContext
  priv surfaces : Array[SdlMultiWindowSurface]
  priv mut focused_window_id : @lib.SDL_WindowID?
}

///|
/// Keeps the private SDL window mirror visible to MoonBit's field checks.
fn _touch_sdl_window_event_struct() -> Unit {
  let event = SdlWindowEvent::{
    event_type: SDL_EVENT_WINDOW_RESIZED,
    reserved: 0U,
    timestamp: 0UL,
    windowID: 0U,
    data1: 0,
    data2: 0,
  }
  ignore(event.event_type)
  ignore(event.reserved)
  ignore(event.timestamp)
  ignore(event.windowID)
  ignore(event.data1)
  ignore(event.data2)
}

///|
/// Keeps the private SDL window-scoped mirror visible to MoonBit's field checks.
fn _touch_sdl_window_scoped_event_struct() -> Unit {
  let event = SdlWindowScopedEvent::{
    event_type: SDL_EVENT_WINDOW_RESIZED,
    reserved: 0U,
    timestamp: 0UL,
    windowID: 0U,
  }
  ignore(event.event_type)
  ignore(event.reserved)
  ignore(event.timestamp)
  ignore(event.windowID)
}

///|
/// Keeps the private SDL mouse motion mirror visible to MoonBit's field checks.
fn _touch_sdl_mouse_motion_event_struct() -> Unit {
  let event = SdlMouseMotionEvent::{
    event_type: SDL_EVENT_MOUSE_MOTION,
    reserved: 0U,
    timestamp: 0UL,
    windowID: 0U,
    which: 0U,
    state: 0U,
    x: (0.0 : Float),
    y: (0.0 : Float),
    xrel: (0.0 : Float),
    yrel: (0.0 : Float),
  }
  ignore(event.event_type)
  ignore(event.reserved)
  ignore(event.timestamp)
  ignore(event.windowID)
  ignore(event.which)
  ignore(event.state)
  ignore(event.x)
  ignore(event.y)
  ignore(event.xrel)
  ignore(event.yrel)
}

///|
/// Keeps the private SDL mouse button mirror visible to MoonBit's field checks.
fn _touch_sdl_mouse_button_event_struct() -> Unit {
  let event = SdlMouseButtonEvent::{
    event_type: SDL_EVENT_MOUSE_BUTTON_DOWN,
    reserved: 0U,
    timestamp: 0UL,
    windowID: 0U,
    which: 0U,
    button: (1 : Byte),
    down: true,
    clicks: (1 : Byte),
    padding: (0 : Byte),
    x: (0.0 : Float),
    y: (0.0 : Float),
  }
  ignore(event.event_type)
  ignore(event.reserved)
  ignore(event.timestamp)
  ignore(event.windowID)
  ignore(event.which)
  ignore(event.button)
  ignore(event.down)
  ignore(event.clicks)
  ignore(event.padding)
  ignore(event.x)
  ignore(event.y)
}

///|
/// Keeps the private SDL wheel mirror visible to MoonBit's field checks.
fn _touch_sdl_mouse_wheel_event_struct() -> Unit {
  let event = SdlMouseWheelEvent::{
    event_type: SDL_EVENT_MOUSE_WHEEL,
    reserved: 0U,
    timestamp: 0UL,
    windowID: 0U,
    which: 0U,
    x: (0.0 : Float),
    y: (0.0 : Float),
    direction: SDL_MOUSEWHEEL_NORMAL,
    mouse_x: (0.0 : Float),
    mouse_y: (0.0 : Float),
  }
  ignore(event.event_type)
  ignore(event.reserved)
  ignore(event.timestamp)
  ignore(event.windowID)
  ignore(event.which)
  ignore(event.x)
  ignore(event.y)
  ignore(event.direction)
  ignore(event.mouse_x)
  ignore(event.mouse_y)
}

///|
/// Returns the Rhodonite GPU context owned by a native SDL3 session.
pub fn SdlMetalWebGpuNativeSession::gpu_context(
  self : SdlMetalWebGpuNativeSession,
) -> @wgpu.GPUContext {
  self.gpu_context
}

///|
/// Returns the current native drawable width in pixels.
pub fn SdlMetalWebGpuNativeSession::surface_width(
  self : SdlMetalWebGpuNativeSession,
) -> Int {
  self.surface_width
}

///|
/// Reports whether the native drawable surface currently has a renderable size.
pub fn SdlMetalWebGpuNativeSession::surface_active(
  self : SdlMetalWebGpuNativeSession,
) -> Bool {
  self.surface_active
}

///|
/// Returns the current native drawable height in pixels.
pub fn SdlMetalWebGpuNativeSession::surface_height(
  self : SdlMetalWebGpuNativeSession,
) -> Int {
  self.surface_height
}

///|
/// Returns the current native surface texture format.
pub fn SdlMetalWebGpuNativeSession::surface_format(
  self : SdlMetalWebGpuNativeSession,
) -> String {
  self.surface_format
}

///|
/// Returns the native window drawable size in physical pixels.
#borrow(width, height)
extern "C" fn sdl_get_window_size_in_pixels(
  window : @lib.SDL_Window,
  width : FixedArray[Int],
  height : FixedArray[Int],
) -> Bool = "SDL_GetWindowSizeInPixels"

///|
/// Returns SDL's stable id for a window.
extern "C" fn sdl_get_window_id(window : @lib.SDL_Window) -> @lib.SDL_WindowID = "SDL_GetWindowID"

///|
/// Raises a structured error if a drawable size cannot be used for WebGPU.
fn ensure_valid_surface_size(
  width : Int,
  height : Int,
) -> Unit raise Sdl3AppError {
  if width <= 0 || height <= 0 {
    raise Sdl3AppError::InvalidSurfaceSize(width, height)
  }
}

///|
/// Queries the SDL window drawable size in physical pixels without validating extent.
fn query_sdl_window_size_in_pixels_raw(
  window : @lib.SDL_Window,
) -> (Int, Int) raise Sdl3AppError {
  let width = FixedArray::make(1, 0)
  let height = FixedArray::make(1, 0)
  if !sdl_get_window_size_in_pixels(window, width, height) {
    raise Sdl3AppError::QueryWindowSizeInPixelsFailed(@lib.sdl_GetError())
  }
  (width[0], height[0])
}

///|
/// Queries a positive SDL window drawable size in physical pixels.
fn query_valid_sdl_window_size_in_pixels(
  window : @lib.SDL_Window,
) -> (Int, Int) raise Sdl3AppError {
  let (width, height) = query_sdl_window_size_in_pixels_raw(window)
  ensure_valid_surface_size(width, height)
  (width, height)
}

///|
/// Creates a WebGPU canvas context from SDL window handles on Linux.
fn create_linux_canvas_context(
  instance : @wgpu.GPUInstance,
  sdl_win : @lib.SDL_Window,
  surface_width : Int,
  surface_height : Int,
) -> @wgpu.GPUCanvasContext raise Sdl3AppError {
  match query_wayland_window_surface(sdl_win) {
    Some(handles) => {
      let canvas = @wgpu_objects.create_wayland_canvas_context(
        instance.raw,
        handles.display,
        handles.surface,
        surface_width,
        surface_height,
      )
      ensure_wgpu_surface_ready(canvas)
      @wgpu.GPUCanvasContext::{ raw: canvas }
    }
    None =>
      match query_xlib_window_surface(sdl_win) {
        Some(handles) => {
          let canvas = @wgpu_objects.create_xlib_canvas_context(
            instance.raw,
            handles.display,
            handles.window,
            surface_width,
            surface_height,
          )
          ensure_wgpu_surface_ready(canvas)
          @wgpu.GPUCanvasContext::{ raw: canvas }
        }
        None =>
          raise Sdl3AppError::CreateNativeSurfaceFailed(
            "SDL window exposes neither Wayland nor X11 handles for Vulkan",
          )
      }
  }
}

///|
/// Raises when wgpu returns a null native swapchain surface.
fn ensure_wgpu_surface_ready(
  canvas : @wgpu_objects.WebGPUCanvasContext,
) -> Unit raise Sdl3AppError {
  if @wgpu_objects.webgpu_canvas_context_surface_is_null(canvas) {
    raise Sdl3AppError::CreateNativeSurfaceFailed(
      "wgpu native surface handle is null",
    )
  }
}

///|
/// Requests a native GPU adapter, preferring one that can present to `canvas`.
fn request_native_webgpu_adapter(
  instance : @wgpu.GPUInstance,
  canvas : @wgpu.GPUCanvasContext,
) -> @wgpu.GPUAdapter raise Error {
  instance.request_adapter_for_surface(canvas) catch {
    _ => instance.request_adapter_sync()
  }
}

///|
/// Completes WebGPU device setup after a native swapchain surface exists.
fn finish_sdl_webgpu_native_session(
  ctx : @sdl3_pkg.Context,
  sdl_win : @lib.SDL_Window,
  metal_view : @wgpu_objects.OpaquePtr,
  instance : @wgpu.GPUInstance,
  webgpu_canvas_context : @wgpu.GPUCanvasContext,
  surface_width : Int,
  surface_height : Int,
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  let adapter = request_native_webgpu_adapter(instance, webgpu_canvas_context) catch {
    _ => {
      webgpu_canvas_context.release()
      instance.release()
      if !@wgpu_objects.opaque_ptr_is_null(metal_view) {
        sdl_metal_destroy_view(metal_view)
      }
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise Sdl3AppError::RequestAdapterFailed
    }
  }
  let device = adapter.request_device_sync() catch {
    _ => {
      webgpu_canvas_context.release()
      adapter.release()
      instance.release()
      if !@wgpu_objects.opaque_ptr_is_null(metal_view) {
        sdl_metal_destroy_view(metal_view)
      }
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise Sdl3AppError::RequestDeviceFailed
    }
  }
  let format = instance.get_preferred_canvas_format_for_surface(
    adapter, webgpu_canvas_context,
  )
  webgpu_canvas_context.configure(device, format)
  let queue = device.get_queue()
  let render_format = webgpu_canvas_context.get_format()
  let gpu_context = @wgpu.create_webgpu_context(
    device, webgpu_canvas_context, render_format, queue,
  )
  {
    ctx,
    sdl_win,
    metal_view,
    instance,
    webgpu_canvas_context,
    adapter,
    device,
    queue,
    gpu_context,
    surface_active: true,
    surface_width,
    surface_height,
    surface_format: render_format,
  }
}

///|
/// Initializes SDL3, creates a Linux Vulkan surface, and returns a native session.
pub fn init_sdl_linux_webgpu_native(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  if !@wgpu_native.platform_is_linux() {
    raise Sdl3AppError::UnsupportedNativePlatform
  }
  ensure_valid_surface_size(width, height)
  println(init_log)
  preinit_linux_sdl_video()
  let ctx = @sdl3_pkg.Context::new() catch {
    _ => raise Sdl3AppError::CreateContextFailed
  }
  println("native: creating SDL window (Linux Vulkan)")
  let sdl_win = create_linux_wgpu_sdl_window(window_title, width, height)
  if sdl_win.is_null() {
    ctx.quit()
    raise Sdl3AppError::CreateWindowFailed(@lib.sdl_GetError())
  }
  rhodonite_sdl_prepare_shown_window(sdl_win)
  let (surface_width, surface_height) = query_valid_sdl_window_size_in_pixels(
    sdl_win,
  )
  println("native: creating WebGPU instance and Vulkan surface")
  let instance = @wgpu.create_native_webgpu_instance() catch {
    _ => {
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise Sdl3AppError::CreateWebGpuInstanceFailed
    }
  }
  let webgpu_canvas_context = create_linux_canvas_context(
    instance, sdl_win, surface_width, surface_height,
  ) catch {
    error => {
      instance.release()
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise error
    }
  }
  finish_sdl_webgpu_native_session(
    ctx,
    sdl_win,
    @wgpu_objects.null_opaque_ptr(),
    instance,
    webgpu_canvas_context,
    surface_width,
    surface_height,
  )
}

///|
/// Initializes SDL3 and a native WebGPU surface for the current host OS.
pub fn init_sdl_webgpu_native(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  if @wgpu_native.platform_is_macos() {
    init_sdl_metal_webgpu_native(window_title, width, height, init_log)
  } else if @wgpu_native.platform_is_linux() {
    init_sdl_linux_webgpu_native(window_title, width, height, init_log)
  } else {
    raise Sdl3AppError::UnsupportedNativePlatform
  }
}

///|
/// Initializes SDL3, creates a Metal-backed WebGPU surface, and returns a native session.
pub fn init_sdl_metal_webgpu_native(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  ensure_valid_surface_size(width, height)
  println(init_log)
  let ctx = @sdl3_pkg.Context::new() catch {
    _ => raise Sdl3AppError::CreateContextFailed
  }
  let sdl_win = @lib.sdl_CreateWindow(
    window_title,
    width,
    height,
    @lib.SDL_WINDOW_METAL | @lib.SDL_WINDOW_RESIZABLE,
  )
  if sdl_win.is_null() {
    ctx.quit()
    raise Sdl3AppError::CreateWindowFailed(@lib.sdl_GetError())
  }
  let _ = @lib.sdl_ShowWindow(sdl_win)
  let _ = @lib.sdl_RaiseWindow(sdl_win)
  let _ = @lib.sdl_SyncWindow(sdl_win)
  let (surface_width, surface_height) = query_valid_sdl_window_size_in_pixels(
    sdl_win,
  ) catch {
    error => {
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise error
    }
  }
  let metal_view = sdl_metal_create_view(sdl_win)
  if @wgpu_objects.opaque_ptr_is_null(metal_view) {
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    raise Sdl3AppError::CreateMetalViewFailed(@lib.sdl_GetError())
  }
  let cametal_ptr = sdl_metal_get_layer_ptr(metal_view)
  if @wgpu_objects.opaque_ptr_is_null(cametal_ptr) {
    sdl_metal_destroy_view(metal_view)
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    raise Sdl3AppError::GetMetalLayerFailed(@lib.sdl_GetError())
  }
  let cametal = sdl_metal_get_layer(metal_view)
  let instance = @wgpu.create_native_webgpu_instance() catch {
    _ => {
      sdl_metal_destroy_view(metal_view)
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise Sdl3AppError::CreateWebGpuInstanceFailed
    }
  }
  let webgpu_canvas_context = @wgpu.create_metal_canvas_context(
    instance, cametal, surface_width, surface_height,
  )
  finish_sdl_webgpu_native_session(
    ctx, sdl_win, metal_view, instance, webgpu_canvas_context, surface_width, surface_height,
  )
}

///|
/// Releases WebGPU, Metal, and SDL3 resources owned by a native session.
pub fn release_sdl_metal_webgpu_native(
  session : SdlMetalWebGpuNativeSession,
) -> Unit {
  session.webgpu_canvas_context.release()
  session.queue.release()
  session.device.release()
  session.adapter.release()
  session.instance.release()
  if !@wgpu_objects.opaque_ptr_is_null(session.metal_view) {
    sdl_metal_destroy_view(session.metal_view)
  }
  @lib.sdl_DestroyWindow(session.sdl_win)
  session.ctx.quit()
}

///|
/// Returns the compatibility GPU context for engine creation.
pub fn SdlMultiWindowPlatformSession::gpu_context(
  self : SdlMultiWindowPlatformSession,
) -> @wgpu.GPUContext {
  self.gpu_context
}

///|
/// Returns the GPU surface owned by a native multi-window surface.
pub fn SdlMultiWindowSurface::gpu_surface(
  self : SdlMultiWindowSurface,
) -> @wgpu.GPUSurface {
  self.gpu_surface
}

///|
/// Releases a single native multi-window surface.
fn release_sdl_multi_window_surface(surface : SdlMultiWindowSurface) -> Unit {
  surface.webgpu_canvas_context.release()
  if !@wgpu_objects.opaque_ptr_is_null(surface.metal_view) {
    sdl_metal_destroy_view(surface.metal_view)
  }
  @lib.sdl_DestroyWindow(surface.sdl_win)
}

///|
/// Releases all resources owned by a native multi-window platform.
pub fn release_sdl_multi_window_platform(
  session : SdlMultiWindowPlatformSession,
) -> Unit {
  for i = 0; i < session.surfaces.length(); i = i + 1 {
    release_sdl_multi_window_surface(session.surfaces[i])
  }
  session.queue.release()
  session.device.release()
  session.adapter.release()
  session.instance.release()
  session.ctx.quit()
}

///|
/// Converts the legacy single-window bootstrap result into a multi-window platform.
fn init_sdl_multi_window_platform_from_first(
  first : SdlMetalWebGpuNativeSession,
) -> SdlMultiWindowPlatformSession {
  let surface = @wgpu.create_gpu_surface(
    first.webgpu_canvas_context,
    first.surface_format,
    first.surface_width,
    first.surface_height,
  )
  let surfaces : Array[SdlMultiWindowSurface] = [
    {
      window_id: sdl_get_window_id(first.sdl_win),
      sdl_win: first.sdl_win,
      metal_view: first.metal_view,
      webgpu_canvas_context: first.webgpu_canvas_context,
      gpu_surface: surface,
      engine_surface_id: None,
    },
  ]
  {
    ctx: first.ctx,
    instance: first.instance,
    adapter: first.adapter,
    device: first.device,
    queue: first.queue,
    gpu_context: first.gpu_context,
    surfaces,
    focused_window_id: Some(sdl_get_window_id(first.sdl_win)),
  }
}

///|
/// Creates one additional SDL window surface using an existing shared WebGPU device.
fn attach_sdl_multi_window_surface(
  session : SdlMultiWindowPlatformSession,
  config : PlatformConfig,
) -> Unit raise Sdl3AppError {
  ensure_valid_surface_size(config.width, config.height)
  let (sdl_win, metal_view, webgpu_canvas_context, surface_width, surface_height
  ) = if @wgpu_native.platform_is_macos() {
    let sdl_win = @lib.sdl_CreateWindow(
      config.window_title,
      config.width,
      config.height,
      @lib.SDL_WINDOW_METAL | @lib.SDL_WINDOW_RESIZABLE,
    )
    if sdl_win.is_null() {
      raise Sdl3AppError::CreateWindowFailed(@lib.sdl_GetError())
    }
    let _ = @lib.sdl_ShowWindow(sdl_win)
    let _ = @lib.sdl_RaiseWindow(sdl_win)
    let _ = @lib.sdl_SyncWindow(sdl_win)
    let (surface_width, surface_height) = query_valid_sdl_window_size_in_pixels(
      sdl_win,
    ) catch {
      error => {
        @lib.sdl_DestroyWindow(sdl_win)
        raise error
      }
    }
    let metal_view = sdl_metal_create_view(sdl_win)
    if @wgpu_objects.opaque_ptr_is_null(metal_view) {
      @lib.sdl_DestroyWindow(sdl_win)
      raise Sdl3AppError::CreateMetalViewFailed(@lib.sdl_GetError())
    }
    let cametal_ptr = sdl_metal_get_layer_ptr(metal_view)
    if @wgpu_objects.opaque_ptr_is_null(cametal_ptr) {
      sdl_metal_destroy_view(metal_view)
      @lib.sdl_DestroyWindow(sdl_win)
      raise Sdl3AppError::GetMetalLayerFailed(@lib.sdl_GetError())
    }
    let cametal = sdl_metal_get_layer(metal_view)
    (
      sdl_win,
      metal_view,
      @wgpu.create_metal_canvas_context(
        session.instance,
        cametal,
        surface_width,
        surface_height,
      ),
      surface_width,
      surface_height,
    )
  } else if @wgpu_native.platform_is_linux() {
    let sdl_win = create_linux_wgpu_sdl_window(
      config.window_title,
      config.width,
      config.height,
    )
    if sdl_win.is_null() {
      raise Sdl3AppError::CreateWindowFailed(@lib.sdl_GetError())
    }
    rhodonite_sdl_prepare_shown_window(sdl_win)
    let (surface_width, surface_height) = query_valid_sdl_window_size_in_pixels(
      sdl_win,
    ) catch {
      error => {
        @lib.sdl_DestroyWindow(sdl_win)
        raise error
      }
    }
    let webgpu_canvas_context = create_linux_canvas_context(
      session.instance,
      sdl_win,
      surface_width,
      surface_height,
    ) catch {
      error => {
        @lib.sdl_DestroyWindow(sdl_win)
        raise error
      }
    }
    (
      sdl_win,
      @wgpu_objects.null_opaque_ptr(),
      webgpu_canvas_context,
      surface_width,
      surface_height,
    )
  } else {
    raise Sdl3AppError::UnsupportedNativePlatform
  }
  let format = session.instance.get_preferred_canvas_format_for_surface(
    session.adapter,
    webgpu_canvas_context,
  )
  webgpu_canvas_context.configure(session.device, format)
  let render_format = webgpu_canvas_context.get_format()
  let gpu_surface = @wgpu.create_gpu_surface(
    webgpu_canvas_context, render_format, surface_width, surface_height,
  )
  session.surfaces.push({
    window_id: sdl_get_window_id(sdl_win),
    sdl_win,
    metal_view,
    webgpu_canvas_context,
    gpu_surface,
    engine_surface_id: None,
  })
}

///|
/// Runs a native render loop with an engine-independent frame callback.
pub fn run_sdl_metal_webgpu_render_loop(
  session : SdlMetalWebGpuNativeSession,
  render_frame : (Float) -> Unit,
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  let input = @input.InputState::new()
  run_sdl_metal_webgpu_input_render_loop(session, input, render_frame)
}

///|
/// Returns the monotonic SDL tick counter in milliseconds.
extern "C" fn sdl_get_ticks() -> UInt64 = "SDL_GetTicks"

///|
/// Returns an SDL scancode name without freeing SDL's borrowed static string.
extern "C" fn sdl_scancode_name_borrowed(
  scancode : @lib.SDL_Scancode,
) -> String = "rhodonite_sdl_get_scancode_name_borrowed"

///|
/// Returns an SDL key name without freeing SDL's borrowed static string.
extern "C" fn sdl_key_name_borrowed(key : @lib.SDL_Keycode) -> String = "rhodonite_sdl_get_key_name_borrowed"

///|
/// Returns a browser-style physical key code for mapped SDL scancodes.
extern "C" fn sdl_browser_key_code_from_scancode(
  scancode : @lib.SDL_Scancode,
) -> String = "rhodonite_sdl_browser_key_code_from_scancode"

///|
/// Converts an SDL keyboard event into the current input key code naming.
fn sdl_key_code_from_keyboard_event(
  event : @lib.SDL_KeyboardEvent,
) -> @input.KeyCode {
  let browser_code = sdl_browser_key_code_from_scancode(event.scancode)
  if browser_code != "" {
    @input.KeyCode::new(browser_code)
  } else {
    let scancode_name = sdl_scancode_name_borrowed(event.scancode)
    if scancode_name == "" {
      @input.KeyCode::new(sdl_key_name_borrowed(event.key))
    } else {
      @input.KeyCode::new(scancode_name)
    }
  }
}

///|
/// Converts SDL key modifier bits into the engine's normalized modifier state.
fn input_modifiers_from_sdl_keymod(mod : @lib.SDL_Keymod) -> @input.Modifiers {
  @input.Modifiers::new(mod.shift(), mod.ctrl(), mod.alt(), mod.meta())
}

///|
/// Queues one keyboard event from SDL into the engine input state.
fn enqueue_sdl_keyboard_event(
  input : @input.InputState,
  event : @lib.SDL_Event,
) -> Unit {
  let key_event : @lib.SDL_KeyboardEvent = @lib.unsafe_from_sdl_event(event)
  let key = sdl_key_code_from_keyboard_event(key_event)
  let modifiers = input_modifiers_from_sdl_keymod(key_event.mod)
  match event.get_type() {
    SDL_EVENT_KEY_DOWN =>
      input.enqueue_event(KeyDown(key, modifiers, key_event.repeat))
    SDL_EVENT_KEY_UP => input.enqueue_event(KeyUp(key, modifiers))
    _ => ()
  }
}

///|
/// Queues one mouse wheel event from SDL into the engine input state.
fn enqueue_sdl_mouse_wheel_event(
  input : @input.InputState,
  event : @lib.SDL_Event,
) -> Unit {
  let wheel_event : SdlMouseWheelEvent = @lib.unsafe_from_sdl_event(event)
  let direction_scale_x : Float = match wheel_event.direction {
    SDL_MOUSEWHEEL_NORMAL => (100.0 : Float)
    SDL_MOUSEWHEEL_FLIPPED => (-100.0 : Float)
  }
  let direction_scale_y : Float = match wheel_event.direction {
    SDL_MOUSEWHEEL_NORMAL => (-100.0 : Float)
    SDL_MOUSEWHEEL_FLIPPED => (100.0 : Float)
  }
  input.enqueue_event(
    Wheel(wheel_event.x * direction_scale_x, wheel_event.y * direction_scale_y),
  )
}

///|
/// Reports whether a native mouse button flag is present in the SDL state mask.
fn sdl_mouse_mask_has(flags : UInt, mask : UInt) -> Bool {
  (flags & mask) != 0U
}
