/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds a four-byte component payload for history white-box tests.
fn history_wb_bytes4(
  a : Byte,
  b : Byte,
  c : Byte,
  d : Byte,
) -> FixedArray[Byte] {
  [a, b, c, d]
}

///|
test "WorldHistory undo failure rollback reapplies completed deltas" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryUndoRollback", 4)
  let entity = world.create_entity()
  let before = history_wb_bytes4(1, 0, 0, 0)
  let after = history_wb_bytes4(2, 0, 0, 0)
  assert_true(world.add_component_bytes(entity, component, after))
  let record : WorldHistoryRecord = {
    label: "undo rollback",
    deltas: [
      ComponentChanged(entity, component, before, after),
      ComponentChanged(entity, component, before, after),
    ],
  }
  world.begin_history_tracked_mutation()
  assert_true(history.apply_delta_inverse(world, record.deltas[1]))
  assert_true(world.component_bytes(entity, component) == Some(before))
  assert_true(history.rollback_applied_undo_deltas(world, record, 0))
  world.end_history_tracked_mutation()
  assert_true(world.component_bytes(entity, component) == Some(after))
}

///|
test "WorldHistory redo failure rollback inverses completed deltas" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryRedoRollback", 4)
  let entity = world.create_entity()
  let before = history_wb_bytes4(1, 0, 0, 0)
  let after = history_wb_bytes4(2, 0, 0, 0)
  assert_true(world.add_component_bytes(entity, component, before))
  let record : WorldHistoryRecord = {
    label: "redo rollback",
    deltas: [
      ComponentChanged(entity, component, before, after),
      ComponentChanged(entity, component, before, after),
    ],
  }
  world.begin_history_tracked_mutation()
  assert_true(history.apply_delta(world, record.deltas[0]))
  assert_true(world.component_bytes(entity, component) == Some(after))
  assert_true(history.rollback_applied_redo_deltas(world, record, 1))
  world.end_history_tracked_mutation()
  assert_true(world.component_bytes(entity, component) == Some(before))
}

///|
test "WorldHistory undo apply failure rolls back and keeps stacks" {
  let world = World::new()
  let history = WorldHistory::new()
  let bad = world.create_entity()
  let good = world.create_entity()
  world.locations[bad.index] = None
  history.undo_stack.push({
    label: "undo apply failure",
    deltas: [EntityCreated(bad), EntityCreated(good)],
  })
  assert_true(!history.undo(world))
  assert_eq(history.last_diagnostic(), "apply_failed_rolled_back")
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_true(world.is_alive(good))
}

///|
test "WorldHistory undo apply failure clears history when rollback fails" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryUndoApplyHardClear", 4)
  let bad = world.create_entity()
  let good = world.create_entity()
  let bytes = history_wb_bytes4(1, 0, 0, 0)
  world.locations[bad.index] = None
  history.undo_stack.push({
    label: "undo apply hard clear",
    deltas: [
      EntityCreated(bad),
      EntityCreated(good),
      ComponentRemoved(good, component, bytes),
    ],
  })
  assert_true(!history.undo(world))
  assert_eq(history.last_diagnostic(), "apply_failed")
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
}

///|
test "WorldHistory redo apply failure rolls back and keeps stacks" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryRedoApplyRollback", 4)
  let bad = world.create_entity()
  let good = world.create_entity()
  let before = history_wb_bytes4(1, 0, 0, 0)
  let after = history_wb_bytes4(2, 0, 0, 0)
  assert_true(world.add_component_bytes(good, component, before))
  world.locations[bad.index] = None
  history.redo_stack.push({
    label: "redo apply failure",
    deltas: [
      ComponentChanged(good, component, before, after),
      EntityDestroyed({ entity: bad, components: [] }),
    ],
  })
  assert_true(!history.redo(world))
  assert_eq(history.last_diagnostic(), "apply_failed_rolled_back")
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(world.component_bytes(good, component) == Some(before))
}

///|
test "WorldHistory redo apply failure clears history when rollback fails" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryRedoApplyHardClear", 4)
  let bad = world.create_entity()
  let good = world.create_entity()
  let bytes = history_wb_bytes4(1, 0, 0, 0)
  world.locations[bad.index] = None
  history.redo_stack.push({
    label: "redo apply hard clear",
    deltas: [
      ComponentAdded(good, component, bytes),
      EntityDestroyed({ entity: good, components: [] }),
      EntityDestroyed({ entity: bad, components: [] }),
    ],
  })
  assert_true(!history.redo(world))
  assert_eq(history.last_diagnostic(), "apply_failed")
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
}

