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
test "SystemRunner run_phase_report exposes command apply failures" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandBufferReportA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let missing = EntityId::new(e.index + 100, 0)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "report-failure",
      update_phase(),
      [],
      [qa],
      (_w, _ctx, commands) => {
        commands.set_component_bytes(e, qa, bytes4(2, 0, 0, 0))
        commands.destroy_entity(missing)
      },
    ),
  )
  let report = runner.run_phase_report(
    world,
    SystemContext::new((0.016 : Float), 1),
    update_phase(),
  )
  assert_false(report.ok)
  assert_eq(report.batch_count, 1)
  assert_eq(report.system_count, 1)
  assert_eq(report.queued_command_count, 2)
  assert_eq(report.applied_command_count, 1)
  assert_eq(report.failed_command_count, 1)
  let batch = report.batches[0]
  assert_false(batch.ok)
  assert_eq(batch.index, 0)
  let system = batch.systems[0]
  assert_eq(system.runner_index, 0)
  assert_eq(system.batch_index, 0)
  assert_eq(system.name, "report-failure")
  assert_eq(system.queued_command_count, 2)
  assert_eq(system.applied_command_count, 1)
  assert_eq(system.failed_command_count, 1)
  let failure = system.failures[0]
  assert_eq(failure.command_index, 1)
  assert_eq(failure.command_kind, "destroy_entity")
  assert_eq(failure.reason, "apply_failed")
  assert_eq(failure.entity.index, missing.index)
  assert_eq(failure.component.index, -1)
  assert_true(world.component_bytes(e, qa) == Some(bytes4(2, 0, 0, 0)))
}

///|
test "SystemRunner run_phase_report reports successful command counts" {
  let world = World::new()
  let qa = world.register_cpu_component("CommandBufferReportSuccessA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("report-success", update_phase(), [], [qa], (_w, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(3, 0, 0, 0))
    }),
  )
  let report = runner.run_phase_report(
    world,
    SystemContext::new((0.016 : Float), 1),
    update_phase(),
  )
  assert_true(report.ok)
  assert_eq(report.batch_count, 1)
  assert_eq(report.system_count, 1)
  assert_eq(report.queued_command_count, 1)
  assert_eq(report.applied_command_count, 1)
  assert_eq(report.failed_command_count, 0)
  assert_eq(report.batches[0].systems[0].name, "report-success")
}

