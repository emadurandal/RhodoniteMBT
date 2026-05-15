///|
/// Creates an empty registry; call `register_*` before spawning entities that use those components.
fn ComponentRegistry::new() -> ComponentRegistry {
  let components : Array[RegisteredComponent] = []
  { components, }
}

///|
/// Registers a component: data lives in archetype SoA columns (`cpu_stride` bytes per row).
fn ComponentRegistry::register_cpu(
  self : ComponentRegistry,
  name : String,
  cpu_stride : Int,
) -> ComponentTypeId {
  let id = ComponentTypeId::new(self.components.length())
  self.components.push({ id, name, cpu_stride })
  id
}

///|
/// Implements `ComponentRegistry::get`.
fn ComponentRegistry::get(
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
/// Implements `ComponentRegistry::stride`.
fn ComponentRegistry::stride(
  self : ComponentRegistry,
  id : ComponentTypeId,
) -> Int {
  match self.get(id) {
    Some(component) => component.cpu_stride
    None => abort("unknown component type")
  }
}

///|
