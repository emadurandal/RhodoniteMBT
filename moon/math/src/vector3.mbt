///|
/// 3 次元ベクトル。成分は `FixedArray[T]` に保持する。
/// `T` は浮動小数点（`Float` / `Double` など）を想定する。
pub(all) struct Vector3[T] {
  data : FixedArray[T]
}

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
