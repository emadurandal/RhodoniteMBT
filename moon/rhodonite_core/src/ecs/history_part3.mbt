/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Returns the archive delta index that makes an imported undo record invalid.
fn HistoryValidationState::imported_undo_record_invalid_delta_index(
  self : HistoryValidationState,
  record : WorldHistoryRecord,
) -> Int? {
  for i = record.deltas.length() - 1; i >= 0; i = i - 1 {
    if !self.validate_delta_inverse(record.deltas[i]) {
      return Some(i)
    }
  }
  None
}

///|
/// Returns the archive delta index that makes an imported redo record invalid.
fn HistoryValidationState::imported_redo_record_invalid_delta_index(
  self : HistoryValidationState,
  record : WorldHistoryRecord,
) -> Int? {
  for i = 0; i < record.deltas.length(); i = i + 1 {
    if !self.validate_delta(record.deltas[i]) {
      return Some(i)
    }
  }
  None
}

///|
/// Returns the first record and delta index that makes an imported stack invalid.
fn world_history_imported_stack_invalid_location(
  world : World,
  records : Array[WorldHistoryRecord],
  undo : Bool,
) -> (Int, Int)? {
  let state = HistoryValidationState::new(world)
  for i = 0; i < records.length(); i = i + 1 {
    let invalid_delta = if undo {
      state.imported_undo_record_invalid_delta_index(records[i])
    } else {
      state.imported_redo_record_invalid_delta_index(records[i])
    }
    match invalid_delta {
      Some(delta_index) => return Some((i, delta_index))
      None => ()
    }
  }
  None
}

///|
/// Marks one record report suffix as failed by the full-stack import validation pass.
fn world_history_import_validation_failed_record_report_from_delta(
  report : WorldHistoryImportValidationRecordReport,
  delta_index : Int,
  undo : Bool,
) -> WorldHistoryImportValidationRecordReport {
  let deltas : Array[WorldHistoryImportValidationDeltaReport] = []
  for i = 0; i < report.deltas.length(); i = i + 1 {
    let failed = if undo { i <= delta_index } else { i >= delta_index }
    if failed {
      deltas.push(
        world_history_import_validation_failed_delta_report(report.deltas[i]),
      )
    } else {
      deltas.push(report.deltas[i])
    }
  }
  {
    index: report.index,
    label: report.label,
    valid: false,
    reason: history_import_diagnostic_validation_failed(),
    delta_count: report.delta_count,
    deltas,
  }
}

///|
/// Marks a whole record report as failed by the full-stack import validation pass.
fn world_history_import_validation_failed_record_report(
  report : WorldHistoryImportValidationRecordReport,
) -> WorldHistoryImportValidationRecordReport {
  let deltas : Array[WorldHistoryImportValidationDeltaReport] = []
  for i = 0; i < report.deltas.length(); i = i + 1 {
    deltas.push(
      world_history_import_validation_failed_delta_report(report.deltas[i]),
    )
  }
  {
    index: report.index,
    label: report.label,
    valid: false,
    reason: history_import_diagnostic_validation_failed(),
    delta_count: report.delta_count,
    deltas,
  }
}

///|
/// Marks one import stack result as failed by the full-stack validation pass.
fn world_history_import_stack_result_validation_failed(
  imported : WorldHistoryImportStackResult,
  record_index : Int,
  delta_index : Int,
  undo : Bool,
) -> WorldHistoryImportStackResult {
  let record_reports : Array[WorldHistoryImportValidationRecordReport] = []
  for i = 0; i < imported.report.records.length(); i = i + 1 {
    if i == record_index {
      record_reports.push(
        world_history_import_validation_failed_record_report_from_delta(
          imported.report.records[i],
          delta_index,
          undo,
        ),
      )
    } else if i > record_index {
      record_reports.push(
        world_history_import_validation_failed_record_report(
          imported.report.records[i],
        ),
      )
    } else {
      record_reports.push(imported.report.records[i])
    }
  }
  {
    records: imported.records,
    diagnostic: history_import_diagnostic_validation_failed(),
    ok: false,
    report: {
      valid: false,
      reason: history_import_diagnostic_validation_failed(),
      format_version: imported.report.format_version,
      record_count: imported.report.record_count,
      records: record_reports,
    },
  }
}

///|
/// Replaces a stack from next-operation-first records.
fn replace_history_stack_from_next_first(
  stack : Array[WorldHistoryRecord],
  records : Array[WorldHistoryRecord],
) -> Unit {
  stack.clear()
  for i = records.length() - 1; i >= 0; i = i - 1 {
    stack.push(records[i])
  }
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
  self.invalidate_transform_hierarchy_index()
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
    self.mark_transform_dirty_for_component(
      entity,
      snapshot.components[i].component,
    )
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
