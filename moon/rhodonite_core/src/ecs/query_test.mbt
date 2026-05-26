/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "Query for_each matches supersets and skips empty required" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryA", 4)
  let qb = world.register_cpu_component("QueryB", 4)
  let e_both = world.create_entity()
  assert_true(world.add_component_bytes(e_both, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e_both, qb, bytes4(5, 6, 7, 8)))
  let e_only_a = world.create_entity()
  assert_true(world.add_component_bytes(e_only_a, qa, bytes4(9, 10, 11, 12)))
  ignore(e_only_a)
  let hits : Array[EntityId] = []
  Query::new([qa, qb]).for_each(world, row => {
    hits.push(row.entity())
    row.read(qa, bytes => ignore(bytes))
    row.read(qb, bytes => ignore(bytes))
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e_both)
  let empty_hits : Array[EntityId] = []
  Query::new([]).for_each(world, row => empty_hits.push(row.entity()))
  assert_eq(empty_hits.length(), 0)
  // Query scope has ended, so normal structural mutation should work again.
  let e_after_query = world.create_entity()
  assert_true(
    world.add_component_bytes(e_after_query, qa, bytes4(13, 14, 15, 16)),
  )
}

///|
test "Query plan exposes matched archetypes and row counts" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryPlanA", 4)
  let qb = world.register_cpu_component("QueryPlanB", 4)
  let e_both = world.create_entity()
  assert_true(world.add_component_bytes(e_both, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e_both, qb, bytes4(2, 0, 0, 0)))
  let e_only_a = world.create_entity()
  assert_true(world.add_component_bytes(e_only_a, qa, bytes4(3, 0, 0, 0)))
  let plan = Query::new([qa, qb]).plan(world)
  assert_eq(plan.required.length(), 2)
  assert_eq(plan.candidate_archetype_count, 1)
  assert_eq(plan.matched_archetype_count, 1)
  assert_eq(plan.matched_row_count, 1)
  assert_false(plan.stale)
  assert_eq(plan.archetypes.length(), 1)
  assert_eq(plan.archetypes[0].row_count, 1)
  let raw_plan = RawQuery::new([qa]).plan(world)
  assert_eq(raw_plan.candidate_archetype_count, 2)
  assert_eq(raw_plan.matched_archetype_count, 2)
  assert_eq(raw_plan.matched_row_count, 2)
  let empty_plan = Query::new([]).plan(world)
  assert_eq(empty_plan.candidate_archetype_count, 0)
  assert_eq(empty_plan.matched_archetype_count, 0)
  assert_eq(empty_plan.matched_row_count, 0)
}

///|
test "Query for_each wraps required row iteration" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryHelperA", 4)
  let qb = world.register_cpu_component("QueryHelperB", 4)
  let required : Array[ComponentTypeId] = [qa, qb]
  let query = Query::new(required)
  required[0] = qb
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let hits : Array[EntityId] = []
  let mut first_len = -1
  let mut second_first_byte = (0 : Byte)
  query.for_each(world, row => {
    hits.push(row.entity())
    row.read(qa, bytes => first_len = bytes.length())
    row.read(qb, bytes => second_first_byte = bytes[0])
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e)
  assert_eq(first_len, 4)
  assert_eq(second_first_byte, (5 : Byte))
}

///|
test "QueryRow closure access uses component ids" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryRowA", 4)
  let qb = world.register_cpu_component("QueryRowB", 4)
  let query = Query::new([qa, qb])
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let hits : Array[EntityId] = []
  let mut a_first = (0 : Byte)
  let mut b_first = (0 : Byte)
  query.for_each(world, row => {
    hits.push(row.entity())
    if !row.has(qa) {
      abort("expected QueryRowA")
    }
    if !row.has(qb) {
      abort("expected QueryRowB")
    }
    row.read(qa, bytes => a_first = bytes[0])
    row.read(qb, bytes => b_first = bytes[0])
    row.write(qb, bytes => bytes[0] = (42 : Byte))
  })
  assert_eq(hits.length(), 1)
  assert_true(hits[0] == e)
  assert_eq(a_first, (1 : Byte))
  assert_eq(b_first, (5 : Byte))
  match world.component_bytes(e, qb) {
    Some(bytes) => assert_eq(bytes[0], (42 : Byte))
    None => abort("expected QueryRowB bytes")
  }
}

