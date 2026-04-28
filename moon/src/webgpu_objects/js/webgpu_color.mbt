///| RGBA clear color (`GPUColorDict` on JS). Mirrored in `native/` for MoonBit virtual implement packages.
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
