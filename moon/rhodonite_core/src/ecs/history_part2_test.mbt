/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "WorldHistory records diagnostics for disabled recording delegates" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryDelegateDiagnostics", 4)
  let entity = world.create_entity()
  history.set_enabled(false)
  assert_eq(history.last_diagnostic(), "none")
  assert_true(
    history.add_component_bytes(world, entity, component, bytes4(1, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "recording_disabled")
}

///|
test "WorldHistory trims old undo records to max_undo_records" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLimit", 4)
  let entity = world.create_entity()
  history.set_max_undo_records(2)
  assert_eq(history.max_undo_records(), 2)
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 2)
  assert_eq(history.last_diagnostic(), "stack_trimmed_record_limit")
  assert_true(history.undo(world))
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after first limited undo")
  }
  assert_true(history.undo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(2, 0, 0, 0))
    None => abort("expected value after second limited undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory trims old records to max_undo_bytes" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryByteLimit", 4)
  let entity = world.create_entity()
  history.set_max_undo_bytes(16)
  assert_eq(history.max_undo_bytes(), 16)
  assert_eq(history.last_diagnostic(), "none")
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 2)
  assert_eq(history.undo_bytes(), 16)
  assert_eq(history.last_diagnostic(), "stack_trimmed_byte_limit")
  assert_true(history.undo(world))
  assert_eq(history.undo_bytes(), 8)
  assert_eq(history.redo_bytes(), 8)
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after byte limited undo")
  }
  assert_true(history.undo(world))
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.redo_bytes(), 16)
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(2, 0, 0, 0))
    None => abort("expected value after second byte limited undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory trims existing stacks when max_undo_bytes is lowered" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLowerByteLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 3)
  history.set_max_undo_bytes(8)
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 8)
  assert_eq(history.last_diagnostic(), "stack_trimmed_byte_limit")
  assert_true(history.undo(world))
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after lowered byte-limit undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory drops oversize record while keeping mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryOversizeByteLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_eq(history.redo_len(), 1)
  history.set_max_undo_bytes(4)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.last_diagnostic(), "stack_trimmed_byte_limit")
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 0)
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.last_diagnostic(), "record_dropped_byte_limit")
  assert_true(!history.can_undo())
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected oversize mutation to remain applied")
  }
}

///|
test "WorldHistory trims existing stacks when max_undo_records is lowered" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLowerLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  history.set_max_undo_records(1)
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after lowered-limit undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory max_undo_records zero clears and keeps future changes unrecorded" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryZeroLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 1)
  history.set_max_undo_records(0)
  assert_eq(history.max_undo_records(), 0)
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.last_diagnostic(), "stack_trimmed_record_limit")
  assert_true(!history.begin_transaction("disabled-by-limit"))
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  assert_true(!history.can_undo())
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected delegated zero-limit value")
  }
}

