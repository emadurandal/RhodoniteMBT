///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  let demo_state = @demo_state.create_demo_state_for_engine(engine)
  @demo_state.register_engine_handlers(engine, demo_state)
  true
}

///|
/// Starts a single browser platform with two canvas surfaces.
async fn create_webgpu_demo_state_async(
  first_canvas : @wgpu.HTMLCanvasElement,
  second_canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let platform = @app_browser.run_multi_surface_platform(
    first_canvas,
    @app_browser.PlatformApp::default_engine(setup_engine),
    @app_browser.PlatformOptions::interactive(),
  )
  match platform {
    Some(platform) => {
      ignore(platform.attach_canvas(second_canvas))
      println("multi-surface-independent-input: DemoState ready")
    }
    None =>
      println("multi-surface-independent-input: failed to create DemoState")
  }
}

///|
/// Implements `create_webgpu_demo_state`.
pub fn create_webgpu_demo_state(
  first_canvas : @wgpu.HTMLCanvasElement,
  second_canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => {
    create_webgpu_demo_state_async(first_canvas, second_canvas)
  })
}

///|
/// Provides the package entry point for MoonBit JS builds.
fn main {
  println("multi-surface-independent-input js stub")
}
