///|
pub type HTMLCanvasElement

///|
pub fn navigatorGPU() -> GPU {
  abort("navigatorGPU is only available in the JS backend")
}

///|
pub fn canvas_getContext(_canvas : HTMLCanvasElement) -> GPUCanvasContext {
  abort("canvas_getContext is only available in the JS backend")
}
