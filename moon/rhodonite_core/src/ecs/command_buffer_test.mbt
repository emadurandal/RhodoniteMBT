/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

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
    Some(bytes) => assert_true(bytes == bytes4(3, 3, 3, 3))
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
    Some(bytes) => assert_true(bytes == bytes4(9, 8, 7, 6))
    None => abort("expected CommandCreateSpawned bytes")
  }
}

///|
test "WorldHistory tracks CommandBuffer component writes through system phase" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_cpu_component("HistoryCommandWriteA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 1, 1, 1)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("history-command-write", update_phase(), [], [qa], (
      _w,
      _ctx,
      commands,
    ) => commands.set_component_bytes(e, qa, bytes4(2, 2, 2, 2))),
  )
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
      "Command Write",
    ),
  )
  assert_eq(history.undo_len(), 1)
  assert_true(world.component_bytes(e, qa) == Some(bytes4(2, 2, 2, 2)))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e, qa) == Some(bytes4(1, 1, 1, 1)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e, qa) == Some(bytes4(2, 2, 2, 2)))
}

///|
test "WorldHistory tracks CommandBuffer create with reserved entity id" {
  let world = World::new()
  let history = WorldHistory::new()
  let source_component = world.register_cpu_component("HistoryCommandSource", 4)
  let spawned_component = world.register_cpu_component(
    "HistoryCommandSpawned", 4,
  )
  let source = world.create_entity()
  assert_true(
    world.add_component_bytes(source, source_component, bytes4(1, 2, 3, 4)),
  )
  let query = Query::new([source_component])
  let mut spawned = EntityId::new(-1, 0)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "history-command-create",
      update_phase(),
      [source_component],
      [spawned_component],
      (w, _ctx, commands) => {
        query.for_each(w, _row => {
          spawned = commands.create_entity()
          commands.add_component_bytes(
            spawned,
            spawned_component,
            bytes4(9, 8, 7, 6),
          )
        })
      },
    ),
  )
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
      "Command Create",
    ),
  )
  assert_true(world.is_alive(spawned))
  assert_true(
    world.component_bytes(spawned, spawned_component) ==
    Some(bytes4(9, 8, 7, 6)),
  )
  assert_true(history.undo(world))
  assert_true(!world.is_alive(spawned))
  assert_true(history.redo(world))
  assert_true(world.is_alive(spawned))
  assert_eq(spawned.generation, 0)
  assert_true(
    world.component_bytes(spawned, spawned_component) ==
    Some(bytes4(9, 8, 7, 6)),
  )
}

///|
test "WorldHistory keeps successful CommandBuffer deltas when a later command fails" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_cpu_component("HistoryCommandPartialA", 4)
  let e = world.create_entity()
  let missing = EntityId::new(e.index + 100, 0)
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "history-command-partial",
      update_phase(),
      [],
      [qa],
      (_w, _ctx, commands) => {
        commands.set_component_bytes(e, qa, bytes4(2, 0, 0, 0))
        commands.destroy_entity(missing)
      },
    ),
  )
  assert_true(
    !history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
      "Command Partial",
    ),
  )
  assert_eq(history.undo_len(), 1)
  assert_true(world.component_bytes(e, qa) == Some(bytes4(2, 0, 0, 0)))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e, qa) == Some(bytes4(1, 0, 0, 0)))
}

///|
test "WorldHistory groups multiple tracked system phases in one open transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_cpu_component("HistoryCommandMultiA", 4)
  let e = world.create_entity()
  let phase_a = PhaseKey::new("history-command-phase-a")
  let phase_b = PhaseKey::new("history-command-phase-b")
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("history-command-a", phase_a, [], [qa], (_w, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(2, 0, 0, 0))
    }),
  )
  runner.add_system(
    System::new("history-command-b", phase_b, [], [qa], (_w, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(3, 0, 0, 0))
    }),
  )
  assert_true(history.begin_transaction("Command Multi"))
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      phase_a,
      "ignored-a",
    ),
  )
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 2),
      phase_b,
      "ignored-b",
    ),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_true(world.component_bytes(e, qa) == Some(bytes4(3, 0, 0, 0)))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e, qa) == Some(bytes4(1, 0, 0, 0)))
}
