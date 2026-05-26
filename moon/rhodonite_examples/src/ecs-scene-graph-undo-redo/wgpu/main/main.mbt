/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| SDL3 + Metal + native wgpu; ECS scene graph Undo/Redo sample.

///|
/// Creates DemoState, applies the Undo/Redo edit, and registers render handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  @demo_state.setup_undo_redo_visual_engine(engine)
}

///|
/// Runs the native ECS scene graph Undo/Redo sample.
async fn run_ecs_scene_graph_undo_redo_native() -> Unit raise Error {
  @sdl_app.run_platform(
    @sdl_app.PlatformConfig::new(
      "MoonBit wgpu + SDL3 (ecs-scene-graph Undo/Redo)", 800, 600, "native: ecs-scene-graph Undo/Redo",
    ),
    @sdl_app.PlatformApp::default_engine(setup_engine),
    @sdl_app.PlatformOptions::interactive(),
  )
}

///|
/// Provides the native sample entry point.
async fn main {
  let _ = @async.now()
  run_ecs_scene_graph_undo_redo_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
