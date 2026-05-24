/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| SDL3 + native wgpu; custom component color sample.

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  @demo_state.setup_engine(engine)
}

///|
/// Runs the custom component color sample on the native SDL3 platform.
async fn run_ecs_custom_component_color_native() -> Unit raise Error {
  @sdl_app.run_platform(
    @sdl_app.PlatformConfig::new(
      "MoonBit wgpu + SDL3 (ecs-custom-component-color)", 800, 600, "native: ecs-custom-component-color",
    ),
    @sdl_app.PlatformApp::default_engine(setup_engine),
    @sdl_app.PlatformOptions::interactive(),
  )
}

///|
/// Provides the native package entry point.
async fn main {
  let _ = @async.now()
  run_ecs_custom_component_color_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
