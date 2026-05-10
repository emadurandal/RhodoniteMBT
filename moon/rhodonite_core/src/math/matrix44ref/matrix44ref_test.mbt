///|
test "Matrix44Ref identity mul_vec4" {
  let buf = Array::make(16, (0.0 : Float))
  let r = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  r.write_identity()
  let v = @v4.Vector4::new(
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (5.0 : Float),
  )
  assert_eq(r.mul_vec4(v), v)
}

///|
test "Matrix44Ref mat_mul diagonal" {
  let buf_s = Array::make(16, (0.0 : Float))
  let buf_t = Array::make(16, (0.0 : Float))
  let s = Matrix44Ref::from_mut_view(buf_s.mut_view(start=0, end=16))
  let t = Matrix44Ref::from_mut_view(buf_t.mut_view(start=0, end=16))
  s.write_col_major(
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
  )
  t.write_col_major(
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (3.0 : Float),
  )
  let p = s.mat_mul(t)
  assert_eq(p.at(0, 0), (6.0 : Float))
  assert_eq(p.at(1, 1), (6.0 : Float))
  assert_eq(p.at(2, 2), (6.0 : Float))
  assert_eq(p.at(3, 3), (6.0 : Float))
}

///|
test "Matrix44Ref transpose twice" {
  let buf = Array::make(16, (0.0 : Float))
  let r = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  r.write_col_major(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
    (7.0 : Float),
    (8.0 : Float),
    (9.0 : Float),
    (10.0 : Float),
    (11.0 : Float),
    (12.0 : Float),
    (13.0 : Float),
    (14.0 : Float),
    (15.0 : Float),
    (16.0 : Float),
  )
  assert_eq(r.transpose().transpose(), r.to_matrix44())
}

///|
test "Matrix44Ref transform_point translation" {
  let buf = Array::make(16, (0.0 : Float))
  let m = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  m.write_col_major(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (10.0 : Float),
    (20.0 : Float),
    (30.0 : Float),
    (1.0 : Float),
  )
  let p = @v3.Vector3::new((1.0 : Float), (2.0 : Float), (3.0 : Float))
  let q = m.transform_point(p)
  assert_eq(q.x(), (11.0 : Float))
  assert_eq(q.y(), (22.0 : Float))
  assert_eq(q.z(), (33.0 : Float))
}

///|
test "Matrix44Ref determinant and inverse" {
  let buf = Array::make(16, (0.0 : Float))
  let m = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  m.write_col_major(
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
  )
  assert_eq(m.determinant(), (16.0 : Float))
  let inv = match m.inverse() {
    Some(x) => x
    None => abort("expected invertible")
  }
  assert_eq(inv.mat_mul(m.to_matrix44()), @m44.Matrix44F::identity())
}

///|
test "Matrix44Ref singular inverse" {
  let buf = Array::make(16, (0.0 : Float))
  let m = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  m.write_col_major(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (2.0 : Float),
    (4.0 : Float),
    (6.0 : Float),
    (8.0 : Float),
    (3.0 : Float),
    (6.0 : Float),
    (9.0 : Float),
    (12.0 : Float),
    (4.0 : Float),
    (8.0 : Float),
    (12.0 : Float),
    (16.0 : Float),
  )
  assert_eq(m.determinant(), (0.0 : Float))
  assert_true(
    match m.inverse() {
      Some(_) => false
      None => true
    },
  )
}

///|
test "Matrix44Ref Show" {
  let buf = Array::make(16, (0.0 : Float))
  let m = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  m.write_identity()
  assert_eq(
    m.to_string(),
    "Matrix44::new_col_major(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)",
  )
}

///|
test "Matrix44Ref set_at roundtrip" {
  let buf = Array::make(16, (0.0 : Float))
  let r = Matrix44Ref::from_mut_view(buf.mut_view(start=0, end=16))
  r.write_zero()
  r.set_at(1, 2, (7.5 : Float))
  assert_eq(r.at(1, 2), (7.5 : Float))
}

///|
test "Matrix44Ref add_matrix matches Matrix44 add" {
  let buf_a = Array::make(16, (1.0 : Float))
  let buf_b = Array::make(16, (2.0 : Float))
  let ra = Matrix44Ref::from_mut_view(buf_a.mut_view(start=0, end=16))
  let rb = Matrix44Ref::from_mut_view(buf_b.mut_view(start=0, end=16))
  let sum_ref = ra.add_matrix(rb)
  let sum_owned = ra.to_matrix44() + rb.to_matrix44()
  assert_eq(sum_ref, sum_owned)
}