///|
test "QueryRow write_tracked records undo and redo component bytes" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryRowTracked", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  Query::new([cpu]).for_each(world, row => {
    if !row.write_tracked(history, cpu, bytes => bytes[0] = (7 : Byte)) {
      abort("expected tracked query row write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo_label() is Some("query_row_write"))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(7, 0, 0, 0))
    None => abort("expected tracked query bytes")
  }
  assert_true(history.undo(world))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(1, 0, 0, 0))
    None => abort("expected undone query bytes")
  }
  assert_true(history.redo(world))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(7, 0, 0, 0))
    None => abort("expected redone query bytes")
  }
}

///|
test "RawQueryRow write_tracked records undo and disabled writes delegate" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("RawQueryRowTracked", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  RawQuery::new([cpu]).for_each(world, row => {
    if !row.write_tracked(history, cpu, bytes => bytes[0] = (5 : Byte)) {
      abort("expected tracked raw query row write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  history.set_max_undo_records(0)
  RawQuery::new([cpu]).for_each(world, row => {
    if !row.write_tracked(history, cpu, bytes => bytes[0] = (9 : Byte)) {
      abort("expected delegated raw query row write")
    }
  })
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(9, 0, 0, 0))
    None => abort("expected delegated raw query bytes")
  }
}

///|
test "QueryRow write_tracked works inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryRowTrackedGuard", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded query write"))
  Query::new([cpu]).for_each(world, row => {
    if !row.write_tracked(history, cpu, bytes => bytes[0] = (3 : Byte)) {
      abort("expected guarded tracked query row write")
    }
  })
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo_label() is Some("guarded query write"))
  assert_true(history.undo(world))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(1, 0, 0, 0))
    None => abort("expected guarded query undo bytes")
  }
}

