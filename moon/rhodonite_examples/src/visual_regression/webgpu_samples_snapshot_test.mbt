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
    _ => None
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
  let command_buffer = encoder.finish()
  fixture.queue.submit(command_buffer)
  encoder.release()
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
  sample : VisualSample,
  render : (@wgpu.GPUDevice, @wgpu.GPUQueue, String, @wgpu.GPUTextureView) -> Unit raise,
) -> Unit raise {
  match render_webgpu_sample(render) {
    Some(image) =>
      if visual_snapshot_update_enabled() {
        write_rgba_png_snapshot(image, filename=sample.filename)
        println(
          "visual_regression(native): UPDATE \{sample.filename} wrote golden PNG",
        )
      } else {
        let result = compare_rgba_matches_png_snapshot_perceptual(
          image,
          filename=sample.filename,
          max_mismatch_rate=sample.max_mismatch_rate,
          perceptual_threshold=sample.perceptual_threshold,
        )
        println(
          "visual_regression(native): PASS \{sample.filename} mismatch_rate=\{result.mismatch_rate} mismatches=\{result.mismatches}/\{result.pixels} max=\{sample.max_mismatch_rate} threshold=\{sample.perceptual_threshold}",
        )
      }
    None =>
      println(
        "visual_regression(native): SKIP \{sample.filename} native WebGPU adapter unavailable",
      )
  }
}

///|
fn assert_native_visual_sample(id : String) -> Unit raise {
  assert_native_visual_manifest_matches_test_blocks()
  let sample = visual_sample_for_target_id("native", id)
  assert_webgpu_sample(sample, fn(device, queue, format, view) raise {
    render_native_visual_sample(sample.id, device, queue, format, view)
  })
}

///|
fn assert_native_visual_manifest_matches_test_blocks() -> Unit raise {
  let samples = visual_samples_for_target("native")
  if samples.length() != 5 {
    @test.fail(
      "native visual regression manifest has \{samples.length()} samples, but MoonBit declares 5 native test blocks",
    )
  }
  for i = 0; i < samples.length(); i = i + 1 {
    match samples[i].id {
      "basic-triangle"
      | "triangle-with-buffer"
      | "depth-test"
      | "ecs-scene-graph"
      | "ecs-mass-cubes" => ()
      id =>
        @test.fail(
          "native visual regression manifest sample has no MoonBit test block: \{id}",
        )
    }
  }
}

///|
test "visual WebGPU native basic triangle PNG golden" {
  assert_native_visual_sample("basic-triangle")
}

///|
test "visual WebGPU native triangle with buffer PNG golden" {
  assert_native_visual_sample("triangle-with-buffer")
}

///|
test "visual WebGPU native depth test PNG golden" {
  assert_native_visual_sample("depth-test")
}

///|
test "visual WebGPU native ECS scene graph PNG golden" {
  assert_native_visual_sample("ecs-scene-graph")
}

///|
test "visual WebGPU native ECS mass cubes PNG golden" {
  assert_native_visual_sample("ecs-mass-cubes")
}

///|
fn render_native_visual_sample(
  id : String,
  device : @wgpu.GPUDevice,
  queue : @wgpu.GPUQueue,
  format : String,
  view : @wgpu.GPUTextureView,
) -> Unit raise {
  match id {
    "basic-triangle" => {
      let renderer = @basic_triangle.create_renderer_for_device(
        device, queue, format,
      )
      @basic_triangle.render_frame_to_view(renderer, view)
      renderer.release()
    }
    "triangle-with-buffer" => {
      let renderer = @triangle_with_buffer.create_renderer_for_device(
        device, queue, format,
      )
      @triangle_with_buffer.render_frame_to_view(renderer, view)
      renderer.release()
    }
    "depth-test" => {
      let renderer = @depth_test.create_renderer_for_device(
        device, queue, format,
      )
      @depth_test.render_frame_to_view(renderer, view)
      renderer.release()
    }
    "ecs-scene-graph" => {
      let renderer = @ecs_scene_graph.create_renderer_for_device(
        device, queue, format,
      )
      @ecs_scene_graph.render_frame_to_view(renderer, view)
      renderer.release()
    }
    "ecs-mass-cubes" => {
      let renderer = @ecs_mass_cubes.create_renderer_for_device(
        device, queue, format,
      )
      @ecs_mass_cubes.render_frame_to_view(renderer, view)
      renderer.release()
    }
    _ => @test.fail("unknown native visual regression sample id: \{id}")
  }
}
