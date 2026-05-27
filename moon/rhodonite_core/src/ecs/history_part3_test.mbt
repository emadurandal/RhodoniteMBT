/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "WorldHistory import validation marks skipped records and deltas invalid" {
  let world = World::new()
  let source = WorldHistory::new()
  let imported = WorldHistory::new()
  let a = world.register_cpu_component_with_identity(
    "HistoryImportSkippedA",
    4,
    "com.example.HistoryImportSkippedA",
    None,
    None,
  )
  let b = world.register_cpu_component_with_identity(
    "HistoryImportSkippedB",
    4,
    "com.example.HistoryImportSkippedB",
    None,
    None,
  )
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, a, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(entity, b, bytes4(3, 0, 0, 0)))
  assert_true(source.set_component_bytes(world, entity, a, bytes4(2, 0, 0, 0)))
  assert_true(source.begin_transaction("multi-set"))
  assert_true(source.set_component_bytes(world, entity, a, bytes4(5, 0, 0, 0)))
  assert_true(source.set_component_bytes(world, entity, b, bytes4(4, 0, 0, 0)))
  assert_true(source.commit_transaction())
  let archive = match source.export_undo_stack(world) {
    Some(archive) => archive
    None => abort("expected exportable archive")
  }
  assert_eq(archive.record_count, 2)
  assert_eq(archive.records[0].delta_count, 2)
  assert_true(world.remove_component(entity, b))
  let report = imported.validate_import_undo_stack(world, archive)
  assert_true(!report.valid)
  assert_eq(report.reason, "import_validation_failed")
  assert_true(!report.records[0].valid)
  assert_eq(report.records[0].reason, "import_validation_failed")
  assert_true(!report.records[0].deltas[0].valid)
  assert_eq(report.records[0].deltas[0].reason, "import_validation_failed")
  assert_true(!report.records[0].deltas[1].valid)
  assert_eq(report.records[0].deltas[1].reason, "import_validation_failed")
  assert_true(!report.records[1].valid)
  assert_eq(report.records[1].reason, "import_validation_failed")
  assert_true(!report.records[1].deltas[0].valid)
  assert_eq(report.records[1].deltas[0].reason, "import_validation_failed")
  assert_eq(imported.last_diagnostic(), "none")
}

///|
test "WorldHistory clears labels with history state" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLabelClears", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction(""))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.undo_label() is Some(""))
  history.clear()
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(history.undo_label() is Some("set_component_bytes"))
  history.set_enabled(false)
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  history.set_enabled(true)
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_true(history.undo_label() is Some("set_component_bytes"))
  history.set_max_undo_records(0)
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
}

///|
test "WorldHistory restores destroyed GlobalTransform presence for recompute" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(
    world.set_transform_trs(
      entity,
      (4.0 : Float),
      (5.0 : Float),
      (6.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  assert_true(history.destroy_entity(world, entity))
  assert_true(!world.is_alive(entity))
  assert_true(history.undo(world))
  assert_true(world.is_alive(entity))
  assert_true(world.has_component(entity, world.transform_component()))
  assert_true(world.has_component(entity, world.global_transform_component()))
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(entity) {
    Some(m) => {
      assert_eq(m.at(0, 3), (4.0 : Float))
      assert_eq(m.at(1, 3), (5.0 : Float))
      assert_eq(m.at(2, 3), (6.0 : Float))
    }
    None => abort("expected recomputed GlobalTransform")
  }
}

///|
test "WorldHistory restores removed GlobalTransform as fresh recomputable blob" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(
    world.set_transform_trs(
      entity,
      (9.0 : Float),
      (2.0 : Float),
      (-3.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  let global_transform = world.global_transform_component()
  assert_true(history.remove_component(world, entity, global_transform))
  assert_true(!world.has_component(entity, global_transform))
  assert_true(history.undo(world))
  assert_true(world.has_component(entity, global_transform))
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(entity) {
    Some(m) => {
      assert_eq(m.at(0, 3), (9.0 : Float))
      assert_eq(m.at(1, 3), (2.0 : Float))
      assert_eq(m.at(2, 3), (-3.0 : Float))
    }
    None => abort("expected recomputed GlobalTransform after remove undo")
  }
}

///|
test "WorldHistory tracks GlobalTransform add undo and redo" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let matrix = @m44.Matrix44::translation(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(history.set_global_transform(world, entity, matrix))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, matrix)
    None => abort("expected tracked GlobalTransform")
  }
  assert_true(world.has_component(entity, world.global_transform_component()))
  assert_true(history.undo(world))
  assert_true(!world.has_component(entity, world.global_transform_component()))
  assert_true(history.redo(world))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, matrix)
    None => abort("expected restored GlobalTransform")
  }
}

