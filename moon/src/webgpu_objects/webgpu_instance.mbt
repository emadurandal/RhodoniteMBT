///|
pub type WebGPUInstance

///|
pub fn webgpu_instance_get_preferred_canvas_format(WebGPUInstance) -> String

///|
/// サーフェス能力と既定ヒントから、[`webgpu_canvas_context_configure`] で選ばれる形式に相当する文字列を返す（ネイティブ向け）。
pub fn webgpu_instance_get_preferred_canvas_format_for_surface(
  WebGPUInstance,
  WebGPUAdapter,
  WebGPUCanvasContext,
) -> String

///|
pub async fn webgpu_instance_request_adapter(WebGPUInstance) -> WebGPUAdapter

///|
pub fn native_webgpu_instance_request_adapter(WebGPUInstance) -> WebGPUAdapter raise Error
