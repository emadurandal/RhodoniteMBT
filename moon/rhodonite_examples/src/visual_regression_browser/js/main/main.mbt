///|
let sample_width : UInt = 800U

///|
let sample_height : UInt = 600U

///|
async fn create_browser_webgpu_fixture() -> (
  @wgpu.GPUInstance,
  @wgpu.GPUDevice,
  @wgpu.GPUQueue,
) raise Error {
  let instance = @wgpu.create_webgpu_instance(@wgpu.navigatorGPU())
  let adapter = instance.request_adapter()
  let device = adapter.request_device()
  let queue = device.get_queue()
  (instance, device, queue)
}

///|
async fn render_browser_webgpu_sample(
  render : (@wgpu.GPUDevice, @wgpu.GPUQueue, String, @wgpu.GPUTextureView) -> Unit raise,
) -> Bytes raise Error {
  let (instance, device, queue) = create_browser_webgpu_fixture()
  let texture = device.create_rgba8_render_texture(sample_width, sample_height)
  let view = texture.create_view()
  let readback = device.create_buffer(
    @wgpu.rgba8_copy_padded_byte_length(sample_width, sample_height),
    @wgpu.GPU_BUFFER_USAGE_MAP_READ | @wgpu.GPU_BUFFER_USAGE_COPY_DST,
  )
  render(device, queue, "rgba8unorm", view)
  let encoder = device.create_command_encoder()
  encoder.copy_texture_to_buffer_rgba8(
    texture, readback, sample_width, sample_height,
  )
  queue.submit(encoder.finish())
  let width = sample_width.reinterpret_as_int()
  let height = sample_height.reinterpret_as_int()
  let padded_row = @wgpu.rgba8_copy_bytes_per_row(sample_width).to_int()
  let raw = readback.readback_async(
    0UL,
    @wgpu.rgba8_copy_padded_byte_length(sample_width, sample_height),
  )
  let data = Bytes::makei(width * height * 4, fn(i) {
    let pixel = i / 4
    let x = pixel % width
    let y = pixel / width
    let channel = i % 4
    raw[y * padded_row + x * 4 + channel]
  })
  readback.release()
  @wgpu.textureView_release(view)
  texture.release()
  queue.release()
  device.release()
  instance.release()
  data
}

///|
async fn render_basic_triangle_browser_snapshot_async() -> Bytes raise Error {
  render_browser_webgpu_sample(fn(device, queue, format, view) {
    let renderer = @basic_triangle.create_renderer_for_device(
      device, queue, format,
    )
    @basic_triangle.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
pub fn render_basic_triangle_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_basic_triangle_browser_snapshot_async()
  })
}

///|
async fn render_triangle_with_buffer_browser_snapshot_async() -> Bytes raise Error {
  render_browser_webgpu_sample(fn(device, queue, format, view) {
    let renderer = @triangle_with_buffer.create_renderer_for_device(
      device, queue, format,
    )
    @triangle_with_buffer.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
pub fn render_triangle_with_buffer_browser_snapshot() -> @js_async.Promise[
  Bytes,
] {
  @js_async.Promise::from_async(() => {
    render_triangle_with_buffer_browser_snapshot_async()
  })
}

///|
async fn render_depth_test_browser_snapshot_async() -> Bytes raise Error {
  render_browser_webgpu_sample(fn(device, queue, format, view) {
    let renderer = @depth_test.create_renderer_for_device(device, queue, format)
    @depth_test.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
pub fn render_depth_test_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => render_depth_test_browser_snapshot_async())
}

///|
async fn render_ecs_scene_graph_browser_snapshot_async() -> Bytes raise Error {
  render_browser_webgpu_sample(fn(device, queue, format, view) {
    let renderer = @ecs_scene_graph.create_renderer_for_device(
      device, queue, format,
    )
    @ecs_scene_graph.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
pub fn render_ecs_scene_graph_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_ecs_scene_graph_browser_snapshot_async()
  })
}

///|
async fn render_ecs_mass_cubes_browser_snapshot_async() -> Bytes raise Error {
  render_browser_webgpu_sample(fn(device, queue, format, view) {
    let renderer = @ecs_mass_cubes.create_renderer_for_device(
      device, queue, format,
    )
    @ecs_mass_cubes.render_frame_to_view(renderer, view, record_perf=false)
    renderer.release()
  })
}

///|
pub fn render_ecs_mass_cubes_browser_snapshot() -> @js_async.Promise[Bytes] {
  @js_async.Promise::from_async(() => {
    render_ecs_mass_cubes_browser_snapshot_async()
  })
}

///|
fn main {
  println("visual_regression_browser js main")
}
