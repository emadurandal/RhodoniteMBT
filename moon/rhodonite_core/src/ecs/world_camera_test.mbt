///|
test "builtin Camera uses ComponentTypeId index 3" {
  let world = World::new()
  assert_eq(world.camera_component().index, 3)
  assert_eq(world.component_cpu_stride(world.camera_component()), Some(4))
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
  let orbit = register_orbit_camera_controller_component(world)
  let home = register_camera_home_transform_component(world)
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
      orbit,
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
  let schedule = Schedule::new()
  schedule.add_system(orbit_camera_transform_system(world, phase, orbit, home))
  assert_true(
    schedule.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
  )
  assert_true(request_orbit_camera_reset(world, camera, orbit))
  assert_true(
    schedule.run_phase(world, SystemContext::new((0.016 : Float), 2), phase),
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
  let lens = register_camera_lens_component(world)
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
  let schedule = Schedule::new()
  schedule.add_system(camera_blob_sync_system(world, phase, lens))
  assert_true(
    schedule.run_phase(world, SystemContext::new((0.016 : Float), 1), phase),
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
