///|
#cfg(target="js")
extern "js" fn monotonic_ms() -> Double =
  #| () => performance.now()

///|
#cfg(target="native")
extern "C" fn c_clock() -> Int = "clock"

///|
#cfg(target="native")
fn monotonic_ms() -> Double {
  c_clock().to_double() / 1000.0
}

///|
#cfg(not(any(target="js", target="native")))
fn monotonic_ms() -> Double {
  0.0
}

///|
fn grid_side_len(n : Int) -> Int {
  let mut s = 1
  while s * s < n {
    s = s + 1
  }
  s
}

///|
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
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_writes(gt)
  (world, tf, gt, per_side)
}

///|
fn make_world_batch(
  count : Int,
) -> (@ecs.World, @ecs.ComponentTypeId, @ecs.ComponentTypeId, Int) {
  let world = @ecs.World::new()
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let per_side = grid_side_len(count)
  let _ = world.spawn_transform_global_batch(count, fn(i, _e, tf_row, gt_row) {
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
    @comp.global_transform_write_identity_row(gt_row)
  })
  let _ = world.drain_resize_events()
  let _ = world.drain_gpu_write_views(gt)
  (world, tf, gt, per_side)
}

///|
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
fn bench_query_row(count : Int) -> Unit {
  let (world, tf, _, per_side) = make_world(count)
  let q = @ecs.Query::new([tf])
  let started = monotonic_ms()
  let mut checksum = 0
  q.for_each(world, row => {
    let idx = row.entity().gpu_index()
    let (x, z) = grid_xz_for_index(idx, per_side)
    let view = row.write_view(tf)
    @comp.Transform3D::write_position_to_component_mut_view(
      view,
      x,
      Float::from_double(idx.to_double() * 0.001),
      z,
    )
    checksum = checksum + idx
  })
  report("query_row", count, started, checksum)
}

///|
fn bench_query_archetype(count : Int) -> Unit {
  let (world, tf, _, per_side) = make_world(count)
  let q = @ecs.Query::new([tf])
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
fn bench_global_and_drain(count : Int) -> Unit {
  let (world, _, gt, _) = make_world(count)
  let started = monotonic_ms()
  world.update_global_transforms_from_transforms()
  let writes = world.drain_gpu_writes(gt)
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  report("global_transform_drain", count, started, uploaded)
}

///|
fn bench_global_and_drain_views(count : Int) -> Unit {
  let (world, _, gt, _) = make_world_batch(count)
  let started = monotonic_ms()
  world.update_global_transforms_from_transforms()
  let writes = world.drain_gpu_write_views(gt)
  let mut uploaded = 0
  for i = 0; i < writes.length(); i = i + 1 {
    uploaded = uploaded + writes[i].bytes.length()
  }
  report("global_transform_drain_views", count, started, uploaded)
}

///|
fn bench_make_world_batch(count : Int) -> Unit {
  let started = monotonic_ms()
  let (_, _, _, _) = make_world_batch(count)
  report("make_world_batch", count, started, count)
}

///|
fn run_suite(count : Int) -> Unit {
  bench_query_row(count)
  bench_query_archetype(count)
  bench_builtin_positions(count)
  bench_global_and_drain(count)
  bench_global_and_drain_views(count)
  bench_make_world_batch(count)
}

///|
fn main {
  println("ecs_bench: QueryRow vs archetype vs builtin transform paths")
  run_suite(1000)
  run_suite(10000)
}
