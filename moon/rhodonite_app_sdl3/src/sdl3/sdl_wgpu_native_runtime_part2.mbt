/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

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
  let was_down = input.mouse_down_including_queued(button)
  if down && !was_down {
    input.enqueue_event(MouseDown(button, x, y))
  } else if !down && was_down {
    input.enqueue_event(MouseUp(button, x, y))
  }
}

///|
/// Maps an SDL mouse button index to the shared Rhodonite input button enum.
fn sdl_input_mouse_button(button : Byte) -> @input.MouseButton? {
  match button.to_int() {
    @lib.SDL_BUTTON_LEFT => Some(Left)
    @lib.SDL_BUTTON_MIDDLE => Some(Middle)
    @lib.SDL_BUTTON_RIGHT => Some(Right)
    @lib.SDL_BUTTON_X1 => Some(Back)
    @lib.SDL_BUTTON_X2 => Some(Forward)
    _ => None
  }
}

///|
/// Merges window-local SDL button flags with global hardware state only for
/// buttons already held in engine input. A full OR would treat desktop-wide
/// presses in other applications as local MouseDown after FocusLost cleared state.
fn merge_sdl_mouse_button_flags(
  input : @input.InputState,
  local_flags : UInt,
  global_flags : UInt,
) -> UInt {
  let mut flags = local_flags
  if input.mouse_down_including_queued(Left) &&
    !sdl_mouse_mask_has(local_flags, @lib.SDL_BUTTON_LMASK) &&
    sdl_mouse_mask_has(global_flags, @lib.SDL_BUTTON_LMASK) {
    flags = flags | @lib.SDL_BUTTON_LMASK
  }
  if input.mouse_down_including_queued(Middle) &&
    !sdl_mouse_mask_has(local_flags, @lib.SDL_BUTTON_MMASK) &&
    sdl_mouse_mask_has(global_flags, @lib.SDL_BUTTON_MMASK) {
    flags = flags | @lib.SDL_BUTTON_MMASK
  }
  if input.mouse_down_including_queued(Right) &&
    !sdl_mouse_mask_has(local_flags, @lib.SDL_BUTTON_RMASK) &&
    sdl_mouse_mask_has(global_flags, @lib.SDL_BUTTON_RMASK) {
    flags = flags | @lib.SDL_BUTTON_RMASK
  }
  if input.mouse_down_including_queued(Back) &&
    !sdl_mouse_mask_has(local_flags, @lib.SDL_BUTTON_X1MASK) &&
    sdl_mouse_mask_has(global_flags, @lib.SDL_BUTTON_X1MASK) {
    flags = flags | @lib.SDL_BUTTON_X1MASK
  }
  if input.mouse_down_including_queued(Forward) &&
    !sdl_mouse_mask_has(local_flags, @lib.SDL_BUTTON_X2MASK) &&
    sdl_mouse_mask_has(global_flags, @lib.SDL_BUTTON_X2MASK) {
    flags = flags | @lib.SDL_BUTTON_X2MASK
  }
  flags
}

///|
/// Syncs all normalized mouse buttons from an SDL button-state bitmask.
fn enqueue_sdl_mouse_buttons_from_flags(
  input : @input.InputState,
  flags : UInt,
  x : Float,
  y : Float,
) -> Unit {
  enqueue_sdl_mouse_button(input, flags, @lib.SDL_BUTTON_LMASK, Left, x, y)
  enqueue_sdl_mouse_button(input, flags, @lib.SDL_BUTTON_MMASK, Middle, x, y)
  enqueue_sdl_mouse_button(input, flags, @lib.SDL_BUTTON_RMASK, Right, x, y)
  enqueue_sdl_mouse_button(input, flags, @lib.SDL_BUTTON_X1MASK, Back, x, y)
  enqueue_sdl_mouse_button(input, flags, @lib.SDL_BUTTON_X2MASK, Forward, x, y)
}

