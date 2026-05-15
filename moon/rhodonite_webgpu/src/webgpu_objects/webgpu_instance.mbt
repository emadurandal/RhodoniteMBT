///|
pub type WebGPUInstance

///|
/// Implements `webgpu_instance_get_preferred_canvas_format`.
pub fn webgpu_instance_get_preferred_canvas_format(WebGPUInstance) -> String

///|
/// Returns the format string matching what [`webgpu_canvas_context_configure`] would choose from surface caps and default hints (native).
pub fn webgpu_instance_get_preferred_canvas_format_for_surface(
  WebGPUInstance,
  WebGPUAdapter,
  WebGPUCanvasContext,
) -> String

///|
pub async fn webgpu_instance_request_adapter(WebGPUInstance) -> WebGPUAdapter

///|
/// Implements `native_webgpu_instance_request_adapter`.
pub fn native_webgpu_instance_request_adapter(WebGPUInstance) -> WebGPUAdapter raise Error
