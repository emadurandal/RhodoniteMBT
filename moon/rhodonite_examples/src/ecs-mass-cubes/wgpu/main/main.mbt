///| SDL3 + Metal + native wgpu; ECS mass instancing sample.

///|
async fn run_ecs_mass_cubes_native() -> Unit raise Error {
  match
    @sdl_wgpu.init_sdl_metal_webgpu_native(
      "MoonBit wgpu + SDL3 (ecs-mass-cubes)", 800, 600, "native: ecs-mass-cubes",
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
  run_ecs_mass_cubes_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check macOS+Metal, SDL3/wgpu link, and headers.",
      )
  }
}
