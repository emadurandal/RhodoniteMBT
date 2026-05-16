///| Shared SDL3 + Metal (`CAMetalLayer`) + native wgpu bootstrap and render loop.

///|
/// Defines `SdlMetalWebGpuNativeSession`.
pub(all) struct SdlMetalWebGpuNativeSession {
  ctx : @sdl3.Context
  sdl_win : @lib.SDL_Window
  metal_view : @c.OpaquePtr
  instance : @wgpu.GPUInstance
  webgpu_canvas_context : @wgpu.GPUCanvasContext
  adapter : @wgpu.GPUAdapter
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  gpu_context : @wgpu.GPUContext
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
pub async fn init_sdl_metal_webgpu_native(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
) -> SdlMetalWebGpuNativeSession? raise Error {
  println(init_log)
  let ctx = @sdl3.Context::new()
  println("native: creating SDL Metal window")
  let sdl_win = @lib.sdl_CreateWindow(
    window_title,
    width,
    height,
    @lib.SDL_WINDOW_METAL | @lib.SDL_WINDOW_RESIZABLE,
  )
  if sdl_win.is_null() {
    ctx.quit()
    println("SDL_CreateWindow failed (check SDL3 installation)")
    return None
  }
  let _ = @lib.sdl_ShowWindow(sdl_win)
  let _ = @lib.sdl_RaiseWindow(sdl_win)
  let _ = @lib.sdl_SyncWindow(sdl_win)
  println("native: creating SDL Metal view")
  let metal_view = sdl_metal_create_view(sdl_win)
  if @c.opaque_ptr_is_null(metal_view) {
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_CreateView failed")
    return None
  }
  println("native: retrieving CAMetalLayer")
  let cametal_ptr = sdl_metal_get_layer_ptr(metal_view)
  if @c.opaque_ptr_is_null(cametal_ptr) {
    sdl_metal_destroy_view(metal_view)
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_GetLayer failed")
    return None
  }
  let cametal = sdl_metal_get_layer(metal_view)
  println("native: creating WebGPU instance and surface")
  let instance = @wgpu.create_native_webgpu_instance()
  let webgpu_canvas_context = @wgpu.create_metal_canvas_context(
    instance, cametal, width, height,
  )
  println("native: requesting adapter and device")
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let format = instance.get_preferred_canvas_format_for_surface(
    adapter, webgpu_canvas_context,
  )
  println("native: configuring surface")
  webgpu_canvas_context.configure(device, format)
  let swap_format = @wgpu.webgpu_canvas_context_get_format(
    webgpu_canvas_context,
  )
  let queue = device.get_queue()
  let gpu_context = @wgpu.create_webgpu_context(
    device, webgpu_canvas_context, swap_format, queue,
  )
  Some({
    ctx,
    sdl_win,
    metal_view,
    instance,
    webgpu_canvas_context,
    adapter,
    device,
    queue,
    gpu_context,
  })
}

///|
/// Implements `release_native_demo_infrastructure`.
pub fn release_native_demo_infrastructure(
  session : SdlMetalWebGpuNativeSession,
) -> Unit {
  session.webgpu_canvas_context.release()
  session.queue.release()
  session.device.release()
  session.adapter.release()
  session.instance.release()
  sdl_metal_destroy_view(session.metal_view)
  @lib.sdl_DestroyWindow(session.sdl_win)
  session.ctx.quit()
}

///|
/// Implements `run_sdl_metal_webgpu_render_loop`.
pub fn run_sdl_metal_webgpu_render_loop(
  session : SdlMetalWebGpuNativeSession,
  render_frame : () -> Unit,
) -> SdlMetalWebGpuNativeSession {
  let input = @input.InputState::new()
  run_sdl_metal_webgpu_input_render_loop(session, input, render_frame)
}

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
  let direction_scale : Float = match wheel_event.direction {
    SDL_MOUSEWHEEL_NORMAL => (-100.0 : Float)
    SDL_MOUSEWHEEL_FLIPPED => (100.0 : Float)
  }
  input.enqueue_event(
    Wheel(wheel_event.x * direction_scale, wheel_event.y * direction_scale),
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
/// Implements `run_sdl_metal_webgpu_input_render_loop`.
pub fn run_sdl_metal_webgpu_input_render_loop(
  session : SdlMetalWebGpuNativeSession,
  input : @input.InputState,
  render_frame : () -> Unit,
) -> SdlMetalWebGpuNativeSession {
  println("native: entering render loop")
  let timer = session.ctx.getTimer()
  let quit = @ref.new(false)
  while !quit.val {
    let event = @lib.new_sdl_event()
    while @lib.sdl_PollEvent(event) {
      match event.get_type() {
        SDL_EVENT_QUIT | SDL_EVENT_WINDOW_CLOSE_REQUESTED => quit.val = true
        SDL_EVENT_WINDOW_FOCUS_LOST => input.enqueue_event(FocusLost)
        SDL_EVENT_KEY_DOWN | SDL_EVENT_KEY_UP =>
          enqueue_sdl_keyboard_event(input, event)
        SDL_EVENT_MOUSE_WHEEL => enqueue_sdl_mouse_wheel_event(input, event)
        _ => ()
      }
    }
    enqueue_sdl_mouse_state(input)
    render_frame()
    let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
    @wgpu.webgpu_instance_process_events(session.instance)
    timer.delay(16)
  }
  session
}