///|
test "WorldHistory exposes undo and redo labels for UI state" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLabels", 4)
  let entity = world.create_entity()
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction("Move Entity"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  assert_true(history.commit_transaction())
  assert_true(history.undo_label() is Some("Move Entity"))
  assert_true(history.redo_label() is None)
  assert_true(history.begin_transaction("Rename Entity"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.undo_label() is Some("Rename Entity"))
  assert_true(history.undo(world))
  assert_true(history.undo_label() is Some("Move Entity"))
  assert_true(history.redo_label() is Some("Rename Entity"))
  assert_true(history.redo(world))
  assert_true(history.undo_label() is Some("Rename Entity"))
  assert_true(history.redo_label() is None)
}

///|
test "WorldHistory exposes payload-free undo and redo summaries" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistorySummary", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction("Change Component"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.begin_transaction("Destroy Entity"))
  assert_true(history.destroy_entity(world, entity))
  assert_true(history.commit_transaction())
  let diagnostic = history.last_diagnostic()
  let summaries = history.undo_summary()
  assert_eq(summaries.length(), 2)
  assert_eq(summaries[0].label, "Destroy Entity")
  assert_eq(summaries[0].delta_count, 1)
  assert_eq(summaries[0].payload_bytes, 4)
  assert_eq(summaries[0].deltas[0].kind, "entity_destroyed")
  assert_true(summaries[0].deltas[0].entity == Some(entity))
  assert_true(summaries[0].deltas[0].component is None)
  assert_eq(summaries[0].deltas[0].component_count, 1)
  assert_eq(summaries[0].deltas[0].payload_bytes, 4)
  assert_true(summaries[0].deltas[0].before_present)
  assert_true(!summaries[0].deltas[0].after_present)
  assert_eq(summaries[1].label, "Change Component")
  assert_eq(summaries[1].delta_count, 1)
  assert_eq(summaries[1].payload_bytes, 8)
  assert_eq(summaries[1].deltas[0].kind, "component_changed")
  assert_true(summaries[1].deltas[0].entity == Some(entity))
  assert_true(summaries[1].deltas[0].component == Some(component))
  assert_eq(summaries[1].deltas[0].component_count, 0)
  assert_eq(summaries[1].deltas[0].payload_bytes, 8)
  assert_true(summaries[1].deltas[0].before_present)
  assert_true(summaries[1].deltas[0].after_present)
  assert_eq(history.last_diagnostic(), diagnostic)
  assert_eq(history.undo_len(), 2)
  assert_eq(history.redo_len(), 0)
  assert_true(history.undo(world))
  let redo_summaries = history.redo_summary()
  assert_eq(redo_summaries.length(), 1)
  assert_eq(redo_summaries[0].label, "Destroy Entity")
  assert_eq(redo_summaries[0].deltas[0].kind, "entity_destroyed")
}

///|
test "WorldHistory reports serialization eligibility without exposing payloads" {
  let world = World::new()
  let history = WorldHistory::new()
  let stable = world.register_cpu_component_with_identity(
    "HistorySerializableStable",
    4,
    "com.example.HistorySerializableStable",
    Some("1"),
    Some("sha256:history-serializable-stable"),
  )
  let legacy = world.register_cpu_component("HistorySerializableLegacy", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, stable, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(entity, legacy, bytes4(2, 0, 0, 0)))
  assert_true(
    history.set_transform_trs(
      world,
      entity,
      (1.0 : Float),
      (2.0 : Float),
      (3.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(history.begin_transaction("Destroy Mixed Serializable Entity"))
  assert_true(history.destroy_entity(world, entity))
  assert_true(history.commit_transaction())
  let diagnostic = history.last_diagnostic()
  let report = history.undo_serialization_report(world)
  assert_true(!report.serializable)
  assert_eq(report.record_count, 2)
  assert_eq(report.records[0].label, "Destroy Mixed Serializable Entity")
  assert_true(!report.records[0].serializable)
  assert_eq(report.records[0].reason, "missing_stable_component_identity")
  assert_eq(report.records[0].deltas[0].kind, "entity_destroyed")
  assert_true(!report.records[0].deltas[0].serializable)
  assert_eq(
    report.records[0].deltas[0].reason,
    "missing_stable_component_identity",
  )
  assert_eq(report.records[0].deltas[0].components.length(), 3)
  let mut saw_stable = false
  let mut saw_legacy = false
  let mut saw_transform = false
  for i = 0; i < report.records[0].deltas[0].components.length(); i = i + 1 {
    let component_report = report.records[0].deltas[0].components[i]
    if component_report.component == stable {
      saw_stable = true
      assert_true(component_report.serializable)
      assert_true(
        component_report.stable_key ==
        Some("com.example.HistorySerializableStable"),
      )
    } else if component_report.component == legacy {
      saw_legacy = true
      assert_true(!component_report.serializable)
      assert_eq(component_report.reason, "missing_stable_component_identity")
    } else if component_report.component == world.transform_component() {
      saw_transform = true
      assert_true(component_report.serializable)
      assert_true(component_report.stable_key == Some("Transform3D"))
    }
  }
  assert_true(saw_stable)
  assert_true(saw_legacy)
  assert_true(saw_transform)
  assert_true(report.records[1].serializable)
  assert_eq(report.records[1].deltas[0].kind, "component_added")
  assert_true(
    report.records[1].deltas[0].components[0].stable_key == Some("Transform3D"),
  )
  assert_eq(history.undo_len(), 2)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.last_diagnostic(), diagnostic)
  assert_true(history.undo(world))
  let redo_report = history.redo_serialization_report(world)
  assert_true(!redo_report.serializable)
  assert_eq(redo_report.records[0].label, "Destroy Mixed Serializable Entity")
}

///|
test "WorldHistory exports stable component byte changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryExportStable",
    4,
    "com.example.HistoryExportStable",
    Some("2"),
    Some("sha256:history-export-stable"),
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  let diagnostic = history.last_diagnostic()
  let archive = match history.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable undo stack")
  }
  assert_eq(archive.format_version, 1)
  assert_eq(archive.record_count, 1)
  assert_eq(archive.records[0].label, "set_component_bytes")
  assert_eq(archive.records[0].delta_count, 1)
  let delta = archive.records[0].deltas[0]
  assert_eq(delta.kind, "component_changed")
  assert_true(delta.entity == Some(entity))
  match delta.component {
    Some(identity) => {
      assert_true(identity.local_component == component)
      assert_eq(identity.key, "com.example.HistoryExportStable")
      assert_true(!identity.builtin)
      assert_true(identity.schema_version == Some("2"))
      assert_true(identity.schema_hash == Some("sha256:history-export-stable"))
    }
    None => abort("expected exported component identity")
  }
  match delta.before {
    Some(payload) => {
      assert_true(payload.global_transform_format is None)
      assert_true(payload.bytes == bytes4(1, 0, 0, 0))
    }
    None => abort("expected exported before bytes")
  }
  match delta.after {
    Some(payload) => {
      assert_true(payload.global_transform_format is None)
      assert_true(payload.bytes == bytes4(2, 0, 0, 0))
    }
    None => abort("expected exported after bytes")
  }
  assert_eq(history.last_diagnostic(), diagnostic)
  assert_true(history.undo(world))
  let redo_archive = match history.export_redo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable redo stack")
  }
  assert_eq(redo_archive.records[0].label, "set_component_bytes")
  assert_eq(redo_archive.records[0].deltas[0].kind, "component_changed")
}

