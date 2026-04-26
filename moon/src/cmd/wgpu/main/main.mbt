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

  let instance = @w.WebGPUInstance::create()
  let webgpu_canvas_context = @w.WebGPUCanvasContext::newMetalLayer(
    instance, cametal, width, height,
  )
  let adapter = instance.requestAdapter()
  let device = adapter.requestDevice()
  let format = instance.getPreferredCanvasFormat()
  webgpu_canvas_context.configure(device.get(), format)
  let render_format = webgpu_canvas_context.getFormat()
  let queue = device.getQueue()
  let wgsl : String =
    #|struct VertexOutput {
    #|  @builtin(position) position: vec4<f32>,
    #|  @location(0) color: vec3<f32>,
    #|};
    #|
    #|@vertex
    #|fn vertexMain(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput {
    #|  var pos = array<vec2<f32>, 3>(
    #|    vec2<f32>(0.0, 0.5),
    #|    vec2<f32>(-0.5, -0.5),
    #|    vec2<f32>(0.5, -0.5),
    #|  );
    #|  var colors = array<vec3<f32>, 3>(
    #|    vec3<f32>(1.0, 0.0, 0.0),
    #|    vec3<f32>(0.0, 1.0, 0.0),
    #|    vec3<f32>(0.0, 0.0, 1.0),
    #|  );
    #|  var output: VertexOutput;
    #|  output.position = vec4<f32>(pos[vertexIndex], 0.0, 1.0);
    #|  output.color = colors[vertexIndex];
    #|  return output;
    #|}
    #|
    #|@fragment
    #|fn fragmentMain(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
    #|  return vec4<f32>(color, 1.0);
    #|}
    #|
  let shader = device.createShaderModule(wgsl)
  let pipeline = device.createRenderPipeline(
    @w.WebGPURenderPipelineDescriptor::new(
      vertex=shader,
      fragment=shader,
      topology="triangle-list",
      formats=[render_format],
    ),
  )

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
    let texture = webgpu_canvas_context.getCurrentTexture()
    let view = texture.createView()
    let encoder = device.createCommandEncoder()
    let render_pass = encoder.beginRenderPass(
      @w.WebGPURenderPassDescriptor::new(colorAttachments=[
        Some(
          @w.WebGPURenderPassColorAttachment::new(
            view~,
            clearValue=@w.WebGPUColor::new(0.0, 0.0, 0.2, 1.0),
            loadOp="clear",
            storeOp="store",
          ),
        ),
      ]),
    )
    render_pass.setPipeline(pipeline)
    render_pass.draw(3)
    render_pass.end()
    render_pass.release()
    let command_buffer = encoder.finish()
    queue.submit(command_buffer)
    encoder.release()
    @w.textureView_release(view)
    webgpu_canvas_context.present()
    let _ = device.poll(wait=true)
    instance.processEvents()
    timer.delay(16)
  }
  @w.renderPipeline_release(pipeline)
  @w.shaderModule_release(shader)
  webgpu_canvas_context.release()
  queue.release()
  device.release()
  adapter.release()
  instance.release()
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
