///|
/// Creates an empty registry; call `register_*` before spawning entities that use those components.
pub fn ComponentRegistry::new() -> ComponentRegistry {
  let components : Array[RegisteredComponent] = []
  { components, }
}

///|
/// Registers a CPU-only component: data lives only in archetype SoA columns (`cpu_stride` bytes per row).
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
/// Registers a GPU-visible component: payload lives only in the flat [`GpuComponentStore`]
/// (`cpu_stride` is always `0`; archetypes hold this id for signatures only; see `GpuLayout.stride` for packing).
pub fn ComponentRegistry::register_gpu(
  self : ComponentRegistry,
  name : String,
  gpu_layout : @comp.GpuLayout,
) -> ComponentTypeId {
  let id = ComponentTypeId::new(self.components.length())
  self.components.push({
    id,
    name,
    kind: GpuVisible,
    cpu_stride: 0,
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
) -> @comp.GpuLayout? {
  match self.get(id) {
    Some(component) => component.gpu_layout
    None => None
  }
}
