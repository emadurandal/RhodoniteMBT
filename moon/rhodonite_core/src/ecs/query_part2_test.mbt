/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "RawQueryArchetype write_column_rows_tracked works inside guarded transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_component("QueryArchRowsTrackedGuard", 4)
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
  let cpu = world.register_component("QueryArchTrackedDisabled", 4)
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
  let cpu = world.register_component("QueryArchTrackedGuard", 4)
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
  let cpu = world.register_component("RawQueryArchRawGuard", 4)
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
  let qa = world.register_component("QueryArchCapacityA", 4)
  let qb = world.register_component("QueryArchCapacityB", 4)
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
  let qa = world.register_component("PreparedQueryA", 4)
  let qb = world.register_component("PreparedQueryB", 4)
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
  let qa = world.register_component("PreparedQueryPlanA", 4)
  let qb = world.register_component("PreparedQueryPlanB", 4)
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
  let qa = world.register_component("PreparedQueryRowA", 4)
  let qb = world.register_component("PreparedQueryRowB", 4)
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
test "PreparedQuery for_each_read_at reads indexed rows and rebuilds stale plans" {
  let world = World::new()
  let qa = world.register_component("PreparedQueryReadAtA", 4)
  let qb = world.register_component("PreparedQueryReadAtB", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let prepared = Query::new([qa, qb]).prepare(world)
  let qc = world.register_component("PreparedQueryReadAtC", 4)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  let mut rows = 0
  let mut sum = 0
  prepared.for_each_read_at(world, 1, (entity, bytes) => {
    if entity != e0 && entity != e1 {
      abort("expected prepared read_at entity")
    }
    rows = rows + 1
    sum = sum + bytes[0].to_int()
  })
  assert_eq(rows, 2)
  assert_eq(sum, 6)
}

///|
test "RawPreparedQuery for_each_read_view_at reads indexed rows and rebuilds stale plans" {
  let world = World::new()
  let qa = world.register_component("RawPreparedQueryReadAtA", 4)
  let qb = world.register_component("RawPreparedQueryReadAtB", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let prepared = RawQuery::new([qa, qb]).prepare(world)
  let qc = world.register_component("RawPreparedQueryReadAtC", 4)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  let mut rows = 0
  let mut sum = 0
  prepared.for_each_read_view_at(world, 1, (entity, bytes) => {
    if entity != e0 && entity != e1 {
      abort("expected raw prepared read_at entity")
    }
    rows = rows + 1
    sum = sum + bytes[0].to_int()
  })
  assert_eq(rows, 2)
  assert_eq(sum, 6)
}

///|
test "PreparedQuery plan reports current and stale row diagnostics" {
  let world = World::new()
  let qa = world.register_component("PreparedQueryRowPlanA", 4)
  let qb = world.register_component("PreparedQueryRowPlanB", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(4, 0, 0, 0)))
  let prepared = Query::new([qa, qb]).prepare(world)
  let current_plan = prepared.plan(world)
  assert_false(current_plan.stale)
  assert_eq(current_plan.matched_archetype_count, 1)
  assert_eq(current_plan.matched_row_count, 1)
  let qc = world.register_component("PreparedQueryRowPlanC", 4)
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
  let qa = world.register_component("PreparedQueryRefreshA", 4)
  let qb = world.register_component("PreparedQueryRefreshB", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let prepared = Query::new([qa, qb]).prepare(world)
  assert_false(prepared.is_stale(world))
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_false(prepared.is_stale(world))
  let qc = world.register_component("PreparedQueryRefreshC", 4)
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
test "PreparedQuery refresh preserves excluded filters" {
  let world = World::new()
  let qa = world.register_component("PreparedQueryWithoutRefreshA", 4)
  let qb = world.register_component("PreparedQueryWithoutRefreshB", 4)
  let qc = world.register_component("PreparedQueryWithoutRefreshC", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let prepared = Query::new_with_excluded([qa, qb], [qc]).prepare(world)
  assert_eq(prepared.plan(world).excluded.length(), 1)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  assert_true(prepared.is_stale(world))
  assert_eq(prepared.plan(world).matched_row_count, 1)
  let refreshed = prepared.refresh(world)
  assert_eq(refreshed.plan(world).matched_row_count, 1)
}

///|
test "RawPreparedQuery refresh returns a fresh reusable archetype plan" {
  let world = World::new()
  let qa = world.register_component("RawPreparedQueryRefreshA", 4)
  let qb = world.register_component("RawPreparedQueryRefreshB", 4)
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
test "RawPreparedQuery refresh preserves excluded filters" {
  let world = World::new()
  let qa = world.register_component("RawPreparedQueryWithoutRefreshA", 4)
  let qb = world.register_component("RawPreparedQueryWithoutRefreshB", 4)
  let qc = world.register_component("RawPreparedQueryWithoutRefreshC", 4)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let prepared = RawQuery::new_with_excluded([qa, qb], [qc]).prepare(world)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  assert_true(prepared.is_stale(world))
  let refreshed = prepared.refresh(world)
  let mut rows = 0
  refreshed.for_each_archetype(world, chunk => rows = rows + chunk.length())
  assert_eq(rows, 1)
}

///|
test "QueryCache reuses and refreshes row plans" {
  let world = World::new()
  let qa = world.register_component("QueryCacheA", 4)
  let qb = world.register_component("QueryCacheB", 4)
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
  let qc = world.register_component("QueryCacheC", 4)
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
test "QueryCache preserves excluded filters across refresh" {
  let world = World::new()
  let qa = world.register_component("QueryCacheWithoutA", 4)
  let qb = world.register_component("QueryCacheWithoutB", 4)
  let qc = world.register_component("QueryCacheWithoutC", 4)
  let cache = QueryCache::new_with_excluded([qa, qb], [qc])
  assert_eq(cache.excluded_components()[0].index, qc.index)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  cache.refresh(world)
  assert_eq(cache.plan(world).matched_row_count, 1)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  assert_true(cache.plan(world).stale)
  let mut sum = 0
  cache.for_each(world, row => {
    row.read(qa, bytes => sum = sum + bytes[0].to_int())
  })
  assert_eq(sum, 1)
  assert_false(cache.plan(world).stale)
  assert_eq(cache.plan(world).matched_row_count, 1)
}

///|
test "RawQueryCache refreshes archetype plans" {
  let world = World::new()
  let qa = world.register_component("RawQueryCacheA", 4)
  let qb = world.register_component("RawQueryCacheB", 4)
  let cache = RawQueryCache::new([qa, qb])
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  cache.refresh(world)
  assert_false(cache.plan(world).stale)
  let qc = world.register_component("RawQueryCacheC", 4)
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

///|
test "RawQueryCache preserves excluded filters across refresh" {
  let world = World::new()
  let qa = world.register_component("RawQueryCacheWithoutA", 4)
  let qb = world.register_component("RawQueryCacheWithoutB", 4)
  let qc = world.register_component("RawQueryCacheWithoutC", 4)
  let cache = RawQueryCache::new_with_excluded([qa, qb], [qc])
  assert_eq(cache.excluded_components()[0].index, qc.index)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  cache.refresh(world)
  assert_eq(cache.plan(world).matched_row_count, 1)
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, qa, bytes4(3, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qb, bytes4(4, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qc, bytes4(5, 0, 0, 0)))
  assert_true(cache.plan(world).stale)
  let mut rows = 0
  cache.for_each_archetype(world, chunk => rows = rows + chunk.length())
  assert_eq(rows, 1)
  assert_false(cache.plan(world).stale)
}

///|
test "Query component index APIs access row payloads" {
  let world = World::new()
  let qa = world.register_component("QueryIndexA", 4)
  let qb = world.register_component("QueryIndexB", 4)
  let query = Query::new([qa, qb])
  let cache = QueryCache::new([qa, qb])
  assert_eq(query.component_index(qa), 0)
  assert_eq(query.component_index(qb), 1)
  assert_eq(cache.component_index(qb), 1)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(entity, qb, bytes4(2, 0, 0, 0)))
  let mut has_a = false
  let mut read_a = (0 : Byte)
  query.for_each(world, row => {
    has_a = row.has_at(0)
    row.read_at(0, bytes => read_a = bytes[0])
    row.write_at(1, bytes => bytes[0] = (7 : Byte))
  })
  assert_true(has_a)
  assert_eq(read_a, (1 : Byte))
  match world.component_bytes(entity, qb) {
    Some(bytes) => assert_eq(bytes[0], (7 : Byte))
    None => abort("expected QueryIndexB bytes")
  }
}

///|
test "QueryRow write_tracked_at records row changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_component("QueryIndexTrackedA", 4)
  let query = Query::new([qa])
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, qa, bytes4(1, 0, 0, 0)))
  query.for_each(world, row => {
    if !row.write_tracked_at(history, 0, bytes => bytes[0] = (9 : Byte)) {
      abort("expected tracked index row write")
    }
  })
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  match world.component_bytes(entity, qa) {
    Some(bytes) => assert_eq(bytes[0], (1 : Byte))
    None => abort("expected QueryIndexTrackedA bytes")
  }
}

///|
test "Raw query index APIs access rows and archetype columns" {
  let world = World::new()
  let qa = world.register_component("RawQueryIndexA", 4)
  let qb = world.register_component("RawQueryIndexB", 4)
  let raw = RawQuery::new([qa, qb])
  let cache = RawQueryCache::new([qa, qb])
  assert_eq(raw.component_index(qa), 0)
  assert_eq(raw.component_index(qb), 1)
  assert_eq(cache.component_index(qb), 1)
  let e0 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e0, qb, bytes4(2, 0, 0, 0)))
  let mut row_has_a = false
  let mut row_read_a = (0 : Byte)
  raw.for_each(world, row => {
    row_has_a = row.has_at(0)
    row_read_a = row.read_view_at(0)[0]
    row.write_view_at(1)[0] = (3 : Byte)
  })
  assert_true(row_has_a)
  assert_eq(row_read_a, (1 : Byte))
  let mut arch_has_b = false
  let mut arch_stride_b = 0
  let mut arch_read_b = (0 : Byte)
  raw.for_each_archetype(world, arch => {
    arch_has_b = arch.has_at(1)
    arch_stride_b = arch.component_stride_at(1)
    arch_read_b = arch.read_column_at(1)[0]
    arch.write_column_at(1)[0] = (4 : Byte)
  })
  assert_true(arch_has_b)
  assert_eq(arch_stride_b, 4)
  assert_eq(arch_read_b, (3 : Byte))
  match world.component_bytes(e0, qb) {
    Some(bytes) => assert_eq(bytes[0], (4 : Byte))
    None => abort("expected RawQueryIndexB bytes")
  }
}

///|
test "RawQueryArchetype tracked index writes record full and sparse column changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let qa = world.register_component("RawQueryIndexTrackedA", 4)
  let raw = RawQuery::new([qa])
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, qa, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, qa, bytes4(2, 0, 0, 0)))
  raw.for_each_archetype(world, arch => {
    if !arch.write_column_tracked_at(history, 0, column => {
        column[0] = (5 : Byte)
      }) {
      abort("expected tracked index column write")
    }
    if !arch.write_column_rows_tracked_at(history, 0, [1], (_row, bytes) => {
        bytes[0] = (8 : Byte)
      }) {
      abort("expected tracked sparse index column write")
    }
  })
  assert_eq(history.undo_len(), 2)
  assert_true(history.undo(world))
  match world.component_bytes(e1, qa) {
    Some(bytes) => assert_eq(bytes[0], (2 : Byte))
    None => abort("expected RawQueryIndexTrackedA row 1 bytes")
  }
  assert_true(history.undo(world))
  match world.component_bytes(e0, qa) {
    Some(bytes) => assert_eq(bytes[0], (1 : Byte))
    None => abort("expected RawQueryIndexTrackedA row 0 bytes")
  }
}