///|
test "QueryRow typed tracked writers work inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let parent_before = world.create_entity()
  let parent_after = world.create_entity()
  let entity = world.create_entity()
  assert_true(
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
  assert_true(world.set_child_of(entity, parent_before))
  assert_true(
    world.set_global_transform(
      entity,
      @m44.Matrix44::translation(
        (1.0 : Float),
        (2.0 : Float),
        (3.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
      ),
    ),
  )
  history.set_raw_mutation_guard_enabled(true)
  assert_true(
    history.begin_guarded_transaction(world, "guarded typed query writers"),
  )
  Query::new([
    world.transform_component(),
    world.child_of_component(),
    world.global_transform_component(),
  ]).for_each(world, row => {
    if !row.write_transform3d_tracked(history, transform => {
        transform.write_position((4.0 : Float), (5.0 : Float), (6.0 : Float))
      }) {
      abort("expected guarded typed Transform3D write")
    }
    if !row.write_child_of_tracked(history, parent_after) {
      abort("expected guarded typed ChildOf write")
    }
    if !row.write_global_transform_tracked(history, global => {
        global.write_matrix(
          @m44.Matrix44::translation(
            (7.0 : Float),
            (8.0 : Float),
            (9.0 : Float),
            (1.0 : Float),
            (0.0 : Float),
          ),
        )
      }) {
      abort("expected guarded typed GlobalTransform write")
    }
  })
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  match world.get_transform(entity) {
    Some(transform) => {
      assert_eq(transform.position.x(), (4.0 : Float))
      assert_eq(transform.position.y(), (5.0 : Float))
      assert_eq(transform.position.z(), (6.0 : Float))
    }
    None => abort("expected written Transform3D")
  }
  assert_true(world.get_child_of(entity) == Some(parent_after))
  match world.get_global_transform(entity) {
    Some(matrix) => {
      assert_eq(matrix.at(0, 3), (7.0 : Float))
      assert_eq(matrix.at(1, 3), (8.0 : Float))
      assert_eq(matrix.at(2, 3), (9.0 : Float))
    }
    None => abort("expected written GlobalTransform")
  }
  assert_true(history.undo(world))
  match world.get_transform(entity) {
    Some(transform) => {
      assert_eq(transform.position.x(), (1.0 : Float))
      assert_eq(transform.position.y(), (2.0 : Float))
      assert_eq(transform.position.z(), (3.0 : Float))
    }
    None => abort("expected undone Transform3D")
  }
  assert_true(world.get_child_of(entity) == Some(parent_before))
  match world.get_global_transform(entity) {
    Some(matrix) => {
      assert_eq(matrix.at(0, 3), (1.0 : Float))
      assert_eq(matrix.at(1, 3), (2.0 : Float))
      assert_eq(matrix.at(2, 3), (3.0 : Float))
    }
    None => abort("expected undone GlobalTransform")
  }
  assert_true(history.redo(world))
  match world.get_transform(entity) {
    Some(transform) => {
      assert_eq(transform.position.x(), (4.0 : Float))
      assert_eq(transform.position.y(), (5.0 : Float))
      assert_eq(transform.position.z(), (6.0 : Float))
    }
    None => abort("expected redone Transform3D")
  }
  assert_true(world.get_child_of(entity) == Some(parent_after))
  match world.get_global_transform(entity) {
    Some(matrix) => {
      assert_eq(matrix.at(0, 3), (7.0 : Float))
      assert_eq(matrix.at(1, 3), (8.0 : Float))
      assert_eq(matrix.at(2, 3), (9.0 : Float))
    }
    None => abort("expected redone GlobalTransform")
  }
}

///|
test "QueryRow typed tracked writers delegate when history disabled" {
  let world = World::new()
  let history = WorldHistory::new()
  let parent_before = world.create_entity()
  let parent_after = world.create_entity()
  let entity = world.create_entity()
  assert_true(
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
  assert_true(world.set_child_of(entity, parent_before))
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  history.set_max_undo_records(0)
  Query::new([
    world.transform_component(),
    world.child_of_component(),
    world.global_transform_component(),
  ]).for_each(world, row => {
    if !row.write_transform3d_tracked(history, transform => {
        transform.write_position((10.0 : Float), (11.0 : Float), (12.0 : Float))
      }) {
      abort("expected delegated typed Transform3D write")
    }
    if !row.write_child_of_tracked(history, parent_after) {
      abort("expected delegated typed ChildOf write")
    }
    if !row.write_global_transform_tracked(history, global => {
        global.write_matrix(
          @m44.Matrix44::translation(
            (13.0 : Float),
            (14.0 : Float),
            (15.0 : Float),
            (1.0 : Float),
            (0.0 : Float),
          ),
        )
      }) {
      abort("expected delegated typed GlobalTransform write")
    }
  })
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  match world.get_transform(entity) {
    Some(transform) => {
      assert_eq(transform.position.x(), (10.0 : Float))
      assert_eq(transform.position.y(), (11.0 : Float))
      assert_eq(transform.position.z(), (12.0 : Float))
    }
    None => abort("expected delegated Transform3D")
  }
  assert_true(world.get_child_of(entity) == Some(parent_after))
  match world.get_global_transform(entity) {
    Some(matrix) => {
      assert_eq(matrix.at(0, 3), (13.0 : Float))
      assert_eq(matrix.at(1, 3), (14.0 : Float))
      assert_eq(matrix.at(2, 3), (15.0 : Float))
    }
    None => abort("expected delegated GlobalTransform")
  }
}

///|
test "panic QueryRow raw write aborts inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryRowRawGuard", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw query"))
  Query::new([cpu]).for_each(world, row => {
    row.write(cpu, bytes => bytes[0] = (2 : Byte))
  })
}

///|
test "panic QueryRow raw Transform3D writer aborts inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(
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
  history.set_raw_mutation_guard_enabled(true)
  assert_true(
    history.begin_guarded_transaction(world, "guarded raw transform row"),
  )
  Query::new([world.transform_component()]).for_each(world, row => {
    row.write_transform3d(transform => {
      transform.write_position((4.0 : Float), (5.0 : Float), (6.0 : Float))
    })
  })
}

///|
test "panic QueryRow raw ChildOf writer aborts inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let parent_before = world.create_entity()
  let parent_after = world.create_entity()
  let entity = world.create_entity()
  assert_true(world.set_child_of(entity, parent_before))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw child row"))
  Query::new([world.child_of_component()]).for_each(world, row => {
    row.write_child_of(parent_after)
  })
}

///|
test "panic QueryRow raw GlobalTransform writer aborts inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(
    history.begin_guarded_transaction(world, "guarded raw global row"),
  )
  Query::new([world.global_transform_component()]).for_each(world, row => {
    row.write_global_transform(global => {
      global.write_matrix(
        @m44.Matrix44::translation(
          (1.0 : Float),
          (2.0 : Float),
          (3.0 : Float),
          (1.0 : Float),
          (0.0 : Float),
        ),
      )
    })
  })
}

