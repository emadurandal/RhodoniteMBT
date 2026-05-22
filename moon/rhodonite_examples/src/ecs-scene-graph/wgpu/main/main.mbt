/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| SDL3 + Metal + native wgpu; ECS scene graph sample.

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  @demo_state.setup_engine(engine)
}

///|
async fn run_ecs_scene_graph_native() -> Unit raise Error {
  @sdl_app.run_single_window_platform(
    @sdl_app.PlatformConfig::new(
      "MoonBit wgpu + SDL3 (ecs-scene-graph)", 800, 600, "native: ecs-scene-graph",
    ),
    @sdl_app.PlatformApp::default_engine(setup_engine),
    @sdl_app.PlatformOptions::interactive(),
  )
}

///|
async fn main {
  let _ = @async.now()
  run_ecs_scene_graph_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
