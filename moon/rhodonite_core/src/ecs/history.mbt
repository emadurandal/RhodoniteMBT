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
/// One packed GlobalTransform GPU row captured for history replay.
priv struct GlobalTransformHistoryRow {
  format : @comp.GlobalTransformGpuFormat
  bytes : FixedArray[Byte]
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
  GlobalTransformChanged(
    EntityId,
    GlobalTransformHistoryRow?,
    GlobalTransformHistoryRow
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
/// Whether applying stack limits dropped at least one retained record.
priv struct HistoryTrimResult {
  record_limit : Bool
  byte_limit : Bool
}

///|
/// Optional tracked transaction layer for reversible [`World`] mutations.
pub struct WorldHistory {
  priv mut enabled : Bool
  priv mut max_undo_records : Int
  priv mut max_undo_bytes : Int
  priv mut open : Bool
  priv mut applying : Bool
  priv mut current_label : String
  priv mut current_deltas : Array[WorldDelta]
  priv undo_stack : Array[WorldHistoryRecord]
  priv redo_stack : Array[WorldHistoryRecord]
  priv mut raw_mutation_guard_enabled : Bool
  priv mut guarded_world : World?
  priv mut last_diagnostic : String
}

///|
/// Default maximum number of committed undo records retained by a new history.
fn default_max_undo_records() -> Int {
  100
}

///|
/// Default payload byte budget for a new history; zero means unlimited.
fn default_max_undo_bytes() -> Int {
  0
}

///|
/// Diagnostic code for normal history operation results.
fn history_diagnostic_none() -> String {
  "none"
}

///|
/// Converts a stack-trim result to the public diagnostic code.
fn history_trim_result_diagnostic(result : HistoryTrimResult) -> String {
  if result.record_limit && result.byte_limit {
    "stack_trimmed_limits"
  } else if result.record_limit {
    "stack_trimmed_record_limit"
  } else if result.byte_limit {
    "stack_trimmed_byte_limit"
  } else {
    history_diagnostic_none()
  }
}

///|
/// Returns the captured payload byte count for one entity snapshot.
fn entity_snapshot_payload_bytes(snapshot : EntitySnapshot) -> Int {
  let mut total = 0
  for i = 0; i < snapshot.components.length(); i = i + 1 {
    total = total + snapshot.components[i].bytes.length()
  }
  total
}

///|
/// Returns the captured payload byte count for one delta.
fn world_delta_payload_bytes(delta : WorldDelta) -> Int {
  match delta {
    EntityCreated(_) => 0
    EntityDestroyed(snapshot) => entity_snapshot_payload_bytes(snapshot)
    ComponentAdded(_, _, bytes) => bytes.length()
    ComponentRemoved(_, _, bytes) => bytes.length()
    ComponentChanged(_, _, before, after) => before.length() + after.length()
    GlobalTransformChanged(_, before, after) =>
      match before {
        Some(row) => row.bytes.length() + after.bytes.length()
        None => after.bytes.length()
      }
    CameraChanged(_, before, after) =>
      match before {
        Some(bytes) => bytes.length() + after.length()
        None => after.length()
      }
  }
}

///|
/// Returns the captured payload byte count for one committed history record.
fn world_history_record_payload_bytes(record : WorldHistoryRecord) -> Int {
  let mut total = 0
  for i = 0; i < record.deltas.length(); i = i + 1 {
    total = total + world_delta_payload_bytes(record.deltas[i])
  }
  total
}

///|
/// Returns the captured payload byte count for a history stack.
fn world_history_stack_payload_bytes(
  records : Array[WorldHistoryRecord],
) -> Int {
  let mut total = 0
  for i = 0; i < records.length(); i = i + 1 {
    total = total + world_history_record_payload_bytes(records[i])
  }
  total
}

///|
/// Drops `count` oldest records from a history stack.
fn drop_oldest_history_records(
  records : Array[WorldHistoryRecord],
  count : Int,
) -> Bool {
  if count <= 0 || records.length() == 0 {
    return false
  }
  if count >= records.length() {
    records.clear()
    return true
  }
  let keep = records.length() - count
  for i = 0; i < keep; i = i + 1 {
    records[i] = records[i + count]
  }
  for i = 0; i < count; i = i + 1 {
    let _ = records.pop()
  }
  true
}

///|
/// Counts oldest records that must be dropped to satisfy a byte limit.
fn history_byte_trim_drop_count(
  records : Array[WorldHistoryRecord],
  limit : Int,
) -> Int {
  if limit <= 0 {
    return 0
  }
  let mut total = 0
  let sizes : Array[Int] = []
  for i = 0; i < records.length(); i = i + 1 {
    let size = world_history_record_payload_bytes(records[i])
    sizes.push(size)
    total = total + size
  }
  let mut drop_count = 0
  while drop_count < sizes.length() && total > limit {
    total = total - sizes[drop_count]
    drop_count = drop_count + 1
  }
  drop_count
}

///|
/// Drops oldest records until `count` records remain.
fn trim_history_stack_to_record_count(
  records : Array[WorldHistoryRecord],
  count : Int,
) -> Bool {
  if count <= 0 {
    let trimmed = records.length() > 0
    records.clear()
    return trimmed
  }
  if records.length() <= count {
    return false
  }
  drop_oldest_history_records(records, records.length() - count)
}

///|
/// Drops oldest records until retained payload bytes fit `limit`.
fn trim_history_stack_to_payload_bytes(
  records : Array[WorldHistoryRecord],
  limit : Int,
) -> Bool {
  if limit <= 0 {
    return false
  }
  let drop_count = history_byte_trim_drop_count(records, limit)
  drop_oldest_history_records(records, drop_count)
}

///|
/// Drops the oldest records until the stack fits `limit`.
fn trim_history_stack_to_limit(
  records : Array[WorldHistoryRecord],
  limit : Int,
) -> Bool {
  trim_history_stack_to_record_count(records, limit)
}

///|
/// Drops the oldest records until the stack fits the configured byte budget.
fn trim_history_stack_to_byte_limit(
  records : Array[WorldHistoryRecord],
  limit : Int,
) -> Bool {
  trim_history_stack_to_payload_bytes(records, limit)
}

///|
/// Reports whether new records should be created.
fn WorldHistory::recording_enabled(self : WorldHistory) -> Bool {
  self.enabled && self.max_undo_records > 0
}

///|
/// Trims undo and redo stacks to the configured limits.
fn WorldHistory::trim_stacks_to_limit(self : WorldHistory) -> HistoryTrimResult {
  let undo_record_trimmed = trim_history_stack_to_limit(
    self.undo_stack,
    self.max_undo_records,
  )
  let redo_record_trimmed = trim_history_stack_to_limit(
    self.redo_stack,
    self.max_undo_records,
  )
  let undo_byte_trimmed = trim_history_stack_to_byte_limit(
    self.undo_stack,
    self.max_undo_bytes,
  )
  let redo_byte_trimmed = trim_history_stack_to_byte_limit(
    self.redo_stack,
    self.max_undo_bytes,
  )
  let record_trimmed = undo_record_trimmed || redo_record_trimmed
  let byte_trimmed = undo_byte_trimmed || redo_byte_trimmed
  { record_limit: record_trimmed, byte_limit: byte_trimmed }
}

///|
/// Reports whether `record` can be retained under the configured byte budget.
fn WorldHistory::record_fits_byte_limit(
  self : WorldHistory,
  record : WorldHistoryRecord,
) -> Bool {
  self.max_undo_bytes <= 0 ||
  world_history_record_payload_bytes(record) <= self.max_undo_bytes
}

///|
/// Stores the last public diagnostic code for this history.
fn WorldHistory::set_diagnostic(self : WorldHistory, code : String) -> Unit {
  self.last_diagnostic = code
}

///|
/// Clears the last public diagnostic code after a normal result.
fn WorldHistory::clear_diagnostic(self : WorldHistory) -> Unit {
  self.last_diagnostic = history_diagnostic_none()
}

///|
/// Stores the diagnostic represented by a trim result.
fn WorldHistory::set_trim_diagnostic(
  self : WorldHistory,
  result : HistoryTrimResult,
) -> Unit {
  self.set_diagnostic(history_trim_result_diagnostic(result))
}

///|
/// Stores the diagnostic for a delegated raw mutation result.
fn WorldHistory::set_delegate_diagnostic(
  self : WorldHistory,
  ok : Bool,
  reason : String,
) -> Unit {
  if ok {
    self.set_diagnostic(reason)
  } else {
    self.set_diagnostic("operation_failed")
  }
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
) -> Bool {
  if !self.recording_enabled() || !self.open || self.applying {
    return false
  }
  match self.guarded_world {
    Some(_) => false
    None => {
      world.begin_history_raw_mutation_guard()
      self.guarded_world = Some(world)
      true
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
/// Returns whether a GlobalTransform history row matches its declared format.
fn global_transform_history_row_valid(row : GlobalTransformHistoryRow) -> Bool {
  row.bytes.length() == @comp.global_transform_word_count(row.format) * 4
}

///|
/// Returns whether two GlobalTransform history rows carry the same format and bytes.
fn global_transform_history_row_equal(
  a : GlobalTransformHistoryRow,
  b : GlobalTransformHistoryRow,
) -> Bool {
  a.format == b.format && a.bytes == b.bytes
}

///|
/// Captures the current GlobalTransform blob row for one entity.
fn World::global_transform_history_row(
  self : World,
  entity : EntityId,
) -> GlobalTransformHistoryRow? {
  match self.global_transform_ref(entity) {
    Some(gt_ref) =>
      match
        self.global_transform_blob.read_row_bytes(
          gt_ref.format,
          gt_ref.word_offset,
        ) {
        Some(bytes) => Some({ format: gt_ref.format, bytes })
        None => None
      }
    None => None
  }
}

///|
/// Restores a GlobalTransform blob row, allocating a fresh blob slot.
fn World::restore_global_transform_history_row(
  self : World,
  entity : EntityId,
  row : GlobalTransformHistoryRow,
) -> Bool {
  if !self.is_alive(entity) || !global_transform_history_row_valid(row) {
    return false
  }
  let component = self.global_transform_component()
  let had_component = self.has_component(entity, component)
  if had_component {
    self.release_global_transform_ref(entity)
  }
  let gt_ref = self.alloc_global_transform_ref(
    row.format,
    @m44.Matrix44F::identity(),
  )
  if !self.global_transform_blob.write_row_bytes(
      row.format,
      gt_ref.word_offset,
      row.bytes,
    ) {
    return false
  }
  let ref_bytes = @comp.global_transform_ref_bytes(
    gt_ref.format,
    gt_ref.word_offset,
  )
  if had_component {
    self.set_component_bytes(entity, component, ref_bytes)
  } else {
    self.add_component_bytes(entity, component, ref_bytes)
  }
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
/// Predicted entity state used to validate an undo/redo record before applying it.
priv struct HistoryValidationEntityState {
  entity : EntityId
  alive : Bool
  reserved : Bool
  components : Array[ComponentTypeId]
}

///|
/// Order-aware validation state for simulating one history record.
priv struct HistoryValidationState {
  world : World
  states : Array[HistoryValidationEntityState]
}

///|
/// Returns whether the component is registered in the current world.
fn World::history_component_registered(
  self : World,
  component : ComponentTypeId,
) -> Bool {
  self.registry.get(component) is Some(_)
}

///|
/// Returns whether `bytes` can be written as this component's CPU payload.
fn World::history_component_stride_matches(
  self : World,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  match self.registry.get(component) {
    Some(rc) => bytes.length() == rc.cpu_stride
    None => false
  }
}

///|
/// Copies the currently owned component list for validation.
fn World::history_entity_components(
  self : World,
  entity : EntityId,
) -> Array[ComponentTypeId]? {
  if !self.is_alive(entity) {
    return None
  }
  match self.locations[entity.index] {
    Some(loc) =>
      Some(
        copy_component_array(self.archetypes[loc.archetype_index].components),
      )
    None => None
  }
}

///|
/// Returns whether an entity slot is occupied, regardless of generation.
fn World::history_entity_slot_blocked(self : World, entity : EntityId) -> Bool {
  entity.index >= 0 &&
  entity.index < self.alive.length() &&
  (self.alive[entity.index] || self.reserved[entity.index])
}

///|
/// Creates validation state anchored to the current world.
fn HistoryValidationState::new(world : World) -> HistoryValidationState {
  { world, states: [] }
}

///|
/// Finds a cached predicted entity state.
fn HistoryValidationState::find_state_index(
  self : HistoryValidationState,
  entity : EntityId,
) -> Int {
  for i = 0; i < self.states.length(); i = i + 1 {
    if self.states[i].entity == entity {
      return i
    }
  }
  -1
}

///|
/// Ensures an entity has a predicted state initialized from the current world.
fn HistoryValidationState::ensure_state_index(
  self : HistoryValidationState,
  entity : EntityId,
) -> Int {
  let existing = self.find_state_index(entity)
  if existing >= 0 {
    return existing
  }
  let components = match self.world.history_entity_components(entity) {
    Some(components) => components
    None => []
  }
  let alive = self.world.is_alive(entity)
  self.states.push({
    entity,
    alive,
    reserved: !alive && self.world.history_entity_slot_blocked(entity),
    components,
  })
  self.states.length() - 1
}

///|
/// Replaces one predicted entity state.
fn HistoryValidationState::replace_state(
  self : HistoryValidationState,
  index : Int,
  alive : Bool,
  reserved : Bool,
  components : Array[ComponentTypeId],
) -> Unit {
  let entity = self.states[index].entity
  self.states[index] = { entity, alive, reserved, components }
}

///|
/// Returns the predicted component list with `component` appended.
fn history_components_with_added(
  components : Array[ComponentTypeId],
  component : ComponentTypeId,
) -> Array[ComponentTypeId] {
  let out = copy_component_array(components)
  out.push(component)
  out
}

///|
/// Returns the predicted component list without `component`.
fn history_components_with_removed(
  components : Array[ComponentTypeId],
  component : ComponentTypeId,
) -> Array[ComponentTypeId] {
  let out : Array[ComponentTypeId] = []
  for i = 0; i < components.length(); i = i + 1 {
    if components[i] != component {
      out.push(components[i])
    }
  }
  out
}

///|
/// Validates that a snapshot can be restored, then predicts its entity state.
fn HistoryValidationState::validate_restore_snapshot(
  self : HistoryValidationState,
  snapshot : EntitySnapshot,
) -> Bool {
  if snapshot.entity.index < 0 {
    return false
  }
  let index = self.ensure_state_index(snapshot.entity)
  let state = self.states[index]
  if state.alive || state.reserved {
    return false
  }
  let components : Array[ComponentTypeId] = []
  for i = 0; i < snapshot.components.length(); i = i + 1 {
    let component = snapshot.components[i].component
    if !self.world.history_component_stride_matches(
        component,
        snapshot.components[i].bytes,
      ) {
      return false
    }
    components.push(component)
  }
  if component_array_has_duplicates(components) {
    return false
  }
  self.replace_state(index, true, false, components)
  true
}

///|
/// Validates restoration of an entity created by history without generation rewinding.
fn HistoryValidationState::validate_restore_created_entity(
  self : HistoryValidationState,
  entity : EntityId,
) -> Bool {
  if entity.index < 0 {
    return false
  }
  if entity.index < self.world.generations.length() &&
    self.world.generations[entity.index] != entity.generation {
    return false
  }
  self.validate_restore_snapshot({ entity, components: [] })
}

///|
/// Validates that an entity can be removed, then predicts it as dead.
fn HistoryValidationState::validate_destroy_entity(
  self : HistoryValidationState,
  entity : EntityId,
) -> Bool {
  let index = self.ensure_state_index(entity)
  let state = self.states[index]
  if !state.alive {
    return false
  }
  self.replace_state(index, false, false, [])
  true
}

///|
/// Validates that a component can be added, then predicts the ownership change.
fn HistoryValidationState::validate_add_component(
  self : HistoryValidationState,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.world.history_component_stride_matches(component, bytes) {
    return false
  }
  let index = self.ensure_state_index(entity)
  let state = self.states[index]
  if !state.alive || component_array_contains(state.components, component) {
    return false
  }
  self.replace_state(
    index,
    true,
    false,
    history_components_with_added(state.components, component),
  )
  true
}

///|
/// Validates that a component can be removed, then predicts the ownership change.
fn HistoryValidationState::validate_remove_component(
  self : HistoryValidationState,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  let index = self.ensure_state_index(entity)
  let state = self.states[index]
  if !state.alive || !component_array_contains(state.components, component) {
    return false
  }
  self.replace_state(
    index,
    true,
    false,
    history_components_with_removed(state.components, component),
  )
  true
}

///|
/// Validates that a component payload can be overwritten.
fn HistoryValidationState::validate_set_component(
  self : HistoryValidationState,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.world.history_component_stride_matches(component, bytes) {
    return false
  }
  let index = self.ensure_state_index(entity)
  let state = self.states[index]
  state.alive && component_array_contains(state.components, component)
}

///|
/// Validates that a Camera GPU row can be restored, then predicts Camera ownership.
fn HistoryValidationState::validate_restore_camera(
  self : HistoryValidationState,
  entity : EntityId,
  bytes : FixedArray[Byte],
) -> Bool {
  if bytes.length() != @comp.camera_gpu_byte_stride() {
    return false
  }
  let camera = self.world.camera_component()
  if !self.world.history_component_registered(camera) {
    return false
  }
  let index = self.ensure_state_index(entity)
  let state = self.states[index]
  if !state.alive {
    return false
  }
  if component_array_contains(state.components, camera) {
    true
  } else {
    self.replace_state(
      index,
      true,
      false,
      history_components_with_added(state.components, camera),
    )
    true
  }
}

///|
/// Validates that a GlobalTransform row can be restored, then predicts ownership.
fn HistoryValidationState::validate_restore_global_transform(
  self : HistoryValidationState,
  entity : EntityId,
  row : GlobalTransformHistoryRow,
) -> Bool {
  if !global_transform_history_row_valid(row) {
    return false
  }
  let global_transform = self.world.global_transform_component()
  if !self.world.history_component_registered(global_transform) {
    return false
  }
  let index = self.ensure_state_index(entity)
  let state = self.states[index]
  if !state.alive {
    return false
  }
  if component_array_contains(state.components, global_transform) {
    true
  } else {
    self.replace_state(
      index,
      true,
      false,
      history_components_with_added(state.components, global_transform),
    )
    true
  }
}

///|
/// Validates one redo delta and updates predicted state.
fn HistoryValidationState::validate_delta(
  self : HistoryValidationState,
  delta : WorldDelta,
) -> Bool {
  match delta {
    EntityCreated(entity) => self.validate_restore_created_entity(entity)
    EntityDestroyed(snapshot) => self.validate_destroy_entity(snapshot.entity)
    ComponentAdded(entity, component, bytes) =>
      self.validate_add_component(entity, component, bytes)
    ComponentRemoved(entity, component, _) =>
      self.validate_remove_component(entity, component)
    ComponentChanged(entity, component, _, after) =>
      self.validate_set_component(entity, component, after)
    GlobalTransformChanged(entity, _, after) =>
      self.validate_restore_global_transform(entity, after)
    CameraChanged(entity, _, after) =>
      self.validate_restore_camera(entity, after)
  }
}

///|
/// Validates one undo delta and updates predicted state.
fn HistoryValidationState::validate_delta_inverse(
  self : HistoryValidationState,
  delta : WorldDelta,
) -> Bool {
  match delta {
    EntityCreated(entity) => self.validate_destroy_entity(entity)
    EntityDestroyed(snapshot) => self.validate_restore_snapshot(snapshot)
    ComponentAdded(entity, component, _) =>
      self.validate_remove_component(entity, component)
    ComponentRemoved(entity, component, before) =>
      self.validate_add_component(entity, component, before)
    ComponentChanged(entity, component, before, _) =>
      self.validate_set_component(entity, component, before)
    GlobalTransformChanged(entity, before, _) =>
      match before {
        Some(row) => self.validate_restore_global_transform(entity, row)
        None =>
          self.validate_remove_component(
            entity,
            self.world.global_transform_component(),
          )
      }
    CameraChanged(entity, before, _) =>
      match before {
        Some(bytes) => self.validate_restore_camera(entity, bytes)
        None =>
          self.validate_remove_component(entity, self.world.camera_component())
      }
  }
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
/// Pushes a GlobalTransform row delta, merging repeated writes inside the transaction.
fn WorldHistory::push_global_transform_delta(
  self : WorldHistory,
  entity : EntityId,
  before : GlobalTransformHistoryRow?,
  after : GlobalTransformHistoryRow,
) -> Unit {
  for i = self.current_deltas.length() - 1; i >= 0; i = i - 1 {
    match self.current_deltas[i] {
      GlobalTransformChanged(e, old_before, _) =>
        if e == entity {
          match old_before {
            Some(old) =>
              if global_transform_history_row_equal(old, after) {
                remove_delta_at(self.current_deltas, i)
              } else {
                self.current_deltas[i] = GlobalTransformChanged(
                  entity, old_before, after,
                )
              }
            None =>
              self.current_deltas[i] = GlobalTransformChanged(
                entity, old_before, after,
              )
          }
          return
        }
      _ => ()
    }
  }
  match before {
    Some(old) =>
      if !global_transform_history_row_equal(old, after) {
        self.current_deltas.push(GlobalTransformChanged(entity, before, after))
      }
    None =>
      self.current_deltas.push(GlobalTransformChanged(entity, before, after))
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
    GlobalTransformChanged(entity, before, after) =>
      self.push_global_transform_delta(entity, before, after)
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
    max_undo_bytes: default_max_undo_bytes(),
    open: false,
    applying: false,
    current_label: "",
    current_deltas: [],
    undo_stack: [],
    redo_stack: [],
    raw_mutation_guard_enabled: false,
    guarded_world: None,
    last_diagnostic: history_diagnostic_none(),
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
/// Returns the maximum retained undo payload bytes; zero means unlimited.
pub fn WorldHistory::max_undo_bytes(self : WorldHistory) -> Int {
  self.max_undo_bytes
}

///|
/// Returns the diagnostic code from the most recent history operation.
pub fn WorldHistory::last_diagnostic(self : WorldHistory) -> String {
  self.last_diagnostic
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
    let had_records = self.undo_stack.length() > 0 ||
      self.redo_stack.length() > 0
    self.clear()
    if had_records {
      self.set_diagnostic("stack_trimmed_record_limit")
    }
  } else {
    self.set_trim_diagnostic(self.trim_stacks_to_limit())
  }
}

///|
/// Sets the maximum retained undo payload bytes; zero means unlimited.
pub fn WorldHistory::set_max_undo_bytes(
  self : WorldHistory,
  limit : Int,
) -> Unit {
  if limit < 0 {
    abort("WorldHistory::set_max_undo_bytes: limit must be non-negative")
  }
  self.max_undo_bytes = limit
  self.set_trim_diagnostic(self.trim_stacks_to_limit())
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
    self.clear_diagnostic()
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
  self.clear_diagnostic()
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
/// Returns the payload bytes currently retained on the undo stack.
pub fn WorldHistory::undo_bytes(self : WorldHistory) -> Int {
  world_history_stack_payload_bytes(self.undo_stack)
}

///|
/// Returns the payload bytes currently retained on the redo stack.
pub fn WorldHistory::redo_bytes(self : WorldHistory) -> Int {
  world_history_stack_payload_bytes(self.redo_stack)
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
  if !self.recording_enabled() {
    self.set_diagnostic("recording_disabled")
    return false
  }
  if self.open {
    self.set_diagnostic("transaction_open")
    return false
  }
  if self.applying {
    self.set_diagnostic("applying")
    return false
  }
  self.open = true
  self.current_label = label
  self.current_deltas = []
  self.clear_diagnostic()
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
  if !self.recording_enabled() {
    self.set_diagnostic("recording_disabled")
    return false
  }
  if !self.open {
    self.set_diagnostic("no_open_transaction")
    return false
  }
  if self.applying {
    self.set_diagnostic("applying")
    return false
  }
  if self.current_deltas.length() > 0 {
    let record = { label: self.current_label, deltas: self.current_deltas }
    if self.record_fits_byte_limit(record) {
      self.undo_stack.push(record)
      self.redo_stack.clear()
      self.set_trim_diagnostic(self.trim_stacks_to_limit())
    } else {
      self.redo_stack.clear()
      self.set_diagnostic("record_dropped_byte_limit")
    }
  } else {
    self.set_diagnostic("transaction_empty")
  }
  self.clear_current()
  true
}

///|
/// Cancels the active transaction without reverting already-applied world changes.
pub fn WorldHistory::cancel_transaction(self : WorldHistory) -> Bool {
  if !self.open {
    self.set_diagnostic("no_open_transaction")
    return false
  }
  if self.applying {
    self.set_diagnostic("applying")
    return false
  }
  self.clear_current()
  self.clear_diagnostic()
  true
}

///|
/// Cancels the active transaction and reverts deltas already applied in that transaction.
fn WorldHistory::cancel_transaction_reverting(
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
    self.set_diagnostic("applying")
    return false
  }
  if !self.recording_enabled() {
    let ok = runner.run_phase(world, ctx, phase)
    self.set_delegate_diagnostic(ok, "recording_disabled")
    return ok
  }
  let auto = self.begin_auto(label)
  let forced_guard = self.force_guarded_world(world)
  let ok = runner.run_phase_tracked(world, ctx, phase, self)
  if forced_guard && !self.raw_mutation_guard_enabled {
    self.release_guard()
  }
  self.finish_auto(auto, true)
  if !ok {
    self.set_diagnostic("operation_failed")
  }
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
    GlobalTransformChanged(entity, _, after) =>
      world.restore_global_transform_history_row(entity, after)
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
    GlobalTransformChanged(entity, before, _) =>
      match before {
        Some(row) => world.restore_global_transform_history_row(entity, row)
        None =>
          world.remove_component(entity, world.global_transform_component())
      }
    CameraChanged(entity, before, _) =>
      match before {
        Some(bytes) => world.restore_camera_history_row(entity, bytes)
        None => world.remove_component(entity, world.camera_component())
      }
  }
}

///|
/// Validates the next undo record without mutating world state or history stacks.
fn WorldHistory::validate_record_for_undo(
  self : WorldHistory,
  world : World,
  record : WorldHistoryRecord,
) -> Bool {
  ignore(self)
  let state = HistoryValidationState::new(world)
  for i = record.deltas.length() - 1; i >= 0; i = i - 1 {
    if !state.validate_delta_inverse(record.deltas[i]) {
      return false
    }
  }
  true
}

///|
/// Validates the next redo record without mutating world state or history stacks.
fn WorldHistory::validate_record_for_redo(
  self : WorldHistory,
  world : World,
  record : WorldHistoryRecord,
) -> Bool {
  ignore(self)
  let state = HistoryValidationState::new(world)
  for i = 0; i < record.deltas.length(); i = i + 1 {
    if !state.validate_delta(record.deltas[i]) {
      return false
    }
  }
  true
}

///|
/// Reapplies original deltas that had already been undone before an undo failure.
fn WorldHistory::rollback_applied_undo_deltas(
  self : WorldHistory,
  world : World,
  record : WorldHistoryRecord,
  failed_index : Int,
) -> Bool {
  for i = failed_index + 1; i < record.deltas.length(); i = i + 1 {
    if !self.apply_delta(world, record.deltas[i]) {
      return false
    }
  }
  true
}

///|
/// Applies inverse deltas for redo work that completed before a redo failure.
fn WorldHistory::rollback_applied_redo_deltas(
  self : WorldHistory,
  world : World,
  record : WorldHistoryRecord,
  failed_index : Int,
) -> Bool {
  for i = failed_index - 1; i >= 0; i = i - 1 {
    if !self.apply_delta_inverse(world, record.deltas[i]) {
      return false
    }
  }
  true
}

///|
/// Undoes the most recent committed transaction.
pub fn WorldHistory::undo(self : WorldHistory, world : World) -> Bool {
  if !self.enabled || self.max_undo_records <= 0 {
    self.set_diagnostic("recording_disabled")
    return false
  }
  if self.open {
    self.set_diagnostic("transaction_open")
    return false
  }
  if self.applying {
    self.set_diagnostic("applying")
    return false
  }
  if self.undo_stack.length() == 0 {
    self.set_diagnostic("empty_undo_stack")
    return false
  }
  let next = self.undo_stack[self.undo_stack.length() - 1]
  if !self.validate_record_for_undo(world, next) {
    self.set_diagnostic("validation_failed")
    return false
  }
  let record = next
  self.applying = true
  world.begin_history_tracked_mutation()
  ignore(record.label)
  let mut failed_index = -1
  for i = record.deltas.length() - 1; i >= 0; i = i - 1 {
    if !self.apply_delta_inverse(world, record.deltas[i]) {
      failed_index = i
      break
    }
  }
  let rollback_ok = if failed_index >= 0 {
    self.rollback_applied_undo_deltas(world, record, failed_index)
  } else {
    true
  }
  world.end_history_tracked_mutation()
  self.applying = false
  if failed_index < 0 {
    let record = match self.undo_stack.pop() {
      Some(record) => record
      None => {
        self.set_diagnostic("empty_undo_stack")
        return false
      }
    }
    self.redo_stack.push(record)
    self.set_trim_diagnostic(self.trim_stacks_to_limit())
    true
  } else if rollback_ok {
    self.set_diagnostic("apply_failed_rolled_back")
    false
  } else {
    self.clear()
    self.set_diagnostic("apply_failed")
    false
  }
}

///|
/// Redoes the most recently undone transaction.
pub fn WorldHistory::redo(self : WorldHistory, world : World) -> Bool {
  if !self.enabled || self.max_undo_records <= 0 {
    self.set_diagnostic("recording_disabled")
    return false
  }
  if self.open {
    self.set_diagnostic("transaction_open")
    return false
  }
  if self.applying {
    self.set_diagnostic("applying")
    return false
  }
  if self.redo_stack.length() == 0 {
    self.set_diagnostic("empty_redo_stack")
    return false
  }
  let next = self.redo_stack[self.redo_stack.length() - 1]
  if !self.validate_record_for_redo(world, next) {
    self.set_diagnostic("validation_failed")
    return false
  }
  let record = next
  self.applying = true
  world.begin_history_tracked_mutation()
  ignore(record.label)
  let mut failed_index = -1
  for i = 0; i < record.deltas.length(); i = i + 1 {
    if !self.apply_delta(world, record.deltas[i]) {
      failed_index = i
      break
    }
  }
  let rollback_ok = if failed_index >= 0 {
    self.rollback_applied_redo_deltas(world, record, failed_index)
  } else {
    true
  }
  world.end_history_tracked_mutation()
  self.applying = false
  if failed_index < 0 {
    let record = match self.redo_stack.pop() {
      Some(record) => record
      None => {
        self.set_diagnostic("empty_redo_stack")
        return false
      }
    }
    self.undo_stack.push(record)
    self.set_trim_diagnostic(self.trim_stacks_to_limit())
    true
  } else if rollback_ok {
    self.set_diagnostic("apply_failed_rolled_back")
    false
  } else {
    self.clear()
    self.set_diagnostic("apply_failed")
    false
  }
}
