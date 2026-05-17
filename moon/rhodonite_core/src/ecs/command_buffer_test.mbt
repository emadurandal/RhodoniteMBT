///|
test "CommandBuffer applies queued structural changes after query" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandBufferA", 4)
  let qb = world.register_cpu_component("CommandBufferB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let query = Query::new([qa])
  let mut queued_count = 0
  let mut saw_qa_before_apply = false
  let mut saw_qb_before_apply = true
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "queue-structural-after-query",
      update_phase(),
      [],
      [qa, qb],
      (w, _ctx, commands) => {
        query.for_each(w, row => {
          commands.add_component_bytes(row.entity(), qb, bytes4(5, 6, 7, 8))
          commands.remove_component(row.entity(), qa)
        })
        saw_qa_before_apply = w.has_component(e, qa)
        saw_qb_before_apply = w.has_component(e, qb)
        queued_count = commands.len()
      },
    ),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  assert_true(saw_qa_before_apply)
  assert_true(!saw_qb_before_apply)
  assert_eq(queued_count, 2)
  assert_true(!world.has_component(e, qa))
  assert_true(world.has_component(e, qb))
}

///|
test "CommandBuffer applies queued component writes and reports failed commands" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandBufferWriteA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let missing = EntityId::new(e.index + 100, 0)
  let mut queued_count = 0
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "queue-component-write-and-failed-destroy",
      update_phase(),
      [],
      [qa],
      (_w, _ctx, commands) => {
        commands.set_component_bytes(e, qa, bytes4(3, 3, 3, 3))
        commands.destroy_entity(missing)
        queued_count = commands.len()
      },
    ),
  )
  assert_true(
    !runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  assert_eq(queued_count, 2)
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_eq(bytes, bytes4(3, 3, 3, 3))
    None => abort("expected CommandBufferWriteA bytes")
  }
}

///|
test "CommandBuffer create_entity reserves id and applies components after query" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandCreateSource", 4)
  let qb = world.register_cpu_component("CommandCreateSpawned", 4)
  let source = world.create_entity()
  assert_true(world.add_component_bytes(source, qa, bytes4(1, 2, 3, 4)))
  let query = Query::new([qa])
  let mut spawned = EntityId::new(-1, 0)
  let mut alive_before_apply = true
  let mut queued_count = 0
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "command-create-entity",
      update_phase(),
      [qa],
      [qb],
      (w, _ctx, commands) => {
        query.for_each(w, _row => {
          spawned = commands.create_entity()
          alive_before_apply = w.is_alive(spawned)
          commands.add_component_bytes(spawned, qb, bytes4(9, 8, 7, 6))
        })
        queued_count = commands.len()
      },
    ),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  assert_eq(queued_count, 2)
  assert_true(!alive_before_apply)
  assert_true(world.is_alive(spawned))
  assert_true(world.has_component(spawned, qb))
  match world.component_bytes(spawned, qb) {
    Some(bytes) => assert_eq(bytes, bytes4(9, 8, 7, 6))
    None => abort("expected CommandCreateSpawned bytes")
  }
}