///|
test "WorldHistory export returns None for legacy component identity" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryExportLegacy", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  let diagnostic = history.last_diagnostic()
  assert_true(history.export_undo_stack(world) is None)
  assert_eq(history.last_diagnostic(), diagnostic)
}

///|
test "WorldHistory export includes entity destroyed component snapshots" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryExportDestroyStable",
    4,
    "com.example.HistoryExportDestroyStable",
    None,
    None,
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(7, 0, 0, 0)))
  assert_true(
    history.set_transform_trs(
      world,
      entity,
      (1.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(history.begin_transaction("Export Destroy Stable Entity"))
  assert_true(history.destroy_entity(world, entity))
  assert_true(history.commit_transaction())
  let archive = match history.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable destroy stack")
  }
  assert_eq(archive.records[0].label, "Export Destroy Stable Entity")
  let delta = archive.records[0].deltas[0]
  assert_eq(delta.kind, "entity_destroyed")
  assert_true(delta.entity == Some(entity))
  let mut saw_stable = false
  let mut saw_transform = false
  for i = 0; i < delta.components.length(); i = i + 1 {
    let snapshot = delta.components[i]
    if snapshot.component.local_component == component {
      saw_stable = true
      assert_eq(
        snapshot.component.key,
        "com.example.HistoryExportDestroyStable",
      )
      assert_true(snapshot.bytes == bytes4(7, 0, 0, 0))
    } else if snapshot.component.key == "Transform3D" {
      saw_transform = true
      assert_true(snapshot.component.builtin)
    }
  }
  assert_true(saw_stable)
  assert_true(saw_transform)
}

///|
test "WorldHistory export includes GlobalTransform and Camera payloads" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let before = @m44.Matrix44::translation(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let after = @m44.Matrix44::translation(
    (2.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, before))
  assert_true(history.set_global_transform(world, entity, after))
  let camera = world.create_entity()
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
  let archive = match history.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable builtin blob stack")
  }
  assert_eq(archive.record_count, 2)
  assert_eq(archive.records[0].deltas[0].kind, "camera_changed")
  match archive.records[0].deltas[0].component {
    Some(identity) => {
      assert_eq(identity.key, "Camera")
      assert_true(identity.builtin)
    }
    None => abort("expected exported Camera identity")
  }
  match archive.records[0].deltas[0].after {
    Some(payload) => {
      assert_true(payload.global_transform_format is None)
      assert_true(payload.bytes.length() > 0)
    }
    None => abort("expected exported Camera after payload")
  }
  assert_eq(archive.records[1].deltas[0].kind, "global_transform_changed")
  match archive.records[1].deltas[0].component {
    Some(identity) => {
      assert_eq(identity.key, "GlobalTransform")
      assert_true(identity.builtin)
    }
    None => abort("expected exported GlobalTransform identity")
  }
  match archive.records[1].deltas[0].after {
    Some(payload) => {
      assert_true(payload.global_transform_format == Some(1))
      assert_true(payload.bytes.length() > 0)
    }
    None => abort("expected exported GlobalTransform after payload")
  }
}

