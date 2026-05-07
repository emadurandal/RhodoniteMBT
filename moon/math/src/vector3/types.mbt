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
/// `T : Show` のとき、MoonBit 上で再構築可能な `Vector3::new(...)` 形式で出力する。
pub impl[T : Show] Show for Vector3[T] with output(self, logger) {
  logger.write_string("Vector3::new(")
  logger.write_object(self.data[0])
  logger.write_string(", ")
  logger.write_object(self.data[1])
  logger.write_string(", ")
  logger.write_object(self.data[2])
  logger.write_string(")")
}
