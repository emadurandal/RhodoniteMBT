///|
/// Holds the browser frame loop for the page lifetime.
let browser_frame_loop : @ref.Ref[@app_browser.BrowserFrameLoop?] = @ref.new(
  None,
)

///|
/// Holds the browser input binding for the page lifetime.
let browser_input_binding : @ref.Ref[@app_browser.BrowserInputBinding?] = @ref.new(
  None,
)

///|
/// Replaces any existing browser runtime handles.
fn replace_browser_runtime(
  frame_loop : @app_browser.BrowserFrameLoop,
  input : @app_browser.BrowserInputBinding,
) -> Unit {
  match browser_frame_loop.val {
    Some(existing) => existing.stop()
    None => ()
  }
  match browser_input_binding.val {
    Some(existing) => existing.dispose()
    None => ()
  }
  browser_frame_loop.val = Some(frame_loop)
  browser_input_binding.val = Some(input)
}

///|
/// Creates the browser WebGPU demo state and starts browser runtime helpers.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let ctx = @app_browser.gpu_context_from_html_canvas(canvas)
  let engine = @demo_state.create_engine(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      @demo_state.register_engine_handlers(engine, demo_state)
      engine.initialize()
      replace_browser_runtime(
        @app_browser.start_browser_engine_loop(engine),
        @app_browser.install_browser_input(engine, canvas),
      )
      println("ecs-mass-cubes: DemoState ready")
    }
    None => println("ecs-mass-cubes: failed to create DemoState")
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
/// Provides the package entry point for MoonBit JS builds.
fn main {
  println("ecs-mass-cubes js main (use Vite entry)")
}
