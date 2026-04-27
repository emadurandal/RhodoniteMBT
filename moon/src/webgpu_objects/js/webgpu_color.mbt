///|
pub struct WebGPUColor {
  r : Double
  g : Double
  b : Double
  a : Double
}

///|
pub fn WebGPUColor::new(
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> WebGPUColor {
  { r, g, b, a }
}

///|
pub fn WebGPUColor::get(self : WebGPUColor) -> (Double, Double, Double, Double) {
  (self.r, self.g, self.b, self.a)
}