///|
test "SystemRunner run_phase_report returns empty success for empty phase" {
  let world = World::new()
  let runner = SystemRunner::new()
  let report = runner.run_phase_report(
    world,
    SystemContext::new((0.016 : Float), 1),
    update_phase(),
  )
  assert_true(report.ok)
  assert_eq(report.batch_count, 0)
  assert_eq(report.system_count, 0)
  assert_eq(report.failed_command_count, 0)
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
test "CommandBuffer applies queued builtin blob writes after system phase" {
  let world = World::new()
  let gt = world.global_transform_component()
  let camera_component = world.camera_component()
  let entity = world.create_entity()
  let camera = world.create_entity()
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  assert_true(
    world.set_camera_matrices(
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
  let _ = world.drain_global_transform_blob_write_views()
  let _ = world.drain_camera_blob_write_views()
  let matrix = @m44.Matrix44::translation(
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let runner = SystemRunner::new()
  runner.add_system(
    System::new(
      "command-buffer-builtin-blob",
      update_phase(),
      [],
      [gt, camera_component],
      (_w, _ctx, commands) => {
        commands.set_global_transform(entity, matrix)
        commands.set_global_transform_format(entity, Affine3x4F16)
        commands.set_camera_matrices(
          camera,
          @m44.Matrix44F::identity(),
          @m44.Matrix44F::identity(),
          (0.25 : Float),
          (50.0 : Float),
          (1.5 : Float),
          (0.0 : Float),
          (2.0 : Float),
        )
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
  match world.get_global_transform(entity) {
    Some(read) => {
      assert_eq(read.at(0, 3), (4.0 : Float))
      assert_eq(read.at(1, 3), (5.0 : Float))
      assert_eq(read.at(2, 3), (6.0 : Float))
    }
    None => abort("expected command GlobalTransform")
  }
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F16)
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_eq(
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 268),
        (0.25 : Float),
      )
    None => abort("expected command Camera row")
  }
}

///|
test "WorldHistory tracks CommandBuffer builtin blob writes through system phase" {
  let world = World::new()
  let history = WorldHistory::new()
  let gt = world.global_transform_component()
  let camera_component = world.camera_component()
  let entity = world.create_entity()
  let camera = world.create_entity()
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  assert_true(
    world.set_camera_matrices(
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
  let _ = world.drain_global_transform_blob_write_views()
  let _ = world.drain_camera_blob_write_views()
  let matrix = @m44.Matrix44::translation(
    (7.0 : Float),
    (8.0 : Float),
    (9.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  let runner = SystemRunner::new()
  runner.add_system(
    System::new(
      "history-command-builtin-blob",
      update_phase(),
      [],
      [gt, camera_component],
      (_w, _ctx, commands) => {
        commands.set_global_transform(entity, matrix)
        commands.set_global_transform_format(entity, Affine3x4F16)
        commands.set_camera_matrices(
          camera,
          @m44.Matrix44F::identity(),
          @m44.Matrix44F::identity(),
          (0.3 : Float),
          (60.0 : Float),
          (2.0 : Float),
          (0.0 : Float),
          (3.0 : Float),
        )
      },
    ),
  )
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
      "Command Builtins",
    ),
  )
  assert_true(history.undo_label() == Some("Command Builtins"))
  let refs = world.extract_global_transform_refs([entity])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F16)
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_eq(
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 268),
        (0.3 : Float),
      )
    None => abort("expected tracked Camera row")
  }
  assert_true(history.undo(world))
  let refs_undo = world.extract_global_transform_refs([entity])
  let (format_undo, _) = @comp.global_transform_ref_from_component_view(
    refs_undo[0:8],
  )
  assert_true(format_undo == Affine3x4F32)
  match world.get_global_transform(entity) {
    Some(read) => assert_eq(read, @m44.Matrix44F::identity())
    None => abort("expected undone GlobalTransform")
  }
  match world.camera_gpu_row(camera) {
    Some(bytes) =>
      assert_eq(
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 268),
        (0.1 : Float),
      )
    None => abort("expected undone Camera row")
  }
  assert_true(history.redo(world))
  let refs_redo = world.extract_global_transform_refs([entity])
  let (format_redo, _) = @comp.global_transform_ref_from_component_view(
    refs_redo[0:8],
  )
  assert_true(format_redo == Affine3x4F16)
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
test "WorldHistory run_system_phase_report exposes tracked command failures" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_cpu_component("HistoryCommandReportA", 4)
  let e = world.create_entity()
  let missing = EntityId::new(e.index + 100, 0)
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "history-report-failure",
      update_phase(),
      [],
      [qa],
      (_w, _ctx, commands) => {
        commands.set_component_bytes(e, qa, bytes4(2, 0, 0, 0))
        commands.destroy_entity(missing)
      },
    ),
  )
  let report = history.run_system_phase_report(
    runner,
    world,
    SystemContext::new((0.016 : Float), 1),
    update_phase(),
    "History Report Failure",
  )
  assert_false(report.ok)
  assert_eq(report.failed_command_count, 1)
  assert_eq(
    report.batches[0].systems[0].failures[0].command_kind,
    "destroy_entity",
  )
  assert_eq(report.batches[0].systems[0].failures[0].reason, "apply_failed")
  assert_eq(history.last_diagnostic(), "operation_failed")
  assert_eq(history.undo_len(), 1)
  assert_true(world.component_bytes(e, qa) == Some(bytes4(2, 0, 0, 0)))
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

///|
test "WorldHistory releases temporary command-buffer guard inside normal transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_cpu_component("HistoryCommandTemporaryGuardA", 4)
  let e = world.create_entity()
  let phase = PhaseKey::new("history-command-temporary-guard")
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("history-command-guard", phase, [], [qa], (_w, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(2, 0, 0, 0))
    }),
  )
  assert_true(history.begin_transaction("Command Guard"))
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      phase,
      "ignored",
    ),
  )
  assert_true(world.set_component_bytes(e, qa, bytes4(3, 0, 0, 0)))
  assert_true(history.set_component_bytes(world, e, qa, bytes4(4, 0, 0, 0)))
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e, qa) == Some(bytes4(1, 0, 0, 0)))
}

///|
test "WorldHistory keeps command-buffer guard inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_cpu_component("HistoryCommandStickyGuardA", 4)
  let e = world.create_entity()
  let phase = PhaseKey::new("history-command-sticky-guard")
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("history-command-sticky", phase, [], [qa], (_w, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(2, 0, 0, 0))
    }),
  )
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "Command Sticky Guard"))
  assert_true(
    history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      phase,
      "ignored",
    ),
  )
  assert_true(history.set_component_bytes(world, e, qa, bytes4(3, 0, 0, 0)))
  assert_true(history.commit_transaction())
}
