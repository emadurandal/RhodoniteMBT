/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
#cfg(target="js")
extern "js" fn monotonic_ms() -> Double =
  #| () => performance.now()

///|
#cfg(target="native")
extern "C" fn native_monotonic_ms() -> Double = "rhodonite_ecs_bench_monotonic_ms"

///|

///|
/// Implements `monotonic_ms`.
#cfg(target="native")
fn monotonic_ms() -> Double {
  native_monotonic_ms()
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
/// Implements `make_world_entities`.
fn make_world_entities(
  count : Int,
) -> (
  @ecs.World,
  @ecs.ComponentTypeId,
  @ecs.ComponentTypeId,
  Int,
  Array[@ecs.EntityId],
) {
  let world = @ecs.World::new()
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let per_side = grid_side_len(count)
  let id = @m44.Matrix44F::identity()
  let entities : Array[@ecs.EntityId] = []
  for i = 0; i < count; i = i + 1 {
    let e = world.create_entity()
    entities.push(e)
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
  (world, tf, gt, per_side, entities)
}

///|
/// Implements `make_world`.
fn make_world(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId, Int) {
  let (world, tf, gt, per_side, _) = make_world_entities(count)
  (world, tf, gt, per_side)
}

///|
/// Implements `make_world_batch_entities`.
fn make_world_batch_entities(
  count : Int,
) -> (
  @ecs.World,
  @ecs.ComponentTypeId,
  @ecs.ComponentTypeId,
  Int,
  Array[@ecs.EntityId],
) {
  let world = @ecs.World::new()
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let per_side = grid_side_len(count)
  let entities = world.spawn_transform_global_batch(count, fn(
    i,
    _e,
    tf_row,
    _gt_row,
  ) {
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
  (world, tf, gt, per_side, entities)
}

///|
/// Implements `make_world_batch`.
fn make_world_batch(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId, Int) {
  let (world, tf, gt, per_side, _) = make_world_batch_entities(count)
  (world, tf, gt, per_side)
}

///|
/// Builds a flat transform world and clears initial transform/upload dirtiness.
fn make_clean_flat_transform_world(
  count : Int,
) -> (@ecs.World, Array[@ecs.EntityId]) {
  let (world, _, _, _, entities) = make_world_batch_entities(count)
  world.update_global_transforms_from_transforms()
  let _ = world.drain_global_transform_blob_write_views()
  (world, entities)
}

///|
/// Builds a broad transform hierarchy and clears initial transform/upload dirtiness.
fn make_clean_broad_transform_world(
  count : Int,
) -> (@ecs.World, Array[@ecs.EntityId]) {
  let (world, _, _, _, entities) = make_world_batch_entities(count)
  if count > 1 {
    let root = entities[0]
    for i = 1; i < entities.length(); i = i + 1 {
      ignore(world.set_child_of(entities[i], root))
    }
  }
  world.update_global_transforms_from_transforms()
  let _ = world.drain_global_transform_blob_write_views()
  (world, entities)
}

///|
/// Builds a chain transform hierarchy and clears initial transform/upload dirtiness.
fn make_clean_chain_transform_world(
  count : Int,
) -> (@ecs.World, Array[@ecs.EntityId]) {
  let (world, _, _, _, entities) = make_world_batch_entities(count)
  for i = 1; i < entities.length(); i = i + 1 {
    ignore(world.set_child_of(entities[i], entities[i - 1]))
  }
  world.update_global_transforms_from_transforms()
  let _ = world.drain_global_transform_blob_write_views()
  (world, entities)
}

///|
/// Marks one entity's Transform3D dirty with a deterministic changed translation.
fn mark_transform_propagation_dirty(
  world : @ecs.World,
  entity : @ecs.EntityId,
  seed : Int,
) -> Int {
  let idx = entity.gpu_index()
  let changed = world.set_transform_trs(
    entity,
    Float::from_double(idx.to_double() * 0.01 + seed.to_double() * 0.001),
    Float::from_double(seed.to_double() * 0.002 + 1.0),
    Float::from_double(idx.to_double() * -0.01),
    0.0,
    0.0,
    0.0,
    1.0,
    (1.0 : Float),
    (1.0 : Float),
    (1.0 : Float),
  )
  if changed {
    idx + 1
  } else {
    idx
  }
}

///|
/// Returns uploaded byte count from pending GlobalTransform blob write views.
fn drain_global_transform_upload_bytes(world : @ecs.World) -> Int {
  let writes = world.drain_global_transform_blob_write_views()
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  uploaded
}

///|
/// Builds a runner that executes the builtin dirty TransformPropagation path.
fn make_dirty_transform_propagation_runner(
  world : @ecs.World,
  phase : @ecs.PhaseKey,
) -> @ecs.SystemRunner {
  let runner = @ecs.SystemRunner::new()
  runner.add_system(@ecs.transform_propagation_system(world, phase))
  runner
}

///|
/// Builds a runner that forces the public full transform recompute path.
fn make_full_transform_propagation_runner(
  world : @ecs.World,
  phase : @ecs.PhaseKey,
) -> @ecs.SystemRunner {
  let runner = @ecs.SystemRunner::new()
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let co = world.child_of_component()
  runner.add_system(
    @ecs.System::new("TransformPropagationFullBench", phase, [tf, co], [gt], (
      system_world,
      _ctx,
      _commands,
    ) => system_world.update_global_transforms_from_transforms()),
  )
  runner
}

///|
/// Runs one transform propagation benchmark phase and drains resulting uploads.
fn run_transform_propagation_runner(
  name : String,
  count : Int,
  world : @ecs.World,
  runner : @ecs.SystemRunner,
  phase : @ecs.PhaseKey,
  checksum_seed : Int,
) -> BenchSample {
  let started = monotonic_ms()
  if !runner.run_phase(
      world,
      @ecs.SystemContext::new((0.016 : Float), 1),
      phase,
    ) {
    abort("expected transform propagation benchmark phase")
  }
  let uploaded = drain_global_transform_upload_bytes(world)
  report(name, count, started, uploaded + checksum_seed + 1)
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
  let component = world.register_component("BenchHistoryBytes", 4)
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
/// One measured benchmark sample.
priv struct BenchSample {
  elapsed_ms : Double
  checksum : Int
}

///|
/// Implements `bench_warmup_runs`.
fn bench_warmup_runs() -> Int {
  1
}

///|
/// Implements `bench_measured_runs`.
fn bench_measured_runs() -> Int {
  5
}

///|
/// Implements `bench_schema_version`.
fn bench_schema_version() -> Int {
  1
}

///|
/// Implements `bench_sample`.
fn bench_sample(started : Double, checksum : Int) -> BenchSample {
  { elapsed_ms: monotonic_ms() - started, checksum }
}

///|
/// Implements `sorted_times`.
fn sorted_times(times : FixedArray[Double], count : Int) -> FixedArray[Double] {
  let out = FixedArray::make(count, 0.0)
  for i = 0; i < count; i = i + 1 {
    out[i] = times[i]
  }
  for i = 0; i < count; i = i + 1 {
    for j = i + 1; j < count; j = j + 1 {
      if out[j] < out[i] {
        let tmp = out[i]
        out[i] = out[j]
        out[j] = tmp
      }
    }
  }
  out
}

///|
/// Implements `report_measurement`.
fn report_measurement(
  name : String,
  count : Int,
  times : FixedArray[Double],
  checksum : Int,
) -> Unit {
  let runs = times.length()
  let sorted = sorted_times(times, runs)
  let min_ms = sorted[0]
  let median_ms = sorted[runs / 2]
  let max_ms = sorted[runs - 1]
  let ns_per_item = if count > 0 {
    median_ms * 1000000.0 / count.to_double()
  } else {
    0.0
  }
  println(
    name +
    " count=" +
    count.to_string() +
    " runs=" +
    runs.to_string() +
    " min_ms=" +
    min_ms.to_string() +
    " median_ms=" +
    median_ms.to_string() +
    " max_ms=" +
    max_ms.to_string() +
    " ns_per_item=" +
    ns_per_item.to_string() +
    " checksum=" +
    checksum.to_string(),
  )
  println(
    "ecs_bench_result " +
    "{\"schema\":" +
    bench_schema_version().to_string() +
    ",\"case\":\"" +
    name +
    "\",\"count\":" +
    count.to_string() +
    ",\"runs\":" +
    runs.to_string() +
    ",\"min_ms\":" +
    min_ms.to_string() +
    ",\"median_ms\":" +
    median_ms.to_string() +
    ",\"max_ms\":" +
    max_ms.to_string() +
    ",\"ns_per_item\":" +
    ns_per_item.to_string() +
    ",\"checksum\":" +
    checksum.to_string() +
    "}",
  )
}

///|
/// Implements `run_case`.
fn run_case(name : String, count : Int, measure : (Int) -> BenchSample) -> Unit {
  for warmup = 0; warmup < bench_warmup_runs(); warmup = warmup + 1 {
    ignore(measure(count))
  }
  let runs = bench_measured_runs()
  let times = FixedArray::make(runs, 0.0)
  let mut checksum = 0
  for i = 0; i < runs; i = i + 1 {
    let sample = measure(count)
    times[i] = sample.elapsed_ms
    checksum = sample.checksum
  }
  report_measurement(name, count, times, checksum)
}

///|
/// Implements `report`.
fn report(
  name : String,
  count : Int,
  started : Double,
  checksum : Int,
) -> BenchSample {
  ignore(name)
  ignore(count)
  bench_sample(started, checksum)
}

///|
/// Implements `bench_query_row`.
fn bench_query_row(count : Int) -> BenchSample {
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
/// Implements `bench_query_row_indexed`.
fn bench_query_row_indexed(count : Int) -> BenchSample {
  let (world, tf, _, per_side) = make_world(count)
  let q = @ecs.Query::new([tf])
  let tf_index = q.component_index(tf)
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each(world, row => {
    let idx = row.entity().gpu_index()
    let (x, z) = grid_xz_for_index(idx, per_side)
    row.write_at(tf_index, view => {
      @comp.Transform3D::write_position_to_component_mut_view(
        view,
        x,
        Float::from_double(idx.to_double() * 0.001),
        z,
      )
    })
    checksum = checksum + idx
  })
  report("query_row_indexed", count, started, checksum)
}

///|
/// Implements `bench_query_archetype`.
fn bench_query_archetype(count : Int) -> BenchSample {
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
/// Implements `bench_query_archetype_indexed`.
fn bench_query_archetype_indexed(count : Int) -> BenchSample {
  let (world, tf, _, per_side) = make_world(count)
  let q = @ecs.RawQuery::new([tf])
  let tf_index = q.component_index(tf)
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each_archetype(world, arch => {
    let stride = arch.component_stride_at(tf_index)
    let col = arch.write_column_at(tf_index)
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
  report("query_archetype_indexed", count, started, checksum)
}

///|
/// Implements `many_archetype_signature_count`.
fn many_archetype_signature_count() -> Int {
  32
}

///|
/// Implements `make_many_archetype_query_world`.
fn make_many_archetype_query_world(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, Int) {
  let world = @ecs.World::new()
  let target = world.register_component("BenchManyArchetypeTarget", 4)
  let markers : Array[@ecs.ComponentTypeId] = []
  for i = 0; i < 5; i = i + 1 {
    markers.push(
      world.register_component("BenchManyArchetypeMarker" + i.to_string(), 4),
    )
  }
  let signature_count = many_archetype_signature_count()
  for signature = 0; signature < signature_count; signature = signature + 1 {
    let extra_rows = if signature < count % signature_count { 1 } else { 0 }
    let rows = count / signature_count + extra_rows
    if rows > 0 {
      let components : Array[@ecs.ComponentTypeId] = [target]
      let mut mask = 1
      for bit = 0; bit < markers.length(); bit = bit + 1 {
        if signature / mask % 2 == 1 {
          components.push(markers[bit])
        }
        mask = mask * 2
      }
      ignore(
        world.spawn_batch(components, rows, fn(i, _entity, row) {
          row.write(target, bytes => bytes[0] = (signature + i).to_byte())
        }),
      )
    }
  }
  (world, target, signature_count)
}

///|
/// Implements `make_many_archetype_without_query_world`.
fn make_many_archetype_without_query_world(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId, Int) {
  let world = @ecs.World::new()
  let target = world.register_component("BenchManyArchetypeWithoutTarget", 4)
  let excluded = world.register_component(
    "BenchManyArchetypeWithoutExcluded", 4,
  )
  let markers : Array[@ecs.ComponentTypeId] = []
  for i = 0; i < 4; i = i + 1 {
    markers.push(
      world.register_component(
        "BenchManyArchetypeWithoutMarker" + i.to_string(),
        4,
      ),
    )
  }
  let signature_count = many_archetype_signature_count()
  for signature = 0; signature < signature_count; signature = signature + 1 {
    let extra_rows = if signature < count % signature_count { 1 } else { 0 }
    let rows = count / signature_count + extra_rows
    if rows > 0 {
      let components : Array[@ecs.ComponentTypeId] = [target]
      if signature % 2 == 1 {
        components.push(excluded)
      }
      let mut mask = 1
      for bit = 0; bit < markers.length(); bit = bit + 1 {
        if signature / mask % 2 == 1 {
          components.push(markers[bit])
        }
        mask = mask * 2
      }
      ignore(
        world.spawn_batch(components, rows, fn(i, _entity, row) {
          row.write(target, bytes => bytes[0] = (signature + i).to_byte())
        }),
      )
    }
  }
  (world, target, excluded, signature_count)
}

///|
/// Implements `query_plan_checksum`.
fn query_plan_checksum(plan : @ecs.QueryPlan) -> Int {
  let mut checksum = plan.candidate_archetype_count +
    plan.matched_archetype_count +
    plan.matched_row_count
  for i = 0; i < plan.archetypes.length(); i = i + 1 {
    checksum = checksum +
      plan.archetypes[i].archetype_index +
      plan.archetypes[i].row_count
  }
  if plan.stale {
    checksum = checksum + 1
  }
  checksum
}

///|
/// Implements `bench_query_many_archetypes_without_plan`.
fn bench_query_many_archetypes_without_plan(count : Int) -> BenchSample {
  let (world, target, excluded, _) = make_many_archetype_without_query_world(
    count,
  )
  let q = @ecs.Query::new_with_excluded([target], [excluded])
  let started = monotonic_ms()
  let plan = q.plan(world)
  report(
    "query_many_archetypes_without_plan",
    count,
    started,
    query_plan_checksum(plan),
  )
}

///|
/// Implements `bench_query_many_archetypes_without_row`.
fn bench_query_many_archetypes_without_row(count : Int) -> BenchSample {
  let (world, target, excluded, _) = make_many_archetype_without_query_world(
    count,
  )
  let q = @ecs.Query::new_with_excluded([target], [excluded])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each(world, row => {
    row.write(target, bytes => {
      bytes[0] = (bytes[0].to_int() + 1).to_byte()
      checksum = checksum + bytes[0].to_int()
    })
  })
  report("query_many_archetypes_without_row", count, started, checksum)
}

///|
/// Implements `bench_query_many_archetypes_without_archetype`.
fn bench_query_many_archetypes_without_archetype(count : Int) -> BenchSample {
  let (world, target, excluded, _) = make_many_archetype_without_query_world(
    count,
  )
  let q = @ecs.RawQuery::new_with_excluded([target], [excluded])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each_archetype(world, arch => {
    let stride = arch.component_stride(target)
    let col = arch.write_column(target)
    for row = 0; row < arch.length(); row = row + 1 {
      let base = row * stride
      col[base] = (col[base].to_int() + 1).to_byte()
      checksum = checksum + col[base].to_int()
    }
  })
  report("query_many_archetypes_without_archetype", count, started, checksum)
}

///|
/// Implements `bench_query_many_archetypes_plan`.
fn bench_query_many_archetypes_plan(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let q = @ecs.Query::new([target])
  let started = monotonic_ms()
  let plan = q.plan(world)
  report(
    "query_many_archetypes_plan",
    count,
    started,
    query_plan_checksum(plan),
  )
}

///|
/// Implements `bench_query_many_archetypes_prepare`.
fn bench_query_many_archetypes_prepare(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let q = @ecs.Query::new([target])
  let started = monotonic_ms()
  let prepared = q.prepare(world)
  let plan = prepared.plan(world)
  report(
    "query_many_archetypes_prepare",
    count,
    started,
    query_plan_checksum(plan),
  )
}

///|
/// Implements `bench_query_many_archetypes_row`.
fn bench_query_many_archetypes_row(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let q = @ecs.Query::new([target])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each(world, row => {
    row.write(target, bytes => {
      bytes[0] = (bytes[0].to_int() + 1).to_byte()
      checksum = checksum + bytes[0].to_int()
    })
  })
  report("query_many_archetypes_row", count, started, checksum)
}

///|
/// Implements `bench_query_many_archetypes_archetype`.
fn bench_query_many_archetypes_archetype(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let q = @ecs.RawQuery::new([target])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each_archetype(world, arch => {
    let stride = arch.component_stride(target)
    let col = arch.write_column(target)
    for row = 0; row < arch.length(); row = row + 1 {
      let base = row * stride
      col[base] = (col[base].to_int() + 1).to_byte()
      checksum = checksum + col[base].to_int()
    }
  })
  report("query_many_archetypes_archetype", count, started, checksum)
}

///|
/// Implements `bench_prepared_query_many_archetypes_reuse`.
fn bench_prepared_query_many_archetypes_reuse(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let started = monotonic_ms()
  let mut checksum = 0
  prepared.for_each(world, row => {
    row.read(target, bytes => checksum = checksum + bytes[0].to_int())
  })
  report("prepared_query_many_archetypes_reuse", count, started, checksum)
}

///|
/// Implements `bench_prepared_query_tiny_rows_many_archetypes_repeated`.
fn bench_prepared_query_tiny_rows_many_archetypes_repeated(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(
    many_archetype_signature_count(),
  )
  let prepared = @ecs.Query::new([target]).prepare(world)
  let started = monotonic_ms()
  let mut checksum = 0
  for _iteration = 0; _iteration < count; _iteration = _iteration + 1 {
    prepared.for_each(world, row => {
      row.read(target, bytes => checksum = checksum + bytes[0].to_int())
    })
  }
  report(
    "prepared_query_tiny_rows_many_archetypes_repeated", count, started, checksum,
  )
}

///|
/// Implements `bench_prepared_query_tiny_rows_many_archetypes_repeated_read_at`.
fn bench_prepared_query_tiny_rows_many_archetypes_repeated_read_at(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(
    many_archetype_signature_count(),
  )
  let prepared = @ecs.Query::new([target]).prepare(world)
  let started = monotonic_ms()
  let mut checksum = 0
  for _iteration = 0; _iteration < count; _iteration = _iteration + 1 {
    prepared.for_each_read_at(world, 0, (_entity, bytes) => {
      checksum = checksum + bytes[0].to_int()
    })
  }
  report(
    "prepared_query_tiny_rows_many_archetypes_repeated_read_at", count, started,
    checksum,
  )
}

///|
/// Implements `bench_raw_prepared_query_tiny_rows_many_archetypes_repeated`.
fn bench_raw_prepared_query_tiny_rows_many_archetypes_repeated(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(
    many_archetype_signature_count(),
  )
  let prepared = @ecs.RawQuery::new([target]).prepare(world)
  let started = monotonic_ms()
  let mut checksum = 0
  for _iteration = 0; _iteration < count; _iteration = _iteration + 1 {
    prepared.for_each(world, row => {
      let bytes = row.read_view_at(0)
      checksum = checksum + bytes[0].to_int()
    })
  }
  report(
    "raw_prepared_query_tiny_rows_many_archetypes_repeated", count, started, checksum,
  )
}

///|
/// Implements `bench_raw_prepared_query_tiny_rows_many_archetypes_repeated_read_view_at`.
fn bench_raw_prepared_query_tiny_rows_many_archetypes_repeated_read_view_at(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(
    many_archetype_signature_count(),
  )
  let prepared = @ecs.RawQuery::new([target]).prepare(world)
  let started = monotonic_ms()
  let mut checksum = 0
  for _iteration = 0; _iteration < count; _iteration = _iteration + 1 {
    prepared.for_each_read_view_at(world, 0, (_entity, bytes) => {
      checksum = checksum + bytes[0].to_int()
    })
  }
  report(
    "raw_prepared_query_tiny_rows_many_archetypes_repeated_read_view_at", count,
    started, checksum,
  )
}

///|
/// Implements `bench_prepared_query_many_archetypes_rebuild`.
fn bench_prepared_query_many_archetypes_rebuild(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let extra = world.register_component("BenchManyArchetypeExtra", 4)
  ignore(
    world.spawn_batch([target, extra], 1, fn(_i, _entity, row) {
      row.write(target, bytes => bytes[0] = (7 : Byte))
    }),
  )
  let started = monotonic_ms()
  let mut checksum = 0
  prepared.for_each(world, row => {
    row.read(target, bytes => checksum = checksum + bytes[0].to_int())
  })
  report("prepared_query_many_archetypes_rebuild", count, started, checksum)
}

///|
/// Implements `bench_prepared_query_many_archetypes_is_stale_fresh`.
fn bench_prepared_query_many_archetypes_is_stale_fresh(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let started = monotonic_ms()
  let checksum = if prepared.is_stale(world) { 1 } else { 0 }
  report(
    "prepared_query_many_archetypes_is_stale_fresh", count, started, checksum,
  )
}

///|
/// Implements `bench_prepared_query_many_archetypes_refresh_fresh`.
fn bench_prepared_query_many_archetypes_refresh_fresh(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let started = monotonic_ms()
  let refreshed = prepared.refresh(world)
  let plan = refreshed.plan(world)
  report(
    "prepared_query_many_archetypes_refresh_fresh",
    count,
    started,
    query_plan_checksum(plan),
  )
}

///|
/// Implements `bench_prepared_query_many_archetypes_refresh_stale`.
fn bench_prepared_query_many_archetypes_refresh_stale(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let extra = world.register_component("BenchManyArchetypeRefreshExtra", 4)
  ignore(
    world.spawn_batch([target, extra], 1, fn(_i, _entity, row) {
      row.write(target, bytes => bytes[0] = (7 : Byte))
    }),
  )
  let started = monotonic_ms()
  let refreshed = prepared.refresh(world)
  let plan = refreshed.plan(world)
  report(
    "prepared_query_many_archetypes_refresh_stale",
    count,
    started,
    query_plan_checksum(plan),
  )
}

///|
/// Implements `bench_prepared_query_many_archetypes_refresh_then_reuse`.
fn bench_prepared_query_many_archetypes_refresh_then_reuse(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let extra = world.register_component("BenchManyArchetypeRefreshReuse", 4)
  ignore(
    world.spawn_batch([target, extra], 1, fn(_i, _entity, row) {
      row.write(target, bytes => bytes[0] = (7 : Byte))
    }),
  )
  let refreshed = prepared.refresh(world)
  let started = monotonic_ms()
  let mut checksum = 0
  refreshed.for_each(world, row => {
    row.read(target, bytes => checksum = checksum + bytes[0].to_int())
  })
  report(
    "prepared_query_many_archetypes_refresh_then_reuse", count, started, checksum,
  )
}

///|
/// Implements `bench_query_cache_many_archetypes_reuse`.
fn bench_query_cache_many_archetypes_reuse(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let cache = @ecs.QueryCache::new([target])
  cache.refresh(world)
  let started = monotonic_ms()
  let mut checksum = 0
  cache.for_each(world, row => {
    row.read(target, bytes => checksum = checksum + bytes[0].to_int())
  })
  report("query_cache_many_archetypes_reuse", count, started, checksum)
}

///|
/// Implements `bench_query_cache_many_archetypes_refresh_after_structural_change`.
fn bench_query_cache_many_archetypes_refresh_after_structural_change(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let cache = @ecs.QueryCache::new([target])
  cache.refresh(world)
  let extra = world.register_component("BenchQueryCacheExtra", 4)
  ignore(
    world.spawn_batch([target, extra], 1, fn(_i, _entity, row) {
      row.write(target, bytes => bytes[0] = (7 : Byte))
    }),
  )
  let started = monotonic_ms()
  let mut checksum = 0
  cache.for_each(world, row => {
    row.read(target, bytes => checksum = checksum + bytes[0].to_int())
  })
  report(
    "query_cache_many_archetypes_refresh_after_structural_change", count, started,
    checksum,
  )
}

///|
/// Implements `bench_raw_query_cache_many_archetypes_archetype_reuse`.
fn bench_raw_query_cache_many_archetypes_archetype_reuse(
  count : Int,
) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let cache = @ecs.RawQueryCache::new([target])
  cache.refresh(world)
  let started = monotonic_ms()
  let mut checksum = 0
  cache.for_each_archetype(world, arch => {
    let stride = arch.component_stride(target)
    let col = arch.read_column(target)
    for row = 0; row < arch.length(); row = row + 1 {
      checksum = checksum + col[row * stride].to_int()
    }
  })
  report(
    "raw_query_cache_many_archetypes_archetype_reuse", count, started, checksum,
  )
}

///|
/// Implements `bench_builtin_positions`.
fn bench_builtin_positions(count : Int) -> BenchSample {
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
fn bench_global_and_drain(count : Int) -> BenchSample {
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
fn bench_global_and_drain_views(count : Int) -> BenchSample {
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
/// Implements `bench_transform_propagation_dirty_noop_flat`.
fn bench_transform_propagation_dirty_noop_flat(count : Int) -> BenchSample {
  let (world, _) = make_clean_flat_transform_world(count)
  let phase = @ecs.PhaseKey::new("transform-propagation-dirty-noop-flat")
  let runner = make_dirty_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_dirty_noop_flat", count, world, runner, phase, count,
  )
}

///|
/// Implements `bench_transform_propagation_dirty_one_flat`.
fn bench_transform_propagation_dirty_one_flat(count : Int) -> BenchSample {
  let (world, entities) = make_clean_flat_transform_world(count)
  let target_index = if count > 0 { count / 2 } else { 0 }
  let checksum_seed = if entities.length() > 0 {
    mark_transform_propagation_dirty(world, entities[target_index], count)
  } else {
    0
  }
  let phase = @ecs.PhaseKey::new("transform-propagation-dirty-one-flat")
  let runner = make_dirty_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_dirty_one_flat", count, world, runner, phase, checksum_seed,
  )
}

///|
/// Implements `bench_transform_propagation_full_one_flat`.
fn bench_transform_propagation_full_one_flat(count : Int) -> BenchSample {
  let (world, entities) = make_clean_flat_transform_world(count)
  let target_index = if count > 0 { count / 2 } else { 0 }
  let checksum_seed = if entities.length() > 0 {
    mark_transform_propagation_dirty(world, entities[target_index], count)
  } else {
    0
  }
  let phase = @ecs.PhaseKey::new("transform-propagation-full-one-flat")
  let runner = make_full_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_full_one_flat", count, world, runner, phase, checksum_seed,
  )
}

///|
/// Implements `bench_transform_propagation_dirty_broad_root`.
fn bench_transform_propagation_dirty_broad_root(count : Int) -> BenchSample {
  let (world, entities) = make_clean_broad_transform_world(count)
  let checksum_seed = if entities.length() > 0 {
    mark_transform_propagation_dirty(world, entities[0], count)
  } else {
    0
  }
  let phase = @ecs.PhaseKey::new("transform-propagation-dirty-broad-root")
  let runner = make_dirty_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_dirty_broad_root", count, world, runner, phase, checksum_seed,
  )
}

///|
/// Implements `bench_transform_propagation_full_broad_root`.
fn bench_transform_propagation_full_broad_root(count : Int) -> BenchSample {
  let (world, entities) = make_clean_broad_transform_world(count)
  let checksum_seed = if entities.length() > 0 {
    mark_transform_propagation_dirty(world, entities[0], count)
  } else {
    0
  }
  let phase = @ecs.PhaseKey::new("transform-propagation-full-broad-root")
  let runner = make_full_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_full_broad_root", count, world, runner, phase, checksum_seed,
  )
}

///|
/// Implements `bench_transform_propagation_dirty_chain_root`.
fn bench_transform_propagation_dirty_chain_root(count : Int) -> BenchSample {
  let (world, entities) = make_clean_chain_transform_world(count)
  let checksum_seed = if entities.length() > 0 {
    mark_transform_propagation_dirty(world, entities[0], count)
  } else {
    0
  }
  let phase = @ecs.PhaseKey::new("transform-propagation-dirty-chain-root")
  let runner = make_dirty_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_dirty_chain_root", count, world, runner, phase, checksum_seed,
  )
}

///|
/// Implements `bench_transform_propagation_full_chain_root`.
fn bench_transform_propagation_full_chain_root(count : Int) -> BenchSample {
  let (world, entities) = make_clean_chain_transform_world(count)
  let checksum_seed = if entities.length() > 0 {
    mark_transform_propagation_dirty(world, entities[0], count)
  } else {
    0
  }
  let phase = @ecs.PhaseKey::new("transform-propagation-full-chain-root")
  let runner = make_full_transform_propagation_runner(world, phase)
  run_transform_propagation_runner(
    "transform_propagation_full_chain_root", count, world, runner, phase, checksum_seed,
  )
}

///|
/// Implements `bench_matrix_for_index`.
fn bench_matrix_for_index(idx : Int) -> @m44.Matrix44F {
  @m44.Matrix44::translation(
    Float::from_double(idx.to_double() * 0.001),
    Float::from_double(idx.to_double() * 0.002),
    Float::from_double(idx.to_double() * -0.001),
    (1.0 : Float),
    (0.0 : Float),
  )
}
