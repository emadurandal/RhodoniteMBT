///|
test "GlobalTransform blob range writer writes mixed refs" {
  let world = World::new()
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.set_global_transform(e0, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(e1, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform_format(e1, Affine3x4F16))
  let _ = world.drain_global_transform_blob_write_views()
  let refs = world.extract_global_transform_refs([e0, e1])
  let dense = detect_dense_global_transform_layout(refs, 2)
  match dense {
    Some(_) => abort("expected mixed refs")
    None => ()
  }
  let range = compute_global_transform_upload_range(refs, 2, dense)
  let writes = world.write_global_transform_blob_range_by_refs(
    refs,
    2,
    range,
    dense,
    ///|
    /// Implements `this function`.
    fn(writer) {
      writer.set_affine3x4_at(
        0,
        (1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (4.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
        (5.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (6.0 : Float),
      )
      writer.set_affine3x4_at(
        1,
        (1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (7.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
        (0.25 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (-2.0 : Float),
      )
      let set_y = writer.element_setter(1, 3)
      set_y(1, (0.5 : Float))
    },
  )
  assert_eq(writes.length(), 1)
  match world.get_global_transform(e0) {
    Some(m) => {
      assert_eq(m.at(0, 3), (4.0 : Float))
      assert_eq(m.at(1, 3), (5.0 : Float))
      assert_eq(m.at(2, 3), (6.0 : Float))
    }
    None => abort("expected f32 transform")
  }
  match world.get_global_transform(e1) {
    Some(m) => {
      assert_eq(m.at(0, 3), (7.0 : Float))
      assert_eq(m.at(1, 3), (0.5 : Float))
      assert_eq(m.at(2, 3), (-2.0 : Float))
    }
    None => abort("expected f16 transform")
  }
}

///|
test "GlobalTransform f16 scalar writer paths use same rounding" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.set_global_transform(e0, @m44.Matrix44F::identity()))
  assert_true(world.set_global_transform(e1, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  let refs = world.extract_global_transform_refs([e0, e1])
  let dense = detect_dense_global_transform_layout(refs, 2)
  let words_per_entity = match dense {
    Some(layout) => {
      assert_true(layout.format == Affine3x4F16)
      layout.words_per_entity
    }
    None => abort("expected dense f16 refs")
  }
  let range = compute_global_transform_upload_range(refs, 2, dense)
  let value = (1.0006 : Float)
  let expected = @comp.global_transform_f32_to_f16_bits(value)
  let writes = world.write_global_transform_blob_range_by_refs(
    refs,
    2,
    range,
    dense,
    ///|
    /// Implements `this function`.
    fn(writer) {
      writer.set_element_at(0, 0, 0, value)
      let set_x = writer.element_setter(0, 0)
      set_x(1, value)
    },
  )
  assert_eq(writes.length(), 1)
  assert_eq(u16_le(writes[0].bytes, 0), expected)
  assert_eq(u16_le(writes[0].bytes, words_per_entity * 4), expected)
}