///|
test "QueryRow write_tracked blob delegate works inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let gt = world.global_transform_component()
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded blob query"))
  let mut saw_blob = false
  Query::new([gt]).for_each(world, row => {
    if !row.write_tracked(history, gt, bytes => saw_blob = bytes.length() > 0) {
      abort("expected guarded blob query row write")
    }
  })
  assert_true(saw_blob)
  assert_true(history.commit_transaction())
  assert_eq(history.last_diagnostic(), "transaction_empty")
}

///|
test "panic RawQueryRow raw write view aborts inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("RawQueryRowRawGuard", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw row"))
  RawQuery::new([cpu]).for_each(world, row => {
    let bytes = row.write_view(cpu)
    bytes[0] = (2 : Byte)
  })
}

///|
test "RawQuery for_each_archetype exposes contiguous CPU columns" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryArchA", 4)
  let qb = world.register_cpu_component("QueryArchB", 4)
  let query = RawQuery::new([qa, qb])
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(10, 11, 12, 13)))
  assert_true(world.add_component_bytes(e1, qa, bytes4(5, 6, 7, 8)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(20, 21, 22, 23)))
  let mut archetype_count = 0
  let mut row_count = 0
  let mut saw_qa = false
  let mut saw_qb = false
  let mut stride_qa = -1
  query.for_each_archetype(world, chunk => {
    archetype_count = archetype_count + 1
    saw_qa = chunk.has(qa)
    saw_qb = chunk.has(qb)
    stride_qa = chunk.component_stride(qa)
    let a = chunk.read_column(qa)
    let b = chunk.write_column(qb)
    for row = 0; row < chunk.length(); row = row + 1 {
      let base = row * 4
      b[base] = a[base]
      row_count = row_count + 1
    }
  })
  assert_eq(archetype_count, 1)
  assert_eq(row_count, 2)
  assert_true(saw_qa)
  assert_true(saw_qb)
  assert_eq(stride_qa, 4)
  match world.component_bytes(e0, qb) {
    Some(bytes) => assert_eq(bytes[0], (1 : Byte))
    None => abort("expected QueryArchB bytes")
  }
  match world.component_bytes(e1, qb) {
    Some(bytes) => assert_eq(bytes[0], (5 : Byte))
    None => abort("expected QueryArchB bytes")
  }
}

///|
test "RawQueryArchetype write_column_tracked records changed rows only" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTracked", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, cpu, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, cpu, bytes4(2, 0, 0, 0)))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => col[0] = (9 : Byte)) {
      abort("expected tracked column write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 8)
  match world.component_bytes(e0, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(9, 0, 0, 0))
    None => abort("expected tracked column e0 bytes")
  }
  match world.component_bytes(e1, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(2, 0, 0, 0))
    None => abort("expected tracked column e1 bytes")
  }
  assert_true(history.undo(world))
  match world.component_bytes(e0, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(1, 0, 0, 0))
    None => abort("expected tracked column undone e0 bytes")
  }
  assert_true(history.redo(world))
  match world.component_bytes(e0, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(9, 0, 0, 0))
    None => abort("expected tracked column redone e0 bytes")
  }
}

///|
test "RawQueryArchetype write_column_tracked records no undo for unchanged column" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTrackedNoop", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, _col => ()) {
      abort("expected noop tracked column write")
    }
  })
  assert_eq(history.undo_len(), 0)
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.last_diagnostic(), "transaction_empty")
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(1, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_tracked records sparse changed rows only" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTrackedSparse", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e0, cpu, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, cpu, bytes4(2, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, cpu, bytes4(3, 0, 0, 0)))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => {
        col[0] = (9 : Byte)
        col[8] = (7 : Byte)
      }) {
      abort("expected sparse tracked column write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 16)
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e0, cpu) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(world.component_bytes(e2, cpu) == Some(bytes4(3, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e0, cpu) == Some(bytes4(9, 0, 0, 0)))
  assert_true(world.component_bytes(e1, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(world.component_bytes(e2, cpu) == Some(bytes4(7, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_tracked compresses inside transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTrackedCompress", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction("column gesture"))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => col[0] = (2 : Byte)) {
      abort("expected first tracked column write")
    }
    if !arch.write_column_tracked(history, cpu, col => col[0] = (3 : Byte)) {
      abort("expected second tracked column write")
    }
  })
  assert_true(history.commit_transaction())
  assert_eq(history.undo_bytes(), 8)
  assert_true(history.undo(world))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(1, 0, 0, 0))
    None => abort("expected compressed column undo bytes")
  }
  assert_true(history.redo(world))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected compressed column redo bytes")
  }
}

