///|
/// Holds the browser demo engine between the async setup and the page lifetime.
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
/// Holds the browser demo app between the async setup and the page lifetime.
let demo_app : @ref.Ref[@app.App?] = @ref.new(None)

///|
/// Initializes the browser WebGPU sample and renders the first engine tick.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  let engine = @app.Engine::new(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      let app = @demo_state.create_app(demo_state)
      engine.initialize_app(app)
      demo_engine.val = Some(engine)
      demo_app.val = Some(app)
      engine.tick(app)
      println("WebGPU triangle rendered successfully!")
    }
    None => println("Failed to create DemoState")
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
  println("Hello")
}
