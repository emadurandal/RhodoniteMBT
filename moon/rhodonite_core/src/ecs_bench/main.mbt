/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
#cfg(target="js")
extern "js" fn monotonic_ms() -> Double =
  #| () => performance.now()

///|
#cfg(target="native")
extern "C" fn c_clock() -> Int = "clock"

///|

///|
/// Implements `monotonic_ms`.
#cfg(target="native")
fn monotonic_ms() -> Double {
  c_clock().to_double() / 1000.0
}

///|

///|
/// Implements `monotonic_ms`.
#cfg(not(any(target="js", target="native")))
fn monotonic_ms() -> Double {
  0.0
}

///|
/// Implements `grid_side_len`.
fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
}

///|
/// Implements `grid_xz_for_index`.
fn grid_xz_for_index(idx : Int, per_side : Int) -> (Float, Float) {
  let ix = idx % per_side
  let iz = idx / per_side
  let half = (per_side - 1).to_double() * 0.5
  (
    Float::from_double((ix.to_double() - half) * 0.14),
    Float::from_double((iz.to_double() - half) * 0.14),
  )
}

///|
/// Implements `make_world`.
fn make_world(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId, Int) {
  let world = @ecs.World::new()
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let per_side = grid_side_len(count)
  let id = @m44.Matrix44F::identity()
  for i = 0; i < count; i = i + 1 {
    let e = world.create_entity()
    let (x, z) = grid_xz_for_index(i, per_side)
    ignore(
      world.set_transform_trs(
        e,
        x,
        (0.0 : Float),
        z,
        0.0,
        0.0,
        0.0,
        1.0,
        (1.0 : Float),
        (1.0 : Float),
        (1.0 : Float),
      ),
    )
    ignore(world.set_global_transform(e, id))
  }
  let _ = world.drain_global_transform_blob_write_views()
  (world, tf, gt, per_side)
}

///|
/// Implements `make_world_batch`.
fn make_world_batch(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId, Int) {
  let world = @ecs.World::new()
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let per_side = grid_side_len(count)
  let _ = world.spawn_transform_global_batch(count, fn(i, _e, tf_row, _gt_row) {
    let (x, z) = grid_xz_for_index(i, per_side)
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row,
      x,
      (0.0 : Float),
      z,
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    )
  })
  let _ = world.drain_global_transform_blob_write_views()
  (world, tf, gt, per_side)
}

///|
/// Implements `bench_bytes4`.
fn bench_bytes4(seed : Int) -> FixedArray[Byte] {
  let bytes = FixedArray::make(4, (0 : Byte))
  bytes[0] = seed.to_byte()
  bytes[1] = (seed + 1).to_byte()
  bytes[2] = (seed + 2).to_byte()
  bytes[3] = (seed + 3).to_byte()
  bytes
}

///|
/// Implements `write_bench_bytes4_to_view`.
fn write_bench_bytes4_to_view(view : MutArrayView[Byte], seed : Int) -> Unit {
  view[0] = seed.to_byte()
  view[1] = (seed + 1).to_byte()
  view[2] = (seed + 2).to_byte()
  view[3] = (seed + 3).to_byte()
}

///|
/// Implements `make_component_world`.
fn make_component_world(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, Array[@ecs.EntityId]) {
  let world = @ecs.World::new()
  let component = world.register_cpu_component("BenchHistoryBytes", 4)
  let entities : Array[@ecs.EntityId] = []
  for i = 0; i < count; i = i + 1 {
    let entity = world.create_entity()
    if !world.add_component_bytes(entity, component, bench_bytes4(i)) {
      abort("expected benchmark component add")
    }
    entities.push(entity)
  }
  (world, component, entities)
}

///|
/// Implements `report`.
fn report(name : String, count : Int, started : Double, checksum : Int) -> Unit {
  let elapsed = monotonic_ms() - started
  println(
    name +
    " count=" +
    count.to_string() +
    " elapsed_ms=" +
    elapsed.to_string() +
    " checksum=" +
    checksum.to_string(),
  )
}

///|
/// Implements `bench_query_row`.
fn bench_query_row(count : Int) -> Unit {
  let (world, tf, _, per_side) = make_world(count)
  let q = @ecs.Query::new([tf])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each(world, row => {
    let idx = row.entity().gpu_index()
    let (x, z) = grid_xz_for_index(idx, per_side)
    row.write(tf, view => {
      @comp.Transform3D::write_position_to_component_mut_view(
        view,
        x,
        Float::from_double(idx.to_double() * 0.001),
        z,
      )
    })
    checksum = checksum + idx
  })
  report("query_row", count, started, checksum)
}

