/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `bench_affine_values_for_index`.
fn bench_affine_values_for_index(
  idx : Int,
) -> (
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
  Float,
) {
  (
    (1.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
    Float::from_double(idx.to_double() * 0.001),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    Float::from_double(idx.to_double() * 0.002),
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    Float::from_double(idx.to_double() * -0.001),
  )
}

///|
/// Implements `make_global_blob_bench_world`.
fn make_global_blob_bench_world(
  count : Int,
) -> (
  @ecs.World,
  FixedArray[Byte],
  @ecs.GlobalTransformUploadRange,
  @ecs.GlobalTransformDenseLayout?,
) {
  let (world, _, _, _, entities) = make_world_batch_entities(count)
  let refs = world.extract_global_transform_refs(entities)
  let dense = @ecs.detect_dense_global_transform_layout(refs, count)
  let range = @ecs.compute_global_transform_upload_range(refs, count, dense)
  (world, refs, range, dense)
}

///|
/// Implements `bench_global_transform_dense_range_write`.
fn bench_global_transform_dense_range_write(count : Int) -> BenchSample {
  let (world, _, range, dense) = make_global_blob_bench_world(count)
  let layout = match dense {
    Some(layout) => layout
    None => abort("expected dense GlobalTransform layout")
  }
  let started = monotonic_ms()
  let writes = world.write_global_transform_blob_range_views(
    range.first_word,
    range.word_count,
    fn(bytes) {
      for i = 0; i < count; i = i + 1 {
        let byte_start = (i * layout.words_per_entity - range.first_word) * 4
        let byte_end = byte_start + layout.words_per_entity * 4
        @comp.matrix44f_write_global_transform_to_gpu_row(
          bench_matrix_for_index(i),
          bytes.mut_view(start=byte_start, end=byte_end),
          layout.format,
        )
      }
    },
  )
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  report("global_transform_dense_range_write", count, started, uploaded)
}

///|
/// Implements `bench_global_transform_by_refs_write`.
fn bench_global_transform_by_refs_write(count : Int) -> BenchSample {
  let (world, refs, range, dense) = make_global_blob_bench_world(count)
  let started = monotonic_ms()
  let writes = world.write_global_transform_blob_range_by_refs(
    refs,
    count,
    range,
    dense,
    fn(writer) {
      for i = 0; i < count; i = i + 1 {
        let (m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23) = bench_affine_values_for_index(
          i,
        )
        writer.set_affine3x4_at(
          i, m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23,
        )
      }
    },
  )
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  report("global_transform_by_refs_write", count, started, uploaded)
}

///|
/// Implements `bench_global_transform_blob_reverse_row_drain`.
fn bench_global_transform_blob_reverse_row_drain(count : Int) -> BenchSample {
  let (world, _, _, _, entities) = make_world_entities(count)
  let started = monotonic_ms()
  let mut changed = 0
  let mut i = entities.length() - 1
  while i >= 0 {
    if world.set_global_transform(entities[i], bench_matrix_for_index(i + 1)) {
      changed = changed + 1
    }
    i = i - 1
  }
  let writes = world.drain_global_transform_blob_write_views()
  let mut uploaded = 0
  for j = 0; j < writes.length(); j = j + 1 {
    uploaded = uploaded + writes[j].bytes.length()
  }
  report(
    "global_transform_blob_reverse_row_drain",
    count,
    started,
    uploaded + writes.length() * 1000000 + changed,
  )
}

///|
/// Implements `bench_set_global_transform_changed`.
fn bench_set_global_transform_changed(count : Int) -> BenchSample {
  let (world, _, _, _, entities) = make_world_entities(count)
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if world.set_global_transform(entities[i], bench_matrix_for_index(i)) {
      checksum = checksum + entities[i].gpu_index()
    }
  }
  if world.has_global_transform_blob_write_views() {
    checksum = checksum + 1
  }
  report("set_global_transform_changed", count, started, checksum)
}

