///|
let demo_renderer : @ref.Ref[@renderer.WebGPURenderer?] = @ref.new(None)

///|
async fn create_webgpu_renderer_async(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  match @renderer.create_renderer(ctx) {
    Some(renderer) => {
      demo_renderer.val = Some(renderer)
      println("depth-test: renderer ready (use depth_test_render_tick in rAF)")
    }
    None => println("depth-test: failed to create renderer")
  }
}

///|
pub fn create_webgpu_renderer(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_renderer_async(canvas))
}

///|
pub fn depth_test_render_tick() -> Unit {
  match demo_renderer.val {
    Some(renderer) => @renderer.render_frame(renderer)
    None => ()
  }
}

///|
fn main {
  println("depth-test js stub")
}
