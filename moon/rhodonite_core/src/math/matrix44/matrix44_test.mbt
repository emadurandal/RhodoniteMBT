///|
test "Matrix44 identity mul_vec4" {
  let id = Matrix44F::identity()
  let v = @v4.Vector4::new(
    (2.0 : Float),
    (3.0 : Float),
    (4.0 : Float),
    (5.0 : Float),
  )
  assert_eq(id.mul_vec4(v), v)
}

///|
test "Matrix44 mat_mul diagonal" {
  let s = Matrix44::new_col_major(
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
  let t = Matrix44::new_col_major(
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
test "Matrix44 transpose col_major_1_to_16" {
  let m = Matrix44::new_col_major(
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
  let t = Matrix44::new_col_major(
    (1.0 : Float),
    (5.0 : Float),
    (9.0 : Float),
    (13.0 : Float),
    (2.0 : Float),
    (6.0 : Float),
    (10.0 : Float),
    (14.0 : Float),
    (3.0 : Float),
    (7.0 : Float),
    (11.0 : Float),
    (15.0 : Float),
    (4.0 : Float),
    (8.0 : Float),
    (12.0 : Float),
    (16.0 : Float),
  )
  assert_eq(m.transpose(), t)
}

///|
test "Matrix44 transform_point translation" {
  let m = Matrix44::new_col_major(
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
test "Matrix44 determinant and inverse" {
  let m = Matrix44::new_col_major(
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
  assert_eq(inv.mat_mul(m), Matrix44F::identity())
}

///|
test "Matrix44 singular inverse" {
  let m = Matrix44::new_col_major(
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
test "Matrix44 Show" {
  let m = Matrix44F::identity()
  assert_eq(
    m.to_string(),
    "Matrix44::new_col_major(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)",
  )
}

///|
test "Matrix44F translation" {
  let m = Matrix44::translation(
    (10.0 : Float),
    (20.0 : Float),
    (30.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let p = @v3.Vector3::new((1.0 : Float), (2.0 : Float), (3.0 : Float))
  let q = m.transform_point(p)
  assert_eq(q.x(), (11.0 : Float))
  assert_eq(q.y(), (22.0 : Float))
  assert_eq(q.z(), (33.0 : Float))
}

///|
test "Matrix44D rotation_x zero is identity" {
  let m = Matrix44::rotation_x((0.0 : Double))
  assert_eq(m, Matrix44::identity_with((1.0 : Double), (0.0 : Double)))
}

///|
test "Matrix44D rotation_x matches explicit col major" {
  let rad = (0.7 : Double)
  let c = @math.cos(rad)
  let s = @math.sin(rad)
  let one = (1.0 : Double)
  let zero = (0.0 : Double)
  let m0 = Matrix44::new_col_major(
    one,
    zero,
    zero,
    zero,
    zero,
    c,
    s,
    zero,
    zero,
    -s,
    c,
    zero,
    zero,
    zero,
    zero,
    one,
  )
  let m1 = Matrix44::rotation_x(rad)
  assert_eq(m0, m1)
}

///|
test "Matrix44D rotation_z zero is identity" {
  let m = Matrix44::rotation_z((0.0 : Double))
  assert_eq(m, Matrix44::identity_with((1.0 : Double), (0.0 : Double)))
}

///|
test "Matrix44D rotation_z matches explicit col major" {
  let rad = (0.7 : Double)
  let c = @math.cos(rad)
  let s = @math.sin(rad)
  let one = (1.0 : Double)
  let zero = (0.0 : Double)
  let m0 = Matrix44::new_col_major(
    c,
    -s,
    zero,
    zero,
    s,
    c,
    zero,
    zero,
    zero,
    zero,
    one,
    zero,
    zero,
    zero,
    zero,
    one,
  )
  let m1 = Matrix44::rotation_z(rad)
  assert_eq(m0, m1)
}

///|
test "Matrix44F ortho scales xy" {
  let m = Matrix44::ortho(
    (-1.0 : Float),
    (1.0 : Float),
    (-1.0 : Float),
    (1.0 : Float),
    (0.1 : Float),
    (10.0 : Float),
  )
  assert_eq(m.at(0, 0), (1.0 : Float))
  assert_eq(m.at(1, 1), (1.0 : Float))
}
