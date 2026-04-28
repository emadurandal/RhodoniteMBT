///|
pub type WebGPUInstance

///|
pub fn WebGPUInstance::new(GPU) -> WebGPUInstance

///|
pub fn WebGPUInstance::get(Self) -> GPU

///|
pub fn WebGPUInstance::getPreferredCanvasFormat(Self) -> String

///|
pub async fn WebGPUInstance::requestAdapter(Self) -> WebGPUAdapter

///|
pub fn webgpu_instance_get_preferred_canvas_format(WebGPUInstance) -> String

///|
pub async fn webgpu_instance_request_adapter(WebGPUInstance) -> WebGPUAdapter

///|
pub fn native_webgpu_instance_request_adapter(WebGPUInstance) -> WebGPUAdapter raise Error