///|
test "WorldHistory serialization report marks unknown components" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let unknown = ComponentTypeId::new(9999)
  history.undo_stack.push({
    label: "unknown component report",
    deltas: [ComponentAdded(entity, unknown, history_wb_bytes4(1, 0, 0, 0))],
  })
  let diagnostic = history.last_diagnostic()
  let report = history.undo_serialization_report(world)
  assert_true(!report.serializable)
  assert_eq(report.record_count, 1)
  assert_true(!report.records[0].serializable)
  assert_eq(report.records[0].reason, "unknown_component")
  assert_true(!report.records[0].deltas[0].serializable)
  assert_eq(report.records[0].deltas[0].reason, "unknown_component")
  assert_eq(report.records[0].deltas[0].components.length(), 1)
  assert_true(!report.records[0].deltas[0].components[0].serializable)
  assert_eq(
    report.records[0].deltas[0].components[0].reason,
    "unknown_component",
  )
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.last_diagnostic(), diagnostic)
}

///|
test "WorldHistory compresses repeated CameraChanged deltas inside transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let before = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected original Camera row")
  }
  assert_true(history.begin_transaction("camera drag"))
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (200.0 : Float),
      (1.25 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_eq(history.current_deltas.length(), 1)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.3 : Float),
      (300.0 : Float),
      (1.5 : Float),
      (0.0 : Float),
      (2.0 : Float),
    ),
  )
  let after = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected final Camera row")
  }
  assert_eq(history.current_deltas.length(), 1)
  match history.current_deltas[0] {
    CameraChanged(e, Some(old), latest) => {
      assert_true(e == camera)
      assert_true(old == before)
      assert_true(latest == after)
    }
    _ => abort("expected compressed CameraChanged delta")
  }
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  assert_true(world.camera_gpu_row(camera) == Some(before))
  assert_true(history.redo(world))
  assert_true(world.camera_gpu_row(camera) == Some(after))
}

///|
test "WorldHistory drops CameraChanged when transaction returns to original row" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let before = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected original Camera row")
  }
  assert_true(history.begin_transaction("camera no-op"))
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (200.0 : Float),
      (1.25 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_eq(history.current_deltas.length(), 1)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(world.camera_gpu_row(camera) == Some(before))
  assert_eq(history.current_deltas.length(), 0)
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 0)
}

///|
test "WorldHistory guarded transactions release raw mutation guard" {
  let world = World::new()
  let history = WorldHistory::new()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.raw_mutation_guard_enabled())
  assert_true(history.begin_guarded_transaction(world, "guard commit"))
  assert_eq(world.history_raw_mutation_guard_depth, 1)
  assert_true(history.commit_transaction())
  assert_eq(world.history_raw_mutation_guard_depth, 0)
  assert_true(history.begin_guarded_transaction(world, "guard cancel"))
  assert_eq(world.history_raw_mutation_guard_depth, 1)
  assert_true(history.cancel_transaction())
  assert_eq(world.history_raw_mutation_guard_depth, 0)
  assert_true(history.begin_guarded_transaction(world, "guard disable"))
  assert_eq(world.history_raw_mutation_guard_depth, 1)
  history.set_raw_mutation_guard_enabled(false)
  assert_false(history.raw_mutation_guard_enabled())
  assert_eq(world.history_raw_mutation_guard_depth, 0)
}

///|
test "WorldHistory tracked mutations bypass guarded raw mutation checks" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryGuardBypass", 4)
  let entity = world.create_entity()
  assert_true(
    world.add_component_bytes(entity, component, history_wb_bytes4(1, 0, 0, 0)),
  )
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded set"))
  assert_eq(world.history_raw_mutation_guard_depth, 1)
  assert_eq(world.history_tracked_mutation_depth, 0)
  assert_true(
    history.set_component_bytes(
      world,
      entity,
      component,
      history_wb_bytes4(2, 0, 0, 0),
    ),
  )
  assert_eq(world.history_tracked_mutation_depth, 0)
  assert_true(history.commit_transaction())
  assert_eq(world.history_raw_mutation_guard_depth, 0)
  assert_true(history.undo(world))
  assert_true(
    world.component_bytes(entity, component) ==
    Some(history_wb_bytes4(1, 0, 0, 0)),
  )
}