///|
test "WorldHistory tracks GlobalTransform row changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let before = @m44.Matrix44::translation(
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let after = @m44.Matrix44::translation(
    (-1.0 : Float),
    (0.5 : Float),
    (9.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, before))
  assert_true(history.set_global_transform(world, entity, after))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, after)
    None => abort("expected changed GlobalTransform")
  }
  assert_true(history.undo(world))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, before)
    None => abort("expected original GlobalTransform")
  }
  assert_true(history.redo(world))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, after)
    None => abort("expected redone GlobalTransform")
  }
}

///|
test "WorldHistory tracks fp16 GlobalTransform rows" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let before = @m44.Matrix44::translation(
    (7.0 : Float),
    (0.25 : Float),
    (-2.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let after = @m44.Matrix44::translation(
    (8.0 : Float),
    (0.5 : Float),
    (-3.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, before))
  assert_true(history.set_global_transform(world, entity, after))
  assert_true(history.undo(world))
  match world.get_global_transform(entity) {
    Some(read) => {
      assert_eq(read.at(0, 3), (7.0 : Float))
      assert_eq(read.at(1, 3), (0.25 : Float))
      assert_eq(read.at(2, 3), (-2.0 : Float))
    }
    None => abort("expected original fp16 GlobalTransform")
  }
  assert_true(history.redo(world))
  match world.get_global_transform(entity) {
    Some(read) => {
      assert_eq(read.at(0, 3), (8.0 : Float))
      assert_eq(read.at(1, 3), (0.5 : Float))
      assert_eq(read.at(2, 3), (-3.0 : Float))
    }
    None => abort("expected redone fp16 GlobalTransform")
  }
}

///|
test "WorldHistory compresses repeated GlobalTransform changes in one transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let before = @m44.Matrix44::translation(
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let middle = @m44.Matrix44::translation(
    (2.0 : Float),
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
  assert_true(history.begin_transaction("GlobalTransform Drag"))
  assert_true(history.set_global_transform(world, entity, middle))
  assert_true(history.set_global_transform(world, entity, after))
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 96)
  assert_true(history.undo(world))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, before)
    None => abort("expected original GlobalTransform")
  }
  assert_true(history.redo(world))
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, after)
    None => abort("expected redone GlobalTransform")
  }
}

///|
test "WorldHistory GlobalTransform tracking disabled and zero limit delegate" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  history.set_enabled(false)
  assert_true(
    history.set_global_transform(world, entity, @m44.Matrix44F::identity()),
  )
  assert_true(world.has_component(entity, world.global_transform_component()))
  assert_true(!history.can_undo())
  history.set_enabled(true)
  history.set_max_undo_records(0)
  let matrix = @m44.Matrix44::translation(
    (5.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(history.set_global_transform(world, entity, matrix))
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, matrix)
    None => abort("expected delegated GlobalTransform")
  }
}

///|
test "WorldHistory tracks GlobalTransform format add undo and redo" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F16)
  assert_true(world.has_component(entity, world.global_transform_component()))
  assert_true(history.undo(world))
  assert_true(!world.has_component(entity, world.global_transform_component()))
  assert_true(history.redo(world))
  let refs_after = world.extract_global_transform_refs([entity])
  let (format_after, _) = @comp.global_transform_ref_from_component_view(
    refs_after[0:8],
  )
  assert_true(format_after == Affine3x4F16)
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, @m44.Matrix44F::identity())
    None => abort("expected restored fp16 GlobalTransform")
  }
}