///|
test "RawQueryArchetype write_column_tracked compresses repeated sparse rows" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTrackedSparseCompress", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e0, cpu, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, cpu, bytes4(2, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, cpu, bytes4(3, 0, 0, 0)))
  assert_true(history.begin_transaction("sparse column gesture"))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => {
        col[0] = (4 : Byte)
        col[8] = (5 : Byte)
      }) {
      abort("expected first sparse tracked column write")
    }
    if !arch.write_column_tracked(history, cpu, col => col[8] = (6 : Byte)) {
      abort("expected second sparse tracked column write")
    }
  })
  assert_true(history.commit_transaction())
  assert_eq(history.undo_bytes(), 16)
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e0, cpu) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(world.component_bytes(e2, cpu) == Some(bytes4(3, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e0, cpu) == Some(bytes4(4, 0, 0, 0)))
  assert_true(world.component_bytes(e1, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(world.component_bytes(e2, cpu) == Some(bytes4(6, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_rows_tracked records sparse requested rows" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchRowsTrackedSparse", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e0, cpu, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, cpu, bytes4(2, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, cpu, bytes4(3, 0, 0, 0)))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_rows_tracked(history, cpu, [0, 2], (row, bytes) => {
        bytes[0] = (row + 7).to_byte()
      }) {
      abort("expected sparse rows tracked column write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 16)
  assert_true(world.component_bytes(e0, cpu) == Some(bytes4(7, 0, 0, 0)))
  assert_true(world.component_bytes(e1, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(world.component_bytes(e2, cpu) == Some(bytes4(9, 0, 0, 0)))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e0, cpu) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, cpu) == Some(bytes4(2, 0, 0, 0)))
  assert_true(world.component_bytes(e2, cpu) == Some(bytes4(3, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_rows_tracked accepts empty rows as no-op" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchRowsTrackedEmpty", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_rows_tracked(history, cpu, [], (_row, bytes) => {
        bytes[0] = (9 : Byte)
      }) {
      abort("expected empty rows tracked column write")
    }
  })
  assert_eq(history.undo_len(), 0)
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.last_diagnostic(), "transaction_empty")
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(1, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_rows_tracked rejects invalid row before mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchRowsTrackedInvalid", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  let mut called = false
  let mut ok = true
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    ok = arch.write_column_rows_tracked(history, cpu, [0, 1], (_row, bytes) => {
      called = true
      bytes[0] = (9 : Byte)
    })
  })
  assert_true(!ok)
  assert_true(!called)
  assert_eq(history.last_diagnostic(), "operation_failed")
  assert_eq(history.undo_len(), 0)
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(1, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_rows_tracked compresses duplicate rows" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchRowsTrackedDuplicate", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    let mut write_value = (2 : Byte)
    if !arch.write_column_rows_tracked(history, cpu, [0, 0], (_row, bytes) => {
        bytes[0] = write_value
        write_value = (3 : Byte)
      }) {
      abort("expected duplicate rows tracked column write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 8)
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(3, 0, 0, 0)))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(1, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(3, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_rows_tracked delegates when history disabled" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchRowsTrackedDisabled", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_enabled(false)
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_rows_tracked(history, cpu, [0], (_row, bytes) => {
        bytes[0] = (8 : Byte)
      }) {
      abort("expected disabled rows tracked column write")
    }
  })
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(8, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_rows_tracked works inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchRowsTrackedGuard", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded row column"))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_rows_tracked(history, cpu, [0], (_row, bytes) => {
        bytes[0] = (5 : Byte)
      }) {
      abort("expected guarded rows tracked column write")
    }
  })
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  assert_true(world.component_bytes(entity, cpu) == Some(bytes4(1, 0, 0, 0)))
}

///|
test "RawQueryArchetype write_column_tracked delegates when history disabled" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTrackedDisabled", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_max_undo_records(0)
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => col[0] = (6 : Byte)) {
      abort("expected delegated tracked column write")
    }
  })
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(6, 0, 0, 0))
    None => abort("expected delegated column bytes")
  }
}

