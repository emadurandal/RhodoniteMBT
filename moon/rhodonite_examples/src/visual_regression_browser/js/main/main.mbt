/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
let sample_width : UInt = 800U

///|
let sample_height : UInt = 600U

///|
/// Creates an off-document canvas for browser visual regression.
extern "js" fn create_visual_regression_canvas(
  width : Int,
  height : Int,
) -> @wgpu.HTMLCanvasElement =
  #| (width, height) => {
  #|   const canvas = document.createElement("canvas");
  #|   canvas.width = width;
  #|   canvas.height = height;
  #|   return canvas;
  #| }

///|
/// Reads the presented WebGPU canvas pixels as top-left RGBA bytes.
extern "js" fn read_visual_regression_canvas_rgba8_async(
  canvas : @wgpu.HTMLCanvasElement,
) -> @js_async.Promise[Bytes] =
  #| async (canvas) => {
  #|   await new Promise((resolve) => requestAnimationFrame(() => resolve()));
  #|   await new Promise((resolve) => requestAnimationFrame(() => resolve()));
  #|   const bitmap = await createImageBitmap(canvas);
  #|   try {
  #|     const readback = document.createElement("canvas");
  #|     readback.width = canvas.width;
  #|     readback.height = canvas.height;
  #|     const ctx = readback.getContext("2d", { willReadFrequently: true });
  #|     ctx.drawImage(bitmap, 0, 0);
  #|     const image = ctx.getImageData(0, 0, canvas.width, canvas.height);
  #|     return new Uint8Array(image.data.buffer.slice(0));
  #|   } finally {
  #|     bitmap.close();
  #|   }
  #| }

///|
/// Implements `read_visual_regression_canvas_rgba8`.
async fn read_visual_regression_canvas_rgba8(
  canvas : @wgpu.HTMLCanvasElement,
) -> Bytes raise Error {
  @js_async.Promise::wait(read_visual_regression_canvas_rgba8_async(canvas))
}

///|
/// Runs a browser platform in single-frame mode and reads the canvas result.
async fn render_browser_platform_sample(
  app : @app_browser.PlatformApp,
) -> Bytes raise Error {
  let canvas = create_visual_regression_canvas(
    sample_width.reinterpret_as_int(),
    sample_height.reinterpret_as_int(),
  )
  let platform = @app_browser.run_platform(
    @app_browser.PlatformConfig::new(canvas),
    app,
    @app_browser.PlatformOptions::single_frame(),
  )
  let platform = match platform {
    Some(platform) => platform
    None => abort("browser visual regression failed to initialize platform")
  }
  let data = read_visual_regression_canvas_rgba8(canvas)
  platform.dispose()
  data
}

///|
async fn render_basic_triangle_browser_snapshot_async() -> Bytes raise Error {
  render_browser_platform_sample(
    @app_browser.PlatformApp::default_engine(@basic_triangle.setup_engine),
  )
}

///|
/// Implements `render_basic_triangle_browser_snapshot`.
pub fn render_basic_triangle_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_basic_triangle_browser_snapshot_async()
  })
}

///|
async fn render_ondemand_triangle_browser_snapshot_async() -> Bytes raise Error {
  render_browser_platform_sample(
    @app_browser.PlatformApp::default_engine(@ondemand_triangle.setup_engine),
  )
}

///|
/// Implements `render_ondemand_triangle_browser_snapshot`.
pub fn render_ondemand_triangle_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_ondemand_triangle_browser_snapshot_async()
  })
}

///|
async fn render_ecs_scene_graph_browser_snapshot_async() -> Bytes raise Error {
  render_browser_platform_sample(
    @app_browser.PlatformApp::default_engine(@ecs_scene_graph.setup_engine),
  )
}

///|
/// Renders the MoonBit ECS scene graph Undo/Redo browser sample.
async fn render_ecs_scene_graph_undo_redo_browser_snapshot_async() -> Bytes raise Error {
  render_browser_platform_sample(
    @app_browser.PlatformApp::default_engine(
      @ecs_scene_graph.setup_undo_redo_visual_engine,
    ),
  )
}

///|
/// Implements `render_ecs_scene_graph_browser_snapshot`.
pub fn render_ecs_scene_graph_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_ecs_scene_graph_browser_snapshot_async()
  })
}

///|
/// Implements `render_ecs_scene_graph_undo_redo_browser_snapshot`.
pub fn render_ecs_scene_graph_undo_redo_browser_snapshot() -> @js_async.Promise[
  Bytes,
] {
  @js_async.Promise::from_async(() => {
    render_ecs_scene_graph_undo_redo_browser_snapshot_async()
  })
}

///|
async fn render_ecs_custom_component_color_browser_snapshot_async() -> Bytes raise Error {
  render_browser_platform_sample(
    @app_browser.PlatformApp::default_engine(
      @ecs_custom_component_color.setup_engine,
    ),
  )
}

///|
/// Implements `render_ecs_custom_component_color_browser_snapshot`.
pub fn render_ecs_custom_component_color_browser_snapshot() -> @js_async.Promise[
  Bytes,
] {
  @js_async.Promise::from_async(() => {
    render_ecs_custom_component_color_browser_snapshot_async()
  })
}

///|
async fn render_ecs_mass_cubes_browser_snapshot_async() -> Bytes raise Error {
  render_browser_platform_sample(
    @app_browser.PlatformApp::new(
      @ecs_mass_cubes.create_engine, @ecs_mass_cubes.setup_engine,
    ),
  )
}

///|
/// Implements `render_ecs_mass_cubes_browser_snapshot`.
pub fn render_ecs_mass_cubes_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_ecs_mass_cubes_browser_snapshot_async()
  })
}

///|
/// Implements `main {`.
fn main {
  println("visual_regression_browser js main")
}
