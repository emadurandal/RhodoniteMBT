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
