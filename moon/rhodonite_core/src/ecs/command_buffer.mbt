/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `CommandBuffer::new_for_system`.
fn CommandBuffer::new_for_system(
  world : World,
  system_name : String,
  writes : Array[ComponentTypeId],
  structural_write : Bool,
) -> CommandBuffer {
  {
    commands: [],
    world,
    system_name,
    writes: copy_component_array(writes),
    structural_write,
    history: None,
  }
}

///|
/// Implements `CommandBuffer::new_for_history_system`.
fn CommandBuffer::new_for_history_system(
  world : World,
  system_name : String,
  writes : Array[ComponentTypeId],
  structural_write : Bool,
  history : WorldHistory,
) -> CommandBuffer {
  {
    commands: [],
    world,
    system_name,
    writes: copy_component_array(writes),
    structural_write,
    history: Some(history),
  }
}

///|
/// Implements `CommandBuffer::assert_component_write`.
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
/// Implements `CommandBuffer::assert_structural_write`.
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
/// Requires structural write permission when a builtin setter may add a component.
fn CommandBuffer::assert_structural_write_if_missing_component(
  self : CommandBuffer,
  entity : EntityId,
  component : ComponentTypeId,
  operation : String,
) -> Unit {
  if !self.world.has_component(entity, component) {
    self.assert_structural_write(operation)
  }
}

///|
/// Sentinel component used when a command failure has no component target.
fn command_failure_no_component() -> ComponentTypeId {
  ComponentTypeId::new(-1)
}

///|
/// Returns a stable command kind for execution reports.
fn world_command_kind(command : WorldCommand) -> String {
  match command {
    CreateEntity(_) => "create_entity"
    DestroyEntity(_) => "destroy_entity"
    AddComponent(_, _) => "add_component"
    AddComponentBytes(_, _, _) => "add_component_bytes"
    SetComponentBytes(_, _, _) => "set_component_bytes"
    RemoveComponent(_, _) => "remove_component"
    SetGlobalTransform(_, _) => "set_global_transform"
    SetGlobalTransformFormat(_, _) => "set_global_transform_format"
    SetCameraMatrices(_, _, _, _, _, _, _, _) => "set_camera_matrices"
  }
}

///|
/// Returns the entity targeted by a command.
fn world_command_entity(command : WorldCommand) -> EntityId {
  match command {
    CreateEntity(entity) => entity
    DestroyEntity(entity) => entity
    AddComponent(entity, _) => entity
    AddComponentBytes(entity, _, _) => entity
    SetComponentBytes(entity, _, _) => entity
    RemoveComponent(entity, _) => entity
    SetGlobalTransform(entity, _) => entity
    SetGlobalTransformFormat(entity, _) => entity
    SetCameraMatrices(entity, _, _, _, _, _, _, _) => entity
  }
}

///|
/// Returns the component targeted by a command, or a sentinel for structural-only commands.
fn CommandBuffer::command_component(
  self : CommandBuffer,
  command : WorldCommand,
) -> ComponentTypeId {
  match command {
    CreateEntity(_) => command_failure_no_component()
    DestroyEntity(_) => command_failure_no_component()
    AddComponent(_, component) => component
    AddComponentBytes(_, component, _) => component
    SetComponentBytes(_, component, _) => component
    RemoveComponent(_, component) => component
    SetGlobalTransform(_, _) => self.world.global_transform_component()
    SetGlobalTransformFormat(_, _) => self.world.global_transform_component()
    SetCameraMatrices(_, _, _, _, _, _, _, _) => self.world.camera_component()
  }
}

///|
/// Builds one command failure report with stable metadata.
fn CommandBuffer::command_failure(
  self : CommandBuffer,
  command : WorldCommand,
  command_index : Int,
) -> CommandBufferCommandFailure {
  {
    command_index,
    command_kind: world_command_kind(command),
    reason: "apply_failed",
    entity: world_command_entity(command),
    component: self.command_component(command),
  }
}

///|
/// Implements `CommandBuffer::len`.
pub fn CommandBuffer::len(self : CommandBuffer) -> Int {
  self.commands.length()
}

