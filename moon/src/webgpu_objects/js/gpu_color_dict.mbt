///|
/// Matches WebGPU `GPUColorDict` property names for JS interop.
pub struct GPUColorDict {
  r : Double
  g : Double
  b : Double
  a : Double
}

///|
pub fn gpu_color_dict(
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> GPUColorDict {
  { r, g, b, a }
}
