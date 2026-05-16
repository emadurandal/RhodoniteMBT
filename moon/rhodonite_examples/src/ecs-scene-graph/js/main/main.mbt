///|
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
let demo_app : @ref.Ref[@app.App?] = @ref.new(None)

///|
async fn create_webgpu_renderer_async(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  let engine = @app.Engine::new(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      let app = @demo_state.create_app(demo_state)
      engine.initialize_app(app)
      demo_engine.val = Some(engine)
      demo_app.val = Some(app)
      println("ecs-scene-graph: DemoState ready")
    }
    None => println("ecs-scene-graph: failed to create DemoState")
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
/// Implements `ecs_scene_graph_render_tick`.
pub fn ecs_scene_graph_render_tick() -> Unit {
  match (demo_engine.val, demo_app.val) {
    (Some(engine), Some(app)) => engine.tick(app)
    _ => ()
  }
}

///|
/// Implements `main {`.
fn main {
  println("ecs-scene-graph js stub")
}
