///|
async fn create_webgpu_renderer_async(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  let ctx = @html_ctx.gpu_context_from_html_canvas(canvas)
  match @renderer.create_renderer(ctx) {
    Some(renderer) => {
      @renderer.render_frame(renderer)
      println("WebGPU triangle (vertex buffer) rendered successfully!")
    }
    None => println("Failed to create renderer")
  }
}

///|
pub fn create_webgpu_renderer(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_renderer_async(canvas))
}

///|
fn main {
  println("Hello")
}
