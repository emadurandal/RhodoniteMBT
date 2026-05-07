///|
pub fn create_native_webgpu_instance() -> WebGPUInstance raise Error {
  abort("create_native_webgpu_instance is only available in the native backend")
}

///|
pub fn create_metal_canvas_context(
  _instance : WebGPUInstance,
  _layer : HTMLCanvasElement,
  _width : Int,
  _height : Int,
) -> WebGPUCanvasContext {
  abort("create_metal_canvas_context is only available in the native backend")
}

///|
pub fn webgpu_canvas_context_get_format(
  _context : WebGPUCanvasContext,
) -> String {
  abort(
    "webgpu_canvas_context_get_format is only available in the native backend",
  )
}

///|
pub fn webgpu_canvas_context_release(_context : WebGPUCanvasContext) -> Unit {
  ()
}

///|
pub fn webgpu_queue_release(_queue : WebGPUQueue) -> Unit {
  ()
}

///|
pub fn webgpu_device_poll(_device : WebGPUDevice, wait? : Bool = false) -> Bool {
  ignore(wait)
  true
}

///|
pub fn webgpu_device_release(_device : WebGPUDevice) -> Unit {
  ()
}

///|
pub fn webgpu_adapter_release(_adapter : WebGPUAdapter) -> Unit {
  ()
}

///|
pub fn webgpu_instance_process_events(_instance : WebGPUInstance) -> Unit {
  ()
}

///|
pub fn webgpu_instance_release(_instance : WebGPUInstance) -> Unit {
  ()
}

///|
pub fn native_webgpu_instance_request_adapter(
  _instance : WebGPUInstance,
) -> WebGPUAdapter raise Error {
  abort(
    "native_webgpu_instance_request_adapter is only available in the native backend",
  )
}

///|
pub fn native_webgpu_adapter_request_device(
  _adapter : WebGPUAdapter,
) -> WebGPUDevice raise Error {
  abort(
    "native_webgpu_adapter_request_device is only available in the native backend",
  )
}
