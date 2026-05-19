///| SDL3 + native wgpu multi-surface independent-input sample.

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  let demo_state = @demo_state.create_demo_state_for_engine(engine)
  @demo_state.register_engine_handlers(engine, demo_state)
  true
}

///|
/// Runs the native sample through the SDL3 platform entry point.
async fn run_multi_surface_independent_input_native() -> Unit raise Error {
  @sdl_app.run_multi_window_platform(
    [
      @sdl_app.PlatformConfig::new(
        "MoonBit wgpu + SDL3 (multi-surface A)", 800, 600, "native: multi-surface-independent-input A",
      ),
      @sdl_app.PlatformConfig::new(
        "MoonBit wgpu + SDL3 (multi-surface B)", 800, 600, "native: multi-surface-independent-input B",
      ),
    ],
    @sdl_app.PlatformApp::default_engine(setup_engine),
    @sdl_app.PlatformOptions::interactive(),
  )
}

///|
/// Provides the native package entry point.
async fn main {
  let _ = @async.now()
  run_multi_surface_independent_input_native() catch {
    _ =>
      println(
        "wgpu+SDL3 failed to start: check SDL3/wgpu link, Vulkan (Linux), or Metal (macOS).",
      )
  }
}
