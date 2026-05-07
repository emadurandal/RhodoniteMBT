///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run src/basic-triangle/js/main` from the moon-examples module root.
/// 
/// 
async fn create_webgpu_renderer_async(canvas : @wgpu.HTMLCanvasElement) -> Unit {
  let instance = @wgpu.create_webgpu_instance(@wgpu.navigatorGPU())
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let format = instance.get_preferred_canvas_format()
  let webgpu_canvas_context = @wgpu.create_canvas_context(
    @wgpu.canvas_getContext(canvas),
  )
  webgpu_canvas_context.configure(device, format)
  let queue = device.get_queue()
  let webgpu_context = @wgpu.create_webgpu_context(
    device, webgpu_canvas_context, format, queue,
  )
  match @renderer.create_renderer(webgpu_context) {
    Some(renderer) => {
      @renderer.render_frame(renderer)
      println("WebGPU triangle rendered successfully!")
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
