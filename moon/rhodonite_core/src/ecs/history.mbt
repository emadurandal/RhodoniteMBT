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
  CameraChanged(EntityId, FixedArray[Byte]?, FixedArray[Byte])
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
  priv mut max_undo_records : Int
  priv mut open : Bool
  priv mut applying : Bool
  priv mut current_label : String
  priv mut current_deltas : Array[WorldDelta]
  priv undo_stack : Array[WorldHistoryRecord]
  priv redo_stack : Array[WorldHistoryRecord]
  priv mut raw_mutation_guard_enabled : Bool
  priv mut guarded_world : World?
}

///|
/// Default maximum number of committed undo records retained by a new history.
fn default_max_undo_records() -> Int {
  100
}

///|
/// Drops the oldest records until the stack fits `limit`.
fn trim_history_stack_to_limit(
  records : Array[WorldHistoryRecord],
  limit : Int,
) -> Unit {
  if limit <= 0 {
    records.clear()
    return
  }
  while records.length() > limit {
    let last = records.length() - 1
    for i = 0; i < last; i = i + 1 {
      records[i] = records[i + 1]
    }
    let _ = records.pop()
  }
}

///|
/// Reports whether new records should be created.
fn WorldHistory::recording_enabled(self : WorldHistory) -> Bool {
  self.enabled && self.max_undo_records > 0
}

///|
/// Trims undo and redo stacks to the configured record limit.
fn WorldHistory::trim_stacks_to_limit(self : WorldHistory) -> Unit {
  trim_history_stack_to_limit(self.undo_stack, self.max_undo_records)
  trim_history_stack_to_limit(self.redo_stack, self.max_undo_records)
}

///|
/// Releases the raw mutation guard currently armed on a world.
fn WorldHistory::release_guard(self : WorldHistory) -> Unit {
  match self.guarded_world {
    Some(world) => {
      world.end_history_raw_mutation_guard()
      self.guarded_world = None
    }
    None => ()
  }
}

///|
/// Arms the raw mutation guard for this transaction if requested.
fn WorldHistory::ensure_guarded_world(
  self : WorldHistory,
  world : World,
) -> Unit {
  if !self.raw_mutation_guard_enabled ||
    !self.recording_enabled() ||
    !self.open ||
    self.applying {
    return
  }
  match self.guarded_world {
    Some(_) => ()
    None => {
      world.begin_history_raw_mutation_guard()
      self.guarded_world = Some(world)
    }
  }
}

///|
/// Arms the raw mutation guard even when the optional public guard flag is off.
fn WorldHistory::force_guarded_world(
  self : WorldHistory,
  world : World,
) -> Unit {
  if !self.recording_enabled() || !self.open || self.applying {
    return
  }
  match self.guarded_world {
    Some(_) => ()
    None => {
      world.begin_history_raw_mutation_guard()
      self.guarded_world = Some(world)
    }
  }
}

///|
/// Opens a tracked mutation bypass used by WorldHistory methods.
fn WorldHistory::begin_tracked_world_mutation(
  self : WorldHistory,
  world : World,
) -> Unit {
  self.ensure_guarded_world(world)
  world.begin_history_tracked_mutation()
}