///|
/// Queues pointer position and button transitions from an SDL mouse motion event.
fn enqueue_sdl_mouse_motion_event(
  input : @input.InputState,
  event : @lib.SDL_Event,
) -> Unit {
  let motion : SdlMouseMotionEvent = @lib.unsafe_from_sdl_event(event)
  input.enqueue_event(PointerMove(motion.x, motion.y))
  enqueue_sdl_mouse_buttons_from_flags(input, motion.state, motion.x, motion.y)
}

///|
/// Queues one mouse button transition from an SDL mouse button event.
fn enqueue_sdl_mouse_button_event(
  input : @input.InputState,
  event : @lib.SDL_Event,
) -> Unit {
  let button_event : SdlMouseButtonEvent = @lib.unsafe_from_sdl_event(event)
  match sdl_input_mouse_button(button_event.button) {
    Some(button) =>
      if button_event.down {
        if !input.mouse_down_including_queued(button) {
          input.enqueue_event(MouseDown(button, button_event.x, button_event.y))
        }
      } else if input.mouse_down_including_queued(button) {
        input.enqueue_event(MouseUp(button, button_event.x, button_event.y))
      }
    None => ()
  }
}

///|
/// Queues SDL mouse position and button state for the next engine frame.
fn enqueue_sdl_mouse_state(input : @input.InputState) -> Unit {
  let x = FixedArray::make(1, (0.0 : Float))
  let y = FixedArray::make(1, (0.0 : Float))
  let local_flags = @lib.sdl_GetMouseState(x, y)
  let global_x = FixedArray::make(1, (0.0 : Float))
  let global_y = FixedArray::make(1, (0.0 : Float))
  let global_flags = @lib.sdl_GetGlobalMouseState(global_x, global_y)
  let flags = merge_sdl_mouse_button_flags(input, local_flags, global_flags)
  input.enqueue_event(PointerMove(x[0], y[0]))
  enqueue_sdl_mouse_buttons_from_flags(input, flags, x[0], y[0])
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
        SDL_EVENT_MOUSE_MOTION =>
          if install_input {
            enqueue_sdl_mouse_motion_event(input, event)
          }
        SDL_EVENT_MOUSE_BUTTON_DOWN | SDL_EVENT_MOUSE_BUTTON_UP =>
          if install_input {
            enqueue_sdl_mouse_button_event(input, event)
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
    let _ = @wgpu.webgpu_device_poll(session.device, wait=false)
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
    SDL_EVENT_MOUSE_MOTION => {
      if install_input {
        enqueue_sdl_mouse_motion_event(input, event)
        request_render("input")
      }
      false
    }
    SDL_EVENT_MOUSE_BUTTON_DOWN | SDL_EVENT_MOUSE_BUTTON_UP => {
      if install_input {
        enqueue_sdl_mouse_button_event(input, event)
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
      let _ = @wgpu.webgpu_device_poll(session.device, wait=false)
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
    SDL_EVENT_MOUSE_MOTION => {
      if install_input {
        let window_id = sdl_event_window_id(event)
        session.focused_window_id = Some(window_id)
        match session.find_surface_index_by_window_id(window_id) {
          Some(index) =>
            match
              sdl_multi_window_engine_input_for_surface(session, engine, index) {
              Some(input) => {
                enqueue_sdl_mouse_motion_event(input, event)
                request_render("input")
              }
              None => ()
            }
          None => ()
        }
      }
      false
    }
    SDL_EVENT_MOUSE_BUTTON_DOWN | SDL_EVENT_MOUSE_BUTTON_UP => {
      if install_input {
        let window_id = sdl_event_window_id(event)
        session.focused_window_id = Some(window_id)
        match session.find_surface_index_by_window_id(window_id) {
          Some(index) =>
            match
              sdl_multi_window_engine_input_for_surface(session, engine, index) {
              Some(input) => {
                enqueue_sdl_mouse_button_event(input, event)
                request_render("input")
              }
              None => ()
            }
          None => ()
        }
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
      let _ = @wgpu.webgpu_device_poll(session.device, wait=false)
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
          let _ = @wgpu.webgpu_device_poll(session.device, wait=false)
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
