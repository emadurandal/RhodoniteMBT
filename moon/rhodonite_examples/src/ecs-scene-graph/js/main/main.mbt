///|
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
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
      println("ecs-scene-graph: DemoState ready")
    }
    None => println("ecs-scene-graph: failed to create DemoState")
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
/// Implements `ecs_scene_graph_render_tick`.
pub fn ecs_scene_graph_render_tick() -> Unit {
  match demo_engine.val {
    Some(engine) => engine.run_render_frame()
    _ => ()
  }
}

///|
/// Implements `main {`.
fn main {
  println("ecs-scene-graph js stub")
}
