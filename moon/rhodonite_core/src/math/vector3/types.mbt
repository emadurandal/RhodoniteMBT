///|
/// 3D vector; components live in `FixedArray[T]`.
/// `T` is expected to be floating-point (`Float`, `Double`, ...).
pub(all) struct Vector3[T] {
  data : FixedArray[T]
}

///|
pub type Vector3F = Vector3[Float]

///|
pub type Vector3D = Vector3[Double]

///|
pub type Vector3I = Vector3[Int]

///|
pub type Vector3U = Vector3[UInt]

///|
/// When `T : Show`, prints a MoonBit-friendly `Vector3::new(...)` form.
pub impl[T : Show] Show for Vector3[T] with output(self, logger) {
  logger.write_string("Vector3::new(")
  logger.write_object(self.data[0])
  logger.write_string(", ")
  logger.write_object(self.data[1])
  logger.write_string(", ")
  logger.write_object(self.data[2])
  logger.write_string(")")
}
