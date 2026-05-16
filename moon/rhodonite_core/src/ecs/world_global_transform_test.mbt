///|
test "GlobalTransform identity roundtrip and GPU drain" {
  let world = World::new()
  let entity = world.create_entity()
  let expected = @m44.Matrix44F::identity()
  assert_true(world.set_global_transform(entity, expected))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, expected)
    None => abort("expected Matrix44F")
  }
  let writes = world.drain_global_transform_blob_write_views()
  assert_eq(writes.length(), 1)
}

///|
test "GlobalTransform fp16 world uses 24 byte packed blob slots" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let gt_id = world.global_transform_component()
  assert_eq(world.component_cpu_stride(gt_id), Some(8))
  let entity = world.create_entity()
  let m = @m44.Matrix44::new_col_major(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.5 : Float),
    (0.0 : Float),
    (4.0 : Float),
    (0.25 : Float),
    (-2.0 : Float),
    (1.0 : Float),
  )
  assert_true(world.set_global_transform(entity, m))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, m)
    None => abort("expected fp16 Matrix44F")
  }
  let writes = world.drain_global_transform_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].bytes.length(), 24)
}

///|
test "compute_global_transform uses Transform3D only without ChildOf" {
  let world = World::new()
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  match world.compute_global_transform(e) {
    Some(m) => {
      assert_eq(m.at(0, 3), (2.0 : Float))
      assert_eq(m.at(1, 3), (0.0 : Float))
      assert_eq(m.at(2, 3), (0.0 : Float))
    }
    None => abort("expected Matrix44F")
  }
}

///|
test "compute_global_transform multiplies parent chain" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let buf_p = transform3d_bytes_translation(
    (10.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let np = buf_p.length()
  let tf_p = @comp.Transform3D::from_component_mut_view(
    buf_p.mut_view(start=0, end=np),
  )
  let buf_c = transform3d_bytes_translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nc = buf_c.length()
  let tf_c = @comp.Transform3D::from_component_mut_view(
    buf_c.mut_view(start=0, end=nc),
  )
  assert_true(world.set_transform(parent, tf_p))
  assert_true(world.set_transform(child, tf_c))
  assert_true(world.set_child_of(child, parent))
  match world.compute_global_transform(child) {
    Some(m) => {
      assert_eq(m.at(0, 3), (15.0 : Float))
      assert_eq(m.at(1, 3), (0.0 : Float))
      assert_eq(m.at(2, 3), (0.0 : Float))
    }
    None => abort("expected Matrix44F")
  }
}

///|
test "compute_global_transform returns None without Transform3D" {
  let world = World::new()
  let e = world.create_entity()
  assert_true(world.compute_global_transform(e) is None)
}

///|
test "compute_global_transform returns None on ChildOf cycle" {
  let world = World::new()
  let a = world.create_entity()
  let b = world.create_entity()
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(a, tf))
  assert_true(world.set_transform(b, tf))
  assert_true(world.set_child_of(a, b))
  assert_true(world.set_child_of(b, a))
  assert_true(world.compute_global_transform(a) is None)
}

