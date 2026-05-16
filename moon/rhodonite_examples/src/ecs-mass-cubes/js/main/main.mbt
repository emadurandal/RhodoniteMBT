///|
let demo_engine : @ref.Ref[@app.Engine?] = @ref.new(None)

///|
let demo_app : @ref.Ref[@app.App?] = @ref.new(None)

///|
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  let engine = @demo_state.create_engine(ctx)
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      let app = @demo_state.create_app(demo_state)
      engine.initialize_app(app)
      demo_engine.val = Some(engine)
      demo_app.val = Some(app)
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
/// Implements `ecs_mass_cubes_render_tick`.
pub fn ecs_mass_cubes_render_tick() -> Unit {
  match (demo_engine.val, demo_app.val) {
    (Some(engine), Some(app)) => engine.run_render_frame(app)
    _ => ()
  }
}

///|
/// Implements `main {`.
fn main {
  println("ecs-mass-cubes js main (use Vite entry)")
}
