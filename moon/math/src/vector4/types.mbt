///|
/// 4 次元ベクトル。成分は `FixedArray[T]` に保持する。
/// `T` は浮動小数点（`Float` / `Double` など）を想定する。
pub(all) struct Vector4[T] {
  data : FixedArray[T]
}

///|
pub type Vector4F = Vector4[Float]

///|
pub type Vector4D = Vector4[Double]
