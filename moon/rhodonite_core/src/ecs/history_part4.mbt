/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

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
/// Builds a transaction index key for one component-row delta.
fn history_component_delta_index_key(
  entity : EntityId,
  component : ComponentTypeId,
) -> HistoryComponentDeltaIndexKey {
  {
    entity_index: entity.index,
    entity_generation: entity.generation,
    component_index: component.index,
  }
}

///|
/// Builds a transaction index key for one entity-scoped builtin delta.
fn history_entity_delta_index_key(
  entity : EntityId,
) -> HistoryEntityDeltaIndexKey {
  { entity_index: entity.index, entity_generation: entity.generation }
}

///|
/// Creates an empty component-delta transaction index.
fn new_component_delta_index() -> @hashmap.HashMap[
  HistoryComponentDeltaIndexKey,
  Int,
] {
  @hashmap.HashMap([])
}

///|
/// Creates an empty entity-delta transaction index.
fn new_entity_delta_index() -> @hashmap.HashMap[HistoryEntityDeltaIndexKey, Int] {
  @hashmap.HashMap([])
}

///|
/// Clears every transaction-local delta index.
fn WorldHistory::clear_current_delta_indices(self : WorldHistory) -> Unit {
  self.current_component_delta_index.clear()
  self.current_camera_delta_index.clear()
  self.current_global_transform_delta_index.clear()
}

///|
/// Indexes one current delta by its merge key when it is mergeable.
fn WorldHistory::index_current_delta_at(
  self : WorldHistory,
  index : Int,
) -> Unit {
  match self.current_deltas[index] {
    ComponentAdded(entity, component, _)
    | ComponentRemoved(entity, component, _)
    | ComponentChanged(entity, component, _, _) =>
      self.current_component_delta_index.set(
        history_component_delta_index_key(entity, component),
        index,
      )
    CameraChanged(entity, _, _) =>
      self.current_camera_delta_index.set(
        history_entity_delta_index_key(entity),
        index,
      )
    GlobalTransformChanged(entity, _, _) =>
      self.current_global_transform_delta_index.set(
        history_entity_delta_index_key(entity),
        index,
      )
    _ => ()
  }
}

///|
/// Rebuilds transaction-local indexes from `current_deltas`.
fn WorldHistory::rebuild_current_delta_indices(self : WorldHistory) -> Unit {
  self.clear_current_delta_indices()
  for i = 0; i < self.current_deltas.length(); i = i + 1 {
    self.index_current_delta_at(i)
  }
}

///|
/// Pushes one current delta and indexes it when it is mergeable.
fn WorldHistory::push_current_delta(
  self : WorldHistory,
  delta : WorldDelta,
) -> Unit {
  let index = self.current_deltas.length()
  self.current_deltas.push(delta)
  self.index_current_delta_at(index)
}

