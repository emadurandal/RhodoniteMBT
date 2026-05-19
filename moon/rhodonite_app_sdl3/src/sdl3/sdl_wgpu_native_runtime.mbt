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
/// `down` uses `Byte` because MoonBit `Bool` is wider than C `bool` in FFI structs.
priv struct SdlMouseButtonEvent {
  event_type : @lib.SDL_EventType
  reserved : UInt
  timestamp : UInt64
  windowID : @lib.SDL_WindowID
  which : @lib.SDL_MouseID
  button : Byte
  down : Byte
  clicks : Byte
  padding : Byte
  x : Float
  y : Float
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
  priv input : @input.InputState
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
    button: (0 : Byte),
    down: (0 : Byte),
    clicks: (0 : Byte),
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
  println("native: requesting adapter and device")
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
  println("native: configuring surface")
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
pub async fn init_sdl_linux_webgpu_native(
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
pub async fn init_sdl_webgpu_native(
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
pub async fn init_sdl_metal_webgpu_native(
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
  println("native: creating SDL Metal window")
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
  println("native: creating SDL Metal view")
  let metal_view = sdl_metal_create_view(sdl_win)
  if @wgpu_objects.opaque_ptr_is_null(metal_view) {
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    raise Sdl3AppError::CreateMetalViewFailed(@lib.sdl_GetError())
  }
  println("native: retrieving CAMetalLayer")
  let cametal_ptr = sdl_metal_get_layer_ptr(metal_view)
  if @wgpu_objects.opaque_ptr_is_null(cametal_ptr) {
    sdl_metal_destroy_view(metal_view)
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    raise Sdl3AppError::GetMetalLayerFailed(@lib.sdl_GetError())
  }
  let cametal = sdl_metal_get_layer(metal_view)
  println("native: creating WebGPU instance and surface")
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
/// Returns the surface-local input state.
pub fn SdlMultiWindowSurface::input(
  self : SdlMultiWindowSurface,
) -> @input.InputState {
  self.input
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
      input: @input.InputState::new(),
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
    input: @input.InputState::new(),
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
/// Queues one keyboard event from SDL into the engine input state.
fn enqueue_sdl_keyboard_event(
  input : @input.InputState,
  event : @lib.SDL_Event,
) -> Unit {
  let key_event : @lib.SDL_KeyboardEvent = @lib.unsafe_from_sdl_event(event)
  let key = sdl_key_code_from_keyboard_event(key_event)
  match event.get_type() {
    SDL_EVENT_KEY_DOWN =>
      input.enqueue_event(
        KeyDown(key, @input.Modifiers::none(), key_event.repeat),
      )
    SDL_EVENT_KEY_UP =>
      input.enqueue_event(KeyUp(key, @input.Modifiers::none()))
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

///|
/// Queues a mouse button transition if the SDL state differs from engine input.
fn enqueue_sdl_mouse_button(
  input : @input.InputState,
  flags : UInt,
  mask : UInt,
  button : @input.MouseButton,
  x : Float,
  y : Float,
) -> Unit {
  let down = sdl_mouse_mask_has(flags, mask)
  let was_down = input.mouse_down(button)
  if down && !was_down {
    input.enqueue_event(MouseDown(button, x, y))
  } else if !down && was_down {
    input.enqueue_event(MouseUp(button, x, y))
  }
}

///|
/// Queues SDL mouse position and button state for the next engine frame.
fn enqueue_sdl_mouse_state(input : @input.InputState) -> Unit {
  let x = FixedArray::make(1, (0.0 : Float))
  let y = FixedArray::make(1, (0.0 : Float))
  let flags = @lib.sdl_GetMouseState(x, y)
  input.enqueue_event(PointerMove(x[0], y[0]))
  enqueue_sdl_mouse_button(
    input,
    flags,
    @lib.SDL_BUTTON_LMASK,
    Left,
    x[0],
    y[0],
  )
  enqueue_sdl_mouse_button(
    input,
    flags,
    @lib.SDL_BUTTON_MMASK,
    Middle,
    x[0],
    y[0],
  )
  enqueue_sdl_mouse_button(
    input,
    flags,
    @lib.SDL_BUTTON_RMASK,
    Right,
    x[0],
    y[0],
  )
  enqueue_sdl_mouse_button(
    input,
    flags,
    @lib.SDL_BUTTON_X1MASK,
    Back,
    x[0],
    y[0],
  )
  enqueue_sdl_mouse_button(
    input,
    flags,
    @lib.SDL_BUTTON_X2MASK,
    Forward,
    x[0],
    y[0],
  )
}

///|
/// Reports whether an SDL event means the native drawable size may have changed.
fn sdl_event_is_resize(event_type : @lib.SDL_EventType) -> Bool {
  match event_type {
    SDL_EVENT_WINDOW_RESIZED
    | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
    | SDL_EVENT_WINDOW_METAL_VIEW_RESIZED => true
    _ => false
  }
}

///|
/// Reconfigures the WebGPU surface if an SDL window resize changed the drawable size.
fn handle_sdl_window_resize_event(
  session : SdlMetalWebGpuNativeSession,
  event : @lib.SDL_Event,
) -> Bool raise Sdl3AppError {
  let event_type = event.get_type()
  if !sdl_event_is_resize(event_type) {
    return false
  }
  let window_event : SdlWindowEvent = @lib.unsafe_from_sdl_event(event)
  let (width, height) = match event_type {
    SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED =>
      (window_event.data1, window_event.data2)
    _ => query_sdl_window_size_in_pixels_raw(session.sdl_win)
  }
  if width <= 0 || height <= 0 {
    if !session.surface_active {
      return false
    }
    session.surface_active = false
    session.surface_width = 0
    session.surface_height = 0
    return true
  }
  if session.surface_active &&
    width == session.surface_width &&
    height == session.surface_height {
    return false
  }
  session.webgpu_canvas_context.resize(
    session.device,
    session.surface_format,
    width,
    height,
  )
  session.surface_active = true
  session.surface_width = width
  session.surface_height = height
  session.surface_format = session.webgpu_canvas_context.get_format()
  true
}

///|
/// Polls SDL3 input, advances the caller-provided input state, and runs frame callbacks.
pub fn run_sdl_metal_webgpu_input_render_loop(
  session : SdlMetalWebGpuNativeSession,
  input : @input.InputState,
  render_frame : (Float) -> Unit,
  install_input? : Bool = true,
  on_surface_change? : (SdlMetalWebGpuNativeSession) -> Unit = fn(_) { () },
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  println("native: entering render loop")
  let quit = @ref.new(false)
  let mut previous_ticks = sdl_get_ticks()
  while !quit.val {
    let event = @lib.new_sdl_event()
    while @lib.sdl_PollEvent(event) {
      let event_type = event.get_type()
      if event_type == SDL_EVENT_POLL_SENTINEL {
        break
      }
      match event_type {
        SDL_EVENT_QUIT | SDL_EVENT_WINDOW_CLOSE_REQUESTED => quit.val = true
        SDL_EVENT_WINDOW_FOCUS_LOST =>
          if install_input {
            input.enqueue_event(FocusLost)
          }
        SDL_EVENT_KEY_DOWN | SDL_EVENT_KEY_UP =>
          if install_input {
            enqueue_sdl_keyboard_event(input, event)
          }
        SDL_EVENT_MOUSE_WHEEL =>
          if install_input {
            enqueue_sdl_mouse_wheel_event(input, event)
          }
        SDL_EVENT_WINDOW_RESIZED
        | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
        | SDL_EVENT_WINDOW_METAL_VIEW_RESIZED =>
          if handle_sdl_window_resize_event(session, event) {
            on_surface_change(session)
          }
        _ => ()
      }
    }
    if install_input {
      enqueue_sdl_mouse_state(input)
    }
    let current_ticks = sdl_get_ticks()
    let delta_seconds = Float::from_double(
      (current_ticks - previous_ticks).to_double() / 1000.0,
    )
    previous_ticks = current_ticks
    @wgpu.webgpu_instance_process_events(session.instance)
    render_frame(delta_seconds)
    let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
    @wgpu.webgpu_instance_process_events(session.instance)
  }
  session
}

///|
/// Processes one SDL event and reports whether the platform should quit.
fn handle_sdl_platform_event_for_on_demand(
  session : SdlMetalWebGpuNativeSession,
  input : @input.InputState,
  event : @lib.SDL_Event,
  install_input : Bool,
  on_surface_change : (SdlMetalWebGpuNativeSession) -> Unit,
  request_render : (String) -> Unit,
) -> Bool raise Sdl3AppError {
  let event_type = event.get_type()
  match event_type {
    SDL_EVENT_QUIT | SDL_EVENT_WINDOW_CLOSE_REQUESTED => true
    SDL_EVENT_WINDOW_FOCUS_LOST => {
      if install_input {
        input.enqueue_event(FocusLost)
        request_render("input")
      }
      false
    }
    SDL_EVENT_KEY_DOWN | SDL_EVENT_KEY_UP => {
      if install_input {
        enqueue_sdl_keyboard_event(input, event)
        request_render("input")
      }
      false
    }
    SDL_EVENT_MOUSE_WHEEL => {
      if install_input {
        enqueue_sdl_mouse_wheel_event(input, event)
        request_render("input")
      }
      false
    }
    SDL_EVENT_MOUSE_MOTION
    | SDL_EVENT_MOUSE_BUTTON_DOWN
    | SDL_EVENT_MOUSE_BUTTON_UP => {
      if install_input {
        request_render("input")
      }
      false
    }
    SDL_EVENT_WINDOW_RESIZED
    | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
    | SDL_EVENT_WINDOW_METAL_VIEW_RESIZED => {
      if handle_sdl_window_resize_event(session, event) {
        on_surface_change(session)
        request_render("surface")
      }
      false
    }
    _ => false
  }
}

///|
/// Runs an SDL3 event loop that renders only while dirty or continuous rendering is active.
pub fn run_sdl_metal_webgpu_input_on_demand_render_loop(
  session : SdlMetalWebGpuNativeSession,
  input : @input.InputState,
  render_frame : (Float) -> Unit,
  request_render : (String) -> Unit,
  render_requested : () -> Bool,
  continuous_render_requested : () -> Bool,
  install_input? : Bool = true,
  on_surface_change? : (SdlMetalWebGpuNativeSession) -> Unit = fn(_) { () },
) -> SdlMetalWebGpuNativeSession raise Sdl3AppError {
  println("native: entering on-demand render loop")
  let quit = @ref.new(false)
  let mut previous_ticks = sdl_get_ticks()
  while !quit.val {
    let event = @lib.new_sdl_event()
    let resumed_from_idle = !render_requested() &&
      !continuous_render_requested()
    if resumed_from_idle {
      if @lib.sdl_WaitEventTimeout(event, 100) {
        if handle_sdl_platform_event_for_on_demand(
            session, input, event, install_input, on_surface_change, request_render,
          ) {
          quit.val = true
        }
      }
    }
    while @lib.sdl_PollEvent(event) {
      let event_type = event.get_type()
      if event_type == SDL_EVENT_POLL_SENTINEL {
        break
      }
      if handle_sdl_platform_event_for_on_demand(
          session, input, event, install_input, on_surface_change, request_render,
        ) {
        quit.val = true
      }
    }
    if render_requested() || continuous_render_requested() {
      if install_input {
        enqueue_sdl_mouse_state(input)
      }
      let current_ticks = sdl_get_ticks()
      let delta_seconds = if resumed_from_idle {
        (0.0 : Float)
      } else {
        Float::from_double(
          (current_ticks - previous_ticks).to_double() / 1000.0,
        )
      }
      previous_ticks = current_ticks
      @wgpu.webgpu_instance_process_events(session.instance)
      render_frame(delta_seconds)
      let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
      @wgpu.webgpu_instance_process_events(session.instance)
    }
  }
  session
}

///|
/// Extracts the SDL window id carried by a window-scoped event.
fn sdl_event_window_id(event : @lib.SDL_Event) -> @lib.SDL_WindowID {
  let scoped : SdlWindowScopedEvent = @lib.unsafe_from_sdl_event(event)
  scoped.windowID
}

///|
/// Snapshots SDL mouse button and position state for the focused native surface.
fn enqueue_sdl_multi_window_focused_mouse_state(
  session : SdlMultiWindowPlatformSession,
  engine : @app.Engine,
) -> Unit {
  match session.focused_surface_index() {
    Some(index) =>
      match sdl_multi_window_engine_input_for_surface(session, engine, index) {
        Some(input) => enqueue_sdl_mouse_state(input)
        None => ()
      }
    None => ()
  }
}

///|
/// Finds a multi-window surface index by SDL window id.
fn SdlMultiWindowPlatformSession::find_surface_index_by_window_id(
  self : SdlMultiWindowPlatformSession,
  window_id : @lib.SDL_WindowID,
) -> Int? {
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    if self.surfaces[i].window_id == window_id {
      return Some(i)
    }
  }
  None
}

///|
/// Returns the focused surface index or falls back to the first live surface.
fn SdlMultiWindowPlatformSession::focused_surface_index(
  self : SdlMultiWindowPlatformSession,
) -> Int? {
  match self.focused_window_id {
    Some(window_id) =>
      match self.find_surface_index_by_window_id(window_id) {
        Some(index) => Some(index)
        None => if self.surfaces.length() > 0 { Some(0) } else { None }
      }
    None => if self.surfaces.length() > 0 { Some(0) } else { None }
  }
}

///|
/// Returns the engine-owned input state for a native surface index.
fn sdl_multi_window_engine_input_for_surface(
  session : SdlMultiWindowPlatformSession,
  engine : @app.Engine,
  index : Int,
) -> @input.InputState? {
  match session.surfaces[index].engine_surface_id {
    Some(id) => Some(engine.surface_input(id))
    None => None
  }
}

///|
/// Removes and releases a native surface and unregisters it from the engine.
fn remove_sdl_multi_window_surface_at(
  session : SdlMultiWindowPlatformSession,
  engine : @app.Engine,
  index : Int,
) -> Unit {
  let surface = session.surfaces[index]
  match surface.engine_surface_id {
    Some(id) => engine.remove_surface(id)
    None => ()
  }
  ignore(session.surfaces.remove(index))
  release_sdl_multi_window_surface(surface)
  match session.focused_window_id {
    Some(window_id) =>
      if window_id == surface.window_id {
        session.focused_window_id = None
      }
    None => ()
  }
}

///|
/// Reconfigures the matching native surface after a window resize event.
fn handle_sdl_multi_window_resize_event(
  session : SdlMultiWindowPlatformSession,
  event : @lib.SDL_Event,
) -> Bool raise Sdl3AppError {
  let event_type = event.get_type()
  if !sdl_event_is_resize(event_type) {
    return false
  }
  let window_event : SdlWindowEvent = @lib.unsafe_from_sdl_event(event)
  match session.find_surface_index_by_window_id(window_event.windowID) {
    Some(index) => {
      let surface = session.surfaces[index]
      let (width, height) = match event_type {
        SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED =>
          (window_event.data1, window_event.data2)
        _ => query_sdl_window_size_in_pixels_raw(surface.sdl_win)
      }
      if width <= 0 || height <= 0 {
        surface.gpu_surface.suspend()
      } else {
        surface.gpu_surface.resize(session.device, width, height)
      }
    }
    None => false
  }
}

///|
/// Processes one SDL event for a native multi-window platform.
fn handle_sdl_multi_window_event(
  session : SdlMultiWindowPlatformSession,
  engine : @app.Engine,
  event : @lib.SDL_Event,
  install_input : Bool,
  request_render : (String) -> Unit,
) -> Bool raise Sdl3AppError {
  let event_type = event.get_type()
  match event_type {
    SDL_EVENT_QUIT => true
    SDL_EVENT_WINDOW_CLOSE_REQUESTED => {
      let window_id = sdl_event_window_id(event)
      match session.find_surface_index_by_window_id(window_id) {
        Some(index) =>
          remove_sdl_multi_window_surface_at(session, engine, index)
        None => ()
      }
      session.surfaces.length() == 0
    }
    SDL_EVENT_WINDOW_FOCUS_LOST => {
      let window_id = sdl_event_window_id(event)
      match session.find_surface_index_by_window_id(window_id) {
        Some(index) =>
          if install_input {
            match
              sdl_multi_window_engine_input_for_surface(session, engine, index) {
              Some(input) => {
                input.enqueue_event(FocusLost)
                request_render("input")
              }
              None => ()
            }
          }
        None => ()
      }
      false
    }
    SDL_EVENT_KEY_DOWN | SDL_EVENT_KEY_UP => {
      if install_input {
        let key_event : @lib.SDL_KeyboardEvent = @lib.unsafe_from_sdl_event(
          event,
        )
        session.focused_window_id = Some(key_event.windowID)
        let target_index = match
          session.find_surface_index_by_window_id(key_event.windowID) {
          Some(index) => Some(index)
          None => session.focused_surface_index()
        }
        match target_index {
          Some(index) =>
            match
              sdl_multi_window_engine_input_for_surface(session, engine, index) {
              Some(input) => {
                enqueue_sdl_keyboard_event(input, event)
                request_render("input")
              }
              None => ()
            }
          None => ()
        }
      }
      false
    }
    SDL_EVENT_MOUSE_WHEEL => {
      if install_input {
        let window_id = sdl_event_window_id(event)
        session.focused_window_id = Some(window_id)
        match session.find_surface_index_by_window_id(window_id) {
          Some(index) =>
            match
              sdl_multi_window_engine_input_for_surface(session, engine, index) {
              Some(input) => {
                enqueue_sdl_mouse_wheel_event(input, event)
                request_render("input")
              }
              None => ()
            }
          None => ()
        }
      }
      false
    }
    SDL_EVENT_MOUSE_MOTION
    | SDL_EVENT_MOUSE_BUTTON_DOWN
    | SDL_EVENT_MOUSE_BUTTON_UP => {
      if install_input {
        session.focused_window_id = Some(sdl_event_window_id(event))
        request_render("input")
      }
      false
    }
    SDL_EVENT_WINDOW_RESIZED
    | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
    | SDL_EVENT_WINDOW_METAL_VIEW_RESIZED => {
      if handle_sdl_multi_window_resize_event(session, event) {
        request_render("surface")
      }
      false
    }
    _ => false
  }
}

///|
/// Runs an SDL3 multi-window loop that renders only while dirty or continuous rendering is active.
fn run_sdl_multi_window_on_demand_platform_loop(
  session : SdlMultiWindowPlatformSession,
  engine : @app.Engine,
  options : PlatformOptions,
) -> Unit raise Sdl3AppError {
  println("native: entering multi-window on-demand render loop")
  let quit = @ref.new(false)
  let mut previous_ticks = sdl_get_ticks()
  while !quit.val {
    let event = @lib.new_sdl_event()
    let resumed_from_idle = !engine.render_requested() &&
      !engine.continuous_render_requested()
    if resumed_from_idle {
      if @lib.sdl_WaitEventTimeout(event, 100) {
        if handle_sdl_multi_window_event(
            session,
            engine,
            event,
            options.install_input,
            fn(reason) { engine.request_render(reason) },
          ) {
          quit.val = true
        }
      }
    }
    while @lib.sdl_PollEvent(event) {
      let event_type = event.get_type()
      if event_type == SDL_EVENT_POLL_SENTINEL {
        break
      }
      if handle_sdl_multi_window_event(
          session,
          engine,
          event,
          options.install_input,
          fn(reason) { engine.request_render(reason) },
        ) {
        quit.val = true
      }
    }
    if session.surfaces.length() == 0 {
      quit.val = true
    } else if engine.render_requested() || engine.continuous_render_requested() {
      if options.install_input {
        enqueue_sdl_multi_window_focused_mouse_state(session, engine)
      }
      let current_ticks = sdl_get_ticks()
      let delta_seconds = if resumed_from_idle {
        (0.0 : Float)
      } else {
        Float::from_double(
          (current_ticks - previous_ticks).to_double() / 1000.0,
        )
      }
      previous_ticks = current_ticks
      @wgpu.webgpu_instance_process_events(session.instance)
      ignore(engine.run_multi_surface_frame(delta_seconds))
      let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
      @wgpu.webgpu_instance_process_events(session.instance)
    }
  }
}

///|
/// Runs the SDL3 event loop for a platform with multiple native window surfaces.
fn run_sdl_multi_window_platform_loop(
  session : SdlMultiWindowPlatformSession,
  engine : @app.Engine,
  options : PlatformOptions,
) -> Unit raise Sdl3AppError {
  println("native: entering multi-window render loop")
  let quit = @ref.new(false)
  let mut previous_ticks = sdl_get_ticks()
  match options.frame_mode {
    SingleFrame => {
      @wgpu.webgpu_instance_process_events(session.instance)
      ignore(engine.run_multi_surface_frame((0.0 : Float)))
      let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
    }
    Loop =>
      while !quit.val {
        let event = @lib.new_sdl_event()
        while @lib.sdl_PollEvent(event) {
          let event_type = event.get_type()
          if event_type == SDL_EVENT_POLL_SENTINEL {
            break
          }
          if handle_sdl_multi_window_event(
              session,
              engine,
              event,
              options.install_input,
              fn(_) { () },
            ) {
            quit.val = true
          }
        }
        if session.surfaces.length() == 0 {
          quit.val = true
        } else {
          let current_ticks = sdl_get_ticks()
          let delta_seconds = Float::from_double(
            (current_ticks - previous_ticks).to_double() / 1000.0,
          )
          previous_ticks = current_ticks
          @wgpu.webgpu_instance_process_events(session.instance)
          if options.install_input {
            enqueue_sdl_multi_window_focused_mouse_state(session, engine)
          }
          ignore(engine.run_multi_surface_frame(delta_seconds))
          let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
          @wgpu.webgpu_instance_process_events(session.instance)
        }
      }
    OnDemand =>
      run_sdl_multi_window_on_demand_platform_loop(session, engine, options)
  }
}

///|
/// Configuration for the SDL3 platform lifecycle owner.
pub struct PlatformConfig {
  priv window_title : String
  priv width : Int
  priv height : Int
  priv init_log : String
}

///|
/// Application hooks used by the SDL3 platform to create and set up an engine.
pub struct PlatformApp {
  priv create_engine : (@wgpu.GPUContext) -> @app.Engine
  priv setup_engine : (@app.Engine) -> Bool
}

///|
/// SDL3 platform frame driving mode.
pub enum FrameMode {
  Loop
  SingleFrame
  OnDemand
}

///|
/// Options for running the SDL3 platform lifecycle owner.
pub struct PlatformOptions {
  priv frame_mode : FrameMode
  priv install_input : Bool
}

///|
/// Builds SDL3 platform configuration for a host WebGPU window.
pub fn PlatformConfig::new(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
) -> PlatformConfig {
  { window_title, width, height, init_log }
}

///|
/// Builds SDL3 platform application hooks.
pub fn PlatformApp::new(
  create_engine : (@wgpu.GPUContext) -> @app.Engine,
  setup_engine : (@app.Engine) -> Bool,
) -> PlatformApp {
  { create_engine, setup_engine }
}

///|
/// Builds SDL3 platform application hooks using the default engine constructor.
pub fn PlatformApp::default_engine(
  setup_engine : (@app.Engine) -> Bool,
) -> PlatformApp {
  PlatformApp::new(fn(context) { @app.Engine::new(context) }, setup_engine)
}

///|
/// Creates options for the standard interactive SDL3 platform.
pub fn PlatformOptions::interactive() -> PlatformOptions {
  { frame_mode: Loop, install_input: true }
}

///|
/// Creates options for a render-only SDL3 loop.
pub fn PlatformOptions::render_loop() -> PlatformOptions {
  { frame_mode: Loop, install_input: false }
}

///|
/// Creates options for an interactive on-demand SDL3 platform.
pub fn PlatformOptions::interactive_on_demand() -> PlatformOptions {
  { frame_mode: OnDemand, install_input: true }
}

///|
/// Creates options for a render-only on-demand SDL3 platform.
pub fn PlatformOptions::render_on_demand() -> PlatformOptions {
  { frame_mode: OnDemand, install_input: false }
}

///|
/// Creates options for a single-frame SDL3 platform run.
pub fn PlatformOptions::single_frame() -> PlatformOptions {
  { frame_mode: SingleFrame, install_input: false }
}

///|
/// Runs the SDL3 platform lifecycle with application hooks.
pub async fn run_platform(
  config : PlatformConfig,
  app : PlatformApp,
  options : PlatformOptions,
) -> Unit raise Sdl3AppError {
  let session = init_sdl_webgpu_native(
    config.window_title,
    config.width,
    config.height,
    config.init_log,
  )
  let engine = (app.create_engine)(session.gpu_context())
  if !(app.setup_engine)(engine) {
    release_sdl_metal_webgpu_native(session)
    return
  }
  if session.surface_active() {
    engine.set_surface_active(
      session.surface_width(),
      session.surface_height(),
      session.surface_format(),
    )
  } else {
    engine.set_surface_suspended()
  }
  engine.initialize()
  let session = match options.frame_mode {
    Loop => {
      let session = run_sdl_metal_webgpu_input_render_loop(
        session,
        engine.input(),
        fn(delta_seconds) { ignore(engine.run_frame(delta_seconds)) },
        install_input=options.install_input,
        on_surface_change=fn(session) {
          if session.surface_active() {
            engine.set_surface_active(
              session.surface_width(),
              session.surface_height(),
              session.surface_format(),
            )
          } else {
            engine.set_surface_suspended()
          }
        },
      ) catch {
        error => {
          engine.shutdown()
          release_sdl_metal_webgpu_native(session)
          raise error
        }
      }
      session
    }
    OnDemand => {
      let session = run_sdl_metal_webgpu_input_on_demand_render_loop(
        session,
        engine.input(),
        fn(delta_seconds) { ignore(engine.run_frame(delta_seconds)) },
        fn(reason) { engine.request_render(reason) },
        fn() { engine.render_requested() },
        fn() { engine.continuous_render_requested() },
        install_input=options.install_input,
        on_surface_change=fn(session) {
          if session.surface_active() {
            engine.set_surface_active(
              session.surface_width(),
              session.surface_height(),
              session.surface_format(),
            )
          } else {
            engine.set_surface_suspended()
          }
        },
      ) catch {
        error => {
          engine.shutdown()
          release_sdl_metal_webgpu_native(session)
          raise error
        }
      }
      session
    }
    SingleFrame => {
      @wgpu.webgpu_instance_process_events(session.instance)
      ignore(engine.run_frame((0.0 : Float)))
      let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
      session
    }
  }
  engine.shutdown()
  release_sdl_metal_webgpu_native(session)
}

///|
/// Runs one SDL3 platform with one shared WebGPU device and multiple native windows.
pub async fn run_multi_window_platform(
  configs : Array[PlatformConfig],
  app : PlatformApp,
  options : PlatformOptions,
) -> Unit raise Sdl3AppError {
  if configs.length() == 0 {
    return
  }
  let first = init_sdl_webgpu_native(
    configs[0].window_title,
    configs[0].width,
    configs[0].height,
    configs[0].init_log,
  )
  let session = init_sdl_multi_window_platform_from_first(first)
  for i = 1; i < configs.length(); i = i + 1 {
    attach_sdl_multi_window_surface(session, configs[i]) catch {
      error => {
        release_sdl_multi_window_platform(session)
        raise error
      }
    }
  }
  let engine = (app.create_engine)(session.gpu_context())
  if !(app.setup_engine)(engine) {
    release_sdl_multi_window_platform(session)
    return
  }
  for i = 0; i < session.surfaces.length(); i = i + 1 {
    let id = engine.add_surface(session.surfaces[i].gpu_surface())
    session.surfaces[i].engine_surface_id = Some(id)
  }
  engine.initialize()
  run_sdl_multi_window_platform_loop(session, engine, options) catch {
    error => {
      engine.shutdown()
      release_sdl_multi_window_platform(session)
      raise error
    }
  }
  engine.shutdown()
  release_sdl_multi_window_platform(session)
}

///|
/// Runs the simplified single-window SDL3 platform entry point.
pub async fn run_single_window_platform(
  config : PlatformConfig,
  app : PlatformApp,
  options : PlatformOptions,
) -> Unit raise Sdl3AppError {
  run_platform(config, app, options)
}
