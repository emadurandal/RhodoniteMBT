///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run src/cmd/main` from the project root.
/// 
/// 
async fn create_webgpu_renderer_async(canvas : @lib.HTMLCanvasElement) -> Unit {
  let instance = @lib.WebGPUInstance::new(@lib.navigatorGPU())
  let adapter = instance.requestAdapter()
  let device = adapter.requestDevice()
  let format = instance.getPreferredCanvasFormat()
  let webgpu_canvas_context = @lib.WebGPUCanvasContext::new(
    @lib.canvas_getContext(canvas),
  )
  webgpu_canvas_context.configure(device.get(), format)
  let queue = device.getQueue()
  let webgpu_context = @lib.WebGPUContext::new(
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
