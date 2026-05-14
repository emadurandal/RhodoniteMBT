///|
let sample_width : UInt = 800U

///|
let sample_height : UInt = 600U

///|
struct NativeWebGpuFixture {
  instance : @wgpu.GPUInstance
  adapter : @wgpu.GPUAdapter
  device : @wgpu.GPUDevice
  queue : @wgpu.GPUQueue
}

///|
fn create_native_webgpu_fixture() -> NativeWebGpuFixture raise Error {
  let instance = @wgpu.create_native_webgpu_instance()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync()
  let queue = device.get_queue()
  { instance, adapter, device, queue }
}

///|
fn try_create_native_webgpu_fixture() -> NativeWebGpuFixture? {
  Some(create_native_webgpu_fixture()) catch {
    _ => {
      println("visual_regression: native WebGPU adapter unavailable; skipping")
      None
    }
  }
}

///|
fn NativeWebGpuFixture::release(self : NativeWebGpuFixture) -> Unit {
  self.queue.release()
  self.device.release()
  self.adapter.release()
  self.instance.release()
}

///|
fn render_webgpu_sample(
  render : (@wgpu.GPUDevice, @wgpu.GPUQueue, String, @wgpu.GPUTextureView) -> Unit raise,
) -> RgbaImage? raise {
  let fixture = match try_create_native_webgpu_fixture() {
    Some(fixture) => fixture
    None => return None
  }
  let texture = fixture.device.create_rgba8_render_texture(
    sample_width, sample_height,
  )
  let view = texture.create_view()
  let readback = fixture.device.create_buffer(
    @wgpu.rgba8_copy_padded_byte_length(sample_width, sample_height),
    @wgpu.GPU_BUFFER_USAGE_MAP_READ | @wgpu.GPU_BUFFER_USAGE_COPY_DST,
  )
  render(fixture.device, fixture.queue, "rgba8unorm", view)
  let encoder = fixture.device.create_command_encoder()
  encoder.copy_texture_to_buffer_rgba8(
    texture, readback, sample_width, sample_height,
  )
  fixture.queue.submit(encoder.finish())
  ignore(fixture.device.poll(wait=true))
  let width = sample_width.reinterpret_as_int()
  let height = sample_height.reinterpret_as_int()
  let padded_row = @wgpu.rgba8_copy_bytes_per_row(sample_width).to_int()
  let raw = readback.readback(
    fixture.instance,
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
  fixture.release()
  Some({ width, height, data })
}

///|
fn assert_webgpu_sample(
  filename : String,
  render : (@wgpu.GPUDevice, @wgpu.GPUQueue, String, @wgpu.GPUTextureView) -> Unit raise,
) -> Unit raise {
  match render_webgpu_sample(render) {
    Some(image) =>
      match_or_update_rgba_png_snapshot_perceptual(
        image,
        filename~,
        max_mismatch_rate=0.0005,
        perceptual_threshold=0.1,
      )
    None => ()
  }
}

///|
test "visual WebGPU sample basic triangle PNG golden" {
  assert_webgpu_sample("basic_triangle_sample.png", fn(
    device,
    queue,
    format,
    view,
  ) {
    let renderer = @basic_triangle.create_renderer_for_device(
      device, queue, format,
    )
    @basic_triangle.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
test "visual WebGPU sample triangle with buffer PNG golden" {
  assert_webgpu_sample("triangle_with_buffer_sample.png", fn(
    device,
    queue,
    format,
    view,
  ) {
    let renderer = @triangle_with_buffer.create_renderer_for_device(
      device, queue, format,
    )
    @triangle_with_buffer.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
test "visual WebGPU sample depth test PNG golden" {
  assert_webgpu_sample("depth_test_sample.png", fn(
    device,
    queue,
    format,
    view,
  ) {
    let renderer = @depth_test.create_renderer_for_device(device, queue, format)
    @depth_test.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
test "visual WebGPU sample ECS scene graph PNG golden" {
  assert_webgpu_sample("ecs_scene_graph_sample.png", fn(
    device,
    queue,
    format,
    view,
  ) {
    let renderer = @ecs_scene_graph.create_renderer_for_device(
      device, queue, format,
    )
    @ecs_scene_graph.render_frame_to_view(renderer, view)
    renderer.release()
  })
}

///|
test "visual WebGPU sample ECS mass cubes PNG golden" {
  assert_webgpu_sample("ecs_mass_cubes_sample.png", fn(
    device,
    queue,
    format,
    view,
  ) {
    let renderer = @ecs_mass_cubes.create_renderer_for_device(
      device, queue, format,
    )
    @ecs_mass_cubes.render_frame_to_view(renderer, view)
    renderer.release()
  })
}
