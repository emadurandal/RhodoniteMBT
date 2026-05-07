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
