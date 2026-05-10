///|
/// 4D vector; components live in `FixedArray[T]`.
/// `T` is expected to be floating-point (`Float`, `Double`, ...).
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
/// When `T : Show`, prints a MoonBit-friendly `Vector4::new(...)` form.
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
