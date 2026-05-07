///|
test "Vector4::new and x y z w" {
  let v = Vector4::new(1, 2, 3, 4)
  assert_eq(v.x(), 1)
  assert_eq(v.y(), 2)
  assert_eq(v.z(), 3)
  assert_eq(v.w(), 4)
}

///|
test "Vector4::zero" {
  let z : Vector4[Int] = Vector4::zero()
  assert_eq(z.x(), 0)
  assert_eq(z.y(), 0)
  assert_eq(z.z(), 0)
  assert_eq(z.w(), 0)
}

///|
test "Vector4 add sub neg" {
  let a = Vector4::new(10, 20, 30, 40)
  let b = Vector4::new(1, 2, 3, 4)
  assert_eq(a + b, Vector4::new(11, 22, 33, 44))
  assert_eq(a - b, Vector4::new(9, 18, 27, 36))
  assert_eq(-b, Vector4::new(-1, -2, -3, -4))
}

///|
test "Vector4 Hadamard mul" {
  let a = Vector4::new(2, 3, 4, 5)
  let b = Vector4::new(6, 7, 8, 9)
  assert_eq(a * b, Vector4::new(12, 21, 32, 45))
}

///|
test "Vector4 scale div_scalar" {
  let v = Vector4::new(8, 12, 16, 20)
  assert_eq(v.scale(2), Vector4::new(16, 24, 32, 40))
  assert_eq(v.div_scalar(4), Vector4::new(2, 3, 4, 5))
}

///|
test "Vector4 Eq" {
  assert_eq(Vector4::new(1, 2, 3, 4), Vector4::new(1, 2, 3, 4))
  assert_true(Vector4::new(1, 2, 3, 4) != Vector4::new(1, 2, 3, 5))
}

///|
test "Vector4 Show" {
  assert_eq(Vector4::new(1, 2, 3, 4).to_string(), "Vector4::new(1, 2, 3, 4)")
}
