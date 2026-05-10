///|
test "Matrix3 identity mul_vec" {
  let id = Matrix3F::identity()
  let v = @v3.Vector3::new((2.0 : Float), (3.0 : Float), (4.0 : Float))
  assert_eq(id.mul_vec(v), v)
}

///|
test "Matrix3 mat_mul scale" {
  let s = Matrix3::new_col_major(
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
  )
  let t = Matrix3::new_col_major(
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (3.0 : Float),
  )
  let p = s.mat_mul(t)
  assert_eq(p.at(0, 0), (6.0 : Float))
  assert_eq(p.at(1, 1), (6.0 : Float))
  assert_eq(p.at(2, 2), (6.0 : Float))
}

///|
test "Matrix3 transpose twice" {
  let m = Matrix3::new_col_major(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
    (7.0 : Float),
    (8.0 : Float),
    (9.0 : Float),
  )
  assert_eq(m.transpose().transpose(), m)
}

///|
test "Matrix3 Hadamard mul" {
  let a = Matrix3::new_col_major(
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let b = Matrix3::new_col_major(
    (5.0 : Float),
    (6.0 : Float),
    (7.0 : Float),
    (2.0 : Float),
    (2.0 : Float),
    (2.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
  )
  let h = a * b
  assert_eq(h.at(0, 0), (10.0 : Float))
  assert_eq(h.at(1, 0), (18.0 : Float))
  assert_eq(h.at(2, 0), (28.0 : Float))
}

///|
test "Matrix3 determinant and inverse" {
  let m = Matrix3::new_col_major(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (4.0 : Float),
  )
  assert_eq(m.determinant(), (8.0 : Float))
  let inv = match m.inverse() {
    Some(x) => x
    None => abort("expected invertible")
  }
  assert_eq(inv.mat_mul(m), Matrix3F::identity())
}

///|
test "Matrix3 singular inverse" {
  let m = Matrix3::new_col_major(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
    (7.0 : Float),
    (8.0 : Float),
    (9.0 : Float),
  )
  assert_eq(m.determinant(), (0.0 : Float))
  assert_true(m.inverse() is None)
}

///|
test "Matrix3 Show" {
  let m = Matrix3::new_col_major(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
  )
  assert_eq(m.to_string(), "Matrix3::new_col_major(1, 0, 0, 0, 1, 0, 0, 0, 1)")
}
