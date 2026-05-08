///|
test "Vector3::new and x y z" {
  let v = Vector3::new(1, 2, 3)
  assert_eq(v.x(), 1)
  assert_eq(v.y(), 2)
  assert_eq(v.z(), 3)
}

///|
test "Vector3::data matches field and components" {
  let v = Vector3::new(1, 2, 3)
  let d = v.data()
  assert_eq(d, v.data)
  assert_eq(d[0], v.x())
  assert_eq(d[1], v.y())
  assert_eq(d[2], v.z())
}

///|
test "Vector3::zero" {
  let z : Vector3[Int] = Vector3::zero()
  assert_eq(z.x(), 0)
  assert_eq(z.y(), 0)
  assert_eq(z.z(), 0)
}

///|
test "Vector3 add sub neg" {
  let a = Vector3::new(10, 20, 30)
  let b = Vector3::new(1, 2, 3)
  assert_eq(a + b, Vector3::new(11, 22, 33))
  assert_eq(a - b, Vector3::new(9, 18, 27))
  assert_eq(-b, Vector3::new(-1, -2, -3))
}

///|
test "Vector3 Hadamard mul" {
  let a = Vector3::new(2, 3, 4)
  let b = Vector3::new(5, 6, 7)
  assert_eq(a * b, Vector3::new(10, 18, 28))
}

///|
test "Vector3 scale div_scalar" {
  let v = Vector3::new(6, 9, 12)
  assert_eq(v.scale(2), Vector3::new(12, 18, 24))
  assert_eq(v.div_scalar(3), Vector3::new(2, 3, 4))
}

///|
test "Vector3 Eq" {
  assert_eq(Vector3::new(1, 2, 3), Vector3::new(1, 2, 3))
  assert_true(Vector3::new(1, 2, 3) != Vector3::new(1, 2, 4))
}

///|
test "Vector3 Show" {
  assert_eq(Vector3::new(1, 2, 3).to_string(), "Vector3::new(1, 2, 3)")
}
