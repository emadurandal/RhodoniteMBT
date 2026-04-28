// WebGPU canvas context abstraction

///|
pub(open) trait WebGPUCanvasContext {
  getCurrentTexture(self : Self) -> &WebGPUTexture
  present(self : Self) -> Unit
}
