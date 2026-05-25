/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "builtin Camera uses ComponentTypeId index 3" {
  let world = World::new()
  assert_eq(world.camera_component().index, 3)
  assert_true(world.component_cpu_stride(world.camera_component()) is Some(4))
  assert_eq(world.orbit_camera_controller_component().index, 4)
  assert_eq(world.camera_home_transform_component().index, 5)
  assert_eq(world.camera_lens_component().index, 6)
  match world.component_cpu_stride(world.orbit_camera_controller_component()) {
    Some(stride) => assert_eq(stride, 80)
    None => abort("missing OrbitCameraController component")
  }
  match world.component_cpu_stride(world.camera_home_transform_component()) {
    Some(stride) => assert_eq(stride, 48)
    None => abort("missing CameraHomeTransform component")
  }
  match world.component_cpu_stride(world.camera_lens_component()) {
    Some(stride) => assert_eq(stride, 32)
    None => abort("missing CameraLens component")
  }
}

///|
test "builtin Camera stores matrices in packed camera blob" {
  let world = World::new()
  let camera = world.create_entity()
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  assert_true(
    world.set_camera_matrices(
      camera,
      view,
      proj,
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_eq(world.camera_blob_word_capacity(), @comp.camera_gpu_word_count())
  match world.camera_ref(camera) {
    Some(camera_ref) => assert_eq(camera_ref.word_offset, 0)
    None => abort("expected camera ref")
  }
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_eq(
        @comp.camera_view_proj_from_gpu_bytes(bytes),
        @m44.Matrix44F::identity(),
      )
    None => abort("expected camera gpu row")
  }
  let writes = world.drain_camera_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), @comp.camera_gpu_byte_stride())
}

///|
test "orbit camera reset restores home Transform3D" {
  let world = World::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let camera = world.create_entity()
  assert_true(
    world.set_transform_trs(
      camera,
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
  )
  assert_true(world.set_global_transform(camera, @m44.Matrix44F::identity()))
  assert_true(add_orbit_camera_controller(world, camera, orbit, 0.0, 0.0))
  assert_true(set_camera_home_from_current_transform(world, camera, home))
  assert_true(
    update_orbit_camera_controller_from_mouse_frame(
      world,
      camera,
      true,
      false,
      false,
      false,
      (10.0 : Float),
      (5.0 : Float),
      (0.0 : Float),
    ),
  )
  let phase = PhaseKey::new("test/post_update")
  let runner = SystemRunner::new()
  runner.add_system(orbit_camera_transform_system(world, phase, orbit, home))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_true(request_orbit_camera_reset(world, camera, orbit))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
  )
  assert_true(
    orbit_camera_pose(world, camera, orbit) ==
    (
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
      (16.0 : Float),
    ),
  )
  match world.get_transform(camera) {
    Some(transform) =>
      assert_eq(
        transform.to_local_matrix(),
        @m44.Matrix44::translation(
          (1.0 : Float),
          (2.0 : Float),
          (3.0 : Float),
          (1.0 : Float),
          (0.0 : Float),
        ),
      )
    None => abort("expected Transform3D")
  }
}

///|
test "camera blob sync system writes from GlobalTransform and CameraLens" {
  let world = World::new()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(world.set_global_transform(camera, @m44.Matrix44F::identity()))
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      camera_projection_orthographic(),
      (0.0 : Float),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    add_camera_lens_orthographic(
      world,
      camera,
      lens,
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      (2.0 : Float),
      (0.0 : Float),
    ),
  )
  let phase = PhaseKey::new("test/render_extract")
  let runner = SystemRunner::new()
  runner.add_system(camera_blob_sync_system(world, phase, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  let writes = world.drain_camera_blob_write_views()
  assert_eq(writes.length(), 1)
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_true(
        @comp.camera_view_proj_from_gpu_bytes(bytes) !=
        @m44.Matrix44F::identity(),
      )
    None => abort("expected camera gpu row")
  }
}