///|
/// Implements `bench_set_global_transform_unchanged`.
fn bench_set_global_transform_unchanged(count : Int) -> BenchSample {
  let (world, _, _, _, entities) = make_world_entities(count)
  let identity = @m44.Matrix44F::identity()
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if world.set_global_transform(entities[i], identity) {
      checksum = checksum + entities[i].gpu_index()
    }
  }
  if world.has_global_transform_blob_write_views() {
    checksum = checksum + 1
  }
  report("set_global_transform_unchanged", count, started, checksum)
}

///|
/// Implements `make_camera_world`.
fn make_camera_world(count : Int) -> (@ecs.World, Array[@ecs.EntityId]) {
  let world = @ecs.World::new()
  let entities : Array[@ecs.EntityId] = []
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  for i = 0; i < count; i = i + 1 {
    let entity = world.create_entity()
    entities.push(entity)
    ignore(
      world.set_camera_matrices(
        entity,
        view,
        proj,
        (0.1 : Float),
        (100.0 : Float),
        (1.0 : Float),
        @ecs.camera_projection_orthographic(),
        (0.0 : Float),
      ),
    )
  }
  ignore(world.drain_camera_blob_write_views())
  (world, entities)
}

///|
/// Implements `make_camera_blob_sync_world`.
fn make_camera_blob_sync_world(
  count : Int,
) -> (
  @ecs.World,
  @ecs.ComponentTypeId,
  @ecs.ComponentTypeId,
  @ecs.ComponentTypeId,
) {
  let world = @ecs.World::new()
  let gt = world.global_transform_component()
  let camera = world.camera_component()
  let lens = world.camera_lens_component()
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  for i = 0; i < count; i = i + 1 {
    let entity = world.create_entity()
    ignore(world.set_global_transform(entity, bench_matrix_for_index(i)))
    ignore(
      world.set_camera_matrices(
        entity,
        view,
        proj,
        (0.1 : Float),
        (100.0 : Float),
        (1.0 : Float),
        @ecs.camera_projection_orthographic(),
        (0.0 : Float),
      ),
    )
    ignore(
      @ecs.add_camera_lens_perspective(
        world,
        entity,
        lens,
        (0.1 : Float),
        (250.0 : Float),
        (1.7777778 : Float),
        Float::from_double(1.0471975511965976),
        (0.0 : Float),
      ),
    )
  }
  ignore(world.drain_global_transform_blob_write_views())
  ignore(world.drain_camera_blob_write_views())
  (world, gt, camera, lens)
}

///|
/// Implements `make_orbit_camera_transform_world`.
fn make_orbit_camera_transform_world(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId) {
  let world = @ecs.World::new()
  let orbit = world.orbit_camera_controller_component()
  let home = world.camera_home_transform_component()
  let id = @m44.Matrix44F::identity()
  for i = 0; i < count; i = i + 1 {
    let entity = world.create_entity()
    ignore(
      world.set_transform_trs(
        entity,
        Float::from_double(i.to_double() * 0.01),
        (0.0 : Float),
        (16.0 : Float),
        0.0,
        0.0,
        0.0,
        1.0,
        (1.0 : Float),
        (1.0 : Float),
        (1.0 : Float),
      ),
    )
    ignore(world.set_global_transform(entity, id))
    ignore(
      @ecs.add_orbit_camera_controller_with_distance(
        world,
        entity,
        orbit,
        0.0,
        0.0,
        (16.0 : Float),
      ),
    )
    ignore(@ecs.set_camera_home_from_current_transform(world, entity, home))
    ignore(
      @ecs.update_orbit_camera_controller_from_mouse_frame(
        world,
        entity,
        true,
        false,
        false,
        false,
        Float::from_double((i % 5).to_double()),
        (1.0 : Float),
        (0.0 : Float),
      ),
    )
  }
  ignore(world.drain_global_transform_blob_write_views())
  (world, orbit, home)
}

