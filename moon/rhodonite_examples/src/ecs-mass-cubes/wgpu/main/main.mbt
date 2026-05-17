///| SDL3 + Metal + native wgpu; ECS mass instancing sample.

///|
async fn run_ecs_mass_cubes_native() -> Unit raise Error {
  @sdl_app.run_sdl_metal_webgpu_app(
    "MoonBit wgpu + SDL3 (ecs-mass-cubes)",
    800,
    600,
    "native: ecs-mass-cubes",
    fn(gpu_context) {
      let engine = @demo_state.create_engine(gpu_context)
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
  run_ecs_mass_cubes_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check macOS+Metal, SDL3/wgpu link, and headers.",
      )
  }
}
