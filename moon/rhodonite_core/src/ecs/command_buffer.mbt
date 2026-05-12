///|
fn CommandBuffer::new_for_system(
  system_name : String,
  writes : Array[ComponentTypeId],
  structural_write : Bool,
) -> CommandBuffer {
  {
    commands: [],
    system_name,
    writes: copy_component_array(writes),
    structural_write,
  }
}

///|
fn CommandBuffer::assert_component_write(
  self : CommandBuffer,
  component : ComponentTypeId,
  operation : String,
) -> Unit {
  if !component_array_contains(self.writes, component) {
    abort(
      operation +
      " tried to queue a write to " +
      component_id_text(component) +
      " while running System '" +
      self.system_name +
      "', but that component is not declared in writes. Hint: add this component to the System writes array; command buffers validate queued mutations before apply.",
    )
  }
}

///|
fn CommandBuffer::assert_structural_write(
  self : CommandBuffer,
  operation : String,
) -> Unit {
  if !self.structural_write {
    abort(
      operation +
      " tried to queue an entity/archetype structural mutation while running System '" +
      self.system_name +
      "', but structural_write is false. Hint: create the system with System::new_with_structural_write before queuing structural commands.",
    )
  }
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
  self.assert_structural_write("CommandBuffer::destroy_entity")
  self.commands.push(DestroyEntity(entity))
}

///|
pub fn CommandBuffer::add_component(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  self.assert_structural_write("CommandBuffer::add_component")
  self.assert_component_write(component, "CommandBuffer::add_component")
  self.commands.push(AddComponent(entity, component))
}

///|
pub fn CommandBuffer::add_component_bytes(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  self.assert_structural_write("CommandBuffer::add_component_bytes")
  self.assert_component_write(component, "CommandBuffer::add_component_bytes")
  self.commands.push(AddComponentBytes(entity, component, bytes))
}

///|
pub fn CommandBuffer::set_component_bytes(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  self.assert_component_write(component, "CommandBuffer::set_component_bytes")
  self.commands.push(SetComponentBytes(entity, component, bytes))
}

///|
pub fn CommandBuffer::remove_component(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  self.assert_structural_write("CommandBuffer::remove_component")
  self.assert_component_write(component, "CommandBuffer::remove_component")
  self.commands.push(RemoveComponent(entity, component))
}

///|
pub fn CommandBuffer::clear_gpu_component(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  self.assert_component_write(component, "CommandBuffer::clear_gpu_component")
  self.commands.push(ClearGpuComponent(entity, component))
}

///|
/// Applies commands in insertion order, then clears the buffer.
///
/// Returns `false` if any command could not be applied, for example because the target entity was
/// already dead by the time the command ran. Later commands still run.
fn CommandBuffer::apply(self : CommandBuffer, world : World) -> Bool {
  let mut ok = true
  for i = 0; i < self.commands.length(); i = i + 1 {
    let command_ok = match self.commands[i] {
      DestroyEntity(entity) => world.destroy_entity(entity)
      AddComponent(entity, component) => world.add_component(entity, component)
      AddComponentBytes(entity, component, bytes) =>
        world.add_component_bytes(entity, component, bytes)
      SetComponentBytes(entity, component, bytes) =>
        world.set_component_bytes(entity, component, bytes)
      RemoveComponent(entity, component) =>
        world.remove_component(entity, component)
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
