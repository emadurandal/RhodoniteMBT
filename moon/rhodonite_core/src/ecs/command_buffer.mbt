///|
pub fn CommandBuffer::new() -> CommandBuffer {
  let commands : Array[WorldCommand] = []
  { commands, }
}

///|
pub fn CommandBuffer::len(self : CommandBuffer) -> Int {
  self.commands.length()
}

///|
pub fn CommandBuffer::is_empty(self : CommandBuffer) -> Bool {
  self.commands.length() == 0
}

///|
pub fn CommandBuffer::destroy_entity(
  self : CommandBuffer,
  entity : EntityId,
) -> Unit {
  self.commands.push(DestroyEntity(entity))
}

///|
pub fn CommandBuffer::add_component_bytes(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  self.commands.push(AddComponentBytes(entity, component, bytes))
}

///|
pub fn CommandBuffer::set_component_bytes(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  self.commands.push(SetComponentBytes(entity, component, bytes))
}

///|
pub fn CommandBuffer::remove_component(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  self.commands.push(RemoveComponent(entity, component))
}

///|
pub fn CommandBuffer::set_gpu_component_bytes(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  self.commands.push(SetGpuComponentBytes(entity, component, bytes))
}

///|
pub fn CommandBuffer::clear_gpu_component(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  self.commands.push(ClearGpuComponent(entity, component))
}

///|
/// Applies commands in insertion order, then clears the buffer.
///
/// Returns `false` if any command could not be applied, for example because the target entity was
/// already dead by the time the command ran. Later commands still run.
pub fn CommandBuffer::apply(self : CommandBuffer, world : World) -> Bool {
  let mut ok = true
  for i = 0; i < self.commands.length(); i = i + 1 {
    let command_ok = match self.commands[i] {
      DestroyEntity(entity) => world.destroy_entity(entity)
      AddComponentBytes(entity, component, bytes) =>
        world.add_component_bytes(entity, component, bytes)
      SetComponentBytes(entity, component, bytes) =>
        world.set_component_bytes(entity, component, bytes)
      RemoveComponent(entity, component) =>
        world.remove_component(entity, component)
      SetGpuComponentBytes(entity, component, bytes) =>
        world.set_gpu_component_bytes(entity, component, bytes)
      ClearGpuComponent(entity, component) =>
        world.clear_gpu_component(entity, component)
    }
    if !command_ok {
      ok = false
    }
  }
  while self.commands.length() > 0 {
    let _ = self.commands.pop()
  }
  ok
}
