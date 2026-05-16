///|
test "spawn_batch creates arbitrary CPU components directly" {
  let world = World::new()
  let cpu_a = world.register_cpu_component("SpawnBatchCpuA", 4)
  let cpu_b = world.register_cpu_component("SpawnBatchCpuB", 4)
  let entities = world.spawn_batch([cpu_b, cpu_a], 3, fn(i, _e, row) {
    row.write(cpu_a, c => c[0] = (10 + i).to_byte())
    row.write(cpu_b, c => c[0] = (20 + i).to_byte())
  })
  assert_eq(entities.length(), 3)
  for i = 0; i < entities.length(); i = i + 1 {
    assert_true(world.has_component(entities[i], cpu_a))
    assert_true(world.has_component(entities[i], cpu_b))
    match world.component_bytes(entities[i], cpu_a) {
      Some(bytes) => assert_eq(bytes[0], (10 + i).to_byte())
      None => abort("expected cpu_a bytes")
    }
    match world.component_bytes(entities[i], cpu_b) {
      Some(bytes) => assert_eq(bytes[0], (20 + i).to_byte())
      None => abort("expected cpu_b bytes")
    }
  }
}

///|
test "spawn_batch allocates builtin GlobalTransform refs" {
  let world = World::new()
  let gt = world.global_transform_component()
  let entities = world.spawn_batch([gt], 2, fn(_i, _e, _row) { () })
  assert_eq(entities.length(), 2)
  assert_true(world.has_component(entities[0], gt))
  assert_true(world.has_component(entities[1], gt))
  let refs = world.extract_global_transform_refs(entities)
  let (fmt0, off0) = @comp.global_transform_ref_from_component_view(refs[0:8])
  let (fmt1, off1) = @comp.global_transform_ref_from_component_view(refs[8:16])
  assert_true(fmt0 == Affine3x4F32)
  assert_true(fmt1 == Affine3x4F32)
  assert_eq(off0, 0)
  assert_eq(off1, 12)
  match world.get_global_transform(entities[1]) {
    Some(m) => assert_eq(m.at(0, 0), (1.0 : Float))
    None => abort("expected blob-backed transform")
  }
}
