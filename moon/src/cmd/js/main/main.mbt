///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run src/cmd/main` from the project root.
/// 
/// 
async fn create_webgpu_renderer_async(canvas : @lib.HTMLCanvasElement) -> Unit {
  let instance = @lib.create_webgpu_instance(@lib.navigatorGPU())
  let adapter = @lib.webgpu_instance_request_adapter(instance)
  let device = @lib.webgpu_adapter_request_device(adapter)
  let format = @lib.webgpu_instance_get_preferred_canvas_format(instance)
  let webgpu_canvas_context = @lib.create_canvas_context(
    @lib.canvas_getContext(canvas),
  )
  @lib.webgpu_canvas_context_configure(
    webgpu_canvas_context,
    @lib.webgpu_device_get(device),
    format,
  )
  let queue = @lib.webgpu_device_get_queue(device)
  let webgpu_context = @lib.create_webgpu_context(
    device, webgpu_canvas_context, format, queue,
  )
  match @lib.create_renderer(webgpu_context) {
    Some(renderer) => {
      @lib.render_frame(renderer)
      println("WebGPU triangle rendered successfully!")
    }
    None => println("Failed to create renderer")
  }
}

///|
pub fn create_webgpu_renderer(
  canvas : @lib.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_renderer_async(canvas))
}

///|
fn main {
  println("Hello")
}
