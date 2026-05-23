/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "phase handler registration key deduplicates exact phase slot key matches" {
  let handlers : Array[PhaseHandler] = [
    {
      phase: phase_input(),
      slot: BeforeSystems,
      key: Some("test/common"),
      run: fn(_engine, _frame) {  },
    },
  ]
  assert_true(
    has_phase_handler_registration(
      handlers,
      phase_input(),
      BeforeSystems,
      "test/common",
    ),
  )
  assert_true(
    !has_phase_handler_registration(
      handlers,
      phase_input(),
      BeforeSystems,
      "test/other",
    ),
  )
  assert_true(
    !has_phase_handler_registration(
      handlers,
      phase_input(),
      AfterSystems,
      "test/common",
    ),
  )
  assert_true(
    !has_phase_handler_registration(
      handlers,
      phase_update(),
      BeforeSystems,
      "test/common",
    ),
  )
}

///|
test "common runtime orbit input key matches common handlers key" {
  let scene = Scene::new("dedupe")
  let key = common_orbit_camera_input_handler_key(scene)
  let handlers : Array[PhaseHandler] = [
    {
      phase: phase_input(),
      slot: BeforeSystems,
      key: Some(key),
      run: fn(_engine, _frame) {  },
    },
  ]
  assert_true(
    has_phase_handler_registration(
      handlers,
      phase_input(),
      BeforeSystems,
      common_orbit_camera_input_handler_key(scene),
    ),
  )
}

///|
test "push unique declared common runtime scene skips duplicates" {
  let main = Scene::new("main")
  let surface_only = Scene::new("surface")
  let result : Array[Scene] = []
  push_unique_declared_common_runtime_scene(result, main)
  push_unique_declared_common_runtime_scene(result, surface_only)
  push_unique_declared_common_runtime_scene(result, main)
  assert_eq(result.length(), 2)
  assert_true(result[0].same(main))
  assert_true(result[1].same(surface_only))
}

///|
test "common handlers honor explicit common runtime flags" {
  let scene = Scene::new("explicit-common-runtime")
  scene.use_common_runtime(
    transform_propagation=false,
    orbit_camera_blob_sync=false,
  )
  let config = common_handlers_runtime_config(
    scene,
    CommonHandlersOptions::default(),
  )
  assert_true(!config.transform_propagation)
  assert_true(config.orbit_camera_transform)
  assert_true(!config.orbit_camera_blob_sync)
}
