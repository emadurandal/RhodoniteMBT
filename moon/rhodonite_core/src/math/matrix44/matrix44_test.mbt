///|
test "Matrix4 identity mul_vec4" {
  let id = Matrix4F::identity()
  let v = @v4.Vector4::new(
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (5.0 : Float),
  )
  assert_eq(id.mul_vec4(v), v)
}

///|
test "Matrix4 mat_mul diagonal" {
  let s = Matrix4::new_col_major(
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
  let t = Matrix4::new_col_major(
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
test "Matrix4 transpose twice" {
  let m = Matrix4::new_col_major(
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
  assert_eq(m.transpose().transpose(), m)
}

///|
test "Matrix4 transform_point translation" {
  let m = Matrix4::new_col_major(
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
test "Matrix4 determinant and inverse" {
  let m = Matrix4::new_col_major(
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
  assert_eq(inv.mat_mul(m), Matrix4F::identity())
}

///|
test "Matrix4 singular inverse" {
  let m = Matrix4::new_col_major(
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
test "Matrix4 Show" {
  let m = Matrix4F::identity()
  assert_eq(
    m.to_string(),
    "Matrix4::new_col_major(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)",
  )
}
