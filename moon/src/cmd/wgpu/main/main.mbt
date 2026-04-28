///| SDL3 ウィンドウ（`SDL_WINDOW_METAL`）＋ `SDL_Metal_*` の `CAMetalLayer` → wgpu サーフェス。

///| ドキュメント: [Kaida-Amethyst/sdl3@0.1.1](https://mooncakes.io/docs/Kaida-Amethyst/sdl3@0.1.1)、[sdl3.mbt リポジトリ](https://github.com/moonbit-community/sdl3.mbt)

///|

///| **ビルド**: SDL3 の開発ヘッダが必要（例: `brew install sdl3`）。`pkg-config` が見えるとよい。参考: mooncakes 内

///| `Kaida-Amethyst/sdl3/env.sh`（`CC_FLAGS` に `pkg-config --cflags sdl3`）。

///|
async fn run_sdl_wgpu_triangle() -> Unit raise Error {
  let width = 800
  let height = 600
  println("native: initializing SDL3")
  let ctx = @sdl3.Context::new()
  let timer = ctx.getTimer()

  println("native: creating SDL Metal window")
  let sdl_win = @lib.sdl_CreateWindow(
    "MoonBit wgpu + SDL3",
    width,
    height,
    @lib.SDL_WINDOW_METAL | @lib.SDL_WINDOW_RESIZABLE,
  )
  if sdl_win.is_null() {
    ctx.quit()
    println("SDL_CreateWindow failed (SDL3 が入っているか確認)")
    return
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
    return
  }

  println("native: retrieving CAMetalLayer")
  let cametal_ptr = sdl_metal_get_layer_ptr(metal_view)
  if @c.opaque_ptr_is_null(cametal_ptr) {
    sdl_metal_destroy_view(metal_view)
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_GetLayer failed")
    return
  }
  let cametal = sdl_metal_get_layer(metal_view)
  println("native: creating WebGPU instance and surface")
  let instance = @w.create_native_webgpu_instance()
  let webgpu_canvas_context = @w.create_metal_canvas_context(
    instance, cametal, width, height,
  )
  println("native: requesting adapter and device")
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let format = instance.get_preferred_canvas_format()
  println("native: configuring surface")
  @w.webgpu_canvas_context_configure(
    webgpu_canvas_context,
    @w.webgpu_device_get(device),
    format,
  )
  let render_format = @w.webgpu_canvas_context_get_format(webgpu_canvas_context)
  let queue = device.get_queue()
  let webgpu_context = @w.create_webgpu_context(
    device, webgpu_canvas_context, render_format, queue,
  )
  println("native: creating renderer")
  let renderer = match @renderer.create_renderer(webgpu_context) {
    Some(renderer) => renderer
    None => {
      @w.webgpu_canvas_context_release(webgpu_canvas_context)
      @w.webgpu_queue_release(queue)
      @w.webgpu_device_release(device)
      @w.webgpu_adapter_release(adapter)
      @w.webgpu_instance_release(instance)
      sdl_metal_destroy_view(metal_view)
      @lib.sdl_DestroyWindow(sdl_win)
      ctx.quit()
      return
    }
  }

  println("native: entering render loop")
  let quit = @ref.new(false)
  while !quit.val {
    let events = ctx.getEvents()
    for i = 0; i < events.length(); i = i + 1 {
      let e = events[i]
      match e.getType() {
        Quit | WINDOW_CLOSE_REQUESTED => quit.val = true
        _ => ()
      }
    }
    @renderer.render_frame(renderer)
    let _ = @w.webgpu_device_poll(device, wait=true)
    @w.webgpu_instance_process_events(instance)
    timer.delay(16)
  }
  @renderer.webgpu_renderer_release(renderer)
  @w.webgpu_canvas_context_release(webgpu_canvas_context)
  @w.webgpu_queue_release(queue)
  @w.webgpu_device_release(device)
  @w.webgpu_adapter_release(adapter)
  @w.webgpu_instance_release(instance)
  sdl_metal_destroy_view(metal_view)
  @lib.sdl_DestroyWindow(sdl_win)
  ctx.quit()
}

///|
async fn main {
  let _ = @async.now()
  run_sdl_wgpu_triangle() catch {
    _ =>
      println(
        "wgpu+SDL3 起動失敗: macOS+Metal か、SDL3/wgpu のリンク・ヘッダを確認してください。",
      )
  }
}