///|
test "WorldHistory tracks GlobalTransform format changes f32 to f16" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let matrix = @m44.Matrix44::translation(
    (3.0 : Float),
    (0.5 : Float),
    (-4.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, matrix))
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F16)
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, matrix)
    None => abort("expected fp16 GlobalTransform")
  }
  assert_true(history.undo(world))
  let refs_undo = world.extract_global_transform_refs([entity])
  let (format_undo, _) = @comp.global_transform_ref_from_component_view(
    refs_undo[0:8],
  )
  assert_true(format_undo == Affine3x4F32)
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, matrix)
    None => abort("expected restored f32 GlobalTransform")
  }
  assert_true(history.redo(world))
  let refs_redo = world.extract_global_transform_refs([entity])
  let (format_redo, _) = @comp.global_transform_ref_from_component_view(
    refs_redo[0:8],
  )
  assert_true(format_redo == Affine3x4F16)
}

///|
test "WorldHistory tracks GlobalTransform format changes f16 to f32" {
  let world = World::new_with_global_transform_format(Affine3x4F16)
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let matrix = @m44.Matrix44::translation(
    (6.0 : Float),
    (0.25 : Float),
    (2.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, matrix))
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F32))
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F32)
  assert_true(history.undo(world))
  let refs_undo = world.extract_global_transform_refs([entity])
  let (format_undo, _) = @comp.global_transform_ref_from_component_view(
    refs_undo[0:8],
  )
  assert_true(format_undo == Affine3x4F16)
  match world.get_global_transform(entity) {
    Some(read) => {
      assert_eq(read.at(0, 3), (6.0 : Float))
      assert_eq(read.at(1, 3), (0.25 : Float))
      assert_eq(read.at(2, 3), (2.0 : Float))
    }
    None => abort("expected restored f16 GlobalTransform")
  }
  assert_true(history.redo(world))
  let refs_redo = world.extract_global_transform_refs([entity])
  let (format_redo, _) = @comp.global_transform_ref_from_component_view(
    refs_redo[0:8],
  )
  assert_true(format_redo == Affine3x4F32)
}

///|
test "WorldHistory compresses repeated GlobalTransform format changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let matrix = @m44.Matrix44::translation(
    (2.0 : Float),
    (0.5 : Float),
    (1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(world.set_global_transform(entity, matrix))
  assert_true(history.begin_transaction("GlobalTransform Format"))
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F32))
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 72)
  assert_true(history.undo(world))
  let refs_undo = world.extract_global_transform_refs([entity])
  let (format_undo, _) = @comp.global_transform_ref_from_component_view(
    refs_undo[0:8],
  )
  assert_true(format_undo == Affine3x4F32)
  assert_true(history.redo(world))
  let refs_redo = world.extract_global_transform_refs([entity])
  let (format_redo, _) = @comp.global_transform_ref_from_component_view(
    refs_redo[0:8],
  )
  assert_true(format_redo == Affine3x4F16)
}

///|
test "WorldHistory GlobalTransform format tracking disabled and zero limit delegate" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  history.set_enabled(false)
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  assert_true(world.has_component(entity, world.global_transform_component()))
  assert_true(!history.can_undo())
  history.set_enabled(true)
  history.set_max_undo_records(0)
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F32))
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F32)
}

///|
test "WorldHistory restores destroyed Camera presence with readable blob row" {
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
  let _ = world.drain_camera_blob_write_views()
  assert_true(history.destroy_entity(world, camera))
  assert_true(!world.is_alive(camera))
  assert_true(history.undo(world))
  assert_true(world.is_alive(camera))
  assert_true(world.has_component(camera, world.camera_component()))
  match world.camera_gpu_row(camera) {
    Some(bytes) => assert_eq(bytes.length(), @comp.camera_gpu_byte_stride())
    None => abort("expected restored Camera GPU row")
  }
  let writes = world.drain_camera_blob_write_views()
  assert_true(writes.length() > 0)
}

