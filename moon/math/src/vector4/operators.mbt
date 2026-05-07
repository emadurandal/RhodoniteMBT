///|
pub impl[T : Add] Add for Vector4[T] with add(self, other) {
  Vector4::new(
    self.data[0] + other.data[0],
    self.data[1] + other.data[1],
    self.data[2] + other.data[2],
    self.data[3] + other.data[3],
  )
}

///|
pub impl[T : Sub] Sub for Vector4[T] with sub(self, other) {
  Vector4::new(
    self.data[0] - other.data[0],
    self.data[1] - other.data[1],
    self.data[2] - other.data[2],
    self.data[3] - other.data[3],
  )
}

///|
pub impl[T : Neg] Neg for Vector4[T] with neg(self) {
  Vector4::new(-self.data[0], -self.data[1], -self.data[2], -self.data[3])
}

///|
/// ベクトル同士の成分ごとの積（Hadamard）。内積ではない。
pub impl[T : Mul] Mul for Vector4[T] with mul(self, other) {
  Vector4::new(
    self.data[0] * other.data[0],
    self.data[1] * other.data[1],
    self.data[2] * other.data[2],
    self.data[3] * other.data[3],
  )
}

///|
pub impl[T : Eq] Eq for Vector4[T] with equal(self, other) {
  self.data[0] == other.data[0] &&
  self.data[1] == other.data[1] &&
  self.data[2] == other.data[2] &&
  self.data[3] == other.data[3]
}