///|
test "update_global_transforms_from_transforms writes hierarchy to GlobalTransform" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let buf_p = transform3d_bytes_translation(
    (10.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let np = buf_p.length()
  let tf_p = @comp.Transform3D::from_component_mut_view(
    buf_p.mut_view(start=0, end=np),
  )
  let buf_c = transform3d_bytes_translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nc = buf_c.length()
  let tf_c = @comp.Transform3D::from_component_mut_view(
    buf_c.mut_view(start=0, end=nc),
  )
  assert_true(world.set_transform(parent, tf_p))
  assert_true(world.set_transform(child, tf_c))
  assert_true(world.set_child_of(child, parent))
  let g0 = @m44.Matrix44F::identity()
  assert_true(world.set_global_transform(parent, g0))
  assert_true(world.set_global_transform(child, g0))
  let _ = world.drain_global_transform_blob_write_views()
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(child) {
    Some(m) => {
      assert_eq(m.at(0, 3), (15.0 : Float))
      assert_eq(m.at(1, 3), (0.0 : Float))
      assert_eq(m.at(2, 3), (0.0 : Float))
    }
    None => abort("expected Matrix44F")
  }
}

///|
test "update_global_transforms_from_transforms applies root Transform3D only" {
  let world = World::new()
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (7.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(e) {
    Some(m) => assert_eq(m.at(0, 3), (7.0 : Float))
    None => abort("expected Matrix44F")
  }
}

///|
test "update_global_transforms_from_transforms writes fp16 GlobalTransform rows" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (7.0 : Float),
    (0.25 : Float),
    (-2.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(e) {
    Some(m) => {
      assert_eq(m.at(0, 3), (7.0 : Float))
      assert_eq(m.at(1, 3), (0.25 : Float))
      assert_eq(m.at(2, 3), (-2.0 : Float))
    }
    None => abort("expected fp16 Matrix44F")
  }
  let writes = world.drain_global_transform_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].bytes.length(), 24)
}

///|
test "update_global_transforms_from_transforms handles mixed child and root archetypes" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let root = world.create_entity()
  let buf_p = transform3d_bytes_translation(
    (10.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let np = buf_p.length()
  let tf_p = @comp.Transform3D::from_component_mut_view(
    buf_p.mut_view(start=0, end=np),
  )
  let buf_c = transform3d_bytes_translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nc = buf_c.length()
  let tf_c = @comp.Transform3D::from_component_mut_view(
    buf_c.mut_view(start=0, end=nc),
  )
  let buf_r = transform3d_bytes_translation(
    (7.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let nr = buf_r.length()
  let tf_r = @comp.Transform3D::from_component_mut_view(
    buf_r.mut_view(start=0, end=nr),
  )
  assert_true(world.set_transform(parent, tf_p))
  assert_true(world.set_transform(child, tf_c))
  assert_true(world.set_child_of(child, parent))
  assert_true(world.set_transform(root, tf_r))
  assert_true(world.set_global_transform(parent, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(child, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(root, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(child) {
    Some(m) => assert_eq(m.at(0, 3), (15.0 : Float))
    None => abort("expected child Matrix44F")
  }
  match world.get_global_transform(root) {
    Some(m) => assert_eq(m.at(0, 3), (7.0 : Float))
    None => abort("expected root Matrix44F")
  }
}

///|
test "GlobalTransform refs extract packed render data" {
  let world = World::new()
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.set_global_transform(e0, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(e1, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform_format(e1, Affine3x4F16))
  let refs = world.extract_global_transform_refs([e0, e1])
  assert_eq(refs.length(), 16)
  let (fmt0, off0) = @comp.global_transform_ref_from_component_view(refs[0:8])
  let (fmt1, off1) = @comp.global_transform_ref_from_component_view(refs[8:16])
  assert_true(fmt0 == Affine3x4F32)
  assert_true(fmt1 == Affine3x4F16)
  assert_eq(off0, 0)
  assert_eq(off1, 24)
}

///|
test "GlobalTransform blob writes update through set_global_transform" {
  let world = World::new()
  let e = world.create_entity()
  let m = @m44.Matrix44::translation(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(e, m))
  let _ = world.drain_global_transform_blob_write_views()
  let m2 = @m44.Matrix44::translation(
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(e, m2))
  match world.get_global_transform(e) {
    Some(read) => assert_eq(read.at(0, 3), (4.0 : Float))
    None => abort("expected blob-backed transform")
  }
  let writes = world.drain_global_transform_blob_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 48)
  let row0 = writes[0].bytes[0:48]
  assert_eq(@comp.get_gpu_f32_byte_view(row0, 12), (4.0 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row0, 28), (5.0 : Float))
  assert_eq(@comp.get_gpu_f32_byte_view(row0, 44), (6.0 : Float))
}
