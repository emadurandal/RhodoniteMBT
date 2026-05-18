///| Native GPU queue synchronization helpers shared by examples.

///|
/// Waits for the native GPU queue before swapchain acquire, render completion, or present.
#cfg(target="native")
pub fn wait_native_gpu_queue(device : @wgpu.GPUDevice) -> Unit {
  let _ = @wgpu.webgpu_device_poll(device, wait=true)
}

///|
/// Keeps browser builds source-compatible with native queue synchronization points.
#cfg(not(target="native"))
pub fn wait_native_gpu_queue(_device : @wgpu.GPUDevice) -> Unit {
  ignore(_device)
}