///|
/// Implements `bench_set_camera_matrices_changed`.
fn bench_set_camera_matrices_changed(count : Int) -> BenchSample {
  let (world, entities) = make_camera_world(count)
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if world.set_camera_matrices(
        entities[i],
        view,
        proj,
        (0.1 : Float),
        (200.0 : Float),
        (1.0 : Float),
        @ecs.camera_projection_orthographic(),
        (0.0 : Float),
      ) {
      checksum = checksum + entities[i].gpu_index()
    }
  }
  if world.has_camera_blob_write_views() {
    checksum = checksum + 1
  }
  report("set_camera_matrices_changed", count, started, checksum)
}

///|
/// Implements `bench_set_camera_matrices_unchanged`.
fn bench_set_camera_matrices_unchanged(count : Int) -> BenchSample {
  let (world, entities) = make_camera_world(count)
  let view = @m44.Matrix44F::identity()
  let proj = @m44.Matrix44F::identity()
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if world.set_camera_matrices(
        entities[i],
        view,
        proj,
        (0.1 : Float),
        (100.0 : Float),
        (1.0 : Float),
        @ecs.camera_projection_orthographic(),
        (0.0 : Float),
      ) {
      checksum = checksum + entities[i].gpu_index()
    }
  }
  if world.has_camera_blob_write_views() {
    checksum = checksum + 1
  }
  report("set_camera_matrices_unchanged", count, started, checksum)
}

///|
/// Implements `bench_camera_blob_sync_row_query`.
fn bench_camera_blob_sync_row_query(count : Int) -> BenchSample {
  let (world, gt, camera, lens) = make_camera_blob_sync_world(count)
  let query = @ecs.Query::new([gt, camera, lens])
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each(world, row => {
    let entity = row.entity()
    match world.get_global_transform(entity) {
      Some(global) =>
        match global.inverse() {
          Some(view) =>
            row.read(lens, lens_row => {
              let (proj, near, far, aspect, projection_kind, flags) = @ecs.camera_lens_projection_from_view(
                lens_row,
              )
              if world.set_camera_matrices(
                  entity, view, proj, near, far, aspect, projection_kind, flags,
                ) {
                checksum = checksum + entity.gpu_index()
              }
            })
          None => ()
        }
      None => ()
    }
  })
  if world.has_camera_blob_write_views() {
    checksum = checksum + 1
  }
  report("camera_blob_sync_row_query", count, started, checksum)
}

///|
/// Implements `bench_camera_blob_sync_raw_cache`.
fn bench_camera_blob_sync_raw_cache(count : Int) -> BenchSample {
  let (world, gt, camera, lens) = make_camera_blob_sync_world(count)
  let cache = @ecs.RawQueryCache::new([gt, camera, lens])
  let lens_index = cache.component_index(lens)
  cache.refresh(world)
  let started = monotonic_ms()
  let mut checksum = 0
  cache.for_each_archetype(world, arch => {
    let lens_stride = arch.component_stride_at(lens_index)
    let lens_col = arch.read_column_at(lens_index)
    for row = 0; row < arch.length(); row = row + 1 {
      let entity = arch.entity(row)
      match world.get_global_transform(entity) {
        Some(global) =>
          match global.inverse() {
            Some(view) => {
              let lens_start = row * lens_stride
              let lens_row = lens_col[lens_start:lens_start + lens_stride]
              let (proj, near, far, aspect, projection_kind, flags) = @ecs.camera_lens_projection_from_view(
                lens_row,
              )
              if world.set_camera_matrices(
                  entity, view, proj, near, far, aspect, projection_kind, flags,
                ) {
                checksum = checksum + entity.gpu_index()
              }
            }
            None => ()
          }
        None => ()
      }
    }
  })
  if world.has_camera_blob_write_views() {
    checksum = checksum + 1
  }
  report("camera_blob_sync_raw_cache", count, started, checksum)
}

