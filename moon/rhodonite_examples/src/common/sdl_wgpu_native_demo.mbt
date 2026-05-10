///| Shared SDL3 + Metal (`CAMetalLayer`) + native wgpu bootstrap and render loop.

///|
pub(all) struct SdlMetalWebGpuNativeSession {
  ctx : @sdl3.Context
  sdl_win : @lib.SDL_Window
  metal_view : @c.OpaquePtr
  instance : @wgpu.GPUInstance
  webgpu_canvas_context : @wgpu.GPUCanvasContext
  adapter : @wgpu.GPUAdapter
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
  gpu_context : @wgpu.GPUContext
}

///|
pub async fn init_sdl_metal_webgpu_native(
  window_title : String,
  width : Int,
  height : Int,
  init_log : String,
) -> SdlMetalWebGpuNativeSession? raise Error {
  println(init_log)
  let ctx = @sdl3.Context::new()
  println("native: creating SDL Metal window")
  let sdl_win = @lib.sdl_CreateWindow(
    window_title,
    width,
    height,
    @lib.SDL_WINDOW_METAL | @lib.SDL_WINDOW_RESIZABLE,
  )
  if sdl_win.is_null() {
    ctx.quit()
    println("SDL_CreateWindow failed (check SDL3 installation)")
    return None
  }
  let _ = @lib.sdl_ShowWindow(sdl_win)
  let _ = @lib.sdl_RaiseWindow(sdl_win)
  let _ = @lib.sdl_SyncWindow(sdl_win)
  println("native: creating SDL Metal view")
  let metal_view = sdl_metal_create_view(sdl_win)
  if @c.opaque_ptr_is_null(metal_view) {
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_CreateView failed")
    return None
  }
  println("native: retrieving CAMetalLayer")
  let cametal_ptr = sdl_metal_get_layer_ptr(metal_view)
  if @c.opaque_ptr_is_null(cametal_ptr) {
    sdl_metal_destroy_view(metal_view)
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_GetLayer failed")
    return None
  }
  let cametal = sdl_metal_get_layer(metal_view)
  println("native: creating WebGPU instance and surface")
  let instance = @wgpu.create_native_webgpu_instance()
  let webgpu_canvas_context = @wgpu.create_metal_canvas_context(
    instance, cametal, width, height,
  )
  println("native: requesting adapter and device")
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let format = instance.get_preferred_canvas_format_for_surface(
    adapter, webgpu_canvas_context,
  )
  println("native: configuring surface")
  webgpu_canvas_context.configure(device, format)
  let swap_format = @wgpu.webgpu_canvas_context_get_format(
    webgpu_canvas_context,
  )
  let queue = device.get_queue()
  let gpu_context = @wgpu.create_webgpu_context(
    device, webgpu_canvas_context, swap_format, queue,
  )
  Some({
    ctx,
    sdl_win,
    metal_view,
    instance,
    webgpu_canvas_context,
    adapter,
    device,
    queue,
    gpu_context,
  })
}

///|
pub fn release_native_demo_infrastructure(
  session : SdlMetalWebGpuNativeSession,
) -> Unit {
  session.webgpu_canvas_context.release()
  session.queue.release()
  session.device.release()
  session.adapter.release()
  session.instance.release()
  sdl_metal_destroy_view(session.metal_view)
  @lib.sdl_DestroyWindow(session.sdl_win)
  session.ctx.quit()
}

///|
pub fn run_sdl_metal_webgpu_render_loop(
  session : SdlMetalWebGpuNativeSession,
  render_frame : () -> Unit,
) -> SdlMetalWebGpuNativeSession {
  println("native: entering render loop")
  let timer = session.ctx.getTimer()
  let quit = @ref.new(false)
  while !quit.val {
    let events = session.ctx.getEvents()
    for i = 0; i < events.length(); i = i + 1 {
      let e = events[i]
      match e.getType() {
        Quit | WINDOW_CLOSE_REQUESTED => quit.val = true
        _ => ()
      }
    }
    render_frame()
    let _ = @wgpu.webgpu_device_poll(session.device, wait=true)
    @wgpu.webgpu_instance_process_events(session.instance)
    timer.delay(16)
  }
  session
}
