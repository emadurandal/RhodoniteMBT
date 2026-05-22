/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "scene infers common orbit camera component ids from registered systems" {
  let scene = Scene::new("camera")
  let world = scene.world()
  let orbit = world.register_cpu_component("RuntimeTestOrbit", 4)
  let home = world.register_cpu_component("RuntimeTestHome", 4)
  let lens = world.register_cpu_component("RuntimeTestLens", 4)
  scene.add_common_systems(
    orbit_component=Some(orbit),
    home_component=Some(home),
    lens_component=Some(lens),
  )
  assert_true(scene.inferred_common_orbit_component() == Some(orbit))
  assert_true(scene.inferred_common_home_component(Some(orbit)) == Some(home))
  assert_true(scene.inferred_common_lens_component(Some(orbit)) == Some(lens))
}

///|
test "scene common runtime records and installs standard systems" {
  let scene = Scene::new("common-runtime")
  let world = scene.world()
  let orbit = world.register_cpu_component("RuntimeOrbit", 4)
  let home = world.register_cpu_component("RuntimeHome", 4)
  let lens = world.register_cpu_component("RuntimeLens", 4)
  scene.use_common_runtime(
    transform_propagation=true,
    orbit_component=Some(orbit),
    home_component=Some(home),
    lens_component=Some(lens),
  )
  assert_true(scene.apply_common_runtime() is Some(_))
  assert_true(scene.inferred_common_orbit_component() == Some(orbit))
  assert_true(scene.inferred_common_home_component(Some(orbit)) == Some(home))
  assert_true(scene.inferred_common_lens_component(Some(orbit)) == Some(lens))
}

///|
test "scene render state preparation runs update post update and render extract" {
  let scene = Scene::new("prepare")
  let calls : Array[Int] = []
  scene.add_system(phase_update(), "update", [], [], fn(
    _world,
    ctx,
    _commands,
  ) {
    calls.push(10 + ctx.frame_index)
  })
  scene.add_system(phase_post_update(), "post-update", [], [], fn(
    _world,
    ctx,
    _commands,
  ) {
    calls.push(20 + ctx.frame_index)
  })
  scene.add_system(phase_render_extract(), "render-extract", [], [], fn(
    _world,
    ctx,
    _commands,
  ) {
    calls.push(30 + ctx.frame_index)
  })
  assert_true(scene.prepare_render_state())
  assert_eq(calls.length(), 3)
  assert_eq(calls[0], 10)
  assert_eq(calls[1], 20)
  assert_eq(calls[2], 30)
}

///|
test "scene can run an explicit ordered phase list with one frame state" {
  let scene = Scene::new("phase-list")
  let calls : Array[Int] = []
  scene.add_system(phase_update(), "update", [], [], fn(
    _world,
    ctx,
    _commands,
  ) {
    calls.push(10 + ctx.frame_index)
  })
  scene.add_system(phase_post_update(), "post-update", [], [], fn(
    _world,
    ctx,
    _commands,
  ) {
    calls.push(20 + ctx.frame_index)
  })
  let frame = FrameState::new((0.016 : Float), 7, 0.112)
  assert_true(
    scene.run_systems_for_phases([phase_post_update(), phase_update()], frame),
  )
  assert_eq(calls.length(), 2)
  assert_eq(calls[0], 27)
  assert_eq(calls[1], 17)
}
