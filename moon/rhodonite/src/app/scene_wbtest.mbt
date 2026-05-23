/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "scene owns the standard Renderable component" {
  let scene = Scene::new("renderable")
  match scene.world().component_cpu_stride(scene.renderable_component_id) {
    Some(stride) => assert_eq(stride, renderable_component_stride())
    None => abort("missing Renderable component")
  }
}

///|
test "scene common systems use builtin camera component ids" {
  let scene = Scene::new("camera")
  let world = scene.world()
  scene.add_common_systems(
    orbit_camera_transform=true,
    orbit_camera_blob_sync=true,
  )
  assert_eq(scene.orbit_camera_transform_registrations.length(), 1)
  assert_eq(scene.orbit_camera_blob_sync_registrations.length(), 1)
  assert_true(
    scene.orbit_camera_transform_registrations[0].orbit_component ==
    world.orbit_camera_controller_component(),
  )
  assert_true(
    scene.orbit_camera_transform_registrations[0].home_component ==
    world.camera_home_transform_component(),
  )
  assert_true(
    scene.orbit_camera_blob_sync_registrations[0].orbit_component ==
    world.orbit_camera_controller_component(),
  )
  assert_true(
    scene.orbit_camera_blob_sync_registrations[0].lens_component ==
    world.camera_lens_component(),
  )
}

///|
test "scene common runtime records and installs standard systems" {
  let scene = Scene::new("common-runtime")
  let world = scene.world()
  scene.use_common_runtime(transform_propagation=true)
  assert_true(scene.apply_common_runtime() is Some(_))
  match scene.common_runtime {
    Some(config) => {
      assert_true(config.transform_propagation)
      assert_true(config.orbit_camera_transform)
      assert_true(config.orbit_camera_blob_sync)
    }
    None => abort("missing common runtime config")
  }
  assert_eq(scene.orbit_camera_transform_registrations.length(), 1)
  assert_eq(scene.orbit_camera_blob_sync_registrations.length(), 1)
  assert_true(
    scene.orbit_camera_transform_registrations[0].orbit_component ==
    world.orbit_camera_controller_component(),
  )
  assert_true(
    scene.orbit_camera_blob_sync_registrations[0].lens_component ==
    world.camera_lens_component(),
  )
}

///|
test "scene common runtime can skip orbit camera blob sync" {
  let scene = Scene::new("common-runtime-no-blob")
  let world = scene.world()
  scene.use_common_runtime(
    transform_propagation=false,
    orbit_camera_blob_sync=false,
  )
  match scene.common_runtime {
    Some(config) => {
      assert_true(!config.transform_propagation)
      assert_true(config.orbit_camera_transform)
      assert_true(!config.orbit_camera_blob_sync)
    }
    None => abort("missing common runtime config")
  }
  assert_eq(scene.orbit_camera_transform_registrations.length(), 1)
  assert_eq(scene.orbit_camera_blob_sync_registrations.length(), 0)
  assert_true(
    scene.orbit_camera_transform_registrations[0].orbit_component ==
    world.orbit_camera_controller_component(),
  )
  assert_true(
    scene.orbit_camera_transform_registrations[0].home_component ==
    world.camera_home_transform_component(),
  )
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
