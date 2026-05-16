///|
test "Transform3D identity roundtrip bytes and World set/get" {
  let world = World::new()
  let entity = world.create_entity()
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let t = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(entity, t))
  match world.get_transform(entity) {
    Some(got) => {
      assert_eq(got.position.x(), t.position.x())
      assert_eq(got.rotation.w(), t.rotation.w())
      assert_eq(got.scale.x(), t.scale.x())
    }
    None => abort("expected Transform3D")
  }
  assert_eq(world.drain_global_transform_blob_write_views().length(), 0)
}

///|
test "Transform3D writes position through zero-copy component view" {
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let row = buf.mut_view(start=0, end=n)
  @comp.Transform3D::write_position_to_component_mut_view(
    row,
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
  )
  let t = @comp.Transform3D::from_component_mut_view(row)
  assert_eq(t.position.x(), (2.0 : Float))
  assert_eq(t.position.y(), (3.0 : Float))
  assert_eq(t.position.z(), (4.0 : Float))
  t.position.set((5.0 : Float), (6.0 : Float), (7.0 : Float))
  assert_eq(t.position.x(), (5.0 : Float))
  assert_eq(t.position.y(), (6.0 : Float))
  assert_eq(t.position.z(), (7.0 : Float))
}

///|
test "spawn_transform_global_batch initializes fp16 GlobalTransform rows" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let entities = world.spawn_transform_global_batch(1, fn(
    _i,
    _entity,
    tf_row,
    _gt_row,
  ) {
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0,
    )
  })
  assert_eq(entities.length(), 1)
  match world.get_global_transform(entities[0]) {
    Some(read) => assert_eq(read, @m44.Matrix44F::identity())
    None => abort("expected fp16 batch GlobalTransform")
  }
}

///|
test "spawn_transform_global_batch creates builtin transform rows directly" {
  let world = World::new()
  let entities = world.spawn_transform_global_batch(2, fn(
    i,
    _e,
    tf_row,
    _gt_row,
  ) {
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row,
      Float::from_double((i + 1).to_double()),
      Float::from_double((i + 2).to_double()),
      Float::from_double((i + 3).to_double()),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    )
  })
  assert_eq(entities.length(), 2)
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  assert_true(world.has_component(entities[0], tf))
  assert_true(world.has_component(entities[0], gt))
  match world.get_transform(entities[1]) {
    Some(t) => {
      assert_eq(t.position.x(), (2.0 : Float))
      assert_eq(t.position.y(), (3.0 : Float))
      assert_eq(t.position.z(), (4.0 : Float))
    }
    None => abort("expected Transform3D")
  }
  let writes = world.drain_global_transform_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 2 * 48)
  assert_eq(
    @comp.get_gpu_f32_byte_view(writes[0].bytes[0:48], 0),
    (1.0 : Float),
  )
  assert_eq(
    @comp.get_gpu_f32_byte_view(writes[0].bytes[48:96], 40),
    (1.0 : Float),
  )
}
