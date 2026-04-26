///| SDL3 ウィンドウ（`SDL_WINDOW_METAL`）＋ `SDL_Metal_*` の `CAMetalLayer` → wgpu サーフェス。

///| ドキュメント: [Kaida-Amethyst/sdl3@0.1.1](https://mooncakes.io/docs/Kaida-Amethyst/sdl3@0.1.1)、[sdl3.mbt リポジトリ](https://github.com/moonbit-community/sdl3.mbt)

///|

///| **ビルド**: SDL3 の開発ヘッダが必要（例: `brew install sdl3`）。`pkg-config` が見えるとよい。参考: mooncakes 内

///| `Kaida-Amethyst/sdl3/env.sh`（`CC_FLAGS` に `pkg-config --cflags sdl3`）。

///|
fn run_sdl_wgpu_triangle() -> Unit raise Error {
  let width = 800
  let height = 600
  let ctx = @sdl3.Context::new()
  let timer = ctx.getTimer()

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

  let metal_view = sdl_metal_create_view(sdl_win)
  if @c.opaque_ptr_is_null(metal_view) {
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_CreateView failed")
    return
  }

  let cametal = sdl_metal_get_layer(metal_view)
  if @c.opaque_ptr_is_null(cametal) {
    sdl_metal_destroy_view(metal_view)
    @lib.sdl_DestroyWindow(sdl_win)
    ctx.quit()
    println("SDL_Metal_GetLayer failed")
    return
  }

  let wgpu_inst = @wgpu.Instance::create()
  let surf_desc = @wgpu.surface_descriptor_metal_layer_new(cametal)
  let surface = wgpu_inst.create_surface(surf_desc)
  @wgpu.surface_descriptor_free(surf_desc)

  let adapter = wgpu_inst.request_adapter_sync_options_surface_u32(
    surface,
    feature_level_u32=@wgpu.FEATURE_LEVEL_CORE,
    backend_type_u32=@wgpu.BACKEND_TYPE_METAL,
  )
  let device = adapter.request_device_sync(wgpu_inst)
  let queue = device.queue()
  let usage = @wgpu.TextureUsage::from_u64(
    @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT | @wgpu.TEXTURE_USAGE_COPY_SRC,
  )
  let wu = width.reinterpret_as_uint()
  let hu = height.reinterpret_as_uint()
  let format = surface.configure_default(adapter, device, wu, hu, usage)

  // 画面全体を覆う大きな三角（NDC フルスクリーン）だと、塗りと同じに見える。
  // 中心付近の小さな三角にし、クリア色とのコントラストで形が分かるようにする。
  let wgsl : String =
    #|struct VSOut { @builtin(position) pos: vec4<f32> };
    #|
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) vid: u32) -> VSOut {
    #|  // 上・右下・左下の小さな正三角形（各辺がクリア色と隣接して見える）
    #|  var positions = array<vec2<f32>, 3>(
    #|    vec2<f32>( 0.0,  0.5),
    #|    vec2<f32>(-0.5, -0.5),
    #|    vec2<f32>( 0.5, -0.5),
    #|  );
    #|  var out: VSOut;
    #|  out.pos = vec4<f32>(positions[vid], 0.0, 1.0);
    #|  return out;
    #|}
    #|
    #|@fragment
    #|fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(0.0, 0.75, 1.0, 1.0);
    #|}
    #|
  let sm = device.create_shader_module_wgsl(wgsl)
  let pipeline = device.create_render_pipeline_color_format(sm, format)

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
    try {
      let frame = surface.get_current_frame_or_raise()
      let view = frame.texture.create_view()
      let encoder = device.create_command_encoder()
      let pass = encoder.begin_render_pass_color_clear(
        view, 0.12, 0.12, 0.16, 1.0,
      )
      pass.set_pipeline(pipeline)
      pass.draw(3U, 1U, 0U, 0U)
      pass.end()
      pass.release()
      let cmd = encoder.finish()
      queue.submit_one(cmd)
      let _ = device.poll(wait=true)
      cmd.release()
      encoder.release()
      view.release()
      frame.present_or_raise()
      frame.release()
    } catch {
      _ => ()
    }
    wgpu_inst.process_events()
    timer.delay(16)
  }
  surface.unconfigure()
  pipeline.release()
  sm.release()
  queue.release()
  device.release()
  adapter.release()
  surface.release()
  wgpu_inst.release()
  sdl_metal_destroy_view(metal_view)
  @lib.sdl_DestroyWindow(sdl_win)
  ctx.quit()
}

///|
fn main {
  run_sdl_wgpu_triangle() catch {
    _ =>
      println(
        "wgpu+SDL3 起動失敗: macOS+Metal か、SDL3/wgpu のリンク・ヘッダを確認してください。",
      )
  }
}
