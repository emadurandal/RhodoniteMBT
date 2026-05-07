///| SDL3 ウィンドウ（`SDL_WINDOW_METAL`）＋ `SDL_Metal_*` の `CAMetalLayer` → wgpu サーフェス（頂点バッファ版）。

///| ドキュメント: [Kaida-Amethyst/sdl3@0.1.1](https://mooncakes.io/docs/Kaida-Amethyst/sdl3@0.1.1)、[sdl3.mbt リポジトリ](https://github.com/moonbit-community/sdl3.mbt)

///|

///| **ビルド**: SDL3 の開発ヘッダが必要（例: `brew install sdl3`）。`pkg-config` が見えるとよい。参考: mooncakes 内

///| `Kaida-Amethyst/sdl3/env.sh`（`CC_FLAGS` に `pkg-config --cflags sdl3`）。

///|
async fn run_sdl_wgpu_triangle_vertex_buffer() -> Unit raise Error {
  match
    @sdl_wgpu.init_sdl_metal_webgpu_native(
      "MoonBit wgpu + SDL3 (vertex buffer)", 800, 600, "native: initializing SDL3 (vertex buffer demo)",
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
  run_sdl_wgpu_triangle_vertex_buffer() catch {
    _ =>
      println(
        "wgpu+SDL3 起動失敗: macOS+Metal か、SDL3/wgpu のリンク・ヘッダを確認してください。",
      )
  }
}