///|
test "orbit camera blob sync applies orthographic dolly scale" {
  let world = World::new()
  let orbit = world.orbit_camera_controller_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(world.set_global_transform(camera, @m44.Matrix44F::identity()))
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      camera_projection_orthographic(),
      (0.0 : Float),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    add_orbit_camera_controller_with_distance(
      world,
      camera,
      orbit,
      0.0,
      0.0,
      (16.0 : Float),
    ),
  )
  assert_true(
    update_orbit_camera_controller_from_mouse_frame(
      world,
      camera,
      false,
      false,
      false,
      false,
      (0.0 : Float),
      (0.0 : Float),
      (1000.0 : Float),
    ),
  )
  assert_true(
    add_camera_lens_orthographic(
      world,
      camera,
      lens,
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      (2.0 : Float),
      (0.0 : Float),
    ),
  )
  let phase = PhaseKey::new("test/render_extract")
  let runner = SystemRunner::new()
  runner.add_system(orbit_camera_blob_sync_system(world, phase, orbit, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  match world.camera_gpu_row(camera) {
    Some(bytes) => {
      let view_proj = @comp.camera_view_proj_from_gpu_bytes(bytes)
      assert_eq(view_proj.at(0, 0), (0.25 : Float))
      assert_eq(view_proj.at(1, 1), (0.25 : Float))
    }
    None => abort("expected camera gpu row")
  }
}

///|
test "camera-control command systems update through SystemRunner" {
  let world = World::new()
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
      false,
      false,
      false,
      false,
      (0.0 : Float),
      (0.0 : Float),
      (1000.0 : Float),
    ),
  )
  let update_phase = PhaseKey::new("test/command_update")
  let update_runner = SystemRunner::new()
  update_runner.add_system(
    orbit_camera_transform_command_system(world, update_phase, orbit, home),
  )
  assert_true(
    update_runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase,
    ),
  )
  let render_phase = PhaseKey::new("test/command_render_extract")
  let render_runner = SystemRunner::new()
  render_runner.add_system(
    orbit_camera_blob_sync_command_system(world, render_phase, orbit, lens),
  )
  assert_true(
    render_runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 2),
      render_phase,
    ),
  )
  match world.camera_gpu_row(camera) {
    Some(bytes) => {
      let view_proj = @comp.camera_view_proj_from_gpu_bytes(bytes)
      assert_eq(view_proj.at(0, 0), (0.25 : Float))
      assert_eq(view_proj.at(1, 1), (0.25 : Float))
    }
    None => abort("expected command Camera row")
  }
}

///|
test "camera blob sync command system writes through command buffer" {
  let world = World::new()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(world.set_global_transform(camera, @m44.Matrix44F::identity()))
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      camera_projection_orthographic(),
      (0.0 : Float),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    add_camera_lens_orthographic(
      world,
      camera,
      lens,
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      (2.0 : Float),
      (0.0 : Float),
    ),
  )
  let phase = PhaseKey::new("test/camera_command_render_extract")
  let runner = SystemRunner::new()
  runner.add_system(camera_blob_sync_command_system(world, phase, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
}

///|
test "setup orbit orthographic camera initializes transform components and camera blob" {
  let world = World::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  let pitch = 0.38
  assert_true(
    setup_orbit_orthographic_camera(
      world,
      camera,
      OrbitOrthographicCameraDesc::new_yz_pitched(
        pitch,
        (2.0 : Float),
        (5.6 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (3.8 : Float),
      ),
    ),
  )
  let (_yaw, stored_pitch, _pan_x, pan_y, dolly, _distance) = orbit_camera_pose(
    world, camera, orbit,
  )
  let expected_pan_y = Float::from_double(-2.0 / @math.cos(pitch))
  assert_eq(stored_pitch, Float::from_double(pitch))
  assert_true(pan_y > expected_pan_y - (0.00001 : Float))
  assert_true(pan_y < expected_pan_y + (0.00001 : Float))
  assert_eq(dolly, (1.0 : Float))
  assert_true(world.has_component(camera, home))
  assert_true(world.has_component(camera, lens))
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_true(
        @comp.camera_view_proj_from_gpu_bytes(bytes) !=
        @m44.Matrix44F::identity(),
      )
    None => abort("expected camera gpu row")
  }
}

///|
test "tracked setup orbit orthographic camera undoes and redoes as one operation" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(
    setup_orbit_orthographic_camera_tracked(
      history,
      world,
      camera,
      OrbitOrthographicCameraDesc::new_yz_pitched(
        0.38,
        (2.0 : Float),
        (5.6 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (3.8 : Float),
      ),
    ),
  )
  assert_eq(history.undo_len(), 1)
  assert_true(world.has_component(camera, world.transform_component()))
  assert_true(world.has_component(camera, world.global_transform_component()))
  assert_true(world.has_component(camera, orbit))
  assert_true(world.has_component(camera, home))
  assert_true(world.has_component(camera, lens))
  assert_true(world.has_component(camera, world.camera_component()))
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(!world.has_component(camera, world.transform_component()))
  assert_true(!world.has_component(camera, world.global_transform_component()))
  assert_true(!world.has_component(camera, orbit))
  assert_true(!world.has_component(camera, home))
  assert_true(!world.has_component(camera, lens))
  assert_true(!world.has_component(camera, world.camera_component()))
  assert_true(history.redo(world))
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_true(world.has_component(camera, orbit))
  assert_true(world.has_component(camera, world.camera_component()))
  assert_true(world.drain_camera_blob_write_views().length() > 0)
}

///|
test "tracked setup orbit orthographic camera rejects existing controller without partial state" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(add_orbit_camera_controller(world, camera, orbit, 0.0, 0.0))
  assert_true(
    !setup_orbit_orthographic_camera_tracked(
      history,
      world,
      camera,
      OrbitOrthographicCameraDesc::new_yz_pitched(
        0.38,
        (2.0 : Float),
        (5.6 : Float),
        (0.1 : Float),
        (50.0 : Float),
        (1.0 : Float),
        (3.8 : Float),
      ),
    ),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(world.has_component(camera, orbit))
  assert_true(!world.has_component(camera, world.transform_component()))
  assert_true(!world.has_component(camera, world.global_transform_component()))
  assert_true(
    !world.has_component(camera, world.camera_home_transform_component()),
  )
  assert_true(!world.has_component(camera, lens))
  assert_true(!world.has_component(camera, world.camera_component()))
}

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
