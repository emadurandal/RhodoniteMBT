///| SDL3 + Metal + native wgpu; runs the `depth-test` DemoState each frame.

///|
async fn run_depth_test_native() -> Unit raise Error {
  @sdl_app.run_sdl_metal_webgpu_app(
    "MoonBit wgpu + SDL3 (depth-test)",
    800,
    600,
    "native: depth-test",
    fn(gpu_context) {
      let engine = @app.Engine::new(gpu_context)
      match @demo_state.create_demo_state_for_engine(engine) {
        Some(demo_state) => {
          @demo_state.register_engine_handlers(engine, demo_state)
          Some(engine)
        }
        None => None
      }
    },
  )
}

///|
async fn main {
  let _ = @async.now()
  run_depth_test_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check macOS+Metal, SDL3/wgpu link, and headers.",
      )
  }
}
