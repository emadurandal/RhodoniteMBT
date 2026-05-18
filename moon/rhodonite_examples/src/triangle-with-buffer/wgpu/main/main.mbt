///| SDL3 window (`SDL_WINDOW_METAL`) + `SDL_Metal_*` `CAMetalLayer` → wgpu surface (vertex + index buffers).

///| Docs: [Kaida-Amethyst/sdl3@0.1.1](https://mooncakes.io/docs/Kaida-Amethyst/sdl3@0.1.1), [sdl3.mbt repo](https://github.com/moonbit-community/sdl3.mbt)

///|

///| **Build**: SDL3 development headers required (e.g. `brew install sdl3`). Prefer visible `pkg-config`. See mooncakes

///| `Kaida-Amethyst/sdl3/env.sh` (`pkg-config --cflags sdl3` in `CC_FLAGS`).

///|
async fn run_sdl_wgpu_triangle_with_buffer() -> Unit raise Error {
  @sdl_app.run_sdl_webgpu_app(
    "MoonBit wgpu + SDL3 (vertex + index buffer)",
    800,
    600,
    "native: initializing SDL3 (triangle-with-buffer demo)",
    fn(gpu_context) {
      let engine = @app.Engine::new(gpu_context)
      match @demo_state.create_demo_state_for_engine(engine) {
        Some(demo_state) => {
          @demo_state.register_engine_handlers(engine, demo_state)
          Some(engine)
        }
        None => None
      }
    },
  )
}

///|
async fn main {
  let _ = @async.now()
  run_sdl_wgpu_triangle_with_buffer() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
