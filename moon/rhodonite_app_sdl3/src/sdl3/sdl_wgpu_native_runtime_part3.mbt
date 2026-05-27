/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Runs the SDL3 platform lifecycle after invoking an optional pre-loop hook.
fn run_platform_lifecycle(
  config : PlatformConfig,
  app : PlatformApp,
  options : PlatformOptions,
  before_frame_mode : (() -> Unit)?,
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
  match before_frame_mode {
    Some(callback) => callback()
    None => ()
  }
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
/// Runs the SDL3 platform lifecycle with application hooks.
pub async fn run_platform(
  config : PlatformConfig,
  app : PlatformApp,
  options : PlatformOptions,
) -> Unit raise Sdl3AppError {
  run_platform_lifecycle(config, app, options, None)
}

///|
/// Runs one SDL3 platform frame and returns the presented canvas as packed RGBA8 bytes.
pub fn run_single_frame_platform_capture_rgba8(
  config : PlatformConfig,
  app : PlatformApp,
) -> Bytes? raise Sdl3AppError {
  run_platform_lifecycle(
    config,
    app,
    PlatformOptions::single_frame(),
    Some(fn() { @wgpu_objects.native_canvas_present_capture_begin() }),
  )
  let bytes = @wgpu_objects.native_canvas_present_capture_take()
  if bytes.length() == 0 {
    None
  } else {
    Some(bytes)
  }
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
