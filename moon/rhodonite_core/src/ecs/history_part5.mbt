/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Cancels the active transaction and reverts deltas already applied in that transaction.
pub fn WorldHistory::cancel_transaction_reverting(
  self : WorldHistory,
  world : World,
) -> Bool {
  if !self.open {
    self.set_diagnostic("no_open_transaction")
    return false
  }
  if self.applying {
    self.set_diagnostic("applying")
    return false
  }
  self.applying = true
  world.begin_history_tracked_mutation()
  let mut failed = false
  for i = self.current_deltas.length() - 1; i >= 0; i = i - 1 {
    if !self.apply_delta_inverse(world, self.current_deltas[i]) {
      failed = true
      break
    }
  }
  world.end_history_tracked_mutation()
  self.applying = false
  if failed {
    self.clear()
    self.set_diagnostic("apply_failed")
    false
  } else {
    self.clear_current()
    self.clear_diagnostic()
    true
  }
}

///|
/// Runs `body` inside a helper-owned transaction, reverting applied deltas on `false`.
fn WorldHistory::finish_transaction_body(
  self : WorldHistory,
  world : World,
  body : () -> Bool,
) -> Bool {
  let ok = body()
  if ok {
    if self.commit_transaction() {
      true
    } else {
      ignore(self.cancel_transaction_preserving_diagnostic())
      false
    }
  } else {
    ignore(self.cancel_transaction_reverting(world))
    false
  }
}

///|
/// Runs `body` inside a helper-owned transaction, reverting applied deltas on `false`.
pub fn WorldHistory::with_transaction(
  self : WorldHistory,
  world : World,
  label : String,
  body : () -> Bool,
) -> Bool {
  if !self.begin_transaction(label) {
    return false
  }
  self.finish_transaction_body(world, body)
}

