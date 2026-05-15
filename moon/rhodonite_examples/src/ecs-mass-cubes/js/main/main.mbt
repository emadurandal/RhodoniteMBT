///|
let demo_renderer : @ref.Ref[@renderer.WebGPURenderer?] = @ref.new(None)

///|
async fn create_webgpu_renderer_async(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  match @renderer.create_renderer(ctx) {
    Some(renderer) => {
      demo_renderer.val = Some(renderer)
      println("ecs-mass-cubes: renderer ready")
    }
    None => println("ecs-mass-cubes: failed to create renderer")
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
/// Implements `ecs_mass_cubes_render_tick`.
pub fn ecs_mass_cubes_render_tick() -> Unit {
  match demo_renderer.val {
    Some(renderer) => @renderer.render_frame(renderer)
    None => ()
  }
}

///|
/// Implements `main {`.
fn main {
  println("ecs-mass-cubes js main (use Vite entry)")
}
