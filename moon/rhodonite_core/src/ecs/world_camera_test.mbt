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
