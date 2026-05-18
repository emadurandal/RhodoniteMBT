///| SDL3 + Metal + native wgpu; ECS scene graph sample.

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
async fn run_ecs_scene_graph_native() -> Unit raise Error {
  @sdl_app.run_platform(
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
