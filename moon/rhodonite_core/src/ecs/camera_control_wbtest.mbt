/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds a four-byte component payload for camera-control white-box tests.
fn camera_control_wb_bytes4(
  a : Byte,
  b : Byte,
  c : Byte,
  d : Byte,
) -> FixedArray[Byte] {
  [a, b, c, d]
}

///|
test "camera-control tracked transaction does not rerun after commit disables recording" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("CameraControlCommitDisabled", 4)
  let entity = world.create_entity()
  let before = camera_control_wb_bytes4(1, 0, 0, 0)
  let after = camera_control_wb_bytes4(2, 0, 0, 0)
  assert_true(world.add_component_bytes(entity, component, before))
  let mut calls = 0
  assert_true(
    run_camera_control_tracked_transaction(history, world, "commit disabled", () => {
      calls = calls + 1
      ignore(history.set_component_bytes(world, entity, component, after))
      history.set_enabled(false)
      true
    }),
  )
  assert_eq(calls, 1)
  assert_eq(history.undo_len(), 0)
  assert_true(world.component_bytes(entity, component) == Some(after))
  history.set_enabled(true)
  assert_true(history.begin_transaction("next"))
  assert_true(history.cancel_transaction())
}
