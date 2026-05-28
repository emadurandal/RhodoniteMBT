/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "SystemRunner permits set_component_bytes without structural write" {
  let world = World::new()
  let qa = world.register_component("SystemRunnerSetComponentA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("set-a", update_phase(), [], [qa], (_world, _ctx, commands) => {
      commands.set_component_bytes(e, qa, bytes4(8, 7, 6, 5))
    }),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_true(bytes == bytes4(8, 7, 6, 5))
    None => abort("expected SystemRunnerSetComponentA bytes")
  }
}

///|
test "SystemRunner permits set_global_transform update with GlobalTransform write" {
  let world = World::new()
  let gt = world.global_transform_component()
  let e = world.create_entity()
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("set-gt", update_phase(), [], [gt], (w, _ctx, _commands) => {
      let m = @m44.Matrix44::new_col_major(
        (1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
        (4.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
      )
      if !w.set_global_transform(e, m) {
        abort("expected system runner set_global_transform")
      }
    }),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  match world.get_global_transform(e) {
    Some(m) => assert_eq(m.at(0, 3), (4.0 : Float))
    None => abort("expected system runner GlobalTransform")
  }
}

///|
test "SystemRunner runs direct systems without command buffers" {
  let world = World::new()
  let qa = world.register_component("SystemRunnerDirectA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_direct("direct-set-a", update_phase(), [], [qa], (w, _ctx) => {
      if !w.set_component_bytes(e, qa, bytes4(4, 3, 2, 1)) {
        abort("expected direct component write")
      }
    }),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_true(bytes == bytes4(4, 3, 2, 1))
    None => abort("expected SystemRunnerDirectA bytes")
  }
}

///|
test "SystemRunner reports direct systems as empty command reports" {
  let world = World::new()
  let qa = world.register_component("SystemRunnerDirectReportA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_direct("direct-report", update_phase(), [], [qa], (w, _ctx) => {
      if !w.set_component_bytes(e, qa, bytes4(2, 0, 0, 0)) {
        abort("expected direct report write")
      }
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
  assert_eq(report.queued_command_count, 0)
  assert_eq(report.applied_command_count, 0)
  assert_eq(report.failed_command_count, 0)
  assert_eq(report.batches[0].systems[0].name, "direct-report")
  assert_eq(report.batches[0].systems[0].queued_command_count, 0)
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_true(bytes == bytes4(2, 0, 0, 0))
    None => abort("expected SystemRunnerDirectReportA bytes")
  }
}