///|
/// Removes one current delta, preserving order and refreshing merge indexes.
fn WorldHistory::remove_current_delta_at(
  self : WorldHistory,
  index : Int,
) -> Unit {
  let last = self.current_deltas.length() - 1
  for i = index; i < last; i = i + 1 {
    self.current_deltas[i] = self.current_deltas[i + 1]
  }
  let _ = self.current_deltas.pop()
  self.rebuild_current_delta_indices()
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
  match
    self.current_component_delta_index.get(
      history_component_delta_index_key(entity, component),
    ) {
    Some(i) =>
      match self.current_deltas[i] {
        ComponentAdded(_, _, _) =>
          if after.length() == 0 {
            self.remove_current_delta_at(i)
          } else {
            self.current_deltas[i] = ComponentAdded(entity, component, after)
          }
        ComponentRemoved(_, _, old) =>
          if after.length() == 0 {
            self.current_deltas[i] = ComponentRemoved(entity, component, old)
          } else if old == after {
            self.remove_current_delta_at(i)
          } else {
            self.current_deltas[i] = ComponentChanged(
              entity, component, old, after,
            )
          }
        ComponentChanged(_, _, old, _) =>
          if after.length() == 0 {
            self.current_deltas[i] = ComponentRemoved(entity, component, old)
          } else if old == after {
            self.remove_current_delta_at(i)
          } else {
            self.current_deltas[i] = ComponentChanged(
              entity, component, old, after,
            )
          }
        _ => ()
      }
    None =>
      if before.length() == 0 && after.length() > 0 {
        self.push_current_delta(ComponentAdded(entity, component, after))
      } else if before.length() > 0 && after.length() == 0 {
        self.push_current_delta(ComponentRemoved(entity, component, before))
      } else if before.length() > 0 && after.length() > 0 && before != after {
        self.push_current_delta(
          ComponentChanged(entity, component, before, after),
        )
      }
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
  match
    self.current_camera_delta_index.get(history_entity_delta_index_key(entity)) {
    Some(i) =>
      match self.current_deltas[i] {
        CameraChanged(_, old_before, _) =>
          match old_before {
            Some(old) =>
              if old == after {
                self.remove_current_delta_at(i)
              } else {
                self.current_deltas[i] = CameraChanged(
                  entity, old_before, after,
                )
              }
            None =>
              self.current_deltas[i] = CameraChanged(entity, old_before, after)
          }
        _ => ()
      }
    None =>
      match before {
        Some(old) =>
          if old != after {
            self.push_current_delta(CameraChanged(entity, before, after))
          }
        None => self.push_current_delta(CameraChanged(entity, before, after))
      }
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
  match
    self.current_global_transform_delta_index.get(
      history_entity_delta_index_key(entity),
    ) {
    Some(i) =>
      match self.current_deltas[i] {
        GlobalTransformChanged(_, old_before, _) =>
          match old_before {
            Some(old) =>
              if global_transform_history_row_equal(old, after) {
                self.remove_current_delta_at(i)
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
        _ => ()
      }
    None =>
      match before {
        Some(old) =>
          if !global_transform_history_row_equal(old, after) {
            self.push_current_delta(
              GlobalTransformChanged(entity, before, after),
            )
          }
        None =>
          self.push_current_delta(GlobalTransformChanged(entity, before, after))
      }
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
  self.clear_current_delta_indices()
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
    current_component_delta_index: new_component_delta_index(),
    current_camera_delta_index: new_entity_delta_index(),
    current_global_transform_delta_index: new_entity_delta_index(),
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
/// Returns payload-free summaries of retained undo records, next undo first.
pub fn WorldHistory::undo_summary(
  self : WorldHistory,
) -> Array[WorldHistoryRecordSummary] {
  world_history_stack_summary_next_first(self.undo_stack)
}

///|
/// Returns payload-free summaries of retained redo records, next redo first.
pub fn WorldHistory::redo_summary(
  self : WorldHistory,
) -> Array[WorldHistoryRecordSummary] {
  world_history_stack_summary_next_first(self.redo_stack)
}

///|
/// Reports whether retained undo records are eligible for future history serialization.
pub fn WorldHistory::undo_serialization_report(
  self : WorldHistory,
  world : World,
) -> WorldHistorySerializationReport {
  world_history_stack_serialization_report_next_first(world, self.undo_stack)
}

///|
/// Reports whether retained redo records are eligible for future history serialization.
pub fn WorldHistory::redo_serialization_report(
  self : WorldHistory,
  world : World,
) -> WorldHistorySerializationReport {
  world_history_stack_serialization_report_next_first(world, self.redo_stack)
}

///|
/// Exports retained undo records as a draft in-memory archive, or `None` when not eligible.
pub fn WorldHistory::export_undo_stack(
  self : WorldHistory,
  world : World,
) -> WorldHistoryExport? {
  world_history_stack_export_next_first(world, self.undo_stack)
}

///|
/// Exports retained redo records as a draft in-memory archive, or `None` when not eligible.
pub fn WorldHistory::export_redo_stack(
  self : WorldHistory,
  world : World,
) -> WorldHistoryExport? {
  world_history_stack_export_next_first(world, self.redo_stack)
}

///|
/// Applies record and byte limits to one imported stack.
fn WorldHistory::trim_imported_stack_to_limit(
  self : WorldHistory,
  stack : Array[WorldHistoryRecord],
) -> HistoryTrimResult {
  let record_trimmed = trim_history_stack_to_limit(stack, self.max_undo_records)
  let byte_trimmed = trim_history_stack_to_byte_limit(
    stack,
    self.max_undo_bytes,
  )
  { record_limit: record_trimmed, byte_limit: byte_trimmed }
}

///|
/// Builds a full import result, including dry-run validation against world state.
fn WorldHistory::import_stack_result(
  self : WorldHistory,
  world : World,
  archive : WorldHistoryExport,
  undo : Bool,
) -> WorldHistoryImportStackResult {
  let empty_records : Array[WorldHistoryImportValidationRecordReport] = []
  if self.open {
    return world_history_import_stack_failure(
      archive, "transaction_open", empty_records,
    )
  }
  if self.applying {
    return world_history_import_stack_failure(
      archive, "applying", empty_records,
    )
  }
  let imported = world_history_import_stack_records(world, archive)
  if !imported.ok {
    return imported
  }
  match
    world_history_imported_stack_invalid_location(world, imported.records, undo) {
    Some((record_index, delta_index)) =>
      world_history_import_stack_result_validation_failed(
        imported, record_index, delta_index, undo,
      )
    None => imported
  }
}

///|
/// Validates an undo archive without mutating history stacks or diagnostics.
pub fn WorldHistory::validate_import_undo_stack(
  self : WorldHistory,
  world : World,
  archive : WorldHistoryExport,
) -> WorldHistoryImportValidationReport {
  self.import_stack_result(world, archive, true).report
}

///|
/// Validates a redo archive without mutating history stacks or diagnostics.
pub fn WorldHistory::validate_import_redo_stack(
  self : WorldHistory,
  world : World,
  archive : WorldHistoryExport,
) -> WorldHistoryImportValidationReport {
  self.import_stack_result(world, archive, false).report
}

///|
/// Imports one history stack from an in-memory archive, replacing the target stack.
fn WorldHistory::import_stack(
  self : WorldHistory,
  world : World,
  archive : WorldHistoryExport,
  undo : Bool,
) -> Bool {
  let imported = self.import_stack_result(world, archive, undo)
  if !imported.ok {
    self.set_diagnostic(imported.diagnostic)
    return false
  }
  if undo {
    replace_history_stack_from_next_first(self.undo_stack, imported.records)
    self.set_trim_diagnostic(self.trim_imported_stack_to_limit(self.undo_stack))
  } else {
    replace_history_stack_from_next_first(self.redo_stack, imported.records)
    self.set_trim_diagnostic(self.trim_imported_stack_to_limit(self.redo_stack))
  }
  true
}

///|
/// Imports undo records from a draft in-memory archive, replacing the undo stack.
pub fn WorldHistory::import_undo_stack(
  self : WorldHistory,
  world : World,
  archive : WorldHistoryExport,
) -> Bool {
  self.import_stack(world, archive, true)
}

///|
/// Imports redo records from a draft in-memory archive, replacing the redo stack.
pub fn WorldHistory::import_redo_stack(
  self : WorldHistory,
  world : World,
  archive : WorldHistoryExport,
) -> Bool {
  self.import_stack(world, archive, false)
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
  self.clear_current_delta_indices()
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
/// Cancels the active transaction while preserving the current diagnostic.
pub fn WorldHistory::cancel_transaction_preserving_diagnostic(
  self : WorldHistory,
) -> Bool {
  let diagnostic = self.last_diagnostic()
  let ok = self.cancel_transaction()
  self.set_diagnostic(diagnostic)
  ok
}
