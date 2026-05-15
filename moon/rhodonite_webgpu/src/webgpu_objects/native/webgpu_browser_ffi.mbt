///|
pub type HTMLCanvasElement

///|
/// Implements `navigatorGPU`.
pub fn navigatorGPU() -> GPU {
  abort("navigatorGPU is only available in the JS backend")
}

///|
/// Implements `canvas_getContext`.
pub fn canvas_getContext(_canvas : HTMLCanvasElement) -> GPUCanvasContext {
  abort("canvas_getContext is only available in the JS backend")
}
