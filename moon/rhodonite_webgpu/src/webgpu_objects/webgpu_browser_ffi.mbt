///|
pub type HTMLCanvasElement

///|
/// Implements `navigatorGPU`.
pub fn navigatorGPU() -> GPU

///|
/// Implements `canvas_getContext`.
pub fn canvas_getContext(canvas : HTMLCanvasElement) -> GPUCanvasContext

///|
/// Implements `create_webgpu_instance`.
pub fn create_webgpu_instance(GPU) -> WebGPUInstance

///|
/// Implements `create_canvas_context`.
pub fn create_canvas_context(GPUCanvasContext) -> WebGPUCanvasContext
