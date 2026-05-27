/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "tracked orbit camera edit helpers group drag sync and reset sync" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(
    setup_orbit_orthographic_camera(
      world,
      camera,
      OrbitOrthographicCameraDesc::new_yz_pitched(
        0.0,
        (0.0 : Float),
        (16.0 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (3.8 : Float),
      ),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  let (yaw_before, _, _, _, _, _) = orbit_camera_pose(world, camera, orbit)
  assert_true(history.begin_transaction("camera drag"))
  assert_true(
    update_orbit_camera_controller_from_mouse_frame_tracked(
      history,
      world,
      camera,
      true,
      false,
      false,
      false,
      (10.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(
    set_camera_lens_orthographic_tracked(
      history,
      world,
      camera,
      lens,
      (0.1 : Float),
      (50.0 : Float),
      (1.0 : Float),
      (4.5 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(
    sync_orbit_camera_transform_component_tracked(
      history, world, camera, orbit, home,
    ),
  )
  assert_true(
    sync_orbit_camera_blob_component_tracked(
      history, world, camera, orbit, lens,
    ),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  let (yaw_after, _, _, _, _, _) = orbit_camera_pose(world, camera, orbit)
  assert_true(yaw_after != yaw_before)
  assert_true(history.undo(world))
  let (yaw_undone, _, _, _, _, _) = orbit_camera_pose(world, camera, orbit)
  assert_eq(yaw_undone, yaw_before)
  assert_true(history.redo(world))
  let (yaw_redone, _, _, _, _, _) = orbit_camera_pose(world, camera, orbit)
  assert_eq(yaw_redone, yaw_after)
  history.clear()
  assert_true(history.begin_transaction("camera reset"))
  assert_true(request_orbit_camera_reset_tracked(history, world, camera, orbit))
  assert_true(
    sync_orbit_camera_transform_component_tracked(
      history, world, camera, orbit, home,
    ),
  )
  assert_true(history.commit_transaction())
  let (yaw_reset, _, _, _, _, _) = orbit_camera_pose(world, camera, orbit)
  assert_eq(yaw_reset, (0.0 : Float))
  assert_true(history.undo(world))
  let (yaw_restored, _, _, _, _, _) = orbit_camera_pose(world, camera, orbit)
  assert_eq(yaw_restored, yaw_after)
}

///|
test "tracked orbit transform sync rejects reset without Transform3D before mutating" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let camera = world.create_entity()
  assert_true(add_orbit_camera_controller(world, camera, orbit, 0.0, 0.0))
  assert_true(
    world.add_component_bytes(
      camera,
      home,
      @comp.transform3d_trs_bytes(
        (1.0 : Float),
        (2.0 : Float),
        (3.0 : Float),
        0.0,
        0.0,
        0.0,
        1.0,
        (1.0 : Float),
        (1.0 : Float),
        (1.0 : Float),
      ),
    ),
  )
  assert_true(request_orbit_camera_reset(world, camera, orbit))
  let before = match world.component_bytes(camera, orbit) {
    Some(bytes) => bytes
    None => abort("expected OrbitCameraController")
  }
  assert_true(
    !sync_orbit_camera_transform_component_tracked(
      history, world, camera, orbit, home,
    ),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(!world.has_component(camera, world.transform_component()))
  assert_true(world.component_bytes(camera, orbit) == Some(before))
}

///|
test "WorldHistory tracks camera-control command systems through system phase" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(
    setup_orbit_orthographic_camera(
      world,
      camera,
      OrbitOrthographicCameraDesc::new_yz_pitched(
        0.0,
        (0.0 : Float),
        (16.0 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (2.0 : Float),
      ),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    update_orbit_camera_controller_from_mouse_frame(
      world,
      camera,
      true,
      false,
      false,
      false,
      (10.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
    ),
  )
  let before = match world.get_global_transform(camera) {
    Some(matrix) => matrix
    None => abort("expected GlobalTransform")
  }
  let update_phase = PhaseKey::new("test/history_command_update")
  let render_phase = PhaseKey::new("test/history_command_render")
  let update_runner = SystemRunner::new()
  update_runner.add_system(
    orbit_camera_transform_command_system(world, update_phase, orbit, home),
  )
  let render_runner = SystemRunner::new()
  render_runner.add_system(
    orbit_camera_blob_sync_command_system(world, render_phase, orbit, lens),
  )
  assert_true(history.begin_transaction("camera command systems"))
  assert_true(
    history.run_system_phase(
      update_runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase,
      "Orbit Transform Command",
    ),
  )
  assert_true(
    history.run_system_phase(
      render_runner,
      world,
      SystemContext::new((0.016 : Float), 2),
      render_phase,
      "Orbit Blob Command",
    ),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  let after = match world.get_global_transform(camera) {
    Some(matrix) => matrix
    None => abort("expected updated GlobalTransform")
  }
  assert_true(after != before)
  assert_true(history.undo(world))
  match world.get_global_transform(camera) {
    Some(matrix) => assert_eq(matrix, before)
    None => abort("expected undone GlobalTransform")
  }
  assert_true(history.redo(world))
  match world.get_global_transform(camera) {
    Some(matrix) => assert_eq(matrix, after)
    None => abort("expected redone GlobalTransform")
  }
  assert_true(world.drain_camera_blob_write_views().length() > 0)
}

///|
test "camera-control command systems run in guarded history phase" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let camera = world.create_entity()
  assert_true(
    setup_orbit_orthographic_camera(
      world,
      camera,
      OrbitOrthographicCameraDesc::new_yz_pitched(
        0.0,
        (0.0 : Float),
        (16.0 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (2.0 : Float),
      ),
    ),
  )
  assert_true(
    update_orbit_camera_controller_from_mouse_frame(
      world,
      camera,
      true,
      false,
      false,
      false,
      (10.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
    ),
  )
  let phase = PhaseKey::new("test/guarded_camera_command_update")
  let runner = SystemRunner::new()
  runner.add_system(
    orbit_camera_transform_command_system(world, phase, orbit, home),
  )
  history.set_raw_mutation_guard_enabled(true)
  assert_true(
    history.begin_guarded_transaction(world, "guarded camera command"),
  )
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      phase,
      "Guarded Camera Command",
    ),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
}
