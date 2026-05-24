/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "WorldHistory compresses repeated CameraChanged deltas inside transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let before = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected original Camera row")
  }
  assert_true(history.begin_transaction("camera drag"))
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (200.0 : Float),
      (1.25 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_eq(history.current_deltas.length(), 1)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.3 : Float),
      (300.0 : Float),
      (1.5 : Float),
      (0.0 : Float),
      (2.0 : Float),
    ),
  )
  let after = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected final Camera row")
  }
  assert_eq(history.current_deltas.length(), 1)
  match history.current_deltas[0] {
    CameraChanged(e, Some(old), latest) => {
      assert_true(e == camera)
      assert_true(old == before)
      assert_true(latest == after)
    }
    _ => abort("expected compressed CameraChanged delta")
  }
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  assert_true(world.camera_gpu_row(camera) == Some(before))
  assert_true(history.redo(world))
  assert_true(world.camera_gpu_row(camera) == Some(after))
}

///|
test "WorldHistory drops CameraChanged when transaction returns to original row" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let before = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected original Camera row")
  }
  assert_true(history.begin_transaction("camera no-op"))
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (200.0 : Float),
      (1.25 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_eq(history.current_deltas.length(), 1)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(world.camera_gpu_row(camera) == Some(before))
  assert_eq(history.current_deltas.length(), 0)
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 0)
}
