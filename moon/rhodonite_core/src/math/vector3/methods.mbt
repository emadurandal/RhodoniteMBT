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
/// Returns the inner `FixedArray` unchanged; shared storage reference, elements are not copied.
pub fn[T] Vector3::data(self : Self[T]) -> FixedArray[T] {
  self.data
}

///|
/// Scalar multiply. Use this instead of `*` because `Mul` is Hadamard for vectors.
pub fn[T : Mul] Vector3::scale(self : Self[T], s : T) -> Vector3[T] {
  Vector3::new(self.data[0] * s, self.data[1] * s, self.data[2] * s)
}

///|
pub fn[T : Div] Vector3::div_scalar(self : Self[T], s : T) -> Vector3[T] {
  Vector3::new(self.data[0] / s, self.data[1] / s, self.data[2] / s)
}
