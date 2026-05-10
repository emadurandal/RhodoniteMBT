///|
/// Browser / JS target: access the global `navigator.gpu` handle via the WebGPU stack.
pub fn navigatorGPU() -> @wgpu.GPU {
  @wgpu.navigatorGPU()
}
