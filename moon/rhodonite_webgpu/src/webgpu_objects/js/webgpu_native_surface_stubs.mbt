///|
/// Implements `create_native_webgpu_instance`.
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  abort("create_native_webgpu_instance is only available in the native backend")
}

///|
/// Implements `create_metal_canvas_context`.
pub fn create_metal_canvas_context(
  _instance : WebGPUInstance,
  _layer : HTMLCanvasElement,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  abort("create_metal_canvas_context is only available in the native backend")
}

///|
/// Implements `webgpu_canvas_context_surface_is_null`.
pub fn webgpu_canvas_context_surface_is_null(
  _context : WebGPUCanvasContext,
) -> Bool {
  true
}

///|
/// Implements `create_wayland_canvas_context`.
pub fn create_wayland_canvas_context(
  _instance : WebGPUInstance,
  _display : OpaquePtr,
  _wl_surface : OpaquePtr,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  abort("create_wayland_canvas_context is only available in the native backend")
}

///|
/// Implements `create_xlib_canvas_context`.
pub fn create_xlib_canvas_context(
  _instance : WebGPUInstance,
  _display : OpaquePtr,
  _window : UInt64,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  abort("create_xlib_canvas_context is only available in the native backend")
}

///|
/// Implements `native_webgpu_instance_request_adapter_for_canvas`.
pub fn native_webgpu_instance_request_adapter_for_canvas(
  _instance : WebGPUInstance,
  _canvas : WebGPUCanvasContext,
) -> WebGPUAdapter raise Error {
  abort(
    "native_webgpu_instance_request_adapter_for_canvas is only available in the native backend",
  )
}

///|
/// Implements `webgpu_canvas_context_get_format`.
pub fn webgpu_canvas_context_get_format(
  _context : WebGPUCanvasContext,
) -> String {
  abort(
    "webgpu_canvas_context_get_format is only available in the native backend",
  )
}

///|
/// Implements `webgpu_canvas_context_release`.
pub fn webgpu_canvas_context_release(_context : WebGPUCanvasContext) -> Unit {
  ()
}

///|
/// Implements `webgpu_queue_release`.
pub fn webgpu_queue_release(_queue : WebGPUQueue) -> Unit {
  ()
}

///|
/// Implements `webgpu_device_poll`.
pub fn webgpu_device_poll(_device : WebGPUDevice, wait? : Bool = false) -> Bool {
  ignore(wait)
  true
}

///|
/// Implements `webgpu_device_release`.
pub fn webgpu_device_release(_device : WebGPUDevice) -> Unit {
  ()
}

///|
/// Implements `webgpu_adapter_release`.
pub fn webgpu_adapter_release(_adapter : WebGPUAdapter) -> Unit {
  ()
}

///|
/// Implements `webgpu_instance_process_events`.
pub fn webgpu_instance_process_events(_instance : WebGPUInstance) -> Unit {
  ()
}

///|
/// Implements `webgpu_instance_release`.
pub fn webgpu_instance_release(_instance : WebGPUInstance) -> Unit {
  ()
}

///|
/// Implements `native_webgpu_instance_request_adapter`.
pub fn native_webgpu_instance_request_adapter(
  _instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  abort(
    "native_webgpu_instance_request_adapter is only available in the native backend",
  )
}

///|
/// Implements `native_webgpu_adapter_request_device`.
pub fn native_webgpu_adapter_request_device(
  _adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  abort(
    "native_webgpu_adapter_request_device is only available in the native backend",
  )
}