///|
test "SystemRunner convenience setters return false for missing components without structural write" {
  let world = World::new()
  let tf_id = world.transform_component()
  let gt_id = world.global_transform_component()
  let co_id = world.child_of_component()
  let target = world.create_entity()
  let parent = world.create_entity()
  let buf = transform3d_bytes_identity()
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  let mut transform_ok = true
  let mut trs_ok = true
  let mut child_ok = true
  let mut global_ok = true
  let runner = SystemRunner::new()
  runner.add_system(
    System::new(
      "missing-convenience-setters",
      update_phase(),
      [],
      [tf_id, gt_id, co_id],
      (w, _ctx, _commands) => {
        transform_ok = w.set_transform(target, tf)
        trs_ok = w.set_transform_trs(
          target,
          (0.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
          0.0,
          0.0,
          0.0,
          1.0,
          (1.0 : Float),
          (1.0 : Float),
          (1.0 : Float),
        )
        child_ok = w.set_child_of(target, parent)
        global_ok = w.set_global_transform(target, @m44.Matrix44F::identity())
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
  assert_true(!transform_ok)
  assert_true(!trs_ok)
  assert_true(!child_ok)
  assert_true(!global_ok)
  assert_true(!world.has_component(target, tf_id))
  assert_true(!world.has_component(target, co_id))
  assert_true(!world.has_component(target, gt_id))
}

///|
test "SystemRunner runs systems by phase and applies commands after conflict-free batches" {
  let world = World::new()
  let qa = world.register_component("SystemRunnerA", 4)
  let qb = world.register_component("SystemRunnerB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let order : Array[Int] = []
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("post", post_update_phase(), [], [], (_world, _ctx, _commands) => {
      order.push(3)
    }),
  )
  runner.add_system(
    System::new_with_structural_write("add-b", update_phase(), [qa], [qb], (
      system_world,
      ctx,
      commands,
    ) => {
      order.push(ctx.frame_index)
      let query = Query::new([qa])
      query.for_each(system_world, row => {
        commands.add_component_bytes(row.entity(), qb, bytes4(5, 6, 7, 8))
      })
    }),
  )
  runner.add_system(
    System::new("see-b", update_phase(), [qb], [], (
      system_world,
      _ctx,
      _commands,
    ) => {
      if system_world.has_component(e, qb) {
        order.push(2)
      } else {
        order.push(20)
      }
    }),
  )
  let ctx = SystemContext::new((0.016 : Float), 1)
  assert_eq(runner.len(), 3)
  assert_true(runner.run_phase(world, ctx, update_phase()))
  assert_true(runner.run_phase(world, ctx, post_update_phase()))
  assert_eq(order.length(), 3)
  assert_eq(order[0], 1)
  assert_eq(order[1], 2)
  assert_eq(order[2], 3)
  assert_true(world.has_component(e, qb))
}

///|
test "SystemRunner::run_phase temporarily locks component registration" {
  let world = World::new()
  assert_true(!world.component_registration_locked())
  let mut locked_during_run = false
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("observe-lock", update_phase(), [], [], (w, _ctx, _cmds) => {
      locked_during_run = w.component_registration_locked()
    }),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  assert_true(locked_during_run)
  assert_true(!world.component_registration_locked())
  let late = world.register_component("RegisteredAfterRunnerRun", 4)
  assert_true(late.index >= 0)
}

///|
test "transform_propagation_system updates GlobalTransform in a system runner" {
  let world = World::new()
  let e = world.create_entity()
  let buf = transform3d_bytes_translation(
    (3.0 : Float),
    (0.0 : Float),
    (0.0 : Float),
  )
  let n = buf.length()
  let tf = @comp.Transform3D::from_component_mut_view(
    buf.mut_view(start=0, end=n),
  )
  assert_true(world.set_transform(e, tf))
  assert_true(world.set_global_transform(e, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  let runner = SystemRunner::new()
  runner.add_system(transform_propagation_system(world, post_update_phase()))
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      post_update_phase(),
    ),
  )
  match world.get_global_transform(e) {
    Some(m) => assert_eq(m.at(0, 3), (3.0 : Float))
    None => abort("expected Matrix44F")
  }
}

///|
test "System access arrays are copied" {
  let world = World::new()
  let qa = world.register_component("SystemAccessA", 4)
  let qb = world.register_component("SystemAccessB", 4)
  let reads : Array[ComponentTypeId] = [qa]
  let writes : Array[ComponentTypeId] = [qb]
  let system = System::new("copy-access", update_phase(), reads, writes, (
    _w,
    _c,
    _b,
  ) => ())
  reads[0] = qb
  writes[0] = qa
  assert_eq(system.name(), "copy-access")
  assert_true(system.phase() == update_phase())
  assert_true(system.reads()[0] == qa)
  assert_true(system.writes()[0] == qb)
  assert_true(!system.structural_write())
}

///|
test "System conflict helpers detect same-phase access overlaps" {
  let world = World::new()
  let qa = world.register_component("SystemConflictA", 4)
  let qb = world.register_component("SystemConflictB", 4)
  let read_a = System::new("read-a", update_phase(), [qa], [], (_w, _c, _b) => {
    ()
  })
  let write_a = System::new("write-a", update_phase(), [], [qa], (_w, _c, _b) => {
    ()
  })
  let write_b = System::new("write-b", update_phase(), [], [qb], (_w, _c, _b) => {
    ()
  })
  let later_write_a = System::new(
    "later-write-a",
    post_update_phase(),
    [],
    [qa],
    (_w, _c, _b) => (),
  )
  assert_true(read_a.conflicts_with(write_a))
  assert_true(!read_a.conflicts_with(write_b))
  let same_phase = SystemRunner::new()
  same_phase.add_system(read_a)
  same_phase.add_system(write_a)
  assert_true(same_phase.has_parallel_access_conflicts())
  let different_phase = SystemRunner::new()
  different_phase.add_system(read_a)
  different_phase.add_system(later_write_a)
  assert_true(!different_phase.has_parallel_access_conflicts())
}

///|
test "SystemRunner::parallel_access_conflicts reports component conflict kinds" {
  let world = World::new()
  let qa = world.register_component("SystemConflictDiagA", 4)
  let qb = world.register_component("SystemConflictDiagB", 4)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("read-a", update_phase(), [qa], [], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("write-a", update_phase(), [], [qa], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("write-b-left", update_phase(), [], [qb], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("write-b-right", update_phase(), [], [qb], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("read-a-other-phase", post_update_phase(), [qa], [], (
      _w,
      _c,
      _b,
    ) => ()),
  )
  assert_true(runner.has_parallel_access_conflicts())
  let conflicts = runner.parallel_access_conflicts()
  assert_eq(conflicts.length(), 2)
  assert_true(conflicts[0].phase == update_phase())
  assert_eq(conflicts[0].left_runner_index, 0)
  assert_eq(conflicts[0].right_runner_index, 1)
  assert_eq(conflicts[0].left_name, "read-a")
  assert_eq(conflicts[0].right_name, "write-a")
  assert_eq(conflicts[0].kind, "left_read_right_write")
  match conflicts[0].component {
    Some(component) => assert_true(component == qa)
    None => abort("expected read/write conflict component")
  }
  assert_eq(conflicts[1].left_runner_index, 2)
  assert_eq(conflicts[1].right_runner_index, 3)
  assert_eq(conflicts[1].kind, "write_write")
  match conflicts[1].component {
    Some(component) => assert_true(component == qb)
    None => abort("expected write/write conflict component")
  }
}

///|
test "SystemRunner::parallel_access_conflicts reports structural conflicts without component" {
  let world = World::new()
  let qa = world.register_component("SystemStructuralConflictDiagA", 4)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("read-a", update_phase(), [qa], [], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new_with_structural_write("structural", update_phase(), [], [], (
      _w,
      _c,
      _b,
    ) => ()),
  )
  let conflicts = runner.parallel_access_conflicts()
  assert_eq(conflicts.length(), 1)
  assert_eq(conflicts[0].kind, "structural_write")
  assert_true(conflicts[0].component is None)
}

///|
test "SystemRunner::plan_phase exposes conflict-free execution batches" {
  let world = World::new()
  let qa = world.register_component("SystemPlanA", 4)
  let qb = world.register_component("SystemPlanB", 4)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("read-a", update_phase(), [qa], [], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("write-b", update_phase(), [], [qb], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("write-a", update_phase(), [], [qa], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new("post", post_update_phase(), [], [], (_w, _c, _b) => ()),
  )
  let plan = runner.plan_phase(update_phase())
  assert_true(plan.phase == update_phase())
  assert_eq(plan.system_count, 3)
  assert_eq(plan.batches.length(), 2)
  assert_eq(plan.batches[0].index, 0)
  assert_eq(plan.batches[0].systems.length(), 2)
  assert_eq(plan.batches[0].systems[0].runner_index, 0)
  assert_eq(plan.batches[0].systems[0].batch_index, 0)
  assert_eq(plan.batches[0].systems[0].name, "read-a")
  assert_true(plan.batches[0].systems[0].phase == update_phase())
  assert_eq(plan.batches[0].systems[0].reads[0].index, qa.index)
  assert_eq(plan.batches[0].systems[1].runner_index, 1)
  assert_eq(plan.batches[0].systems[1].writes[0].index, qb.index)
  assert_true(!plan.batches[0].systems[1].structural_write)
  assert_eq(plan.batches[1].index, 1)
  assert_eq(plan.batches[1].systems.length(), 1)
  assert_eq(plan.batches[1].systems[0].runner_index, 2)
  assert_eq(plan.batches[1].systems[0].name, "write-a")
}

///|
test "SystemRunner::plan_phase isolates structural writes" {
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("before", update_phase(), [], [], (_w, _c, _b) => ()),
  )
  runner.add_system(
    System::new_with_structural_write("structural", update_phase(), [], [], (
      _w,
      _c,
      _b,
    ) => ()),
  )
  runner.add_system(
    System::new("after", update_phase(), [], [], (_w, _c, _b) => ()),
  )
  let plan = runner.plan_phase(update_phase())
  assert_eq(plan.system_count, 3)
  assert_eq(plan.batches.length(), 3)
  assert_eq(plan.batches[0].systems[0].name, "before")
  assert_eq(plan.batches[1].systems[0].name, "structural")
  assert_true(plan.batches[1].systems[0].structural_write)
  assert_eq(plan.batches[2].systems[0].name, "after")
}

///|
test "SystemRunner::plan_phase returns empty and snapshot plans" {
  let world = World::new()
  let qa = world.register_component("SystemPlanSnapshotA", 4)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("snapshot", update_phase(), [qa], [], (_w, _c, _b) => ()),
  )
  let empty = runner.plan_phase(post_update_phase())
  assert_eq(empty.system_count, 0)
  assert_eq(empty.batches.length(), 0)
  let plan = runner.plan_phase(update_phase())
  assert_eq(plan.system_count, 1)
  assert_eq(plan.batches.length(), 1)
  plan.batches[0].systems[0].reads[0] = ComponentTypeId::new(999)
  let fresh = runner.plan_phase(update_phase())
  assert_eq(fresh.batches[0].systems[0].reads[0].index, qa.index)
}

///|
test "SystemRunner::plan_phase cache invalidates when systems are added" {
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("first", update_phase(), [], [], (_w, _c, _b) => ()),
  )
  let before = runner.plan_phase(update_phase())
  assert_eq(before.system_count, 1)
  assert_eq(before.batches.length(), 1)
  assert_eq(before.batches[0].systems[0].name, "first")
  runner.add_system(
    System::new("second", update_phase(), [], [], (_w, _c, _b) => ()),
  )
  let after = runner.plan_phase(update_phase())
  assert_eq(after.system_count, 2)
  assert_eq(after.batches.length(), 1)
  assert_eq(after.batches[0].systems.length(), 2)
  assert_eq(after.batches[0].systems[1].name, "second")
}

///|
test "SystemRunner phase batch cache stays isolated by phase and run path" {
  let world = World::new()
  let phase_a = PhaseKey::new("cache-phase-a")
  let phase_b = PhaseKey::new("cache-phase-b")
  let runner = SystemRunner::new()
  let mut ran_a = 0
  let mut ran_b = 0
  runner.add_system(
    System::new("phase-a", phase_a, [], [], (_w, _c, _b) => ran_a = ran_a + 1),
  )
  runner.add_system(
    System::new("phase-b", phase_b, [], [], (_w, _c, _b) => ran_b = ran_b + 1),
  )
  let plan_a = runner.plan_phase(phase_a)
  let plan_b = runner.plan_phase(phase_b)
  assert_eq(plan_a.system_count, 1)
  assert_eq(plan_a.batches[0].systems[0].name, "phase-a")
  assert_eq(plan_b.system_count, 1)
  assert_eq(plan_b.batches[0].systems[0].name, "phase-b")
  assert_true(
    runner.run_phase(world, SystemContext::new((0.016 : Float), 1), phase_a),
  )
  assert_eq(ran_a, 1)
  assert_eq(ran_b, 0)
  let fresh_b = runner.plan_phase(phase_b)
  assert_eq(fresh_b.batches[0].systems[0].name, "phase-b")
}

///|
test "System writes declaration also permits reads during system runner execution" {
  let world = World::new()
  let qa = world.register_component("SystemWriteCanReadA", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  let mut saw_first = (0 : Byte)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("write-can-read", update_phase(), [], [qa], (w, _ctx, _cmds) => {
      match w.component_bytes(e, qa) {
        Some(bytes) => saw_first = bytes[0]
        None => abort("expected SystemWriteCanReadA bytes")
      }
    }),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  assert_eq(saw_first, (1 : Byte))
}

///|
test "Nested SystemRunner::run_phase restores outer system access declarations" {
  let world = World::new()
  let qa = world.register_component("NestedRunnerOuterA", 4)
  let qb = world.register_component("NestedRunnerInnerB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let inner = SystemRunner::new()
  inner.add_system(
    System::new("inner-write-b", update_phase(), [], [qb], (w, _ctx, _cmds) => {
      if !w.set_component_bytes(e, qb, bytes4(2, 2, 2, 2)) {
        abort("expected nested inner component write")
      }
    }),
  )
  let outer = SystemRunner::new()
  outer.add_system(
    System::new("outer-write-a", update_phase(), [], [qa], (w, ctx, _cmds) => {
      if !inner.run_phase(w, ctx, update_phase()) {
        abort("expected nested inner runner to succeed")
      }
      if !w.set_component_bytes(e, qa, bytes4(3, 3, 3, 3)) {
        abort("expected nested outer component write")
      }
    }),
  )
  assert_true(
    outer.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  match world.component_bytes(e, qa) {
    Some(bytes) => assert_true(bytes == bytes4(3, 3, 3, 3))
    None => abort("expected NestedRunnerOuterA bytes")
  }
}

///|
test "System Query preserves read and write access separation during system runner execution" {
  let world = World::new()
  let qa = world.register_component("SystemQueryReadA", 4)
  let qb = world.register_component("SystemQueryWriteB", 4)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let query = Query::new([qa, qb])
  let runner = SystemRunner::new()
  runner.add_system(
    System::new("query-read-write", update_phase(), [qa], [qb], (w, _ctx, _cmds) => {
      query.for_each(w, row => {
        row.read(qa, src => row.write(qb, dst => dst[0] = src[0]))
      })
    }),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  match world.component_bytes(e, qb) {
    Some(bytes) => assert_eq(bytes[0], (1 : Byte))
    None => abort("expected SystemQueryWriteB bytes")
  }
}

///|
test "System structural write declaration permits entity creation" {
  let world = World::new()
  let mut spawned = EntityId::new(-1, 0)
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write("spawn", update_phase(), [], [], (
      w,
      _ctx,
      _cmds,
    ) => spawned = w.create_entity()),
  )
  runner.add_system(
    System::new("observe", update_phase(), [], [], (_w, _ctx, _cmds) => ()),
  )
  assert_true(
    runner.run_phase(
      world,
      SystemContext::new((0.016 : Float), 1),
      update_phase(),
    ),
  )
  assert_true(world.is_alive(spawned))
  assert_true(runner.has_parallel_access_conflicts())
}
