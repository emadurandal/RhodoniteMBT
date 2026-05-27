/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `bytes4_wb`.
fn bytes4_wb(a : Byte, b : Byte, c : Byte, d : Byte) -> FixedArray[Byte] {
  ([a, b, c, d] : FixedArray[Byte])
}

///|
test "World archetype version only changes when new archetypes are created" {
  let world = World::new()
  let initial_version = world.archetype_version
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_eq(world.archetype_version, initial_version)
  assert_true(world.destroy_entity(e0))
  assert_eq(world.archetype_version, initial_version)
  let reserved = world.reserve_entity_for_command()
  assert_eq(world.archetype_version, initial_version)
  assert_true(world.finalize_reserved_entity(reserved))
  assert_eq(world.archetype_version, initial_version)
  let qa = world.register_cpu_component("ArchetypeVersionA", 4)
  let qb = world.register_cpu_component("ArchetypeVersionB", 4)
  assert_true(world.add_component_bytes(e1, qa, bytes4_wb(1, 2, 3, 4)))
  assert_eq(world.archetype_version, initial_version + 1)
  assert_true(world.add_component_bytes(e1, qb, bytes4_wb(5, 6, 7, 8)))
  let version_after_new_archetypes = world.archetype_version
  assert_eq(version_after_new_archetypes, initial_version + 2)
  let e2 = world.create_entity()
  assert_eq(world.archetype_version, version_after_new_archetypes)
  assert_true(world.add_component_bytes(e2, qa, bytes4_wb(9, 10, 11, 12)))
  assert_eq(world.archetype_version, version_after_new_archetypes)
  assert_true(world.add_component_bytes(e2, qb, bytes4_wb(13, 14, 15, 16)))
  assert_eq(world.archetype_version, version_after_new_archetypes)
  assert_true(world.remove_component(e2, qb))
  assert_eq(world.archetype_version, version_after_new_archetypes)
  assert_true(world.remove_component(e2, qa))
  assert_eq(world.archetype_version, version_after_new_archetypes)
  assert_true(world.destroy_entity(e2))
  assert_eq(world.archetype_version, version_after_new_archetypes)
}

///|
test "PreparedQueryArchetype stores row access metadata at prepare time" {
  let world = World::new()
  let qa = world.register_cpu_component("PreparedRowAccessA", 4)
  let qb = world.register_cpu_component("PreparedRowAccessB", 8)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, qa, bytes4_wb(1, 2, 3, 4)))
  assert_true(
    world.add_component_bytes(
      entity,
      qb,
      ([5, 6, 7, 8, 9, 10, 11, 12] : FixedArray[Byte]),
    ),
  )
  let prepared = Query::new([qb, qa]).prepare(world)
  assert_eq(prepared.archetypes.length(), 1)
  let chunk = prepared.archetypes[0]
  assert_eq(chunk.accesses.length(), 2)
  assert_eq(chunk.row_accesses.length(), 2)
  for i = 0; i < chunk.accesses.length(); i = i + 1 {
    assert_eq(
      chunk.row_accesses[i].column_index,
      chunk.accesses[i].column_index,
    )
    assert_eq(chunk.row_accesses[i].stride, chunk.accesses[i].stride)
  }
  assert_true(chunk.accesses[0].component == qb)
  assert_eq(chunk.row_accesses[0].stride, 8)
  assert_true(chunk.accesses[1].component == qa)
  assert_eq(chunk.row_accesses[1].stride, 4)
}

///|
test "PackedGpuBlobStore normalizes non-monotonic dirty word ranges" {
  let store = PackedGpuBlobStore::new()
  store.ensure_word_capacity(30)
  store.mark_dirty_words(24, 6)
  store.mark_dirty_words(0, 12)
  let writes = store.drain_write_views()
  assert_eq(writes.length(), 2)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 12 * 4)
  assert_eq(writes[1].byte_offset, 24 * 4)
  assert_eq(writes[1].bytes.length(), 6 * 4)
  assert_true(!store.has_dirty_words())
}

///|
test "PackedGpuBlobStore merges adjacent dirty word ranges" {
  let store = PackedGpuBlobStore::new()
  store.ensure_word_capacity(30)
  store.mark_dirty_words(12, 6)
  store.mark_dirty_words(0, 12)
  let writes = store.drain_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 0)
  assert_eq(writes[0].bytes.length(), 18 * 4)
}

///|
test "PackedGpuBlobStore merges overlapping dirty word ranges" {
  let store = PackedGpuBlobStore::new()
  store.ensure_word_capacity(30)
  store.mark_dirty_words(10, 8)
  store.mark_dirty_words(4, 8)
  let writes = store.drain_write_views()
  assert_eq(writes.length(), 1)
  assert_eq(writes[0].byte_offset, 4 * 4)
  assert_eq(writes[0].bytes.length(), 14 * 4)
}

///|
test "PackedGpuBlobStore preserves separated dirty word ranges" {
  let store = PackedGpuBlobStore::new()
  store.ensure_word_capacity(30)
  store.mark_dirty_words(20, 4)
  store.mark_dirty_words(2, 4)
  store.mark_dirty_words(10, 4)
  let writes = store.drain_write_views()
  assert_eq(writes.length(), 3)
  assert_eq(writes[0].byte_offset, 2 * 4)
  assert_eq(writes[0].bytes.length(), 4 * 4)
  assert_eq(writes[1].byte_offset, 10 * 4)
  assert_eq(writes[1].bytes.length(), 4 * 4)
  assert_eq(writes[2].byte_offset, 20 * 4)
  assert_eq(writes[2].bytes.length(), 4 * 4)
}
