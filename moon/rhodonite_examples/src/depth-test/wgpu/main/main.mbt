///| SDL3 + Metal + native wgpu; runs the `depth-test` DemoState each frame.

///|
async fn run_depth_test_native() -> Unit raise Error {
  match
    @sdl_wgpu.init_sdl_metal_webgpu_native(
      "MoonBit wgpu + SDL3 (depth-test)", 800, 600, "native: depth-test",
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
      @demo_state.register_engine_handlers(engine, demo_state)
      engine.initialize()
      let session = @sdl_wgpu.run_sdl_metal_webgpu_input_render_loop(
        session,
        engine.input(),
        fn() { engine.run_render_frame() },
      )
      engine.shutdown()
      @sdl_wgpu.release_native_demo_infrastructure(session)
    }
  }
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
