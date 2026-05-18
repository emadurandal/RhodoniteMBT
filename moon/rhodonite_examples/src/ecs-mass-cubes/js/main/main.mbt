///|
/// Holds the browser platform for the page lifetime.
let browser_platform : @app_browser.PlatformSlot = @app_browser.PlatformSlot::new()

///|
/// Creates the browser WebGPU demo state and starts browser platform helpers.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let platform = @app_browser.create_platform_with_engine(
    canvas,
    @demo_state.create_engine,
    fn(engine) {
      match @demo_state.create_demo_state_for_engine(engine) {
        Some(demo_state) => {
          @demo_state.register_engine_handlers(engine, demo_state)
          true
        }
        None => false
      }
    },
    @app_browser.PlatformOptions::interactive(),
  )
  match platform {
    Some(platform) => {
      browser_platform.replace(platform)
      println("ecs-mass-cubes: DemoState ready")
    }
    None => println("ecs-mass-cubes: failed to create DemoState")
  }
}

///|
/// Implements `create_webgpu_demo_state`.
pub fn create_webgpu_demo_state(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => create_webgpu_demo_state_async(canvas))
}

///|
/// Provides the package entry point for MoonBit JS builds.
fn main {
  println("ecs-mass-cubes js main (use Vite entry)")
}
