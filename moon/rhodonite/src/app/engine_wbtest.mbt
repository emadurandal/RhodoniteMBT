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