///|
/// Implements `CommandBuffer::is_empty`.
pub fn CommandBuffer::is_empty(self : CommandBuffer) -> Bool {
  self.commands.length() == 0
}

///|
/// Reserves an entity id immediately and queues creation for after the current system returns.
pub fn CommandBuffer::create_entity(self : CommandBuffer) -> EntityId {
  self.assert_structural_write("CommandBuffer::create_entity")
  let entity = match self.history {
    Some(history) => history.reserve_entity_for_command(self.world)
    None => self.world.reserve_entity_for_command()
  }
  self.commands.push(CreateEntity(entity))
  entity
}

///|
/// Implements `CommandBuffer::destroy_entity`.
pub fn CommandBuffer::destroy_entity(
  self : CommandBuffer,
  entity : EntityId,
) -> Unit {
  self.assert_structural_write("CommandBuffer::destroy_entity")
  self.commands.push(DestroyEntity(entity))
}

///|
/// Implements `CommandBuffer::add_component`.
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
/// Implements `CommandBuffer::add_component_bytes`.
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
/// Implements `CommandBuffer::set_component_bytes`.
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
/// Implements `CommandBuffer::remove_component`.
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
/// Queues a builtin GlobalTransform matrix write.
pub fn CommandBuffer::set_global_transform(
  self : CommandBuffer,
  entity : EntityId,
  matrix : @m44.Matrix44F,
) -> Unit {
  let component = self.world.global_transform_component()
  self.assert_component_write(component, "CommandBuffer::set_global_transform")
  self.assert_structural_write_if_missing_component(
    entity, component, "CommandBuffer::set_global_transform",
  )
  self.commands.push(SetGlobalTransform(entity, matrix))
}

///|
/// Queues a builtin GlobalTransform storage format write.
pub fn CommandBuffer::set_global_transform_format(
  self : CommandBuffer,
  entity : EntityId,
  format : @comp.GlobalTransformGpuFormat,
) -> Unit {
  let component = self.world.global_transform_component()
  self.assert_component_write(
    component, "CommandBuffer::set_global_transform_format",
  )
  self.assert_structural_write_if_missing_component(
    entity, component, "CommandBuffer::set_global_transform_format",
  )
  self.commands.push(SetGlobalTransformFormat(entity, format))
}

