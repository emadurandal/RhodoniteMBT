///| ブラウザの `<canvas>` から `GPUContext` までを構築する。

///|
pub async fn gpu_context_from_html_canvas(
  canvas : @wgpu.HTMLCanvasElement,
) -> @wgpu.GPUContext raise Error {
  let instance = @wgpu.create_webgpu_instance(@wgpu.navigatorGPU())
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let webgpu_canvas_context = @wgpu.create_canvas_context(
    @wgpu.canvas_getContext(canvas),
  )
  let format = instance.get_preferred_canvas_format_for_surface(
    adapter, webgpu_canvas_context,
  )
  webgpu_canvas_context.configure(device, format)
  let queue = device.get_queue()
  @wgpu.create_webgpu_context(device, webgpu_canvas_context, format, queue)
}