///|
test "RawQueryArchetype write_column_tracked works inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("QueryArchTrackedGuard", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded column"))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => col[0] = (4 : Byte)) {
      abort("expected guarded tracked column write")
    }
  })
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  match world.component_bytes(entity, cpu) {
    Some(bytes) => assert_true(bytes == bytes4(1, 0, 0, 0))
    None => abort("expected guarded tracked column undo bytes")
  }
}

///|
test "panic RawQueryArchetype raw write column aborts inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("RawQueryArchRawGuard", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, cpu, bytes4(1, 0, 0, 0)))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded raw column"))
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    let column = arch.write_column(cpu)
    column[0] = (2 : Byte)
  })
}

///|
test "RawQueryArchetype write_column_tracked blob delegate works inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  let gt = world.global_transform_component()
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  history.set_raw_mutation_guard_enabled(true)
  assert_true(history.begin_guarded_transaction(world, "guarded blob column"))
  let mut saw_blob = false
  RawQuery::new([gt]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, gt, bytes => {
        saw_blob = bytes.length() > 0
      }) {
      abort("expected guarded blob column write")
    }
  })
  assert_true(saw_blob)
  assert_true(history.commit_transaction())
  assert_eq(history.last_diagnostic(), "transaction_empty")
}

///|
test "RawQueryArchetype column views expose logical rows after column capacity growth" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryArchCapacityA", 4)
  let qb = world.register_cpu_component("QueryArchCapacityB", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(10, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qa, bytes4(2, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(20, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qb, bytes4(30, 0, 0, 0)))
  assert_true(world.destroy_entity(e1))
  let query = RawQuery::new([qa, qb])
  let mut row_count = -1
  let mut column_len = -1
  query.for_each_archetype(world, chunk => {
    row_count = chunk.length()
    column_len = chunk.read_column(qa).length()
  })
  assert_eq(row_count, 2)
  assert_eq(column_len, 8)
}

///|
test "RawPreparedQuery rebuilds after structural changes create matching archetype" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryA", 4)
  let qb = world.register_cpu_component("PreparedQueryB", 4)
  let query = RawQuery::new([qa, qb])
  let prepared = query.prepare(world)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(e, qb, bytes4(5, 6, 7, 8)))
  let mut row_count = 0
  let mut first_a = (0 : Byte)
  prepared.for_each_archetype(world, chunk => {
    row_count = row_count + chunk.length()
    first_a = chunk.read_column(qa)[0]
  })
  assert_eq(row_count, 1)
  assert_eq(first_a, (1 : Byte))
}

///|
test "RawPreparedQuery plan reports stale rebuild diagnostics" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryPlanA", 4)
  let qb = world.register_cpu_component("PreparedQueryPlanB", 4)
  let prepared = RawQuery::new([qa, qb]).prepare(world)
  let current_plan = prepared.plan(world)
  assert_false(current_plan.stale)
  assert_eq(current_plan.matched_archetype_count, 0)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e, qb, bytes4(2, 0, 0, 0)))
  let stale_plan = prepared.plan(world)
  assert_true(stale_plan.stale)
  assert_eq(stale_plan.candidate_archetype_count, 1)
  assert_eq(stale_plan.matched_archetype_count, 1)
  assert_eq(stale_plan.matched_row_count, 1)
  assert_eq(stale_plan.archetypes[0].row_count, 1)
}

///|
test "PreparedQuery for_each rebuilds stale row plan" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryRowA", 4)
  let qb = world.register_cpu_component("PreparedQueryRowB", 4)
  let prepared = Query::new([qa, qb]).prepare(world)
  let e = world.create_entity()
  assert_true(world.add_component_bytes(e, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e, qb, bytes4(4, 0, 0, 0)))
  let mut sum = 0
  prepared.for_each(world, row => {
    row.read(qa, bytes => sum = sum + bytes[0].to_int())
    row.read(qb, bytes => sum = sum + bytes[0].to_int())
  })
  assert_eq(sum, 7)
}

///|
test "PreparedQuery plan reports current and stale row diagnostics" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryRowPlanA", 4)
  let qb = world.register_cpu_component("PreparedQueryRowPlanB", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(4, 0, 0, 0)))
  let prepared = Query::new([qa, qb]).prepare(world)
  let current_plan = prepared.plan(world)
  assert_false(current_plan.stale)
  assert_eq(current_plan.matched_archetype_count, 1)
  assert_eq(current_plan.matched_row_count, 1)
  let qc = world.register_cpu_component("PreparedQueryRowPlanC", 4)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(5, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(6, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(7, 0, 0, 0)))
  let stale_plan = prepared.plan(world)
  assert_true(stale_plan.stale)
  assert_eq(stale_plan.matched_archetype_count, 2)
  assert_eq(stale_plan.matched_row_count, 2)
}

