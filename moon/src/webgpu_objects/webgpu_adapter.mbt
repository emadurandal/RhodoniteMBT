// WebGPU adapter implementation

///|
pub(open) trait WebGPUAdapter {
  async requestDevice(self : Self) -> &WebGPUDevice
}