///|
/// Implements `bench_orbit_camera_transform_system_phase`.
fn bench_orbit_camera_transform_system_phase(count : Int) -> BenchSample {
  let (world, orbit, home) = make_orbit_camera_transform_world(count)
  let phase = @ecs.PhaseKey::new("orbit-camera-transform-bench")
  let runner = @ecs.SystemRunner::new()
  runner.add_system(
    @ecs.orbit_camera_transform_system(world, phase, orbit, home),
  )
  let started = monotonic_ms()
  if !runner.run_phase(
      world,
      @ecs.SystemContext::new((0.016 : Float), 1),
      phase,
    ) {
    abort("expected orbit camera transform phase")
  }
  let checksum = if world.has_global_transform_blob_write_views() {
    count
  } else {
    0
  }
  report("orbit_camera_transform_system_phase", count, started, checksum)
}

///|
/// Implements `bench_make_world_batch`.
fn bench_make_world_batch(count : Int) -> BenchSample {
  let started = monotonic_ms()
  let (_, _, _, _) = make_world_batch(count)
  report("make_world_batch", count, started, count)
}

///|
/// Implements `bench_history_raw_set_component_bytes`.
fn bench_history_raw_set_component_bytes(count : Int) -> BenchSample {
  let (world, component, entities) = make_component_world(count)
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if !world.set_component_bytes(entities[i], component, bench_bytes4(i + 17)) {
      abort("expected raw component set")
    }
    checksum = checksum + entities[i].gpu_index()
  }
  report("history_raw_set_component_bytes", count, started, checksum)
}

///|
/// Implements `bench_history_disabled_set_component_bytes`.
fn bench_history_disabled_set_component_bytes(count : Int) -> BenchSample {
  let (world, component, entities) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  history.set_enabled(false)
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if !history.set_component_bytes(
        world,
        entities[i],
        component,
        bench_bytes4(i + 31),
      ) {
      abort("expected disabled history component set")
    }
    checksum = checksum + entities[i].gpu_index()
  }
  report(
    "history_disabled_set_component_bytes",
    count,
    started,
    checksum + history.undo_len(),
  )
}