///|
test "WorldHistory tracks Camera matrix add undo and redo" {
  let world = World::new()
  let history = WorldHistory::new()
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
  let after = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected tracked Camera row")
  }
  assert_true(world.has_component(camera, world.camera_component()))
  assert_true(history.undo(world))
  assert_true(!world.has_component(camera, world.camera_component()))
  assert_true(history.redo(world))
  assert_true(world.camera_gpu_row(camera) == Some(after))
}

///|
test "WorldHistory tracks Camera matrix row changes" {
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
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.25 : Float),
      (500.0 : Float),
      (1.5 : Float),
      (0.0 : Float),
      (2.0 : Float),
    ),
  )
  let after = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected changed Camera row")
  }
  assert_true(before != after)
  assert_true(history.undo(world))
  assert_true(world.camera_gpu_row(camera) == Some(before))
  assert_true(history.redo(world))
  assert_true(world.camera_gpu_row(camera) == Some(after))
}

///|
test "WorldHistory Camera tracking disabled and zero limit delegate" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  history.set_enabled(false)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (10.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  assert_true(world.has_component(camera, world.camera_component()))
  assert_true(!history.can_undo())
  history.set_enabled(true)
  history.set_max_undo_records(0)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (20.0 : Float),
      (2.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(!history.can_undo())
}

///|
test "WorldHistory direct mutation coverage audit" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryCoverageCpu", 4)
  let marker = world.register_cpu_component("HistoryCoverageMarker", 4)
  let removable = world.register_cpu_component("HistoryCoverageRemovable", 4)
  let bulk_add0 = world.create_entity()
  let bulk_add1 = world.create_entity()
  let bulk_set0 = world.create_entity()
  let bulk_set1 = world.create_entity()
  let remove_entity = world.create_entity()
  let victim = world.create_entity()
  assert_true(world.add_component_bytes(bulk_set0, cpu, bytes4(10, 0, 0, 0)))
  assert_true(world.add_component_bytes(bulk_set1, cpu, bytes4(11, 0, 0, 0)))
  assert_true(
    world.add_component_bytes(remove_entity, removable, bytes4(90, 0, 0, 0)),
  )
  assert_true(world.add_component_bytes(victim, cpu, bytes4(99, 0, 0, 0)))
  let global_matrix = @m44.Matrix44::translation(
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(history.begin_transaction("Coverage Direct"))
  let batch_entities = history.create_entities(world, 2)
  let parent = history.create_entity(world)
  let entity = history.create_entity(world)
  let camera = history.create_entity(world)
  let spawned = history.spawn_batch(world, [marker, cpu], 2, fn(i, _e, row) {
    row.write(marker, c => c[0] = (30 + i).to_byte())
    row.write(cpu, c => c[0] = (40 + i).to_byte())
  })
  assert_true(history.add_component(world, parent, marker))
  assert_true(
    history.add_component_bytes(world, entity, cpu, bytes4(1, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, cpu, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_transform_trs(
      world,
      entity,
      (4.0 : Float),
      (5.0 : Float),
      (6.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(history.set_child_of(world, entity, parent))
  assert_true(history.set_global_transform(world, entity, global_matrix))
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.25 : Float),
      (100.0 : Float),
      (1.5 : Float),
      (0.0 : Float),
      (2.0 : Float),
    ),
  )
  assert_true(
    history.add_component_bytes_many(world, marker, [bulk_add0, bulk_add1], [
      bytes4(50, 0, 0, 0),
      bytes4(51, 0, 0, 0),
    ]),
  )
  assert_true(
    history.set_component_bytes_many(world, cpu, [bulk_set0, bulk_set1], [
      bytes4(12, 0, 0, 0),
      bytes4(13, 0, 0, 0),
    ]),
  )
  assert_true(history.remove_component(world, remove_entity, removable))
  assert_true(history.destroy_entity(world, victim))
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_eq(batch_entities.length(), 2)
  assert_eq(spawned.length(), 2)
  assert_true(world.is_alive(batch_entities[0]))
  assert_true(world.is_alive(batch_entities[1]))
  assert_true(world.is_alive(parent))
  assert_true(world.is_alive(entity))
  assert_true(world.is_alive(camera))
  assert_true(world.is_alive(spawned[0]))
  assert_true(world.is_alive(spawned[1]))
  assert_true(!world.is_alive(victim))
  assert_true(history.undo(world))
  assert_true(!world.is_alive(batch_entities[0]))
  assert_true(!world.is_alive(batch_entities[1]))
  assert_true(!world.is_alive(parent))
  assert_true(!world.is_alive(entity))
  assert_true(!world.is_alive(camera))
  assert_true(!world.is_alive(spawned[0]))
  assert_true(!world.is_alive(spawned[1]))
  assert_true(!world.has_component(bulk_add0, marker))
  assert_true(!world.has_component(bulk_add1, marker))
  assert_true(
    world.component_bytes(bulk_set0, cpu) == Some(bytes4(10, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(bulk_set1, cpu) == Some(bytes4(11, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(remove_entity, removable) == Some(bytes4(90, 0, 0, 0)),
  )
  assert_true(world.is_alive(victim))
  assert_true(world.component_bytes(victim, cpu) == Some(bytes4(99, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.is_alive(batch_entities[0]))
  assert_true(world.is_alive(batch_entities[1]))
  assert_true(world.has_component(parent, marker))
  assert_true(world.is_alive(spawned[0]))
  assert_true(world.is_alive(spawned[1]))
  assert_true(
    world.component_bytes(spawned[0], marker) == Some(bytes4(30, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(spawned[1], cpu) == Some(bytes4(41, 0, 0, 0)),
  )
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(
    world.component_bytes(bulk_add0, marker) == Some(bytes4(50, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(bulk_add1, marker) == Some(bytes4(51, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(bulk_set0, cpu) == Some(bytes4(12, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(bulk_set1, cpu) == Some(bytes4(13, 0, 0, 0)),
  )
  assert_true(!world.has_component(remove_entity, removable))
  assert_true(!world.is_alive(victim))
  match world.get_transform(entity) {
    Some(transform) => {
      assert_eq(transform.position.x(), (4.0 : Float))
      assert_eq(transform.position.y(), (5.0 : Float))
      assert_eq(transform.position.z(), (6.0 : Float))
    }
    None => abort("expected coverage Transform3D")
  }
  assert_true(world.get_child_of(entity) == Some(parent))
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F16)
  match world.get_global_transform(entity) {
    Some(read) => {
      assert_eq(read.at(0, 3), (1.0 : Float))
      assert_eq(read.at(1, 3), (2.0 : Float))
      assert_eq(read.at(2, 3), (3.0 : Float))
    }
    None => abort("expected coverage GlobalTransform")
  }
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_eq(
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 268),
        (0.25 : Float),
      )
    None => abort("expected coverage Camera row")
  }
}

///|
test "panic WorldHistory guarded transaction rejects raw World mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryGuardRejectWorld", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw world"))
  ignore(world.set_component_bytes(entity, cpu, bytes4(2, 0, 0, 0)))
}

///|
test "panic WorldHistory callback-scoped guarded transaction rejects raw World mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryScopedGuardRejectWorld", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  ignore(
    history.with_guarded_transaction(world, "guarded scoped raw world", () => {
      ignore(world.set_component_bytes(entity, cpu, bytes4(2, 0, 0, 0)))
      true
    }),
  )
}

///|
test "panic WorldHistory guarded transaction rejects raw entity creation" {
  let world = World::new()
  let history = WorldHistory::new()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw create"))
  ignore(world.create_entity())
}

///|
test "panic WorldHistory guarded transaction rejects raw entity destruction" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw destroy"))
  ignore(world.destroy_entity(entity))
}

///|
test "panic WorldHistory guarded transaction rejects raw component add" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryGuardRejectAdd", 4)
  let entity = world.create_entity()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw add"))
  ignore(world.add_component(entity, cpu))
}

///|
test "panic WorldHistory guarded transaction rejects raw component byte add" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryGuardRejectAddBytes", 4)
  let entity = world.create_entity()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw add bytes"))
  ignore(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
}
