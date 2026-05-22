/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| SDL3 window (`SDL_WINDOW_METAL`) + `SDL_Metal_*` `CAMetalLayer` → wgpu surface.

///| Docs: [emadurandal/sdl3@0.1.2](https://mooncakes.io/docs/emadurandal/sdl3@0.1.2), [sdl3.mbt repo](https://github.com/moonbit-community/sdl3.mbt)

///|

///| **Build**: SDL3 development headers required (e.g. `brew install sdl3`). The `emadurandal/sdl3` binding carries SDL3 stub include flags.

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  @demo_state.setup_engine(engine)
}

///|
async fn run_sdl_wgpu_triangle() -> Unit raise Error {
  @sdl_app.run_single_window_platform(
    @sdl_app.PlatformConfig::new(
      "MoonBit wgpu + SDL3", 800, 600, "native: initializing SDL3",
    ),
    @sdl_app.PlatformApp::default_engine(setup_engine),
    @sdl_app.PlatformOptions::interactive(),
  )
}

///|
async fn main {
  let _ = @async.now()
  run_sdl_wgpu_triangle() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