///|
/// Queues builtin Camera matrices and metadata.
pub fn CommandBuffer::set_camera_matrices(
  self : CommandBuffer,
  entity : EntityId,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Unit {
  let component = self.world.camera_component()
  self.assert_component_write(component, "CommandBuffer::set_camera_matrices")
  self.assert_structural_write_if_missing_component(
    entity, component, "CommandBuffer::set_camera_matrices",
  )
  self.commands.push(
    SetCameraMatrices(
      entity, view, proj, near, far, aspect, projection_kind, flags,
    ),
  )
}

///|
/// Applies one queued command directly to the world.
fn CommandBuffer::apply_command(
  self : CommandBuffer,
  command : WorldCommand,
) -> Bool {
  match command {
    CreateEntity(entity) => self.world.finalize_reserved_entity(entity)
    DestroyEntity(entity) => self.world.destroy_entity(entity)
    AddComponent(entity, component) =>
      self.world.add_component(entity, component)
    AddComponentBytes(entity, component, bytes) =>
      self.world.add_component_bytes(entity, component, bytes)
    SetComponentBytes(entity, component, bytes) =>
      self.world.set_component_bytes(entity, component, bytes)
    RemoveComponent(entity, component) =>
      self.world.remove_component(entity, component)
    SetGlobalTransform(entity, matrix) =>
      self.world.set_global_transform(entity, matrix)
    SetGlobalTransformFormat(entity, format) =>
      self.world.set_global_transform_format(entity, format)
    SetCameraMatrices(
      entity,
      view,
      proj,
      near,
      far,
      aspect,
      projection_kind,
      flags
    ) =>
      self.world.set_camera_matrices(
        entity, view, proj, near, far, aspect, projection_kind, flags,
      )
  }
}

///|
/// Applies one queued command through tracked WorldHistory APIs.
fn CommandBuffer::apply_tracked_command(
  self : CommandBuffer,
  history : WorldHistory,
  command : WorldCommand,
) -> Bool {
  match command {
    CreateEntity(entity) => history.finalize_reserved_entity(self.world, entity)
    DestroyEntity(entity) => history.destroy_entity(self.world, entity)
    AddComponent(entity, component) =>
      history.add_component(self.world, entity, component)
    AddComponentBytes(entity, component, bytes) =>
      history.add_component_bytes(self.world, entity, component, bytes)
    SetComponentBytes(entity, component, bytes) =>
      history.set_component_bytes(self.world, entity, component, bytes)
    RemoveComponent(entity, component) =>
      history.remove_component(self.world, entity, component)
    SetGlobalTransform(entity, matrix) =>
      history.set_global_transform(self.world, entity, matrix)
    SetGlobalTransformFormat(entity, format) =>
      history.set_global_transform_format(self.world, entity, format)
    SetCameraMatrices(
      entity,
      view,
      proj,
      near,
      far,
      aspect,
      projection_kind,
      flags
    ) =>
      history.set_camera_matrices(
        self.world,
        entity,
        view,
        proj,
        near,
        far,
        aspect,
        projection_kind,
        flags,
      )
  }
}

///|
/// Applies commands in insertion order and returns false if any command fails.
fn CommandBuffer::apply(self : CommandBuffer) -> Bool {
  let mut ok = true
  for i = 0; i < self.commands.length(); i = i + 1 {
    if !self.apply_command(self.commands[i]) {
      ok = false
    }
  }
  while self.commands.length() > 0 {
    let _ = self.commands.pop()
  }
  ok
}

///|
/// Applies commands through WorldHistory tracked APIs and returns false on any failure.
fn CommandBuffer::apply_tracked(
  self : CommandBuffer,
  history : WorldHistory,
) -> Bool {
  let mut ok = true
  for i = 0; i < self.commands.length(); i = i + 1 {
    if !self.apply_tracked_command(history, self.commands[i]) {
      ok = false
    }
  }
  while self.commands.length() > 0 {
    let _ = self.commands.pop()
  }
  ok
}

///|
/// Applies commands in insertion order and returns a report for one system buffer.
fn CommandBuffer::apply_report(
  self : CommandBuffer,
  runner_index : Int,
  batch_index : Int,
) -> SystemRunSystemReport {
  let queued_command_count = self.commands.length()
  let mut applied_command_count = 0
  let failures : Array[CommandBufferCommandFailure] = []
  for i = 0; i < self.commands.length(); i = i + 1 {
    let command = self.commands[i]
    let command_ok = self.apply_command(command)
    if command_ok {
      applied_command_count = applied_command_count + 1
    } else {
      failures.push(self.command_failure(command, i))
    }
  }
  while self.commands.length() > 0 {
    let _ = self.commands.pop()
  }
  {
    runner_index,
    batch_index,
    name: self.system_name,
    queued_command_count,
    applied_command_count,
    failed_command_count: failures.length(),
    failures,
  }
}

///|
/// Applies commands through WorldHistory tracked APIs and returns a report.
fn CommandBuffer::apply_tracked_report(
  self : CommandBuffer,
  history : WorldHistory,
  runner_index : Int,
  batch_index : Int,
) -> SystemRunSystemReport {
  let queued_command_count = self.commands.length()
  let mut applied_command_count = 0
  let failures : Array[CommandBufferCommandFailure] = []
  for i = 0; i < self.commands.length(); i = i + 1 {
    let command = self.commands[i]
    let command_ok = self.apply_tracked_command(history, command)
    if command_ok {
      applied_command_count = applied_command_count + 1
    } else {
      failures.push(self.command_failure(command, i))
    }
  }
  while self.commands.length() > 0 {
    let _ = self.commands.pop()
  }
  {
    runner_index,
    batch_index,
    name: self.system_name,
    queued_command_count,
    applied_command_count,
    failed_command_count: failures.length(),
    failures,
  }
}
