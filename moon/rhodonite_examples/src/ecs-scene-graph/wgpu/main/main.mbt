///| SDL3 + Metal + native wgpu; ECS scene graph sample.

///|
async fn run_ecs_scene_graph_native() -> Unit raise Error {
  match
    @sdl_wgpu.init_sdl_metal_webgpu_native(
      "MoonBit wgpu + SDL3 (ecs-scene-graph)", 800, 600, "native: ecs-scene-graph",
    ) {
    None => ()
    Some(session) => {
      let engine = @app.Engine::new(session.gpu_context)
      let demo_state = match @demo_state.create_demo_state_for_engine(engine) {
        Some(demo_state) => demo_state
        None => {
          @sdl_wgpu.release_native_demo_infrastructure(session)
          return
        }
      }
      let app = @demo_state.create_app(demo_state)
      engine.initialize_app(app)
      let session = @sdl_wgpu.run_sdl_metal_webgpu_render_loop(session, fn() {
        engine.tick(app)
      })
      engine.shutdown_app(app)
      @sdl_wgpu.release_native_demo_infrastructure(session)
    }
  }
}

///|
async fn main {
  let _ = @async.now()
  run_ecs_scene_graph_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check macOS+Metal, SDL3/wgpu link, and headers.",
      )
  }
}
