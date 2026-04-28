///|
pub type WebGPUCanvasContext

///|
pub fn WebGPUCanvasContext::new(GPUCanvasContext) -> WebGPUCanvasContext

///|
pub fn WebGPUCanvasContext::get(Self) -> GPUCanvasContext

///|
pub fn WebGPUCanvasContext::configure(Self, GPUDevice, String) -> Unit

///|
pub fn webgpu_canvas_context_configure(
  WebGPUCanvasContext,
  GPUDevice,
  String,
) -> Unit

///|
pub fn WebGPUCanvasContext::getCurrentTexture(Self) -> WebGPUTexture

///|
pub fn WebGPUCanvasContext::present(Self) -> Unit
