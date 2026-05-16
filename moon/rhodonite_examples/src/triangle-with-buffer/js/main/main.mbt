///|
/// Holds the browser demo engine between the async setup and the page lifetime.
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
/// Holds the browser demo app between the async setup and the page lifetime.
let demo_app : @ref.Ref[@app.App?] = @ref.new(None)

///|
/// Initializes the browser WebGPU sample and renders the first engine tick.
async fn create_webgpu_renderer_async(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  let engine = @app.Engine::new(ctx)
  match @renderer.create_demo_state_for_engine(engine) {
    Some(renderer) => {
      let app = @renderer.create_app(renderer)
      engine.initialize_app(app)
      demo_engine.val = Some(engine)
      demo_app.val = Some(app)
      engine.tick(app)
      println("WebGPU triangle (vertex + index buffer) rendered successfully!")
    }
    None => println("Failed to create renderer")
  }
}

///|
/// Implements `create_webgpu_renderer`.
pub fn create_webgpu_renderer(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_renderer_async(canvas))
}

///|
/// Implements `main {`.
fn main {
  println("Hello")
}
