///| SDL3 + Metal + native wgpu; runs the `depth-test` renderer each frame.

///|
async fn run_depth_test_native() -> Unit raise Error {
  match
    @sdl_wgpu.init_sdl_metal_webgpu_native(
      "MoonBit wgpu + SDL3 (depth-test)", 800, 600, "native: depth-test",
    ) {
    None => ()
    Some(session) => {
      let engine = @app.Engine::new(session.gpu_context)
      let renderer = match @renderer.create_renderer_for_engine(engine) {
        Some(renderer) => renderer
        None => {
          @sdl_wgpu.release_native_demo_infrastructure(session)
          return
        }
      }
      let app = @renderer.create_app(renderer)
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
  run_depth_test_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check macOS+Metal, SDL3/wgpu link, and headers.",
      )
  }
}
