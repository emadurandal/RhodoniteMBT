/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

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
/// Runs one system phase with tracked command-buffer diagnostics.
pub fn WorldHistory::run_system_phase_report(
  self : WorldHistory,
  runner : SystemRunner,
  world : World,
  ctx : SystemContext,
  phase : PhaseKey,
  label : String,
) -> SystemRunReport {
  if self.applying {
    self.set_diagnostic("applying")
    return empty_system_run_report(phase, false)
  }
  if !self.recording_enabled() {
    let report = runner.run_phase_report(world, ctx, phase)
    self.set_delegate_diagnostic(report.ok, "recording_disabled")
    return report
  }
  let auto = self.begin_auto(label)
  let forced_guard = self.force_guarded_world(world)
  let report = runner.run_phase_tracked_report(world, ctx, phase, self)
  if forced_guard && !self.raw_mutation_guard_enabled {
    self.release_guard()
  }
  self.finish_auto(auto, true)
  if !report.ok {
    self.set_diagnostic("operation_failed")
  }
  report
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