///|
/// Implements `bench_history_enabled_transaction_set_component_bytes`.
fn bench_history_enabled_transaction_set_component_bytes(
  count : Int,
) -> BenchSample {
  let (world, component, entities) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  if !history.begin_transaction("bench set bytes") {
    abort("expected history transaction begin")
  }
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if !history.set_component_bytes(
        world,
        entities[i],
        component,
        bench_bytes4(i + 47),
      ) {
      abort("expected history component set")
    }
    checksum = checksum + entities[i].gpu_index()
  }
  if !history.commit_transaction() {
    abort("expected history transaction commit")
  }
  report(
    "history_enabled_transaction_set_component_bytes",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_guarded_transaction_set_component_bytes`.
fn bench_history_guarded_transaction_set_component_bytes(
  count : Int,
) -> BenchSample {
  let (world, component, entities) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  history.set_raw_mutation_guard_enabled(true)
  if !history.begin_guarded_transaction(world, "bench guarded set bytes") {
    abort("expected guarded history transaction begin")
  }
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < entities.length(); i = i + 1 {
    if !history.set_component_bytes(
        world,
        entities[i],
        component,
        bench_bytes4(i + 61),
      ) {
      abort("expected guarded history component set")
    }
    checksum = checksum + entities[i].gpu_index()
  }
  if !history.commit_transaction() {
    abort("expected guarded history transaction commit")
  }
  report(
    "history_guarded_transaction_set_component_bytes",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_query_row_tracked_disabled`.
fn bench_history_query_row_tracked_disabled(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  history.set_enabled(false)
  let query = @ecs.Query::new([component])
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each(world, row => {
    let idx = row.entity().gpu_index()
    if !row.write_tracked(history, component, view => {
        write_bench_bytes4_to_view(view, idx + 71)
      }) {
      abort("expected disabled tracked row write")
    }
    checksum = checksum + idx
  })
  report(
    "history_query_row_tracked_disabled",
    count,
    started,
    checksum + history.undo_len(),
  )
}

///|
/// Implements `bench_history_query_row_tracked_enabled`.
fn bench_history_query_row_tracked_enabled(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let query = @ecs.Query::new([component])
  if !history.begin_transaction("bench query row tracked") {
    abort("expected query row history transaction begin")
  }
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each(world, row => {
    let idx = row.entity().gpu_index()
    if !row.write_tracked(history, component, view => {
        write_bench_bytes4_to_view(view, idx + 83)
      }) {
      abort("expected tracked row write")
    }
    checksum = checksum + idx
  })
  if !history.commit_transaction() {
    abort("expected query row history transaction commit")
  }
  report(
    "history_query_row_tracked_enabled",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_archetype_column_tracked_disabled`.
fn bench_history_archetype_column_tracked_disabled(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  history.set_enabled(false)
  let query = @ecs.RawQuery::new([component])
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    let stride = arch.component_stride(component)
    if !arch.write_column_tracked(history, component, col => {
        for row = 0; row < arch.length(); row = row + 1 {
          let idx = arch.entity(row).gpu_index()
          write_bench_bytes4_to_view(
            col.mut_view(start=row * stride, end=row * stride + stride),
            idx + 97,
          )
          checksum = checksum + idx
        }
      }) {
      abort("expected disabled tracked column write")
    }
  })
  report(
    "history_archetype_column_tracked_disabled",
    count,
    started,
    checksum + history.undo_len(),
  )
}

///|
/// Implements `bench_history_archetype_column_tracked_enabled`.
fn bench_history_archetype_column_tracked_enabled(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let query = @ecs.RawQuery::new([component])
  if !history.begin_transaction("bench column tracked") {
    abort("expected column history transaction begin")
  }
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    let stride = arch.component_stride(component)
    if !arch.write_column_tracked(history, component, col => {
        for row = 0; row < arch.length(); row = row + 1 {
          let idx = arch.entity(row).gpu_index()
          write_bench_bytes4_to_view(
            col.mut_view(start=row * stride, end=row * stride + stride),
            idx + 109,
          )
          checksum = checksum + idx
        }
      }) {
      abort("expected tracked column write")
    }
  })
  if !history.commit_transaction() {
    abort("expected column history transaction commit")
  }
  report(
    "history_archetype_column_tracked_enabled",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_archetype_column_raw_noop`.
fn bench_history_archetype_column_raw_noop(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let query = @ecs.RawQuery::new([component])
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    let _ = arch.write_column(component)
    checksum = checksum + arch.length()
  })
  report("history_archetype_column_raw_noop", count, started, checksum)
}

///|
/// Implements `bench_history_archetype_column_tracked_noop`.
fn bench_history_archetype_column_tracked_noop(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let query = @ecs.RawQuery::new([component])
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, component, _col => {
        checksum = checksum + arch.length()
      }) {
      abort("expected noop tracked column write")
    }
  })
  report(
    "history_archetype_column_tracked_noop",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_archetype_column_rows_tracked_noop`.
fn bench_history_archetype_column_rows_tracked_noop(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let query = @ecs.RawQuery::new([component])
  let rows : Array[Int] = []
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    if !arch.write_column_rows_tracked(history, component, rows, (_row, _col) => {
        checksum = checksum + 1
      }) {
      abort("expected noop rows tracked column write")
    }
  })
  report(
    "history_archetype_column_rows_tracked_noop",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_archetype_column_raw_sparse`.
fn bench_history_archetype_column_raw_sparse(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let query = @ecs.RawQuery::new([component])
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    let stride = arch.component_stride(component)
    let col = arch.write_column(component)
    for row = 0; row < arch.length(); row = row + 1 {
      if row % 16 == 0 {
        let idx = arch.entity(row).gpu_index()
        write_bench_bytes4_to_view(
          col.mut_view(start=row * stride, end=row * stride + stride),
          idx + 151,
        )
        checksum = checksum + idx
      }
    }
  })
  report("history_archetype_column_raw_sparse", count, started, checksum)
}

