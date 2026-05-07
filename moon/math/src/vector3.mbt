///|
/// 3 次元ベクトル。成分は `FixedArray[T]` に保持する。
/// `T` は浮動小数点（`Float` / `Double` など）を想定する。
pub(all) struct Vector3Impl[T] {
  data : FixedArray[T]
}

///|
pub type Vector3 = Vector3Impl[Float]

///|
pub type Vector3F = Vector3Impl[Float]

///|
pub type Vector3D = Vector3Impl[Double]

///|
pub fn[T] Vector3Impl::new(x : T, y : T, z : T) -> Vector3Impl[T] {
  Vector3Impl::{ data: ([x, y, z] : FixedArray[T]) }
}

///|
pub fn[T : Default] Vector3Impl::zero() -> Vector3Impl[T] {
  Vector3Impl::new(T::default(), T::default(), T::default())
}

///|
pub fn[T] Vector3Impl::x(self : Self[T]) -> T {
  self.data[0]
}

///|
pub fn[T] Vector3Impl::y(self : Self[T]) -> T {
  self.data[1]
}

///|
pub fn[T] Vector3Impl::z(self : Self[T]) -> T {
  self.data[2]
}
