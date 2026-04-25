///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run src/cmd/main` from the project root.
/// 
/// 
pub fn create_webgpu_renderer(
  device : @lib.GPUDevice,
  context : @lib.GPUCanvasContext,
  format : String,
) -> Unit {
  let webgpu_device = @lib.WebGPUDevice::new(device)
  let webgpu_queue = webgpu_device.getQueue()
  let webgpu_canvas_context = @lib.WebGPUCanvasContext::new(context)
  let webgpu_context = @lib.WebGPUContext::new(
    webgpu_device, webgpu_canvas_context, format, webgpu_queue,
  )

  // Create renderer
  match @lib.create_renderer(webgpu_context) {
    Some(renderer) => {
      // Render single frame
      @lib.render_frame(renderer)
      println("WebGPU triangle rendered successfully!")
    }
    None => println("Failed to create renderer")
  }
}

///|
fn main {
  println("Hello")
}