///|
/// Closes a tracked mutation bypass used by WorldHistory methods.
fn WorldHistory::end_tracked_world_mutation(
  self : WorldHistory,
  world : World,
) -> Unit {
  ignore(self)
  world.end_history_tracked_mutation()
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
/// Ensures the entity has Camera and writes the captured GPU row bytes.
fn World::restore_camera_history_row(
  self : World,
  entity : EntityId,
  bytes : FixedArray[Byte],
) -> Bool {
  let camera = self.camera_component()
  if !self.has_component(entity, camera) && !self.add_component(entity, camera) {
    return false
  }
  self.write_camera_gpu_row_bytes(entity, bytes)
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
/// Pushes a Camera row delta, merging repeated matrix writes inside the transaction.
fn WorldHistory::push_camera_delta(
  self : WorldHistory,
  entity : EntityId,
  before : FixedArray[Byte]?,
  after : FixedArray[Byte],
) -> Unit {
  for i = self.current_deltas.length() - 1; i >= 0; i = i - 1 {
    match self.current_deltas[i] {
      CameraChanged(e, old_before, _) =>
        if e == entity {
          match old_before {
            Some(old) =>
              if old == after {
                remove_delta_at(self.current_deltas, i)
              } else {
                self.current_deltas[i] = CameraChanged(
                  entity, old_before, after,
                )
              }
            None =>
              self.current_deltas[i] = CameraChanged(entity, old_before, after)
          }
          return
        }
      _ => ()
    }
  }
  match before {
    Some(old) =>
      if old != after {
        self.current_deltas.push(CameraChanged(entity, before, after))
      }
    None => self.current_deltas.push(CameraChanged(entity, before, after))
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
    CameraChanged(entity, before, after) =>
      self.push_camera_delta(entity, before, after)
    _ => self.current_deltas.push(delta)
  }
}

///|
/// Clears the current in-progress transaction without touching world state.
fn WorldHistory::clear_current(self : WorldHistory) -> Unit {
  self.release_guard()
  self.open = false
  self.current_label = ""
  self.current_deltas = []
}

///|
/// Implements `WorldHistory::new`.
pub fn WorldHistory::new() -> WorldHistory {
  {
    enabled: true,
    max_undo_records: default_max_undo_records(),
    open: false,
    applying: false,
    current_label: "",
    current_deltas: [],
    undo_stack: [],
    redo_stack: [],
    raw_mutation_guard_enabled: false,
    guarded_world: None,
  }
}

///|
/// Implements `WorldHistory::enabled`.
pub fn WorldHistory::enabled(self : WorldHistory) -> Bool {
  self.enabled
}

///|
/// Returns the maximum number of undo records retained by this history.
pub fn WorldHistory::max_undo_records(self : WorldHistory) -> Int {
  self.max_undo_records
}

///|
/// Sets the maximum number of undo records; zero clears history and disables recording.
pub fn WorldHistory::set_max_undo_records(
  self : WorldHistory,
  limit : Int,
) -> Unit {
  if limit < 0 {
    abort("WorldHistory::set_max_undo_records: limit must be non-negative")
  }
  self.max_undo_records = limit
  if limit == 0 {
    self.clear()
  } else {
    self.trim_stacks_to_limit()
  }
}

///|
/// Returns whether guarded transactions reject raw World mutations.
pub fn WorldHistory::raw_mutation_guard_enabled(self : WorldHistory) -> Bool {
  self.raw_mutation_guard_enabled
}

///|
/// Enables or disables guarded transaction raw mutation checks.
pub fn WorldHistory::set_raw_mutation_guard_enabled(
  self : WorldHistory,
  enabled : Bool,
) -> Unit {
  if self.raw_mutation_guard_enabled == enabled {
    return
  }
  self.raw_mutation_guard_enabled = enabled
  if !enabled {
    self.release_guard()
  }
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
/// Returns the number of committed undo records currently retained.
pub fn WorldHistory::undo_len(self : WorldHistory) -> Int {
  self.undo_stack.length()
}

///|
/// Returns the number of committed redo records currently retained.
pub fn WorldHistory::redo_len(self : WorldHistory) -> Int {
  self.redo_stack.length()
}

///|
/// Returns the label for the next undoable record, when undo is currently available.
pub fn WorldHistory::undo_label(self : WorldHistory) -> String? {
  if !self.can_undo() {
    return None
  }
  Some(self.undo_stack[self.undo_stack.length() - 1].label)
}

///|
/// Returns the label for the next redoable record, when redo is currently available.
pub fn WorldHistory::redo_label(self : WorldHistory) -> String? {
  if !self.can_redo() {
    return None
  }
  Some(self.redo_stack[self.redo_stack.length() - 1].label)
}

///|
/// Begins a named transaction if tracking is enabled and no transaction is open.
pub fn WorldHistory::begin_transaction(
  self : WorldHistory,
  label : String,
) -> Bool {
  if !self.recording_enabled() || self.open || self.applying {
    return false
  }
  self.open = true
  self.current_label = label
  self.current_deltas = []
  true
}

///|
/// Begins a named transaction and arms the raw mutation guard for `world` when enabled.
pub fn WorldHistory::begin_guarded_transaction(
  self : WorldHistory,
  world : World,
  label : String,
) -> Bool {
  if !self.begin_transaction(label) {
    return false
  }
  self.ensure_guarded_world(world)
  true
}

///|
/// Commits the active transaction and clears redo history.
pub fn WorldHistory::commit_transaction(self : WorldHistory) -> Bool {
  if !self.recording_enabled() || !self.open || self.applying {
    return false
  }
  if self.current_deltas.length() > 0 {
    self.undo_stack.push({
      label: self.current_label,
      deltas: self.current_deltas,
    })
    self.trim_stacks_to_limit()
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
    self.begin_transaction(label)
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
  if self.recording_enabled() && self.open && !self.applying {
    self.push_delta(EntityCreated(entity))
  }
}

///|
/// Records an entity destruction when tracking is active.
fn WorldHistory::record_entity_destroyed(
  self : WorldHistory,
  snapshot : EntitySnapshot,
) -> Unit {
  if self.recording_enabled() && self.open && !self.applying {
    self.push_delta(EntityDestroyed(snapshot))
  }
}

///|
/// Reserves an entity id for a tracked command-buffer create.
fn WorldHistory::reserve_entity_for_command(
  self : WorldHistory,
  world : World,
) -> EntityId {
  self.begin_tracked_world_mutation(world)
  let entity = world.reserve_entity_for_command()
  self.end_tracked_world_mutation(world)
  entity
}

///|
/// Finalizes a reserved entity and records the creation in history.
fn WorldHistory::finalize_reserved_entity(
  self : WorldHistory,
  world : World,
  entity : EntityId,
) -> Bool {
  if !self.recording_enabled() || self.applying {
    return world.finalize_reserved_entity(entity)
  }
  let auto = self.begin_auto("finalize_reserved_entity")
  self.begin_tracked_world_mutation(world)
  let ok = world.finalize_reserved_entity(entity)
  self.end_tracked_world_mutation(world)
  if ok {
    self.record_entity_created(entity)
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Creates an entity and records the creation in history.
pub fn WorldHistory::create_entity(
  self : WorldHistory,
  world : World,
) -> EntityId {
  if !self.recording_enabled() || self.applying {
    return world.create_entity()
  }
  let auto = self.begin_auto("create_entity")
  self.begin_tracked_world_mutation(world)
  let entity = world.create_entity()
  self.end_tracked_world_mutation(world)
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
  if !self.recording_enabled() || self.applying {
    return world.destroy_entity(entity)
  }
  let snapshot = match world.entity_snapshot(entity) {
    Some(snapshot) => snapshot
    None => return false
  }
  let auto = self.begin_auto("destroy_entity")
  self.begin_tracked_world_mutation(world)
  let ok = world.destroy_entity(entity)
  self.end_tracked_world_mutation(world)
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
  if !self.recording_enabled() || self.applying {
    return world.add_component(entity, component)
  }
  if world.has_component(entity, component) {
    return false
  }
  let auto = self.begin_auto("add_component")
  self.begin_tracked_world_mutation(world)
  let ok = world.add_component(entity, component)
  self.end_tracked_world_mutation(world)
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
  if !self.recording_enabled() || self.applying {
    return world.add_component_bytes(entity, component, bytes)
  }
  if world.has_component(entity, component) {
    return false
  }
  let auto = self.begin_auto("add_component_bytes")
  self.begin_tracked_world_mutation(world)
  let ok = world.add_component_bytes(entity, component, bytes)
  self.end_tracked_world_mutation(world)
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
  if !self.recording_enabled() ||
    self.applying ||
    world.history_blob_ref_component(component) {
    return world.set_component_bytes(entity, component, bytes)
  }
  let before = match world.component_bytes(entity, component) {
    Some(before) => before
    None => return false
  }
  let auto = self.begin_auto("set_component_bytes")
  self.begin_tracked_world_mutation(world)
  let ok = world.set_component_bytes(entity, component, bytes)
  self.end_tracked_world_mutation(world)
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
  if !self.recording_enabled() || self.applying {
    return world.remove_component(entity, component)
  }
  let before = match world.component_bytes(entity, component) {
    Some(before) => before
    None => return false
  }
  let auto = self.begin_auto("remove_component")
  self.begin_tracked_world_mutation(world)
  let ok = world.remove_component(entity, component)
  self.end_tracked_world_mutation(world)
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
/// Sets builtin Camera matrices through the history layer.
pub fn WorldHistory::set_camera_matrices(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  if !self.recording_enabled() || self.applying {
    return world.set_camera_matrices(
      entity, view, proj, near, far, aspect, projection_kind, flags,
    )
  }
  let camera = world.camera_component()
  let before = if world.has_component(entity, camera) {
    match world.camera_gpu_row(entity) {
      Some(bytes) => Some(bytes)
      None => return false
    }
  } else {
    None
  }
  let auto = self.begin_auto("set_camera_matrices")
  self.begin_tracked_world_mutation(world)
  let ok = world.set_camera_matrices(
    entity, view, proj, near, far, aspect, projection_kind, flags,
  )
  self.end_tracked_world_mutation(world)
  if ok {
    match world.camera_gpu_row(entity) {
      Some(after) => self.push_delta(CameraChanged(entity, before, after))
      None => ()
    }
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Runs one system phase with command-buffer mutations recorded in history.
pub fn WorldHistory::run_system_phase(
  self : WorldHistory,
  runner : SystemRunner,
  world : World,
  ctx : SystemContext,
  phase : PhaseKey,
  label : String,
) -> Bool {
  if self.applying {
    return false
  }
  if !self.recording_enabled() {
    return runner.run_phase(world, ctx, phase)
  }
  let auto = self.begin_auto(label)
  self.force_guarded_world(world)
  let ok = runner.run_phase_tracked(world, ctx, phase, self)
  self.finish_auto(auto, true)
  ok
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
    CameraChanged(entity, _, after) =>
      world.restore_camera_history_row(entity, after)
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
    CameraChanged(entity, before, _) =>
      match before {
        Some(bytes) => world.restore_camera_history_row(entity, bytes)
        None => world.remove_component(entity, world.camera_component())
      }
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
  world.begin_history_tracked_mutation()
  ignore(record.label)
  let mut ok = true
  for i = record.deltas.length() - 1; i >= 0; i = i - 1 {
    if !self.apply_delta_inverse(world, record.deltas[i]) {
      ok = false
    }
  }
  world.end_history_tracked_mutation()
  self.applying = false
  if ok {
    self.redo_stack.push(record)
    self.trim_stacks_to_limit()
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
  world.begin_history_tracked_mutation()
  ignore(record.label)
  let mut ok = true
  for i = 0; i < record.deltas.length(); i = i + 1 {
    if !self.apply_delta(world, record.deltas[i]) {
      ok = false
    }
  }
  world.end_history_tracked_mutation()
  self.applying = false
  if ok {
    self.undo_stack.push(record)
    self.trim_stacks_to_limit()
  } else {
    self.clear()
  }
  ok
}
