///|
/// 3 次元ベクトル。成分は `FixedArray[T]` に保持する。
/// `T` は浮動小数点（`Float` / `Double` など）を想定する。
pub(all) struct Vector3[T] {
  data : FixedArray[T]
}

///|
pub type Vector3F = Vector3[Float]

///|
pub type Vector3D = Vector3[Double]

///|
pub fn[T] Vector3::new(x : T, y : T, z : T) -> Vector3[T] {
  Vector3::{ data: ([x, y, z] : FixedArray[T]) }
}

///|
pub fn[T : Default] Vector3::zero() -> Vector3[T] {
  Vector3::new(T::default(), T::default(), T::default())
}

///|
pub fn[T] Vector3::x(self : Self[T]) -> T {
  self.data[0]
}

///|
pub fn[T] Vector3::y(self : Self[T]) -> T {
  self.data[1]
}

///|
pub fn[T] Vector3::z(self : Self[T]) -> T {
  self.data[2]
}

///|
/// スカラー倍。`*` は `Mul` がベクトル同士（Hadamard）用のためこちらを使う。
pub fn[T : Mul] Vector3::scale(self : Self[T], s : T) -> Vector3[T] {
  Vector3::new(self.data[0] * s, self.data[1] * s, self.data[2] * s)
}

///|
pub fn[T : Div] Vector3::div_scalar(self : Self[T], s : T) -> Vector3[T] {
  Vector3::new(self.data[0] / s, self.data[1] / s, self.data[2] / s)
}

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
