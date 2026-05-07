///|
pub impl[T : Add] Add for Vector3[T] with add(self, other) {
  Vector3::new(
    self.data[0] + other.data[0],
    self.data[1] + other.data[1],
    self.data[2] + other.data[2],
  )
}

///|
pub impl[T : Sub] Sub for Vector3[T] with sub(self, other) {
  Vector3::new(
    self.data[0] - other.data[0],
    self.data[1] - other.data[1],
    self.data[2] - other.data[2],
  )
}

///|
pub impl[T : Neg] Neg for Vector3[T] with neg(self) {
  Vector3::new(-self.data[0], -self.data[1], -self.data[2])
}

///|
/// ベクトル同士の成分ごとの積（Hadamard）。内積ではない。
pub impl[T : Mul] Mul for Vector3[T] with mul(self, other) {
  Vector3::new(
    self.data[0] * other.data[0],
    self.data[1] * other.data[1],
    self.data[2] * other.data[2],
  )
}

///|
pub impl[T : Eq] Eq for Vector3[T] with equal(self, other) {
  self.data[0] == other.data[0] &&
  self.data[1] == other.data[1] &&
  self.data[2] == other.data[2]
}