///|
/// Implements `bench_query_archetype`.
fn bench_query_archetype(count : Int) -> Unit {
  let (world, tf, _, per_side) = make_world(count)
  let q = @ecs.RawQuery::new([tf])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each_archetype(world, arch => {
    let stride = arch.component_stride(tf)
    let col = arch.write_column(tf)
    for row = 0; row < arch.length(); row = row + 1 {
      let entity = arch.entity(row)
      let idx = entity.gpu_index()
      let (x, z) = grid_xz_for_index(idx, per_side)
      @comp.Transform3D::write_position_to_component_mut_view(
        col.mut_view(start=row * stride, end=row * stride + 48),
        x,
        Float::from_double(idx.to_double() * 0.001),
        z,
      )
      checksum = checksum + idx
    }
  })
  report("query_archetype", count, started, checksum)
}

///|
/// Implements `bench_builtin_positions`.
fn bench_builtin_positions(count : Int) -> Unit {
  let (world, _, _, per_side) = make_world(count)
  let started = monotonic_ms()
  let mut checksum = 0
  world.update_transform3d_positions(fn(entity) {
    let idx = entity.gpu_index()
    let (x, z) = grid_xz_for_index(idx, per_side)
    checksum = checksum + idx
    (x, Float::from_double(idx.to_double() * 0.001), z)
  })
  report("builtin_positions", count, started, checksum)
}

///|
/// Implements `bench_global_and_drain`.
fn bench_global_and_drain(count : Int) -> Unit {
  let (world, _, _gt, _) = make_world(count)
  let started = monotonic_ms()
  world.update_global_transforms_from_transforms()
  let writes = world.drain_global_transform_blob_write_views()
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  report("global_transform_drain", count, started, uploaded)
}

///|
/// Implements `bench_global_and_drain_views`.
fn bench_global_and_drain_views(count : Int) -> Unit {
  let (world, _, _gt, _) = make_world_batch(count)
  let started = monotonic_ms()
  world.update_global_transforms_from_transforms()
  let writes = world.drain_global_transform_blob_write_views()
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  report("global_transform_drain_views", count, started, uploaded)
}

///|
/// Implements `bench_make_world_batch`.
fn bench_make_world_batch(count : Int) -> Unit {
  let started = monotonic_ms()
  let (_, _, _, _) = make_world_batch(count)
  report("make_world_batch", count, started, count)
}

///|
/// Implements `bench_history_raw_set_component_bytes`.
fn bench_history_raw_set_component_bytes(count : Int) -> Unit {
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
fn bench_history_disabled_set_component_bytes(count : Int) -> Unit {
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
fn bench_history_enabled_transaction_set_component_bytes(count : Int) -> Unit {
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
fn bench_history_guarded_transaction_set_component_bytes(count : Int) -> Unit {
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
fn bench_history_query_row_tracked_disabled(count : Int) -> Unit {
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
fn bench_history_query_row_tracked_enabled(count : Int) -> Unit {
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
fn bench_history_archetype_column_tracked_disabled(count : Int) -> Unit {
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
fn bench_history_archetype_column_tracked_enabled(count : Int) -> Unit {
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
fn bench_history_archetype_column_raw_noop(count : Int) -> Unit {
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
fn bench_history_archetype_column_tracked_noop(count : Int) -> Unit {
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
fn bench_history_archetype_column_rows_tracked_noop(count : Int) -> Unit {
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
fn bench_history_archetype_column_raw_sparse(count : Int) -> Unit {
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
fn bench_history_archetype_column_tracked_sparse(count : Int) -> Unit {
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
fn bench_history_archetype_column_rows_tracked_sparse(count : Int) -> Unit {
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
fn bench_history_command_raw_phase(count : Int) -> Unit {
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
fn bench_history_command_tracked_phase(count : Int) -> Unit {
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
/// Implements `run_history_suite`.
fn run_history_suite(count : Int) -> Unit {
  bench_history_raw_set_component_bytes(count)
  bench_history_disabled_set_component_bytes(count)
  bench_history_enabled_transaction_set_component_bytes(count)
  bench_history_guarded_transaction_set_component_bytes(count)
  bench_history_query_row_tracked_disabled(count)
  bench_history_query_row_tracked_enabled(count)
  bench_history_archetype_column_tracked_disabled(count)
  bench_history_archetype_column_tracked_enabled(count)
  bench_history_archetype_column_raw_noop(count)
  bench_history_archetype_column_tracked_noop(count)
  bench_history_archetype_column_rows_tracked_noop(count)
  bench_history_archetype_column_raw_sparse(count)
  bench_history_archetype_column_tracked_sparse(count)
  bench_history_archetype_column_rows_tracked_sparse(count)
  bench_history_command_raw_phase(count)
  bench_history_command_tracked_phase(count)
}

///|
/// Implements `run_suite`.
fn run_suite(count : Int) -> Unit {
  bench_query_row(count)
  bench_query_archetype(count)
  bench_builtin_positions(count)
  bench_global_and_drain(count)
  bench_global_and_drain_views(count)
  bench_make_world_batch(count)
  run_history_suite(count)
}

///|
/// Implements `main {`.
fn main {
  println(
    "ecs_bench: QueryRow vs archetype vs builtin transform and history paths",
  )
  run_suite(1000)
  run_suite(10000)
}
