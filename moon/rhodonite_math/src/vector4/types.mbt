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

///|
pub type Vector4I = Vector4[Int]

///|
pub type Vector4U = Vector4[UInt]

///|
/// `T : Show` のとき、MoonBit 上で再構築可能な `Vector4::new(...)` 形式で出力する。
pub impl[T : Show] Show for Vector4[T] with output(self, logger) {
  logger.write_string("Vector4::new(")
  logger.write_object(self.data[0])
  logger.write_string(", ")
  logger.write_object(self.data[1])
  logger.write_string(", ")
  logger.write_object(self.data[2])
  logger.write_string(", ")
  logger.write_object(self.data[3])
  logger.write_string(")")
}