///|
test "WorldHistory imports stable component undo stack" {
  let world = World::new()
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryImportStable",
    4,
    "com.example.HistoryImportStable",
    Some("1"),
    Some("sha256:history-import-stable"),
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    source.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  let archive = match source.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable undo archive")
  }
  let report = imported.validate_import_undo_stack(world, archive)
  assert_true(report.valid)
  assert_eq(report.reason, "none")
  assert_eq(report.record_count, 1)
  assert_eq(report.records[0].index, 0)
  assert_eq(report.records[0].label, "set_component_bytes")
  assert_true(report.records[0].valid)
  assert_eq(report.records[0].deltas[0].index, 0)
  assert_eq(report.records[0].deltas[0].kind, "component_changed")
  assert_true(
    report.records[0].deltas[0].component_key ==
    Some("com.example.HistoryImportStable"),
  )
  assert_true(report.records[0].deltas[0].valid)
  assert_eq(imported.last_diagnostic(), "none")
  assert_true(imported.import_undo_stack(world, archive))
  assert_eq(imported.undo_len(), 1)
  assert_true(imported.undo(world))
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(1, 0, 0, 0)),
  )
  assert_true(imported.redo(world))
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(2, 0, 0, 0)),
  )
}

///|
test "WorldHistory imports redo stack" {
  let world = World::new()
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryImportRedoStable",
    4,
    "com.example.HistoryImportRedoStable",
    None,
    None,
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    source.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(source.undo(world))
  let archive = match source.export_redo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable redo archive")
  }
  assert_true(imported.import_redo_stack(world, archive))
  assert_eq(imported.redo_len(), 1)
  assert_true(imported.redo(world))
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(2, 0, 0, 0)),
  )
}

///|
test "WorldHistory imports entity destroyed snapshots" {
  let world = World::new()
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryImportDestroyStable",
    4,
    "com.example.HistoryImportDestroyStable",
    None,
    None,
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(7, 0, 0, 0)))
  assert_true(source.destroy_entity(world, entity))
  let archive = match source.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable destroy archive")
  }
  assert_true(imported.import_undo_stack(world, archive))
  assert_true(imported.undo(world))
  assert_true(world.is_alive(entity))
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(7, 0, 0, 0)),
  )
  assert_true(imported.redo(world))
  assert_true(!world.is_alive(entity))
}

///|
test "WorldHistory imports builtin blob payloads" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let entity = world.create_entity()
  let before = @m44.Matrix44::translation(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let after = @m44.Matrix44::translation(
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, before))
  assert_true(source.set_global_transform(world, entity, after))
  let camera = world.create_entity()
  assert_true(
    source.set_camera_matrices(
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
  let archive = match source.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable builtin archive")
  }
  assert_true(imported.import_undo_stack(world, archive))
  assert_eq(imported.undo_len(), 2)
  assert_true(imported.undo(world))
  assert_true(!world.has_component(camera, world.camera_component()))
  assert_true(imported.undo(world))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read.at(0, 3), (1.0 : Float))
    None => abort("expected imported GlobalTransform undo")
  }
}

