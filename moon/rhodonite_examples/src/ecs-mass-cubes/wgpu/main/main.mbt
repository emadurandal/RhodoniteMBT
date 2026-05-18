///| SDL3 + native wgpu (macOS Metal / Linux Vulkan); ECS mass instancing sample.

///|
/// Creates the platform-independent engine for the sample.
fn create_engine(gpu_context : @wgpu.GPUContext) -> @app.Engine {
  @demo_state.create_engine(gpu_context)
}

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  match @demo_state.create_demo_state_for_engine(engine) {
    Some(demo_state) => {
      @demo_state.register_engine_handlers(engine, demo_state)
      true
    }
    None => false
  }
}

///|
async fn run_ecs_mass_cubes_native() -> Unit raise Error {
  @sdl_app.run_platform(
    @sdl_app.PlatformConfig::new(
      "MoonBit wgpu + SDL3 (ecs-mass-cubes)",
      800,
      600,
      "native: ecs-mass-cubes",
    ),
    create_engine,
    setup_engine,
    @sdl_app.PlatformOptions::interactive(),
  )
}

///|
async fn main {
  let _ = @async.now()
  run_ecs_mass_cubes_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
