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
  let target = world.register_cpu_component("BenchManyArchetypeTarget", 4)
  let markers : Array[@ecs.ComponentTypeId] = []
  for i = 0; i < 5; i = i + 1 {
    markers.push(
      world.register_cpu_component(
        "BenchManyArchetypeMarker" + i.to_string(),
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
/// Implements `bench_prepared_query_many_archetypes_rebuild`.
fn bench_prepared_query_many_archetypes_rebuild(count : Int) -> BenchSample {
  let (world, target, _) = make_many_archetype_query_world(count)
  let prepared = @ecs.Query::new([target]).prepare(world)
  let extra = world.register_cpu_component("BenchManyArchetypeExtra", 4)
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
  let extra = world.register_cpu_component("BenchManyArchetypeRefreshExtra", 4)
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
  let extra = world.register_cpu_component("BenchManyArchetypeRefreshReuse", 4)
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
  let extra = world.register_cpu_component("BenchQueryCacheExtra", 4)
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

///|
/// Implements `run_history_suite`.
fn run_history_suite(count : Int) -> Unit {
  run_case(
    "history_raw_set_component_bytes", count, bench_history_raw_set_component_bytes,
  )
  run_case(
    "history_disabled_set_component_bytes", count, bench_history_disabled_set_component_bytes,
  )
  run_case(
    "history_enabled_transaction_set_component_bytes", count, bench_history_enabled_transaction_set_component_bytes,
  )
  run_case(
    "history_guarded_transaction_set_component_bytes", count, bench_history_guarded_transaction_set_component_bytes,
  )
  run_case(
    "history_query_row_tracked_disabled", count, bench_history_query_row_tracked_disabled,
  )
  run_case(
    "history_query_row_tracked_enabled", count, bench_history_query_row_tracked_enabled,
  )
  run_case(
    "history_archetype_column_tracked_disabled", count, bench_history_archetype_column_tracked_disabled,
  )
  run_case(
    "history_archetype_column_tracked_enabled", count, bench_history_archetype_column_tracked_enabled,
  )
  run_case(
    "history_archetype_column_raw_noop", count, bench_history_archetype_column_raw_noop,
  )
  run_case(
    "history_archetype_column_tracked_noop", count, bench_history_archetype_column_tracked_noop,
  )
  run_case(
    "history_archetype_column_rows_tracked_noop", count, bench_history_archetype_column_rows_tracked_noop,
  )
  run_case(
    "history_archetype_column_raw_sparse", count, bench_history_archetype_column_raw_sparse,
  )
  run_case(
    "history_archetype_column_tracked_sparse", count, bench_history_archetype_column_tracked_sparse,
  )
  run_case(
    "history_archetype_column_rows_tracked_sparse", count, bench_history_archetype_column_rows_tracked_sparse,
  )
  run_case("history_command_raw_phase", count, bench_history_command_raw_phase)
  run_case(
    "history_command_tracked_phase", count, bench_history_command_tracked_phase,
  )
}

///|
/// Implements `run_suite`.
fn run_suite(count : Int) -> Unit {
  run_case("query_row", count, bench_query_row)
  run_case("query_archetype", count, bench_query_archetype)
  run_case(
    "query_many_archetypes_plan", count, bench_query_many_archetypes_plan,
  )
  run_case(
    "query_many_archetypes_prepare", count, bench_query_many_archetypes_prepare,
  )
  run_case("query_many_archetypes_row", count, bench_query_many_archetypes_row)
  run_case(
    "query_many_archetypes_archetype", count, bench_query_many_archetypes_archetype,
  )
  run_case(
    "prepared_query_many_archetypes_reuse", count, bench_prepared_query_many_archetypes_reuse,
  )
  run_case(
    "prepared_query_many_archetypes_rebuild", count, bench_prepared_query_many_archetypes_rebuild,
  )
  run_case(
    "prepared_query_many_archetypes_is_stale_fresh", count, bench_prepared_query_many_archetypes_is_stale_fresh,
  )
  run_case(
    "prepared_query_many_archetypes_refresh_fresh", count, bench_prepared_query_many_archetypes_refresh_fresh,
  )
  run_case(
    "prepared_query_many_archetypes_refresh_stale", count, bench_prepared_query_many_archetypes_refresh_stale,
  )
  run_case(
    "prepared_query_many_archetypes_refresh_then_reuse", count, bench_prepared_query_many_archetypes_refresh_then_reuse,
  )
  run_case(
    "query_cache_many_archetypes_reuse", count, bench_query_cache_many_archetypes_reuse,
  )
  run_case(
    "query_cache_many_archetypes_refresh_after_structural_change", count, bench_query_cache_many_archetypes_refresh_after_structural_change,
  )
  run_case(
    "raw_query_cache_many_archetypes_archetype_reuse", count, bench_raw_query_cache_many_archetypes_archetype_reuse,
  )
  run_case("builtin_positions", count, bench_builtin_positions)
  run_case("global_transform_drain", count, bench_global_and_drain)
  run_case("global_transform_drain_views", count, bench_global_and_drain_views)
  run_case(
    "global_transform_dense_range_write", count, bench_global_transform_dense_range_write,
  )
  run_case(
    "global_transform_by_refs_write", count, bench_global_transform_by_refs_write,
  )
  run_case(
    "set_global_transform_changed", count, bench_set_global_transform_changed,
  )
  run_case(
    "set_global_transform_unchanged", count, bench_set_global_transform_unchanged,
  )
  run_case(
    "set_camera_matrices_changed", count, bench_set_camera_matrices_changed,
  )
  run_case(
    "set_camera_matrices_unchanged", count, bench_set_camera_matrices_unchanged,
  )
  run_case("make_world_batch", count, bench_make_world_batch)
  run_case("system_runner_phase_empty", count, bench_system_runner_phase_empty)
  run_case(
    "system_runner_phase_plan_cached_many_systems", count, bench_system_runner_phase_plan_cached_many_systems,
  )
  run_case(
    "system_runner_phase_run_cached_many_systems", count, bench_system_runner_phase_run_cached_many_systems,
  )
  run_case(
    "system_runner_phase_command_buffer", count, bench_system_runner_phase_command_buffer,
  )
  run_history_suite(count)
}

///|
/// Runs the fixed ECS microbench suite.
fn main {
  println("ecs_bench: fixed ECS microbench suite (warmup=1 measured=5)")
  run_suite(1000)
  run_suite(10000)
}