///|
test "PreparedQuery refresh returns a fresh reusable row plan" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedQueryRefreshA", 4)
  let qb = world.register_cpu_component("PreparedQueryRefreshB", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let prepared = Query::new([qa, qb]).prepare(world)
  assert_false(prepared.is_stale(world))
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_false(prepared.is_stale(world))
  let qc = world.register_cpu_component("PreparedQueryRefreshC", 4)
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e2, qa, bytes4(5, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qb, bytes4(6, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qc, bytes4(7, 0, 0, 0)))
  assert_true(prepared.is_stale(world))
  assert_true(prepared.plan(world).stale)
  let refreshed = prepared.refresh(world)
  assert_false(refreshed.is_stale(world))
  assert_false(refreshed.plan(world).stale)
  assert_eq(refreshed.plan(world).matched_row_count, 3)
  let mut sum = 0
  refreshed.for_each(world, row => {
    row.read(qa, bytes => sum = sum + bytes[0].to_int())
  })
  assert_eq(sum, 9)
}

///|
test "RawPreparedQuery refresh returns a fresh reusable archetype plan" {
  let world = World::new()
  let qa = world.register_cpu_component("RawPreparedQueryRefreshA", 4)
  let qb = world.register_cpu_component("RawPreparedQueryRefreshB", 4)
  let prepared = RawQuery::new([qa, qb]).prepare(world)
  assert_false(prepared.is_stale(world))
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  assert_true(prepared.is_stale(world))
  let refreshed = prepared.refresh(world)
  assert_false(refreshed.is_stale(world))
  assert_eq(refreshed.plan(world).matched_row_count, 1)
  let mut rows = 0
  refreshed.for_each_archetype(world, chunk => rows = rows + chunk.length())
  assert_eq(rows, 1)
}

///|
test "QueryCache reuses and refreshes row plans" {
  let world = World::new()
  let qa = world.register_cpu_component("QueryCacheA", 4)
  let qb = world.register_cpu_component("QueryCacheB", 4)
  let required : Array[ComponentTypeId] = [qa, qb]
  let cache = QueryCache::new(required)
  required[0] = qb
  let components = cache.required_components()
  assert_eq(components.length(), 2)
  assert_eq(components[0].index, qa.index)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let mut sum = 0
  cache.for_each(world, row => {
    row.read(qa, bytes => sum = sum + bytes[0].to_int())
  })
  assert_eq(sum, 1)
  assert_false(cache.plan(world).stale)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_false(cache.plan(world).stale)
  let qc = world.register_cpu_component("QueryCacheC", 4)
  let e2 = world.create_entity()
  assert_true(world.add_component_bytes(e2, qa, bytes4(5, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qb, bytes4(6, 0, 0, 0)))
  assert_true(world.add_component_bytes(e2, qc, bytes4(7, 0, 0, 0)))
  assert_true(cache.plan(world).stale)
  sum = 0
  cache.for_each(world, row => {
    row.read(qa, bytes => sum = sum + bytes[0].to_int())
  })
  assert_eq(sum, 9)
  assert_false(cache.plan(world).stale)
  assert_eq(cache.plan(world).matched_row_count, 3)
}

///|
test "RawQueryCache refreshes archetype plans" {
  let world = World::new()
  let qa = world.register_cpu_component("RawQueryCacheA", 4)
  let qb = world.register_cpu_component("RawQueryCacheB", 4)
  let cache = RawQueryCache::new([qa, qb])
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  cache.refresh(world)
  assert_false(cache.plan(world).stale)
  let qc = world.register_cpu_component("RawQueryCacheC", 4)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  assert_true(cache.plan(world).stale)
  let mut rows = 0
  cache.for_each_archetype(world, chunk => rows = rows + chunk.length())
  assert_eq(rows, 2)
  assert_false(cache.plan(world).stale)
  let mut row_sum = 0
  cache.for_each(world, row => row_sum = row_sum + row.read_view(qa)[0].to_int())
  assert_eq(row_sum, 4)
}
