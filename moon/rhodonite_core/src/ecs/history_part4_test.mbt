/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "panic WorldHistory guarded transaction rejects raw component removal" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_component("HistoryGuardRejectRemove", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw remove"))
  ignore(world.remove_component(entity, cpu))
}

///|
test "panic WorldHistory guarded transaction rejects raw component registration" {
  let world = World::new()
  let history = WorldHistory::new()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw register"))
  ignore(world.register_component("HistoryGuardRejectRegister", 4))
}

///|
test "panic WorldHistory guarded transaction rejects raw transform mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw transform"))
  ignore(
    world.set_transform_trs(
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
}

///|
test "panic WorldHistory guarded transaction rejects raw GlobalTransform mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(
    history.begin_guarded_transaction(world, "guarded raw global transform"),
  )
  ignore(world.set_global_transform(entity, @m44.Matrix44F::identity()))
}

///|
test "panic WorldHistory guarded transaction rejects raw Camera mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw camera"))
  ignore(
    world.set_camera_matrices(
      entity,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
      (0.0 : Float),
    ),
  )
}

///|
test "panic WorldHistory guarded transaction rejects raw spawn batch" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_component("HistoryGuardRejectSpawnBatch", 4)
  history.set_raw_mutation_guard_enabled(true)
  assert_true(
    history.begin_guarded_transaction(world, "guarded raw spawn batch"),
  )
  ignore(
    world.spawn_batch([cpu], 1, fn(_i, _e, row) {
      row.write(cpu, c => c[0] = (7 : Byte))
    }),
  )
}

///|
test "panic WorldHistory guarded transaction rejects raw system phase" {
  let world = World::new()
  let history = WorldHistory::new()
  let runner = SystemRunner::new()
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw phase"))
  ignore(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      PhaseKey::new("history-guard-raw-phase"),
    ),
  )
}
