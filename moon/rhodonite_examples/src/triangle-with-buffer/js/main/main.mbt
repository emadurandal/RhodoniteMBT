///|
/// Holds the browser runtime for the page lifetime.
let browser_runtime : @app_browser.BrowserEngineRuntimeSlot = @app_browser.BrowserEngineRuntimeSlot::new()

///|
/// Initializes the browser WebGPU sample and renders the first engine tick.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let runtime = @app_browser.create_browser_engine_runtime(
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
    @app_browser.BrowserEngineRuntimeOptions::single_frame(),
  )
  match runtime {
    Some(runtime) => {
      browser_runtime.replace(runtime)
      println("WebGPU triangle (vertex + index buffer) rendered successfully!")
    }
    None => println("Failed to create DemoState")
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
  println("Hello")
}
