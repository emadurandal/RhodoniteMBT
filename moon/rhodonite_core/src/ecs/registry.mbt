///|
pub fn ComponentRegistry::new() -> ComponentRegistry {
  let components : Array[RegisteredComponent] = []
  { components, }
}

///|
pub fn ComponentRegistry::register_cpu(
  self : ComponentRegistry,
  name : String,
  cpu_stride : Int,
) -> ComponentTypeId {
  let id = ComponentTypeId::new(self.components.length())
  self.components.push({ id, name, kind: CpuOnly, cpu_stride, gpu_layout: None })
  id
}

///|
pub fn ComponentRegistry::register_gpu(
  self : ComponentRegistry,
  name : String,
  cpu_stride : Int,
  gpu_layout : GpuLayout,
) -> ComponentTypeId {
  let id = ComponentTypeId::new(self.components.length())
  self.components.push({
    id,
    name,
    kind: GpuVisible,
    cpu_stride,
    gpu_layout: Some(gpu_layout),
  })
  id
}

///|
pub fn ComponentRegistry::get(
  self : ComponentRegistry,
  id : ComponentTypeId,
) -> RegisteredComponent? {
  if id.index < 0 || id.index >= self.components.length() {
    None
  } else {
    Some(self.components[id.index])
  }
}

///|
pub fn ComponentRegistry::stride(
  self : ComponentRegistry,
  id : ComponentTypeId,
) -> Int {
  match self.get(id) {
    Some(component) => component.cpu_stride
    None => abort("unknown component type")
  }
}

///|
pub fn ComponentRegistry::gpu_layout(
  self : ComponentRegistry,
  id : ComponentTypeId,
) -> GpuLayout? {
  match self.get(id) {
    Some(component) => component.gpu_layout
    None => None
  }
}
