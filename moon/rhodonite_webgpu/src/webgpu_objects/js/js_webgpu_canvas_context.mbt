///|
/// Defines `WebGPUCanvasContext`.
pub struct WebGPUCanvasContext {
  context : GPUCanvasContext
}

///|
/// Implements `WebGPUCanvasContext::new`.
pub fn WebGPUCanvasContext::new(
  context : GPUCanvasContext,
) -> WebGPUCanvasContext {
  { context, }
}

///|
/// Implements `create_canvas_context`.
pub fn create_canvas_context(context : GPUCanvasContext) -> WebGPUCanvasContext {
  WebGPUCanvasContext::new(context)
}

///|
/// Implements `webgpu_canvas_context_configure`.
pub fn webgpu_canvas_context_configure(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
) -> Unit {
  context_configure(context.context, device, format)
}

///|
/// Reconfigures a browser canvas context after a host-owned resize.
pub fn webgpu_canvas_context_resize(
  context : WebGPUCanvasContext,
  device : GPUDevice,
  format : String,
  width : Int,
  height : Int,
) -> Unit {
  ignore(width)
  ignore(height)
  context_configure(context.context, device, format)
}

///|
/// Implements `webgpu_canvas_context_get_current_texture`.
pub fn webgpu_canvas_context_get_current_texture(
  context : WebGPUCanvasContext,
) -> WebGPUTexture {
  WebGPUTexture::new(context_getCurrentTexture(context.context))
}

///|
/// Implements `webgpu_canvas_context_present`.
pub fn webgpu_canvas_context_present(context : WebGPUCanvasContext) -> Unit {
  ignore(context)
}
