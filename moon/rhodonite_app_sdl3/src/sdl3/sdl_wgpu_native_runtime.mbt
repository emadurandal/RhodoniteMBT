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
  ) catch {
    error => {
      webgpu_canvas_context.release()
      instance.release()
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise error
    }
  }
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
  )
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
  ) catch {
    error => {
      webgpu_canvas_context.release()
      instance.release()
      sdl_metal_destroy_view(metal_view)
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      raise error
    }
  }
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
        SDL_EVENT_WINDOW_FOCUS_LOST => input.enqueue_event(FocusLost)
        SDL_EVENT_KEY_DOWN | SDL_EVENT_KEY_UP =>
          enqueue_sdl_keyboard_event(input, event)
        SDL_EVENT_MOUSE_WHEEL => enqueue_sdl_mouse_wheel_event(input, event)
        SDL_EVENT_WINDOW_RESIZED
        | SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED
        | SDL_EVENT_WINDOW_METAL_VIEW_RESIZED =>
          if handle_sdl_window_resize_event(session, event) {
            on_surface_change(session)
          }
        _ => ()
      }
    }
    enqueue_sdl_mouse_state(input)
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
/// Runs the standard SDL3 native Rhodonite engine lifecycle for a host WebGPU window.
pub async fn run_sdl_webgpu_app(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
  setup : (@wgpu.GPUContext) -> @app.Engine?,
) -> Unit raise Sdl3AppError {
  let session = init_sdl_webgpu_native(window_title, width, height, init_log)
  let engine = match setup(session.gpu_context()) {
    Some(engine) => engine
    None => {
      release_sdl_metal_webgpu_native(session)
      return
    }
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
  let session = run_sdl_metal_webgpu_input_render_loop(
    session,
    engine.input(),
    fn(delta_seconds) { ignore(engine.run_frame(delta_seconds)) },
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
  engine.shutdown()
  release_sdl_metal_webgpu_native(session)
}

///|
/// Runs the SDL3 native Rhodonite lifecycle using the macOS Metal surface path.
pub async fn run_sdl_metal_webgpu_app(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
  setup : (@wgpu.GPUContext) -> @app.Engine?,
) -> Unit raise Sdl3AppError {
  run_sdl_webgpu_app(window_title, width, height, init_log, setup)
}
