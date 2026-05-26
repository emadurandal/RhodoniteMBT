/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Creates DemoState and registers engine handlers.
fn setup_engine(engine : @app.Engine) -> Bool {
  @demo_state.setup_engine(engine)
}

///|
/// Creates the browser WebGPU demo state and starts browser platform helpers.
async fn create_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let platform = @app_browser.run_platform(
    @app_browser.PlatformConfig::new(canvas),
    @app_browser.PlatformApp::default_engine(setup_engine),
    @app_browser.PlatformOptions::interactive(),
  )
  match platform {
    Some(_) => println("ecs-scene-graph: DemoState ready")
    None => println("ecs-scene-graph: failed to create DemoState")
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
/// Creates the browser WebGPU Undo/Redo demo state and starts browser platform helpers.
async fn create_undo_redo_webgpu_demo_state_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> Unit {
  let platform = @app_browser.run_platform(
    @app_browser.PlatformConfig::new(canvas),
    @app_browser.PlatformApp::default_engine(
      @demo_state.setup_undo_redo_interactive_engine,
    ),
    @app_browser.PlatformOptions::interactive(),
  )
  match platform {
    Some(_) => println("ecs-scene-graph Undo/Redo: DemoState ready")
    None => println("ecs-scene-graph Undo/Redo: failed to create DemoState")
  }
}

///|
/// Implements `create_undo_redo_webgpu_demo_state`.
pub fn create_undo_redo_webgpu_demo_state(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Unit] {
  @js_async.Promise::from_async(() => {
    create_undo_redo_webgpu_demo_state_async(canvas)
  })
}

///|
/// Provides the package entry point for MoonBit JS builds.
fn main {
  println("ecs-scene-graph js stub")
}