///|
/// Runs `body` inside a helper-owned guarded transaction.
pub fn WorldHistory::with_guarded_transaction(
  self : WorldHistory,
  world : World,
  label : String,
  body : () -> Bool,
) -> Bool {
  if !self.begin_guarded_transaction(world, label) {
    return false
  }
  self.finish_transaction_body(world, body)
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
    if ok {
      self.clear_diagnostic()
    } else {
      self.set_diagnostic("operation_failed")
    }
    return
  }
  if ok {
    ignore(self.commit_transaction())
  } else {
    ignore(self.cancel_transaction())
    self.set_diagnostic("operation_failed")
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
    let ok = world.finalize_reserved_entity(entity)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
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
    let entity = world.create_entity()
    self.set_diagnostic(
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return entity
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
/// Creates many entities and records the creations as one history operation.
pub fn WorldHistory::create_entities(
  self : WorldHistory,
  world : World,
  count : Int,
) -> Array[EntityId] {
  if count < 0 {
    abort("WorldHistory::create_entities: count must be non-negative")
  }
  let entities : Array[EntityId] = []
  if count == 0 {
    self.clear_diagnostic()
    return entities
  }
  if !self.recording_enabled() || self.applying {
    for i = 0; i < count; i = i + 1 {
      entities.push(world.create_entity())
    }
    self.set_diagnostic(
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return entities
  }
  let auto = self.begin_auto("create_entities")
  self.begin_tracked_world_mutation(world)
  for i = 0; i < count; i = i + 1 {
    entities.push(world.create_entity())
  }
  self.end_tracked_world_mutation(world)
  for i = 0; i < entities.length(); i = i + 1 {
    self.record_entity_created(entities[i])
  }
  self.finish_auto(auto, true)
  entities
}

///|
/// Records one spawned entity snapshot as creation plus component add deltas.
fn WorldHistory::record_spawned_entity_snapshot(
  self : WorldHistory,
  snapshot : EntitySnapshot,
) -> Unit {
  self.record_entity_created(snapshot.entity)
  for i = 0; i < snapshot.components.length(); i = i + 1 {
    let component = snapshot.components[i].component
    let bytes = snapshot.components[i].bytes
    self.push_delta(ComponentAdded(snapshot.entity, component, bytes))
  }
}

///|
/// Creates many entities directly in an archetype and records their initialized rows.
pub fn WorldHistory::spawn_batch(
  self : WorldHistory,
  world : World,
  components : Array[ComponentTypeId],
  count : Int,
  write : (Int, EntityId, SpawnBatchRow) -> Unit,
) -> Array[EntityId] {
  if count < 0 {
    abort("WorldHistory::spawn_batch: count must be non-negative")
  }
  if component_array_has_duplicates(components) {
    abort("WorldHistory::spawn_batch: duplicate component")
  }
  if count == 0 {
    self.clear_diagnostic()
    return []
  }
  if !self.recording_enabled() || self.applying {
    let entities = world.spawn_batch(components, count, write)
    self.set_delegate_diagnostic(
      entities.length() == count,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return entities
  }
  let auto = self.begin_auto("spawn_batch")
  self.begin_tracked_world_mutation(world)
  let entities = world.spawn_batch(components, count, write)
  self.end_tracked_world_mutation(world)
  let mut ok = entities.length() == count
  if ok {
    let snapshots : Array[EntitySnapshot] = []
    for i = 0; i < entities.length(); i = i + 1 {
      match world.entity_snapshot(entities[i]) {
        Some(snapshot) => snapshots.push(snapshot)
        None => ok = false
      }
    }
    if ok {
      for i = 0; i < snapshots.length(); i = i + 1 {
        self.record_spawned_entity_snapshot(snapshots[i])
      }
    }
  }
  self.finish_auto(auto, ok)
  entities
}

///|
/// Destroys an entity and records a restorable snapshot.
pub fn WorldHistory::destroy_entity(
  self : WorldHistory,
  world : World,
  entity : EntityId,
) -> Bool {
  if !self.recording_enabled() || self.applying {
    let ok = world.destroy_entity(entity)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  let snapshot = match world.entity_snapshot(entity) {
    Some(snapshot) => snapshot
    None => {
      self.set_diagnostic("operation_failed")
      return false
    }
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
    let ok = world.add_component(entity, component)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  if world.has_component(entity, component) {
    self.set_diagnostic("operation_failed")
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
    let ok = world.add_component_bytes(entity, component, bytes)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  if world.has_component(entity, component) {
    self.set_diagnostic("operation_failed")
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
/// Returns whether an entity id appears more than once.
fn entity_array_has_duplicates(entities : Array[EntityId]) -> Bool {
  for i = 0; i < entities.length(); i = i + 1 {
    for j = i + 1; j < entities.length(); j = j + 1 {
      if entities[i] == entities[j] {
        return true
      }
    }
  }
  false
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
    let ok = world.set_component_bytes(entity, component, bytes)
    let reason = if !self.recording_enabled() {
      "recording_disabled"
    } else if self.applying {
      "applying"
    } else {
      history_diagnostic_none()
    }
    self.set_delegate_diagnostic(ok, reason)
    return ok
  }
  let before = match world.component_bytes(entity, component) {
    Some(before) => before
    None => {
      self.set_diagnostic("operation_failed")
      return false
    }
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
/// Adds one component payload to many entities as one atomic history operation.
pub fn WorldHistory::add_component_bytes_many(
  self : WorldHistory,
  world : World,
  component : ComponentTypeId,
  entities : Array[EntityId],
  bytes_list : Array[FixedArray[Byte]],
) -> Bool {
  if entities.length() != bytes_list.length() {
    abort(
      "WorldHistory::add_component_bytes_many: entities and bytes_list length mismatch",
    )
  }
  if entity_array_has_duplicates(entities) {
    self.set_diagnostic("operation_failed")
    return false
  }
  if !self.recording_enabled() || self.applying {
    let mut ok = true
    for i = 0; i < entities.length(); i = i + 1 {
      if !world.add_component_bytes(entities[i], component, bytes_list[i]) {
        ok = false
      }
    }
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  for i = 0; i < entities.length(); i = i + 1 {
    if !world.is_alive(entities[i]) ||
      world.has_component(entities[i], component) ||
      !world.history_component_stride_matches(component, bytes_list[i]) {
      self.set_diagnostic("operation_failed")
      return false
    }
  }
  let auto = self.begin_auto("add_component_bytes_many")
  self.begin_tracked_world_mutation(world)
  let mut ok = true
  for i = 0; i < entities.length(); i = i + 1 {
    if !world.add_component_bytes(entities[i], component, bytes_list[i]) {
      ok = false
    }
  }
  self.end_tracked_world_mutation(world)
  if ok {
    let after_list : Array[FixedArray[Byte]] = []
    for i = 0; i < entities.length(); i = i + 1 {
      match world.component_bytes(entities[i], component) {
        Some(after) => after_list.push(after)
        None => ok = false
      }
    }
    if ok {
      for i = 0; i < entities.length(); i = i + 1 {
        self.push_delta(ComponentAdded(entities[i], component, after_list[i]))
      }
    }
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Sets one component payload for many entities as one atomic history operation.
pub fn WorldHistory::set_component_bytes_many(
  self : WorldHistory,
  world : World,
  component : ComponentTypeId,
  entities : Array[EntityId],
  bytes_list : Array[FixedArray[Byte]],
) -> Bool {
  if entities.length() != bytes_list.length() {
    abort(
      "WorldHistory::set_component_bytes_many: entities and bytes_list length mismatch",
    )
  }
  if entity_array_has_duplicates(entities) {
    self.set_diagnostic("operation_failed")
    return false
  }
  if !self.recording_enabled() ||
    self.applying ||
    world.history_blob_ref_component(component) {
    let mut ok = true
    for i = 0; i < entities.length(); i = i + 1 {
      if !world.set_component_bytes(entities[i], component, bytes_list[i]) {
        ok = false
      }
    }
    let reason = if !self.recording_enabled() {
      "recording_disabled"
    } else if self.applying {
      "applying"
    } else {
      history_diagnostic_none()
    }
    self.set_delegate_diagnostic(ok, reason)
    return ok
  }
  let before_list : Array[FixedArray[Byte]] = []
  for i = 0; i < entities.length(); i = i + 1 {
    let before = match world.component_bytes(entities[i], component) {
      Some(bytes) => bytes
      None => {
        self.set_diagnostic("operation_failed")
        return false
      }
    }
    if before.length() != bytes_list[i].length() {
      self.set_diagnostic("operation_failed")
      return false
    }
    before_list.push(before)
  }
  let auto = self.begin_auto("set_component_bytes_many")
  self.begin_tracked_world_mutation(world)
  let mut ok = true
  for i = 0; i < entities.length(); i = i + 1 {
    if !world.set_component_bytes(entities[i], component, bytes_list[i]) {
      ok = false
    }
  }
  self.end_tracked_world_mutation(world)
  if ok {
    let after_list : Array[FixedArray[Byte]] = []
    for i = 0; i < entities.length(); i = i + 1 {
      match world.component_bytes(entities[i], component) {
        Some(after) => after_list.push(after)
        None => ok = false
      }
    }
    if ok {
      for i = 0; i < entities.length(); i = i + 1 {
        self.push_delta(
          ComponentChanged(
            entities[i],
            component,
            before_list[i],
            after_list[i],
          ),
        )
      }
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
    let ok = world.remove_component(entity, component)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  let before = match world.component_bytes(entity, component) {
    Some(before) => before
    None => {
      self.set_diagnostic("operation_failed")
      return false
    }
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
/// Sets builtin GlobalTransform through the history layer.
pub fn WorldHistory::set_global_transform(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  matrix : @m44.Matrix44F,
) -> Bool {
  if !self.recording_enabled() || self.applying {
    let ok = world.set_global_transform(entity, matrix)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  let global_transform = world.global_transform_component()
  let before = if world.has_component(entity, global_transform) {
    match world.global_transform_history_row(entity) {
      Some(row) => Some(row)
      None => {
        self.set_diagnostic("operation_failed")
        return false
      }
    }
  } else {
    None
  }
  let auto = self.begin_auto("set_global_transform")
  self.begin_tracked_world_mutation(world)
  let ok = world.set_global_transform(entity, matrix)
  self.end_tracked_world_mutation(world)
  if ok {
    match world.global_transform_history_row(entity) {
      Some(after) =>
        self.push_delta(GlobalTransformChanged(entity, before, after))
      None => ()
    }
  }
  self.finish_auto(auto, ok)
  ok
}

///|
/// Sets builtin GlobalTransform storage format through the history layer.
pub fn WorldHistory::set_global_transform_format(
  self : WorldHistory,
  world : World,
  entity : EntityId,
  format : @comp.GlobalTransformGpuFormat,
) -> Bool {
  if !self.recording_enabled() || self.applying {
    let ok = world.set_global_transform_format(entity, format)
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  let global_transform = world.global_transform_component()
  let before = if world.has_component(entity, global_transform) {
    match world.global_transform_history_row(entity) {
      Some(row) => Some(row)
      None => {
        self.set_diagnostic("operation_failed")
        return false
      }
    }
  } else {
    None
  }
  let auto = self.begin_auto("set_global_transform_format")
  self.begin_tracked_world_mutation(world)
  let ok = world.set_global_transform_format(entity, format)
  self.end_tracked_world_mutation(world)
  if ok {
    match world.global_transform_history_row(entity) {
      Some(after) =>
        self.push_delta(GlobalTransformChanged(entity, before, after))
      None => ()
    }
  }
  self.finish_auto(auto, ok)
  ok
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
    let ok = world.set_camera_matrices(
      entity, view, proj, near, far, aspect, projection_kind, flags,
    )
    self.set_delegate_diagnostic(
      ok,
      if self.applying {
        "applying"
      } else {
        "recording_disabled"
      },
    )
    return ok
  }
  let camera = world.camera_component()
  let before = if world.has_component(entity, camera) {
    match world.camera_gpu_row(entity) {
      Some(bytes) => Some(bytes)
      None => {
        self.set_diagnostic("operation_failed")
        return false
      }
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