///|
test "panic Query component_index aborts for missing component" {
  let world = World::new()
  let qa = world.register_component("QueryIndexMissingA", 4)
  let qb = world.register_component("QueryIndexMissingB", 4)
  ignore(Query::new([qa]).component_index(qb))
}

///|
test "panic Query new_with_excluded rejects duplicate excluded component" {
  let world = World::new()
  let qa = world.register_component("QueryWithoutDuplicateA", 4)
  let qb = world.register_component("QueryWithoutDuplicateB", 4)
  ignore(Query::new_with_excluded([qa], [qb, qb]))
}

///|
test "panic RawQuery new_with_excluded rejects required excluded overlap" {
  let world = World::new()
  let qa = world.register_component("RawQueryWithoutOverlapA", 4)
  ignore(RawQuery::new_with_excluded([qa], [qa]))
}

///|
test "panic Query component_index aborts for excluded component" {
  let world = World::new()
  let qa = world.register_component("QueryIndexExcludedA", 4)
  let qb = world.register_component("QueryIndexExcludedB", 4)
  ignore(Query::new_with_excluded([qa], [qb]).component_index(qb))
}

///|
test "panic Query plan aborts for unknown excluded component" {
  let world = World::new()
  let qa = world.register_component("QueryUnknownExcludedA", 4)
  let missing = ComponentTypeId::new(99999)
  ignore(Query::new_with_excluded([qa], [missing]).plan(world))
}

///|
test "panic QueryRow read_at aborts for out-of-range payload index" {
  let world = World::new()
  let qa = world.register_component("QueryIndexInvalidA", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, qa, bytes4(1, 0, 0, 0)))
  Query::new([qa]).for_each(world, row => row.read_at(1, _bytes => ()))
}

///|
test "panic RawQueryArchetype read_column_at aborts for negative payload index" {
  let world = World::new()
  let qa = world.register_component("RawQueryIndexInvalidA", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, qa, bytes4(1, 0, 0, 0)))
  RawQuery::new([qa]).for_each_archetype(world, arch => {
    ignore(arch.read_column_at(-1))
  })
}
