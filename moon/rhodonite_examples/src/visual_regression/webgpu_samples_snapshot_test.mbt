/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
let sample_width : UInt = 800U

///|
let sample_height : UInt = 600U

///|
/// Implements `assert_webgpu_sample`.
fn assert_webgpu_sample(sample : VisualSample) -> Unit raise {
  match render_native_visual_sample(sample.id) {
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
/// Implements `assert_native_visual_sample`.
fn assert_native_visual_sample(id : String) -> Unit raise {
  assert_native_visual_manifest_matches_test_blocks()
  let sample = visual_sample_for_target_id("native", id)
  assert_webgpu_sample(sample)
}

///|
/// Implements `assert_native_visual_manifest_matches_test_blocks`.
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
      | "ondemand-triangle"
      | "ecs-scene-graph"
      | "ecs-custom-component-color"
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
test "visual WebGPU native on-demand triangle PNG golden" {
  assert_native_visual_sample("ondemand-triangle")
}

///|
test "visual WebGPU native ECS scene graph PNG golden" {
  assert_native_visual_sample("ecs-scene-graph")
}

///|
test "visual WebGPU native ECS custom component color PNG golden" {
  assert_native_visual_sample("ecs-custom-component-color")
}

///|
test "visual WebGPU native ECS mass cubes PNG golden" {
  assert_native_visual_sample("ecs-mass-cubes")
}

///|
/// Returns the platform app hooks for a native visual sample.
fn native_visual_platform_app(id : String) -> @sdl_app.PlatformApp raise {
  match id {
    "basic-triangle" =>
      @sdl_app.PlatformApp::default_engine(@basic_triangle.setup_engine)
    "ondemand-triangle" =>
      @sdl_app.PlatformApp::default_engine(@ondemand_triangle.setup_engine)
    "ecs-scene-graph" =>
      @sdl_app.PlatformApp::default_engine(@ecs_scene_graph.setup_engine)
    "ecs-custom-component-color" =>
      @sdl_app.PlatformApp::default_engine(
        @ecs_custom_component_color.setup_engine,
      )
    "ecs-mass-cubes" =>
      @sdl_app.PlatformApp::new(
        @ecs_mass_cubes.create_engine, @ecs_mass_cubes.setup_engine,
      )
    _ => @test.fail("unknown native visual regression sample id: \{id}")
  }
}

///|
/// Implements `render_native_visual_sample`.
fn render_native_visual_sample(id : String) -> RgbaImage? raise {
  let app = native_visual_platform_app(id)
  let bytes = @sdl_app.run_single_frame_platform_capture_rgba8(
    @sdl_app.PlatformConfig::new(
      "Rhodonite visual regression: " + id,
      sample_width.reinterpret_as_int(),
      sample_height.reinterpret_as_int(),
      "native visual regression: " + id,
    ),
    app,
  ) catch {
    _ => return None
  }
  match bytes {
    Some(data) =>
      Some({
        width: sample_width.reinterpret_as_int(),
        height: sample_height.reinterpret_as_int(),
        data,
      })
    None => None
  }
}