///|
test "WorldHistory import rejects invalid archive without mutating stacks" {
  let world = World::new()
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryImportRejectStable",
    4,
    "com.example.HistoryImportRejectStable",
    Some("1"),
    None,
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    source.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  let archive = match source.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable archive")
  }
  assert_true(imported.import_undo_stack(world, archive))
  let unsupported : WorldHistoryExport = {
    format_version: 999,
    record_count: archive.record_count,
    records: archive.records,
  }
  assert_true(!imported.import_undo_stack(world, unsupported))
  assert_eq(imported.last_diagnostic(), "import_unsupported_format")
  assert_eq(imported.undo_len(), 1)
  let bad_identity : WorldHistoryExportComponentIdentity = {
    local_component: component,
    key: "com.example.MissingHistoryImportRejectStable",
    builtin: false,
    schema_version: Some("1"),
    schema_hash: (None : String?),
  }
  let no_snapshots : Array[WorldHistoryExportComponentSnapshot] = []
  let bad_delta : WorldHistoryExportDelta = {
    kind: "component_changed",
    entity: Some(entity),
    component: Some(bad_identity),
    before: archive.records[0].deltas[0].before,
    after: archive.records[0].deltas[0].after,
    components: no_snapshots,
  }
  let bad_records : Array[WorldHistoryExportRecord] = [
    { label: "bad", delta_count: 1, deltas: [bad_delta] },
  ]
  let bad_archive : WorldHistoryExport = {
    format_version: 1,
    record_count: 1,
    records: bad_records,
  }
  let diagnostic_before_validate = imported.last_diagnostic()
  let report = imported.validate_import_undo_stack(world, bad_archive)
  assert_true(!report.valid)
  assert_eq(report.reason, "import_identity_mismatch")
  assert_eq(report.record_count, 1)
  assert_eq(report.records[0].index, 0)
  assert_true(!report.records[0].valid)
  assert_eq(report.records[0].reason, "import_identity_mismatch")
  assert_eq(report.records[0].deltas[0].index, 0)
  assert_true(
    report.records[0].deltas[0].component_key ==
    Some("com.example.MissingHistoryImportRejectStable"),
  )
  assert_true(!report.records[0].deltas[0].valid)
  assert_eq(report.records[0].deltas[0].reason, "import_identity_mismatch")
  assert_eq(imported.last_diagnostic(), diagnostic_before_validate)
  assert_true(!imported.import_undo_stack(world, bad_archive))
  assert_eq(imported.last_diagnostic(), "import_identity_mismatch")
  assert_eq(imported.undo_len(), 1)
}

///|
test "WorldHistory import validates full stack before replacing" {
  let world = World::new()
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let component = world.register_cpu_component_with_identity(
    "HistoryImportFullStackStable",
    4,
    "com.example.HistoryImportFullStackStable",
    None,
    None,
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    source.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    source.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  let archive = match source.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable archive")
  }
  assert_true(world.remove_component(entity, component))
  let report = imported.validate_import_undo_stack(world, archive)
  assert_true(!report.valid)
  assert_eq(report.reason, "import_validation_failed")
  assert_eq(report.records[0].index, 0)
  assert_true(!report.records[0].valid)
  assert_eq(report.records[0].reason, "import_validation_failed")
  assert_eq(report.records[0].deltas[0].index, 0)
  assert_true(!report.records[0].deltas[0].valid)
  assert_eq(report.records[0].deltas[0].reason, "import_validation_failed")
  assert_eq(imported.last_diagnostic(), "none")
  assert_true(!imported.import_undo_stack(world, archive))
  assert_eq(imported.last_diagnostic(), "import_validation_failed")
  assert_eq(imported.undo_len(), 0)
  assert_true(!world.has_component(entity, component))
}
