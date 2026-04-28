// WebGPU command encoder abstraction

///|
pub(open) trait WebGPUCommandEncoder {
  release(self : Self) -> Unit
}
