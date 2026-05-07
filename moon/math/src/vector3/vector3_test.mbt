///|
test "Vector3::new and x y z" {
  let v = Vector3::new(1, 2, 3)
  assert_eq(v.x(), 1)
  assert_eq(v.y(), 2)
  assert_eq(v.z(), 3)
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
  let sum = a + b
  assert_eq(sum.x(), 11)
  assert_eq(sum.y(), 22)
  assert_eq(sum.z(), 33)
  let diff = a - b
  assert_eq(diff.x(), 9)
  assert_eq(diff.y(), 18)
  assert_eq(diff.z(), 27)
  let n = -b
  assert_eq(n.x(), -1)
  assert_eq(n.y(), -2)
  assert_eq(n.z(), -3)
}

///|
test "Vector3 Hadamard mul" {
  let a = Vector3::new(2, 3, 4)
  let b = Vector3::new(5, 6, 7)
  let p = a * b
  assert_eq(p.x(), 10)
  assert_eq(p.y(), 18)
  assert_eq(p.z(), 28)
}

///|
test "Vector3 scale div_scalar" {
  let v = Vector3::new(6, 9, 12)
  let s = v.scale(2)
  assert_eq(s.x(), 12)
  assert_eq(s.y(), 18)
  assert_eq(s.z(), 24)
  let d = v.div_scalar(3)
  assert_eq(d.x(), 2)
  assert_eq(d.y(), 3)
  assert_eq(d.z(), 4)
}

///|
test "Vector3 Eq" {
  assert_true(Vector3::new(1, 2, 3) == Vector3::new(1, 2, 3))
  assert_true(Vector3::new(1, 2, 3) != Vector3::new(1, 2, 4))
}
