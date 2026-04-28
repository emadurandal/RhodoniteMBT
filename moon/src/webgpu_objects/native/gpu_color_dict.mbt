///|
/// Matches WebGPU `GPUColorDict` (same layout as JS for shared descriptors).
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
