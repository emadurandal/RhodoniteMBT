///|
/// Holds the browser demo engine between the async setup and rAF ticks.
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
/// Initializes the browser WebGPU sample and stores its engine lifecycle.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  let engine = @app.Engine::new(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      @demo_state.register_engine_handlers(engine, demo_state)
      engine.initialize()
      demo_engine.val = Some(engine)
      println("depth-test: DemoState ready (use depth_test_render_tick in rAF)")
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
/// Implements `depth_test_render_tick`.
pub fn depth_test_render_tick(delta_seconds : Double) -> Unit {
  match demo_engine.val {
    Some(engine) => engine.run_render_frame(Float::from_double(delta_seconds))
    _ => ()
  }
}

///|
/// Implements `main {`.
fn main {
  println("depth-test js stub")
}
