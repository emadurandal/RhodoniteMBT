///| SDL3 + Metal + wgpu ネイティブ。毎フレーム `depth-test` レンダラを回す。

///|
async fn run_depth_test_native() -> Unit raise Error {
  match
    @sdl_wgpu.init_sdl_metal_webgpu_native(
      "MoonBit wgpu + SDL3 (depth-test)", 800, 600, "native: depth-test",
    ) {
    None => ()
    Some(session) => {
      let renderer = match @renderer.create_renderer(session.gpu_context) {
        Some(renderer) => renderer
        None => {
          @sdl_wgpu.release_native_demo_infrastructure(session)
          return
        }
      }
      let session = @sdl_wgpu.run_sdl_metal_webgpu_render_loop(session, fn() {
        @renderer.render_frame(renderer)
      })
      renderer.release()
      @sdl_wgpu.release_native_demo_infrastructure(session)
    }
  }
}

///|
async fn main {
  let _ = @async.now()
  run_depth_test_native() catch {
    _ =>
      println(
        "wgpu+SDL3 起動失敗: macOS+Metal か、SDL3/wgpu のリンク・ヘッダを確認してください。",
      )
  }
}
