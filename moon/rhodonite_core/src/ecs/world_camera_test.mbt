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
test "builtin Camera identical set skips duplicate blob write" {
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
  ignore(world.drain_camera_blob_write_views())
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
  assert_true(!world.has_camera_blob_write_views())
  assert_eq(world.drain_camera_blob_write_views().length(), 0)
  assert_true(
    world.set_camera_matrices(
      camera,
      view,
      proj,
      (0.1 : Float),
      (200.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(world.has_camera_blob_write_views())
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
}

///|
test "builtin Camera scalar-only far update writes only far word" {
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
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    world.set_camera_matrices(
      camera,
      view,
      proj,
      (0.1 : Float),
      (200.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let writes = world.drain_camera_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 272)
  assert_eq(writes[0].bytes.length(), 4)
}

///|
test "builtin Camera scalar-only sparse update writes scalar span" {
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
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    world.set_camera_matrices(
      camera,
      view,
      proj,
      (0.2 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  let writes = world.drain_camera_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 268)
  assert_eq(writes[0].bytes.length(), 20)
}

///|
test "builtin Camera view update still writes full row" {
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
  ignore(world.drain_camera_blob_write_views())
  let changed_view = @m44.Matrix44::translation(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(
    world.set_camera_matrices(
      camera,
      changed_view,
      proj,
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let writes = world.drain_camera_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), @comp.camera_gpu_byte_stride())
}

///|
test "builtin Camera history restore refreshes input cache" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  assert_true(
    history.set_camera_matrices(
      world,
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
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      view,
      proj,
      (0.2 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  assert_true(history.undo(world))
  ignore(world.drain_camera_blob_write_views())
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
  assert_true(!world.has_camera_blob_write_views())
  assert_eq(world.drain_camera_blob_write_views().length(), 0)
}

///|
test "builtin Camera cache is replaced when freed slot is reused" {
  let world = World::new()
  let camera0 = world.create_entity()
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  assert_true(
    world.set_camera_matrices(
      camera0,
      view,
      proj,
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  assert_true(world.remove_component(camera0, world.camera_component()))
  ignore(world.drain_camera_blob_write_views())
  let camera1 = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera1,
      view,
      proj,
      (0.3 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  ignore(world.drain_camera_blob_write_views())
  match world.camera_ref(camera1) {
    Some(camera_ref) => assert_eq(camera_ref.word_offset, 0)
    None => abort("expected reused camera ref")
  }
  assert_true(
    world.set_camera_matrices(
      camera1,
      view,
      proj,
      (0.3 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(!world.has_camera_blob_write_views())
  assert_eq(world.drain_camera_blob_write_views().length(), 0)
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
test "camera blob sync system reports as direct system" {
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
  let phase = PhaseKey::new("test/render_extract_report")
  let runner = SystemRunner::new()
  runner.add_system(camera_blob_sync_system(world, phase, lens))
  let report = runner.run_phase_report(
    world,
    SystemContext::new((0.016 : Float), 1),
    phase,
  )
  assert_true(report.ok)
  assert_eq(report.batch_count, 1)
  assert_eq(report.system_count, 1)
  assert_eq(report.queued_command_count, 0)
  assert_eq(report.applied_command_count, 0)
  assert_eq(report.failed_command_count, 0)
  assert_eq(report.batches[0].systems[0].name, "rhodonite/camera_blob_sync")
  assert_eq(report.batches[0].systems[0].queued_command_count, 0)
  assert_eq(report.batches[0].systems[0].applied_command_count, 0)
  assert_eq(report.batches[0].systems[0].failed_command_count, 0)
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
}

///|
test "camera blob sync direct system skips clean frames and syncs later dirtiness" {
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
  let phase = PhaseKey::new("test/render_extract_dirty")
  let runner = SystemRunner::new()
  runner.add_system(camera_blob_sync_system(world, phase, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 0)
  assert_true(world.remove_component(camera, lens))
  assert_true(
    add_camera_lens_orthographic(
      world,
      camera,
      lens,
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      (4.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 3), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
}

///|
test "camera blob sync follows explicit Transform3D propagation" {
  let world = World::new()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(
    world.set_transform_trs(
      camera,
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
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
  let phase = PhaseKey::new("test/render_extract_propagated")
  let runner = SystemRunner::new()
  runner.add_system(camera_blob_sync_system(world, phase, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
  assert_true(
    world.set_transform_trs(
      camera,
      (2.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  world.update_global_transforms_from_transforms()
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
}

///|
test "camera blob sync ignores unchanged GlobalTransform writes" {
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
  let phase = PhaseKey::new("test/render_extract_noop_global")
  let runner = SystemRunner::new()
  runner.add_system(camera_blob_sync_system(world, phase, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
  assert_true(world.set_global_transform(camera, @m44.Matrix44F::identity()))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 0)
}

///|
test "camera blob sync follows TransformPropagation system changes" {
  let world = World::new()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(
    world.set_transform_trs(
      camera,
      (0.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
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
  let phase = PhaseKey::new("test/propagate_then_camera_sync")
  let runner = SystemRunner::new()
  runner.add_system(transform_propagation_system(world, phase))
  runner.add_system(camera_blob_sync_system(world, phase, lens))
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
  assert_true(
    world.set_transform_trs(
      camera,
      (3.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
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
  ignore(world.drain_camera_blob_write_views())
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 0)
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
    runner.run_phase(world, SystemContext::new((0.016 : Float), 3), phase),
  )
  assert_eq(world.drain_camera_blob_write_views().length(), 1)
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
test "tracked setup orbit orthographic camera joins open transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(history.begin_transaction("camera setup group"))
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
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  assert_true(!world.has_component(camera, world.transform_component()))
  assert_true(!world.has_component(camera, world.camera_component()))
}

///|
test "tracked setup orbit orthographic camera delegates while history disabled" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  history.set_enabled(false)
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
  assert_eq(history.undo_len(), 0)
  assert_true(world.has_component(camera, world.transform_component()))
  assert_true(world.has_component(camera, world.camera_component()))
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
test "tracked setup orbit orthographic camera rejects unreadable GlobalTransform without partial state" {
  let world = World::new()
  let history = WorldHistory::new()
  let orbit = world.orbit_camera_controller_component()
  let lens = world.camera_lens_component()
  let camera = world.create_entity()
  assert_true(
    world.add_component_bytes(
      camera,
      world.global_transform_component(),
      @comp.global_transform_ref_bytes(Affine3x4F32, 0xffff),
    ),
  )
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
  assert_true(world.has_component(camera, world.global_transform_component()))
  assert_true(!world.has_component(camera, orbit))
  assert_true(!world.has_component(camera, world.transform_component()))
  assert_true(
    !world.has_component(camera, world.camera_home_transform_component()),
  )
  assert_true(!world.has_component(camera, lens))
  assert_true(!world.has_component(camera, world.camera_component()))
}
