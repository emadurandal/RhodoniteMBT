///|
/// Holds the browser frame loop for the page lifetime.
let browser_frame_loop : @ref.Ref[@app_browser.BrowserFrameLoop?] = @ref.new(
  None,
)

///|
/// Initializes the browser WebGPU sample and stores its engine lifecycle.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let ctx = @app_browser.gpu_context_from_html_canvas(canvas)
  let engine = @app.Engine::new(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      @demo_state.register_engine_handlers(engine, demo_state)
      engine.initialize()
      match browser_frame_loop.val {
        Some(frame_loop) => frame_loop.stop()
        None => ()
      }
      browser_frame_loop.val = Some(
        @app_browser.start_browser_engine_loop(engine),
      )
      println("depth-test: DemoState ready")
    }
    None => println("depth-test: failed to create DemoState")
  }
}

///|
/// Implements `create_webgpu_demo_state`.
pub fn create_webgpu_demo_state(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_demo_state_async(canvas))
}

///|
/// Implements `main {`.
fn main {
  println("depth-test js stub")
}