///|
/// Implements `bench_history_archetype_column_tracked_sparse`.
fn bench_history_archetype_column_tracked_sparse(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let query = @ecs.RawQuery::new([component])
  if !history.begin_transaction("bench column tracked sparse") {
    abort("expected sparse column history transaction begin")
  }
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    let stride = arch.component_stride(component)
    if !arch.write_column_tracked(history, component, col => {
        for row = 0; row < arch.length(); row = row + 1 {
          if row % 16 == 0 {
            let idx = arch.entity(row).gpu_index()
            write_bench_bytes4_to_view(
              col.mut_view(start=row * stride, end=row * stride + stride),
              idx + 157,
            )
            checksum = checksum + idx
          }
        }
      }) {
      abort("expected sparse tracked column write")
    }
  })
  if !history.commit_transaction() {
    abort("expected sparse column history transaction commit")
  }
  report(
    "history_archetype_column_tracked_sparse",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_archetype_column_rows_tracked_sparse`.
fn bench_history_archetype_column_rows_tracked_sparse(
  count : Int,
) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let query = @ecs.RawQuery::new([component])
  if !history.begin_transaction("bench column rows tracked sparse") {
    abort("expected sparse column rows history transaction begin")
  }
  let started = monotonic_ms()
  let mut checksum = 0
  query.for_each_archetype(world, arch => {
    let rows : Array[Int] = []
    for row = 0; row < arch.length(); row = row + 1 {
      if row % 16 == 0 {
        rows.push(row)
      }
    }
    if !arch.write_column_rows_tracked(history, component, rows, (row, col) => {
        let idx = arch.entity(row).gpu_index()
        write_bench_bytes4_to_view(col, idx + 163)
        checksum = checksum + idx
      }) {
      abort("expected sparse rows tracked column write")
    }
  })
  if !history.commit_transaction() {
    abort("expected sparse column rows history transaction commit")
  }
  report(
    "history_archetype_column_rows_tracked_sparse",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Implements `bench_history_command_raw_phase`.
fn bench_history_command_raw_phase(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let phase = @ecs.PhaseKey::new("history-command-raw-bench")
  let query = @ecs.Query::new([component])
  let runner = @ecs.SystemRunner::new()
  let mut checksum = 0
  runner.add_system(
    @ecs.System::new("history-command-raw-write", phase, [], [component], (
      system_world,
      _ctx,
      commands,
    ) => {
      query.for_each(system_world, row => {
        let idx = row.entity().gpu_index()
        commands.set_component_bytes(
          row.entity(),
          component,
          bench_bytes4(idx + 131),
        )
        checksum = checksum + idx
      })
    }),
  )
  let started = monotonic_ms()
  if !runner.run_phase(
      world,
      @ecs.SystemContext::new((0.016 : Float), 1),
      phase,
    ) {
    abort("expected raw command phase")
  }
  report("history_command_raw_phase", count, started, checksum)
}

///|
/// Implements `bench_history_command_tracked_phase`.
fn bench_history_command_tracked_phase(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let history = @ecs.WorldHistory::new()
  let phase = @ecs.PhaseKey::new("history-command-tracked-bench")
  let query = @ecs.Query::new([component])
  let runner = @ecs.SystemRunner::new()
  let mut checksum = 0
  runner.add_system(
    @ecs.System::new("history-command-tracked-write", phase, [], [component], (
      system_world,
      _ctx,
      commands,
    ) => {
      query.for_each(system_world, row => {
        let idx = row.entity().gpu_index()
        commands.set_component_bytes(
          row.entity(),
          component,
          bench_bytes4(idx + 149),
        )
        checksum = checksum + idx
      })
    }),
  )
  let started = monotonic_ms()
  if !history.run_system_phase(
      runner,
      world,
      @ecs.SystemContext::new((0.016 : Float), 1),
      phase,
      "bench command tracked",
    ) {
    abort("expected tracked command phase")
  }
  report(
    "history_command_tracked_phase",
    count,
    started,
    checksum + history.undo_len() + history.undo_bytes(),
  )
}

///|
/// Builds a runner with many conflict-free no-op systems for scheduler cache benchmarks.
fn make_cached_noop_runner(
  phase : @ecs.PhaseKey,
  system_count : Int,
) -> @ecs.SystemRunner {
  let runner = @ecs.SystemRunner::new()
  for i = 0; i < system_count; i = i + 1 {
    runner.add_system(
      @ecs.System::new(
        "system-runner-cached-noop-" + i.to_string(),
        phase,
        [],
        [],
        (_world, _ctx, _commands) => (),
      ),
    )
  }
  runner
}

///|
/// Implements `bench_system_runner_phase_plan_cached_many_systems`.
fn bench_system_runner_phase_plan_cached_many_systems(
  count : Int,
) -> BenchSample {
  let phase = @ecs.PhaseKey::new("system-runner-cached-plan-target")
  let runner = make_cached_noop_runner(phase, 32)
  let warm = runner.plan_phase(phase)
  let started = monotonic_ms()
  let mut checksum = warm.system_count + warm.batches.length()
  for _i = 0; _i < count; _i = _i + 1 {
    let plan = runner.plan_phase(phase)
    checksum = checksum + plan.system_count + plan.batches.length()
  }
  report(
    "system_runner_phase_plan_cached_many_systems", count, started, checksum,
  )
}

///|
/// Implements `bench_system_runner_phase_run_cached_many_systems`.
fn bench_system_runner_phase_run_cached_many_systems(
  count : Int,
) -> BenchSample {
  let world = @ecs.World::new()
  let phase = @ecs.PhaseKey::new("system-runner-cached-run-target")
  let runner = make_cached_noop_runner(phase, 32)
  let warm = runner.plan_phase(phase)
  let started = monotonic_ms()
  let mut checksum = warm.system_count + warm.batches.length()
  for i = 0; i < count; i = i + 1 {
    if runner.run_phase(
        world,
        @ecs.SystemContext::new((0.016 : Float), i),
        phase,
      ) {
      checksum = checksum + 1
    }
  }
  report(
    "system_runner_phase_run_cached_many_systems", count, started, checksum,
  )
}

///|
/// Implements `bench_system_runner_phase_empty`.
fn bench_system_runner_phase_empty(count : Int) -> BenchSample {
  let world = @ecs.World::new()
  let other_phase = @ecs.PhaseKey::new("system-runner-empty-other")
  let phase = @ecs.PhaseKey::new("system-runner-empty-target")
  let runner = @ecs.SystemRunner::new()
  runner.add_system(
    @ecs.System::new("system-runner-empty-noop", other_phase, [], [], (
      _world,
      _ctx,
      _commands,
    ) => ()),
  )
  let started = monotonic_ms()
  let mut checksum = 0
  for i = 0; i < count; i = i + 1 {
    if runner.run_phase(
        world,
        @ecs.SystemContext::new((0.016 : Float), i),
        phase,
      ) {
      checksum = checksum + 1
    }
  }
  report("system_runner_phase_empty", count, started, checksum)
}

///|
/// Implements `bench_system_runner_phase_command_buffer`.
fn bench_system_runner_phase_command_buffer(count : Int) -> BenchSample {
  let (world, component, _) = make_component_world(count)
  let phase = @ecs.PhaseKey::new("system-runner-command-buffer-bench")
  let query = @ecs.Query::new([component])
  let runner = @ecs.SystemRunner::new()
  let mut checksum = 0
  runner.add_system(
    @ecs.System::new(
      "system-runner-command-buffer-write",
      phase,
      [],
      [component],
      (system_world, _ctx, commands) => {
        query.for_each(system_world, row => {
          let idx = row.entity().gpu_index()
          commands.set_component_bytes(
            row.entity(),
            component,
            bench_bytes4(idx + 181),
          )
          checksum = checksum + idx
        })
      },
    ),
  )
  let started = monotonic_ms()
  if !runner.run_phase(
      world,
      @ecs.SystemContext::new((0.016 : Float), 1),
      phase,
    ) {
    abort("expected system runner command buffer phase")
  }
  report("system_runner_phase_command_buffer", count, started, checksum)
}
