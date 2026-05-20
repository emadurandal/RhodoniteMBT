/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| SDL3 window (`SDL_WINDOW_METAL`) + `SDL_Metal_*` `CAMetalLayer` -> wgpu surface.

///| Docs: [emadurandal/sdl3@0.1.2](https://mooncakes.io/docs/emadurandal/sdl3@0.1.2), [sdl3.mbt repo](https://github.com/moonbit-community/sdl3.mbt)

///|

///| **Build**: SDL3 development headers required (e.g. `brew install sdl3`). The `emadurandal/sdl3` binding carries SDL3 stub include flags.

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      @demo_state.register_engine_handlers(engine, demo_state)
      true
    }
    None => false
  }
}

///|
/// Runs the SDL3 sample with the library on-demand platform loop.
async fn run_sdl_wgpu_ondemand_triangle() -> Unit raise Error {
  @sdl_app.run_single_window_platform(
    "MoonBit wgpu + SDL3 (on-demand triangle)",
    800,
    600,
    @sdl_app.PlatformApp::default_engine(setup_engine),
    @sdl_app.PlatformOptions::interactive_on_demand(),
    init_log="native: initializing SDL3 (ondemand-triangle demo)",
  )
}

///|
/// Starts the native on-demand triangle sample.
async fn main {
  let _ = @async.now()
  run_sdl_wgpu_ondemand_triangle() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
