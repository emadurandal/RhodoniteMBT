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
  let sum = a + b
  assert_eq(sum.x(), 11)
  assert_eq(sum.y(), 22)
  assert_eq(sum.z(), 33)
  assert_eq(sum.w(), 44)
  let diff = a - b
  assert_eq(diff.x(), 9)
  assert_eq(diff.y(), 18)
  assert_eq(diff.z(), 27)
  assert_eq(diff.w(), 36)
  let n = -b
  assert_eq(n.x(), -1)
  assert_eq(n.y(), -2)
  assert_eq(n.z(), -3)
  assert_eq(n.w(), -4)
}

///|
test "Vector4 Hadamard mul" {
  let a = Vector4::new(2, 3, 4, 5)
  let b = Vector4::new(6, 7, 8, 9)
  let p = a * b
  assert_eq(p.x(), 12)
  assert_eq(p.y(), 21)
  assert_eq(p.z(), 32)
  assert_eq(p.w(), 45)
}

///|
test "Vector4 scale div_scalar" {
  let v = Vector4::new(8, 12, 16, 20)
  let s = v.scale(2)
  assert_eq(s.x(), 16)
  assert_eq(s.y(), 24)
  assert_eq(s.z(), 32)
  assert_eq(s.w(), 40)
  let d = v.div_scalar(4)
  assert_eq(d.x(), 2)
  assert_eq(d.y(), 3)
  assert_eq(d.z(), 4)
  assert_eq(d.w(), 5)
}

///|
test "Vector4 Eq" {
  assert_true(Vector4::new(1, 2, 3, 4) == Vector4::new(1, 2, 3, 4))
  assert_true(Vector4::new(1, 2, 3, 4) != Vector4::new(1, 2, 3, 5))
}
