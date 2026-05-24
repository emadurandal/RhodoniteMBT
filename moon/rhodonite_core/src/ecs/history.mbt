/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// One component payload captured for a restorable entity snapshot.
priv struct ComponentSnapshot {
  component : ComponentTypeId
  bytes : FixedArray[Byte]
}

///|
/// Entity contents captured before destruction so undo can restore the same id.
priv struct EntitySnapshot {
  entity : EntityId
  components : Array[ComponentSnapshot]
}

///|
/// Minimal reversible ECS mutation recorded by [`WorldHistory`].
priv enum WorldDelta {
  EntityCreated(EntityId)
  EntityDestroyed(EntitySnapshot)
  ComponentAdded(EntityId, ComponentTypeId, FixedArray[Byte])
  ComponentRemoved(EntityId, ComponentTypeId, FixedArray[Byte])
  ComponentChanged(
    EntityId,
    ComponentTypeId,
    FixedArray[Byte],
    FixedArray[Byte]
  )
}

///|
/// One committed user-facing undo/redo transaction.
priv struct WorldHistoryRecord {
  label : String
  deltas : Array[WorldDelta]
}

///|
/// Optional tracked transaction layer for reversible [`World`] mutations.
pub struct WorldHistory {
  priv mut enabled : Bool
  priv mut open : Bool
  priv mut applying : Bool
  priv mut current_label : String
  priv mut current_deltas : Array[WorldDelta]
  priv undo_stack : Array[WorldHistoryRecord]
  priv redo_stack : Array[WorldHistoryRecord]
}

///|
/// Returns true when the component row stores a packed blob reference instead of logical payload.
fn World::history_blob_ref_component(
  self : World,
  component : ComponentTypeId,
) -> Bool {
  component == self.global_transform_component_id ||
  component == self.camera_component_id
}

///|
/// Removes one index from the entity free list when a snapshot restores that slot.
fn remove_free_entity_index(indices : Array[Int], index : Int) -> Unit {
  for i = 0; i < indices.length(); i = i + 1 {
    if indices[i] == index {
      let last = indices.length() - 1
      indices[i] = indices[last]
      let _ = indices.pop()
      return
    }
  }
}

///|
/// Extends entity side tables until `index` can be addressed.
fn World::ensure_entity_slot_exists(self : World, index : Int) -> Unit {
  while self.generations.length() <= index {
    self.generations.push(0)
    self.alive.push(false)
    self.reserved.push(false)
    self.locations.push(None)
  }
}

///|
/// Captures every component row currently owned by `entity`.
fn World::entity_snapshot(self : World, entity : EntityId) -> EntitySnapshot? {
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  let arch = self.archetypes[loc.archetype_index]
  let components : Array[ComponentSnapshot] = []
  for i = 0; i < arch.components.length(); i = i + 1 {
    let component = arch.components[i]
    match arch.component_bytes(loc.row, component) {
      Some(bytes) => components.push({ component, bytes })
      None => ()
    }
  }
  Some({ entity, components })
}

