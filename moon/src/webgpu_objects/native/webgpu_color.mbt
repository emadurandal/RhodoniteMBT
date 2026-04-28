///| Mirror of `js/webgpu_color.mbt` for the native implement package.
pub struct WebGPUColor {
  r : Double
  g : Double
  b : Double
  a : Double
}

///|
pub fn webgpu_color_new(
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> WebGPUColor {
  { r, g, b, a }
}
