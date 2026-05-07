///|
pub fn[T] Vector4::new(x : T, y : T, z : T, w : T) -> Vector4[T] {
  Vector4::{ data: ([x, y, z, w] : FixedArray[T]) }
}

///|
pub fn[T : Default] Vector4::zero() -> Vector4[T] {
  Vector4::new(T::default(), T::default(), T::default(), T::default())
}

///|
pub fn[T] Vector4::x(self : Self[T]) -> T {
  self.data[0]
}

///|
pub fn[T] Vector4::y(self : Self[T]) -> T {
  self.data[1]
}

///|
pub fn[T] Vector4::z(self : Self[T]) -> T {
  self.data[2]
}

///|
pub fn[T] Vector4::w(self : Self[T]) -> T {
  self.data[3]
}

///|
/// スカラー倍。`*` は `Mul` がベクトル同士（Hadamard）用のためこちらを使う。
pub fn[T : Mul] Vector4::scale(self : Self[T], s : T) -> Vector4[T] {
  Vector4::new(
    self.data[0] * s,
    self.data[1] * s,
    self.data[2] * s,
    self.data[3] * s,
  )
}

///|
pub fn[T : Div] Vector4::div_scalar(self : Self[T], s : T) -> Vector4[T] {
  Vector4::new(
    self.data[0] / s,
    self.data[1] / s,
    self.data[2] / s,
    self.data[3] / s,
  )
}