///|
/// Removes a living entity without bumping its generation, used when undoing a create.
fn World::remove_entity_without_generation_bump(
  self : World,
  entity : EntityId,
) -> Bool {
  self.assert_not_querying("World::remove_entity_without_generation_bump")
  self.assert_system_structural_write(
    "World::remove_entity_without_generation_bump",
  )
  if !self.is_alive(entity) {
    return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  self.release_global_transform_ref(entity)
  self.release_camera_ref(entity)
  let moved = self.archetypes[loc.archetype_index].swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  self.alive[entity.index] = false
  self.reserved[entity.index] = false
  self.locations[entity.index] = None
  self.free_indices.push(entity.index)
  true
}

///|
/// Writes one restored component row, allocating fresh blob refs for derived builtin rows.
fn World::restore_component_snapshot(
  self : World,
  arch : Archetype,
  row : Int,
  snapshot : ComponentSnapshot,
) -> Unit {
  let component = snapshot.component
  if component == self.global_transform_component_id {
    let gt_ref = self.alloc_global_transform_ref(
      self.global_transform_default_format,
      @m44.Matrix44F::identity(),
    )
    arch.set_component_bytes(
      row,
      component,
      @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset),
    )
  } else if component == self.camera_component_id {
    let camera_ref = self.alloc_camera_ref(
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (1000.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
    )
    arch.set_component_bytes(
      row,
      component,
      @comp.camera_ref_bytes(camera_ref.word_offset),
    )
  } else {
    arch.set_component_bytes(row, component, snapshot.bytes)
  }
}

///|
/// Restores a dead entity slot with the exact captured `EntityId`.
fn World::restore_entity_snapshot(
  self : World,
  snapshot : EntitySnapshot,
) -> Bool {
  self.assert_not_querying("World::restore_entity_snapshot")
  self.assert_system_structural_write("World::restore_entity_snapshot")
  let entity = snapshot.entity
  if entity.index < 0 {
    return false
  }
  self.ensure_entity_slot_exists(entity.index)
  if self.alive[entity.index] || self.reserved[entity.index] {
    return false
  }
  let components : Array[ComponentTypeId] = []
  for i = 0; i < snapshot.components.length(); i = i + 1 {
    let component = snapshot.components[i].component
    match self.registry.get(component) {
      Some(_) => components.push(component)
      None => return false
    }
  }
  if component_array_has_duplicates(components) {
    return false
  }
  let signature = sorted_component_signature(components)
  let arch_index = self.ensure_archetype(signature)
  let arch = self.archetypes[arch_index]
  let row = arch.push_empty_row(entity)
  self.generations[entity.index] = entity.generation
  self.alive[entity.index] = true
  self.reserved[entity.index] = false
  self.locations[entity.index] = Some({ archetype_index: arch_index, row })
  remove_free_entity_index(self.free_indices, entity.index)
  for i = 0; i < snapshot.components.length(); i = i + 1 {
    self.restore_component_snapshot(arch, row, snapshot.components[i])
  }
  true
}

///|
/// Builds a zero-byte array used as the missing side of component changes.
fn empty_component_bytes() -> FixedArray[Byte] {
  FixedArray::make(0, (0 : Byte))
}

///|
/// Returns whether two deltas address the same component row.
fn world_delta_same_component(
  delta : WorldDelta,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  match delta {
    ComponentAdded(e, c, _)
    | ComponentRemoved(e, c, _)
    | ComponentChanged(e, c, _, _) => e == entity && c == component
    _ => false
  }
}

///|
/// Removes one delta from an array without preserving order after `index`.
fn remove_delta_at(deltas : Array[WorldDelta], index : Int) -> Unit {
  let last = deltas.length() - 1
  for i = index; i < last; i = i + 1 {
    deltas[i] = deltas[i + 1]
  }
  let _ = deltas.pop()
}

///|
/// Pushes a component delta, merging repeated writes inside the current transaction.
fn WorldHistory::push_component_delta(
  self : WorldHistory,
  entity : EntityId,
  component : ComponentTypeId,
  before : FixedArray[Byte],
  after : FixedArray[Byte],
) -> Unit {
  for i = self.current_deltas.length() - 1; i >= 0; i = i - 1 {
    let existing = self.current_deltas[i]
    if !world_delta_same_component(existing, entity, component) {
      continue
    }
    match existing {
      ComponentAdded(_, _, _) =>
        if after.length() == 0 {
          remove_delta_at(self.current_deltas, i)
        } else {
          self.current_deltas[i] = ComponentAdded(entity, component, after)
        }
      ComponentRemoved(_, _, old) =>
        if after.length() == 0 {
          self.current_deltas[i] = ComponentRemoved(entity, component, old)
        } else if old == after {
          remove_delta_at(self.current_deltas, i)
        } else {
          self.current_deltas[i] = ComponentChanged(
            entity, component, old, after,
          )
        }
      ComponentChanged(_, _, old, _) =>
        if after.length() == 0 {
          self.current_deltas[i] = ComponentRemoved(entity, component, old)
        } else if old == after {
          remove_delta_at(self.current_deltas, i)
        } else {
          self.current_deltas[i] = ComponentChanged(
            entity, component, old, after,
          )
        }
      _ => ()
    }
    return
  }
  if before.length() == 0 && after.length() > 0 {
    self.current_deltas.push(ComponentAdded(entity, component, after))
  } else if before.length() > 0 && after.length() == 0 {
    self.current_deltas.push(ComponentRemoved(entity, component, before))
  } else if before.length() > 0 && after.length() > 0 && before != after {
    self.current_deltas.push(ComponentChanged(entity, component, before, after))
  }
}

///|
/// Records a delta into the active transaction.
fn WorldHistory::push_delta(self : WorldHistory, delta : WorldDelta) -> Unit {
  match delta {
    ComponentAdded(entity, component, after) =>
      self.push_component_delta(
        entity,
        component,
        empty_component_bytes(),
        after,
      )
    ComponentRemoved(entity, component, before) =>
      self.push_component_delta(
        entity,
        component,
        before,
        empty_component_bytes(),
      )
    ComponentChanged(entity, component, before, after) =>
      self.push_component_delta(entity, component, before, after)
    _ => self.current_deltas.push(delta)
  }
}

///|
/// Clears the current in-progress transaction without touching world state.
fn WorldHistory::clear_current(self : WorldHistory) -> Unit {
  self.open = false
  self.current_label = ""
  self.current_deltas = []
}

///|
/// Implements `WorldHistory::new`.
pub fn WorldHistory::new() -> WorldHistory {
  {
    enabled: true,
    open: false,
    applying: false,
    current_label: "",
    current_deltas: [],
    undo_stack: [],
    redo_stack: [],
  }
}

///|
/// Implements `WorldHistory::enabled`.
pub fn WorldHistory::enabled(self : WorldHistory) -> Bool {
  self.enabled
}

///|
/// Enables or disables tracking; disabling clears all existing history.
pub fn WorldHistory::set_enabled(self : WorldHistory, enabled : Bool) -> Unit {
  if self.enabled == enabled {
    return
  }
  self.enabled = enabled
  self.clear()
}

///|
/// Drops undo, redo, and open transaction state.
pub fn WorldHistory::clear(self : WorldHistory) -> Unit {
  self.undo_stack.clear()
  self.redo_stack.clear()
  self.clear_current()
}

///|
/// Begins a named transaction if tracking is enabled and no transaction is open.
pub fn WorldHistory::begin_transaction(
  self : WorldHistory,
  label : String,
) -> Bool {
  if !self.enabled || self.open || self.applying {
    return false
  }
  self.open = true
  self.current_label = label
  self.current_deltas = []
  true
}

///|
/// Commits the active transaction and clears redo history.
pub fn WorldHistory::commit_transaction(self : WorldHistory) -> Bool {
  if !self.enabled || !self.open || self.applying {
    return false
  }
  if self.current_deltas.length() > 0 {
    self.undo_stack.push({
      label: self.current_label,
      deltas: self.current_deltas,
    })
    self.redo_stack.clear()
  }
  self.clear_current()
  true
}

///|
/// Cancels the active transaction without reverting already-applied world changes.
pub fn WorldHistory::cancel_transaction(self : WorldHistory) -> Bool {
  if !self.open || self.applying {
    return false
  }
  self.clear_current()
  true
}

///|
/// Implements `WorldHistory::can_undo`.
pub fn WorldHistory::can_undo(self : WorldHistory) -> Bool {
  self.enabled && !self.open && self.undo_stack.length() > 0
}

///|
/// Implements `WorldHistory::can_redo`.
pub fn WorldHistory::can_redo(self : WorldHistory) -> Bool {
  self.enabled && !self.open && self.redo_stack.length() > 0
}

///|
/// Begins an automatic single-operation transaction when needed.
fn WorldHistory::begin_auto(self : WorldHistory, label : String) -> Bool {
  if !self.open {
    ignore(self.begin_transaction(label))
    true
  } else {
    false
  }
}

///|
/// Closes an automatic transaction after a tracked operation.
fn WorldHistory::finish_auto(
  self : WorldHistory,
  auto : Bool,
  ok : Bool,
) -> Unit {
  if !auto {
    return
  }
  if ok {
    ignore(self.commit_transaction())
  } else {
    ignore(self.cancel_transaction())
  }
}

///|
/// Records an entity creation when tracking is active.
fn WorldHistory::record_entity_created(
  self : WorldHistory,
  entity : EntityId,
) -> Unit {
  if self.enabled && self.open && !self.applying {
    self.push_delta(EntityCreated(entity))
  }
}

///|
/// Records an entity destruction when tracking is active.
fn WorldHistory::record_entity_destroyed(
  self : WorldHistory,
  snapshot : EntitySnapshot,
) -> Unit {
  if self.enabled && self.open && !self.applying {
    self.push_delta(EntityDestroyed(snapshot))
  }
}

///|
/// Creates an entity and records the creation in history.
pub fn WorldHistory::create_entity(
  self : WorldHistory,
  world : World,
) -> EntityId {
  if !self.enabled || self.applying {
    return world.create_entity()
  }
  let auto = self.begin_auto("create_entity")
  let entity = world.create_entity()
  self.record_entity_created(entity)
  self.finish_auto(auto, true)
  entity
}

///|
/// Destroys an entity and records a restorable snapshot.
pub fn WorldHistory::destroy_entity(
  self : WorldHistory,
  world : World,
  entity : EntityId,
) -> Bool {
  if !self.enabled || self.applying {
    return world.destroy_entity(entity)
  }
  let snapshot = match world.entity_snapshot(entity) {
    Some(snapshot) => snapshot
    None => return false
  }
  let auto = self.begin_auto("destroy_entity")
  let ok = world.destroy_entity(entity)
  if ok {
    self.record_entity_destroyed(snapshot)
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Adds a component through the history layer.
pub fn WorldHistory::add_component(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  if !self.enabled || self.applying {
    return world.add_component(entity, component)
  }
  if world.has_component(entity, component) {
    return false
  }
  let auto = self.begin_auto("add_component")
  let ok = world.add_component(entity, component)
  if ok {
    match world.component_bytes(entity, component) {
      Some(after) => self.push_delta(ComponentAdded(entity, component, after))
      None => ()
    }
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Adds a component payload through the history layer.
pub fn WorldHistory::add_component_bytes(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.enabled || self.applying {
    return world.add_component_bytes(entity, component, bytes)
  }
  if world.has_component(entity, component) {
    return false
  }
  let auto = self.begin_auto("add_component_bytes")
  let ok = world.add_component_bytes(entity, component, bytes)
  if ok {
    match world.component_bytes(entity, component) {
      Some(after) => self.push_delta(ComponentAdded(entity, component, after))
      None => ()
    }
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Sets a component payload through the history layer.
pub fn WorldHistory::set_component_bytes(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.enabled ||
    self.applying ||
    world.history_blob_ref_component(component) {
    return world.set_component_bytes(entity, component, bytes)
  }
  let before = match world.component_bytes(entity, component) {
    Some(before) => before
    None => return false
  }
  let auto = self.begin_auto("set_component_bytes")
  let ok = world.set_component_bytes(entity, component, bytes)
  if ok {
    match world.component_bytes(entity, component) {
      Some(after) =>
        self.push_delta(ComponentChanged(entity, component, before, after))
      None => ()
    }
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Removes a component through the history layer.
pub fn WorldHistory::remove_component(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  if !self.enabled || self.applying {
    return world.remove_component(entity, component)
  }
  let before = match world.component_bytes(entity, component) {
    Some(before) => before
    None => return false
  }
  let auto = self.begin_auto("remove_component")
  let ok = world.remove_component(entity, component)
  if ok {
    self.push_delta(ComponentRemoved(entity, component, before))
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Sets builtin Transform3D TRS through the history layer.
pub fn WorldHistory::set_transform_trs(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  px : Float,
  py : Float,
  pz : Float,
  qx : Double,
  qy : Double,
  qz : Double,
  qw : Double,
  sx : Float,
  sy : Float,
  sz : Float,
) -> Bool {
  let tf = world.transform_component()
  if !world.has_component(entity, tf) {
    let bytes = @comp.transform3d_trs_bytes(
      px, py, pz, qx, qy, qz, qw, sx, sy, sz,
    )
    self.add_component_bytes(world, entity, tf, bytes)
  } else {
    let bytes = @comp.transform3d_trs_bytes(
      px, py, pz, qx, qy, qz, qw, sx, sy, sz,
    )
    self.set_component_bytes(world, entity, tf, bytes)
  }
}

///|
/// Sets builtin ChildOf through the history layer.
pub fn WorldHistory::set_child_of(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  parent : EntityId,
) -> Bool {
  let component = world.child_of_component()
  let bytes = @comp.ChildOf::new(parent.index, parent.generation).to_component_bytes()
  if world.has_component(entity, component) {
    self.set_component_bytes(world, entity, component, bytes)
  } else {
    self.add_component_bytes(world, entity, component, bytes)
  }
}

///|
/// Applies one delta in redo order.
fn WorldHistory::apply_delta(
  self : WorldHistory,
  world : World,
  delta : WorldDelta,
) -> Bool {
  ignore(self)
  match delta {
    EntityCreated(entity) =>
      world.restore_entity_snapshot({ entity, components: [] })
    EntityDestroyed(snapshot) => world.destroy_entity(snapshot.entity)
    ComponentAdded(entity, component, bytes) =>
      if world.history_blob_ref_component(component) {
        world.add_component(entity, component)
      } else {
        world.add_component_bytes(entity, component, bytes)
      }
    ComponentRemoved(entity, component, _) =>
      world.remove_component(entity, component)
    ComponentChanged(entity, component, _, after) =>
      world.set_component_bytes(entity, component, after)
  }
}

///|
/// Applies one delta in undo order.
fn WorldHistory::apply_delta_inverse(
  self : WorldHistory,
  world : World,
  delta : WorldDelta,
) -> Bool {
  ignore(self)
  match delta {
    EntityCreated(entity) => world.remove_entity_without_generation_bump(entity)
    EntityDestroyed(snapshot) => world.restore_entity_snapshot(snapshot)
    ComponentAdded(entity, component, _) =>
      world.remove_component(entity, component)
    ComponentRemoved(entity, component, before) =>
      if world.history_blob_ref_component(component) {
        world.add_component(entity, component)
      } else {
        world.add_component_bytes(entity, component, before)
      }
    ComponentChanged(entity, component, before, _) =>
      world.set_component_bytes(entity, component, before)
  }
}

///|
/// Undoes the most recent committed transaction.
pub fn WorldHistory::undo(self : WorldHistory, world : World) -> Bool {
  if !self.can_undo() {
    return false
  }
  let record = match self.undo_stack.pop() {
    Some(record) => record
    None => return false
  }
  self.applying = true
  ignore(record.label)
  let mut ok = true
  for i = record.deltas.length() - 1; i >= 0; i = i - 1 {
    if !self.apply_delta_inverse(world, record.deltas[i]) {
      ok = false
    }
  }
  self.applying = false
  if ok {
    self.redo_stack.push(record)
  } else {
    self.clear()
  }
  ok
}

///|
/// Redoes the most recently undone transaction.
pub fn WorldHistory::redo(self : WorldHistory, world : World) -> Bool {
  if !self.can_redo() {
    return false
  }
  let record = match self.redo_stack.pop() {
    Some(record) => record
    None => return false
  }
  self.applying = true
  ignore(record.label)
  let mut ok = true
  for i = 0; i < record.deltas.length(); i = i + 1 {
    if !self.apply_delta(world, record.deltas[i]) {
      ok = false
    }
  }
  self.applying = false
  if ok {
    self.undo_stack.push(record)
  } else {
    self.clear()
  }
  ok
}
