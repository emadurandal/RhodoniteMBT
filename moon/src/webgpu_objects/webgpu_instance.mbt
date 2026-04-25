///

///|
pub struct WebGPUInstance {
  instance : GPU
}

///|
pub fn WebGPUInstance::new(instance : GPU) -> WebGPUInstance {
  { instance, }
}

///|
pub fn WebGPUInstance::get(self : WebGPUInstance) -> GPU {
  self.instance
}
