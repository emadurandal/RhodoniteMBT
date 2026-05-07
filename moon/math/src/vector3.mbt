///|
/// 3 次元ベクトル。成分は `FixedArray[Float]` に保持する。
pub(all) struct Vector3 {
  data : FixedArray[Float]
}

///|
pub fn Vector3::new(x : Float, y : Float, z : Float) -> Vector3 {
  Vector3::{ data: ([x, y, z] : FixedArray[Float]) }
}

///|
pub fn Vector3::zero() -> Vector3 {
  Vector3::new(0.0, 0.0, 0.0)
}

///|
pub fn Vector3::x(self : Self) -> Float {
  self.data[0]
}

///|
pub fn Vector3::y(self : Self) -> Float {
  self.data[1]
}

///|
pub fn Vector3::z(self : Self) -> Float {
  self.data[2]
}
