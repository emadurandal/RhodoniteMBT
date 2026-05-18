///|
/// Holds the browser platform for the page lifetime.
let browser_platform : @app_browser.PlatformSlot = @app_browser.PlatformSlot::new()

///|
/// Initializes the browser WebGPU sample and stores its engine lifecycle.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let platform = @app_browser.create_platform(
    canvas,
    fn(engine) {
      match @demo_state.create_demo_state_for_engine(engine) {
        Some(demo_state) => {
          @demo_state.register_engine_handlers(engine, demo_state)
          true
        }
        None => false
      }
    },
    @app_browser.PlatformOptions::loop_only(),
  )
  match platform {
    Some(platform) => {
      browser_platform.replace(platform)
      println("depth-test: DemoState ready")
    }
    None => println("depth-test: failed to create DemoState")
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
/// Implements `main {`.
fn main {
  println("depth-test js stub")
}
