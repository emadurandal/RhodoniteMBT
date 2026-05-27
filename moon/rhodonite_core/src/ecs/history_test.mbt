/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
test "WorldHistory undoes and redoes entity creation with the same id" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = history.create_entity(world)
  assert_true(world.is_alive(entity))
  assert_true(history.can_undo())
  assert_true(history.undo(world))
  assert_true(!world.is_alive(entity))
  assert_true(history.can_redo())
  assert_true(history.redo(world))
  assert_true(world.is_alive(entity))
  assert_eq(entity.generation, 0)
}

///|
test "WorldHistory undoes and redoes batch entity creation with the same ids" {
  let world = World::new()
  let history = WorldHistory::new()
  let entities = history.create_entities(world, 3)
  assert_eq(entities.length(), 3)
  assert_true(world.is_alive(entities[0]))
  assert_true(world.is_alive(entities[1]))
  assert_true(world.is_alive(entities[2]))
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  assert_true(!world.is_alive(entities[0]))
  assert_true(!world.is_alive(entities[1]))
  assert_true(!world.is_alive(entities[2]))
  assert_true(history.redo(world))
  assert_true(world.is_alive(entities[0]))
  assert_true(world.is_alive(entities[1]))
  assert_true(world.is_alive(entities[2]))
  assert_eq(entities[0].generation, 0)
  assert_eq(entities[1].generation, 0)
  assert_eq(entities[2].generation, 0)
}

///|
test "WorldHistory restores destroyed entity id generation and component bytes" {
  let world = World::new()
  let history = WorldHistory::new()
  let a = world.register_component("HistoryDestroyA", 4)
  let b = world.register_component("HistoryDestroyB", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, a, bytes4(1, 2, 3, 4)))
  assert_true(world.add_component_bytes(entity, b, bytes4(5, 6, 7, 8)))
  assert_true(history.destroy_entity(world, entity))
  assert_true(!world.is_alive(entity))
  assert_true(history.undo(world))
  assert_true(world.is_alive(entity))
  match world.component_bytes(entity, a) {
    Some(bytes) => assert_true(bytes == bytes4(1, 2, 3, 4))
    None => abort("expected restored component a")
  }
  match world.component_bytes(entity, b) {
    Some(bytes) => assert_true(bytes == bytes4(5, 6, 7, 8))
    None => abort("expected restored component b")
  }
  assert_true(history.redo(world))
  assert_true(!world.is_alive(entity))
}

///|
test "WorldHistory undoes and redoes component byte changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistorySet", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 1, 1, 1)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 2, 2, 2)),
  )
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(2, 2, 2, 2))
    None => abort("expected changed bytes")
  }
  assert_true(history.undo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(1, 1, 1, 1))
    None => abort("expected original bytes")
  }
  assert_true(history.redo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(2, 2, 2, 2))
    None => abort("expected redone bytes")
  }
}

///|
test "WorldHistory failed undo validation keeps stacks and world unchanged" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryUndoValidate", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 1, 1, 1)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 2, 2, 2)),
  )
  assert_true(world.destroy_entity(entity))
  assert_true(!history.undo(world))
  assert_eq(history.last_diagnostic(), "validation_failed")
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_true(!world.is_alive(entity))
}

///|
test "WorldHistory failed redo validation keeps stacks and world unchanged" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryRedoValidate", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 1, 1, 1)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 2, 2, 2)),
  )
  assert_true(history.undo(world))
  assert_true(world.remove_component(entity, component))
  assert_true(!history.redo(world))
  assert_eq(history.last_diagnostic(), "validation_failed")
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(!world.has_component(entity, component))
}

///|
test "WorldHistory failed redo validation rejects stale created entity generation" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = history.create_entity(world)
  assert_true(history.undo(world))
  let replacement = world.create_entity()
  assert_eq(replacement.index, entity.index)
  assert_true(world.destroy_entity(replacement))
  assert_true(!history.redo(world))
  assert_eq(history.last_diagnostic(), "validation_failed")
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(!world.is_alive(entity))
}

///|
test "WorldHistory validates dependent create and component add transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryCreateAddValidate", 4)
  assert_true(history.begin_transaction("create-add"))
  let entity = history.create_entity(world)
  assert_true(
    history.add_component_bytes(world, entity, component, bytes4(7, 7, 7, 7)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  assert_true(!world.is_alive(entity))
  assert_true(history.redo(world))
  assert_true(world.is_alive(entity))
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(7, 7, 7, 7)),
  )
}

///|
test "WorldHistory undoes add and remove component across archetype moves" {
  let world = World::new()
  let history = WorldHistory::new()
  let a = world.register_component("HistoryArchetypeA", 4)
  let b = world.register_component("HistoryArchetypeB", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, a, bytes4(9, 9, 9, 9)))
  assert_true(history.add_component_bytes(world, entity, b, bytes4(3, 3, 3, 3)))
  assert_true(world.has_component(entity, b))
  assert_true(history.undo(world))
  assert_true(!world.has_component(entity, b))
  assert_true(world.has_component(entity, a))
  assert_true(history.redo(world))
  assert_true(world.has_component(entity, b))
  assert_true(history.remove_component(world, entity, a))
  assert_true(!world.has_component(entity, a))
  assert_true(history.undo(world))
  assert_true(world.has_component(entity, a))
  match world.component_bytes(entity, a) {
    Some(bytes) => assert_true(bytes == bytes4(9, 9, 9, 9))
    None => abort("expected restored a bytes")
  }
}

///|
test "WorldHistory compresses repeated component changes inside a transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryCompress", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction("multi-set"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.undo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(1, 0, 0, 0))
    None => abort("expected compressed undo bytes")
  }
  assert_true(history.redo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected compressed redo bytes")
  }
}

///|
test "WorldHistory keeps component delta index valid after canceling an earlier delta" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryIndexCancel", 4)
  let canceled = world.create_entity()
  let kept = world.create_entity()
  assert_true(world.add_component_bytes(kept, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction("cancel-index"))
  assert_true(
    history.add_component_bytes(world, canceled, component, bytes4(9, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, kept, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.remove_component(world, canceled, component))
  assert_true(
    history.set_component_bytes(world, kept, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  let summaries = history.undo_summary()
  assert_eq(summaries.length(), 1)
  assert_eq(summaries[0].delta_count, 1)
  assert_eq(history.undo_bytes(), 8)
  assert_true(!world.has_component(canceled, component))
  assert_true(
    world.component_bytes(kept, component) == Some(bytes4(3, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_true(!world.has_component(canceled, component))
  assert_true(
    world.component_bytes(kept, component) == Some(bytes4(1, 0, 0, 0)),
  )
  assert_true(history.redo(world))
  assert_true(!world.has_component(canceled, component))
  assert_true(
    world.component_bytes(kept, component) == Some(bytes4(3, 0, 0, 0)),
  )
}

///|
test "WorldHistory records many distinct component changes in one transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryManyDistinct", 4)
  let entities : Array[EntityId] = []
  let count = 128
  for i = 0; i < count; i = i + 1 {
    let entity = world.create_entity()
    assert_true(
      world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)),
    )
    entities.push(entity)
  }
  assert_true(history.begin_transaction("many-distinct"))
  for i = 0; i < entities.length(); i = i + 1 {
    assert_true(
      history.set_component_bytes(
        world,
        entities[i],
        component,
        bytes4((i + 2).to_byte(), 0, 0, 0),
      ),
    )
  }
  assert_true(history.commit_transaction())
  let summaries = history.undo_summary()
  assert_eq(summaries.length(), 1)
  assert_eq(summaries[0].delta_count, count)
  assert_eq(history.undo_bytes(), count * 8)
  assert_true(history.undo(world))
  assert_true(
    world.component_bytes(entities[0], component) == Some(bytes4(1, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[count - 1], component) ==
    Some(bytes4(1, 0, 0, 0)),
  )
  assert_true(history.redo(world))
  assert_true(
    world.component_bytes(entities[0], component) == Some(bytes4(2, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[count - 1], component) ==
    Some(bytes4((count + 1).to_byte(), 0, 0, 0)),
  )
}

///|
test "WorldHistory undoes and redoes bulk component byte changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkSet", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, component, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, component, bytes4(2, 0, 0, 0)))
  assert_true(
    history.set_component_bytes_many(world, component, [e0, e1], [
      bytes4(3, 0, 0, 0),
      bytes4(4, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 1)
  assert_true(world.component_bytes(e0, component) == Some(bytes4(3, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(4, 0, 0, 0)))
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(2, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(3, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(4, 0, 0, 0)))
}

///|
test "WorldHistory undoes and redoes bulk component byte adds" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkAdd", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(
    history.add_component_bytes_many(world, component, [e0, e1], [
      bytes4(1, 0, 0, 0),
      bytes4(2, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 1)
  assert_true(world.component_bytes(e0, component) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(2, 0, 0, 0)))
  assert_true(history.undo(world))
  assert_true(!world.has_component(e0, component))
  assert_true(!world.has_component(e1, component))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(2, 0, 0, 0)))
}

///|
test "WorldHistory groups batch create and bulk add in one open transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBatchAuthoringGroup", 4)
  assert_true(history.begin_transaction("batch author"))
  let entities = history.create_entities(world, 2)
  assert_true(
    history.add_component_bytes_many(world, component, entities, [
      bytes4(3, 0, 0, 0),
      bytes4(4, 0, 0, 0),
    ]),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_true(
    world.component_bytes(entities[0], component) == Some(bytes4(3, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[1], component) == Some(bytes4(4, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_true(!world.is_alive(entities[0]))
  assert_true(!world.is_alive(entities[1]))
  assert_true(history.redo(world))
  assert_true(world.is_alive(entities[0]))
  assert_true(world.is_alive(entities[1]))
  assert_true(
    world.component_bytes(entities[0], component) == Some(bytes4(3, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[1], component) == Some(bytes4(4, 0, 0, 0)),
  )
}

///|
test "WorldHistory undoes and redoes tracked spawn batch rows" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu_a = world.register_component("HistorySpawnBatchA", 4)
  let cpu_b = world.register_component("HistorySpawnBatchB", 4)
  let entities = history.spawn_batch(world, [cpu_b, cpu_a], 2, fn(i, _e, row) {
    row.write(cpu_a, c => c[0] = (10 + i).to_byte())
    row.write(cpu_b, c => c[0] = (20 + i).to_byte())
  })
  assert_eq(entities.length(), 2)
  assert_eq(history.undo_len(), 1)
  assert_true(
    world.component_bytes(entities[0], cpu_a) == Some(bytes4(10, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[1], cpu_b) == Some(bytes4(21, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_true(!world.is_alive(entities[0]))
  assert_true(!world.is_alive(entities[1]))
  assert_true(history.redo(world))
  assert_true(world.is_alive(entities[0]))
  assert_true(world.is_alive(entities[1]))
  assert_true(
    world.component_bytes(entities[0], cpu_a) == Some(bytes4(10, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[1], cpu_b) == Some(bytes4(21, 0, 0, 0)),
  )
}

///|
test "WorldHistory groups tracked spawn batch with later edits in one transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_component("HistorySpawnBatchGroup", 4)
  assert_true(history.begin_transaction("spawn group"))
  let entities = history.spawn_batch(world, [cpu], 1, fn(_i, _e, row) {
    row.write(cpu, c => c[0] = (1 : Byte))
  })
  assert_true(
    history.set_component_bytes(world, entities[0], cpu, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_true(
    world.component_bytes(entities[0], cpu) == Some(bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_true(!world.is_alive(entities[0]))
  assert_true(history.redo(world))
  assert_true(
    world.component_bytes(entities[0], cpu) == Some(bytes4(2, 0, 0, 0)),
  )
}

///|
test "WorldHistory tracked spawn batch reports unknown component without recording" {
  let world = World::new()
  let history = WorldHistory::new()
  let entities = history.spawn_batch(world, [ComponentTypeId::new(9999)], 2, fn(
    _i,
    _e,
    _row,
  ) {
    ()
  })
  assert_eq(entities.length(), 0)
  assert_eq(history.last_diagnostic(), "operation_failed")
  assert_eq(history.undo_len(), 0)
}

///|
test "WorldHistory zero max undo records spawn batch without recording" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_component("HistorySpawnBatchZeroLimit", 4)
  history.set_max_undo_records(0)
  let entities = history.spawn_batch(world, [cpu], 1, fn(_i, _e, row) {
    row.write(cpu, c => c[0] = (7 : Byte))
  })
  assert_eq(entities.length(), 1)
  assert_eq(history.undo_len(), 0)
  assert_true(
    world.component_bytes(entities[0], cpu) == Some(bytes4(7, 0, 0, 0)),
  )
}

///|
test "WorldHistory bulk redo uses stored world bytes not caller buffers" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkCopiesAfter", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, component, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, component, bytes4(2, 0, 0, 0)))
  let after0 = bytes4(3, 0, 0, 0)
  let after1 = bytes4(4, 0, 0, 0)
  assert_true(
    history.set_component_bytes_many(world, component, [e0, e1], [
      after0, after1,
    ]),
  )
  after0[0] = (30 : Byte)
  after1[0] = (40 : Byte)
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(2, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(3, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(4, 0, 0, 0)))
}

///|
test "WorldHistory compresses repeated bulk component changes in one transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkCompress", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, component, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, component, bytes4(2, 0, 0, 0)))
  assert_true(history.begin_transaction("bulk-compress"))
  assert_true(
    history.set_component_bytes_many(world, component, [e0, e1], [
      bytes4(3, 0, 0, 0),
      bytes4(4, 0, 0, 0),
    ]),
  )
  assert_true(
    history.set_component_bytes_many(world, component, [e0, e1], [
      bytes4(5, 0, 0, 0),
      bytes4(6, 0, 0, 0),
    ]),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(2, 0, 0, 0)))
  assert_true(history.redo(world))
  assert_true(world.component_bytes(e0, component) == Some(bytes4(5, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(6, 0, 0, 0)))
}

///|
test "WorldHistory bulk component byte changes are atomic on invalid target" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkAtomic", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, component, bytes4(1, 0, 0, 0)))
  assert_true(
    !history.set_component_bytes_many(world, component, [e0, e1], [
      bytes4(3, 0, 0, 0),
      bytes4(4, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(world.component_bytes(e0, component) == Some(bytes4(1, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) is None)
}

///|
test "WorldHistory bulk component byte changes reject duplicate entities" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkSetDuplicate", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    !history.set_component_bytes_many(world, component, [entity, entity], [
      bytes4(2, 0, 0, 0),
      bytes4(3, 0, 0, 0),
    ]),
  )
  assert_eq(history.last_diagnostic(), "operation_failed")
  assert_eq(history.undo_len(), 0)
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(1, 0, 0, 0)),
  )
}

///|
test "WorldHistory bulk component byte adds are atomic on invalid target" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkAddAtomic", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e1, component, bytes4(9, 0, 0, 0)))
  assert_true(
    !history.add_component_bytes_many(world, component, [e0, e1], [
      bytes4(1, 0, 0, 0),
      bytes4(2, 0, 0, 0),
    ]),
  )
  assert_eq(history.last_diagnostic(), "operation_failed")
  assert_eq(history.undo_len(), 0)
  assert_true(!world.has_component(e0, component))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(9, 0, 0, 0)))
  assert_true(
    !history.add_component_bytes_many(world, component, [e0, e0], [
      bytes4(1, 0, 0, 0),
      bytes4(2, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(!world.has_component(e0, component))
}

///|
test "WorldHistory zero max undo records bulk changes without recording" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkZeroLimit", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  assert_true(world.add_component_bytes(e0, component, bytes4(1, 0, 0, 0)))
  assert_true(world.add_component_bytes(e1, component, bytes4(2, 0, 0, 0)))
  history.set_max_undo_records(0)
  assert_true(
    history.set_component_bytes_many(world, component, [e0, e1], [
      bytes4(3, 0, 0, 0),
      bytes4(4, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(world.component_bytes(e0, component) == Some(bytes4(3, 0, 0, 0)))
  assert_true(world.component_bytes(e1, component) == Some(bytes4(4, 0, 0, 0)))
}

///|
test "WorldHistory zero max undo records batch adds without recording" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryBulkAddZeroLimit", 4)
  history.set_max_undo_records(0)
  let entities = history.create_entities(world, 2)
  assert_eq(history.undo_len(), 0)
  assert_true(
    history.add_component_bytes_many(world, component, entities, [
      bytes4(1, 0, 0, 0),
      bytes4(2, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(
    world.component_bytes(entities[0], component) == Some(bytes4(1, 0, 0, 0)),
  )
  assert_true(
    world.component_bytes(entities[1], component) == Some(bytes4(2, 0, 0, 0)),
  )
}

///|
test "WorldHistory disabled mode delegates without recording history" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryDisabled", 4)
  let entity = world.create_entity()
  history.set_enabled(false)
  assert_true(!history.enabled())
  assert_true(
    history.add_component_bytes(world, entity, component, bytes4(7, 7, 7, 7)),
  )
  assert_true(world.has_component(entity, component))
  assert_true(!history.can_undo())
  assert_true(!history.undo(world))
}

///|
test "WorldHistory clears redo stack after a new transaction" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryRedoInvalidation", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_true(history.can_redo())
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_true(!history.can_redo())
}

///|
test "WorldHistory rejects undo and redo while a transaction is open" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryOpenTransaction", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.begin_transaction("open"))
  assert_true(!history.undo(world))
  assert_true(!history.redo(world))
  assert_true(history.cancel_transaction())
}

///|
test "WorldHistory exposes default record limit and stack lengths" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryLengths", 4)
  let entity = world.create_entity()
  assert_eq(history.last_diagnostic(), "none")
  assert_eq(history.max_undo_records(), 100)
  assert_eq(history.max_undo_bytes(), 0)
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.redo_bytes(), 0)
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "none")
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.undo_bytes(), 8)
  assert_eq(history.redo_bytes(), 0)
  assert_true(history.undo(world))
  assert_eq(history.last_diagnostic(), "none")
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.redo_bytes(), 8)
  assert_true(history.redo(world))
  assert_eq(history.last_diagnostic(), "none")
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.undo_bytes(), 8)
  assert_eq(history.redo_bytes(), 0)
}

///|
test "WorldHistory records diagnostics for common failure paths" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryDiagnostics", 4)
  let entity = world.create_entity()
  assert_true(!history.undo(world))
  assert_eq(history.last_diagnostic(), "empty_undo_stack")
  assert_true(!history.redo(world))
  assert_eq(history.last_diagnostic(), "empty_redo_stack")
  assert_true(!history.commit_transaction())
  assert_eq(history.last_diagnostic(), "no_open_transaction")
  assert_true(!history.cancel_transaction())
  assert_eq(history.last_diagnostic(), "no_open_transaction")
  assert_true(history.begin_transaction("open"))
  assert_eq(history.last_diagnostic(), "none")
  assert_true(!history.undo(world))
  assert_eq(history.last_diagnostic(), "transaction_open")
  assert_true(history.commit_transaction())
  assert_eq(history.last_diagnostic(), "transaction_empty")
  assert_true(
    !history.set_component_bytes(world, entity, component, bytes4(1, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "operation_failed")
}

///|
test "WorldHistory callback-scoped transaction commits and reverts" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_component("HistoryScopedTransaction", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.with_transaction(world, "Scoped Move", () => {
      history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0))
    }),
  )
  assert_eq(history.undo_len(), 1)
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_true(
    world.component_bytes(entity, component) == Some(bytes4(1, 0, 0, 0)),
  )

  let cancel_world = World::new()
  let cancel_history = WorldHistory::new()
  let cancel_component = cancel_world.register_component(
    "HistoryScopedCancel", 4,
  )
  let cancel_entity = cancel_world.create_entity()
  assert_true(
    cancel_world.add_component_bytes(
      cancel_entity,
      cancel_component,
      bytes4(1, 0, 0, 0),
    ),
  )
  assert_true(
    !cancel_history.with_transaction(cancel_world, "Scoped Cancel", () => {
      ignore(
        cancel_history.set_component_bytes(
          cancel_world,
          cancel_entity,
          cancel_component,
          bytes4(3, 0, 0, 0),
        ),
      )
      false
    }),
  )
  assert_eq(cancel_history.undo_len(), 0)
  assert_true(
    cancel_world.component_bytes(cancel_entity, cancel_component) ==
    Some(bytes4(1, 0, 0, 0)),
  )

  let failed_commit_world = World::new()
  let failed_commit_history = WorldHistory::new()
  let failed_commit_component = failed_commit_world.register_component(
    "HistoryScopedCommitFail", 4,
  )
  let failed_commit_entity = failed_commit_world.create_entity()
  assert_true(
    failed_commit_world.add_component_bytes(
      failed_commit_entity,
      failed_commit_component,
      bytes4(1, 0, 0, 0),
    ),
  )
  assert_true(
    !failed_commit_history.with_transaction(
      failed_commit_world,
      "Scoped Commit Fail",
      () => {
        ignore(
          failed_commit_history.set_component_bytes(
            failed_commit_world,
            failed_commit_entity,
            failed_commit_component,
            bytes4(2, 0, 0, 0),
          ),
        )
        failed_commit_history.set_max_undo_records(0)
        true
      },
    ),
  )
  assert_eq(failed_commit_history.last_diagnostic(), "recording_disabled")
  assert_eq(failed_commit_history.undo_len(), 0)
  assert_true(
    failed_commit_world.component_bytes(
      failed_commit_entity, failed_commit_component,
    ) ==
    Some(bytes4(2, 0, 0, 0)),
  )
  failed_commit_history.set_max_undo_records(1)
  assert_true(failed_commit_history.begin_transaction("after cleanup"))
  assert_true(failed_commit_history.cancel_transaction())
}

///|
test "WorldHistory callback-scoped transaction rejects inactive starts" {
  let world = World::new()
  let history = WorldHistory::new()
  let mut called = false
  assert_true(history.begin_transaction("outer"))
  assert_true(
    !history.with_transaction(world, "nested", () => {
      called = true
      true
    }),
  )
  assert_true(!called)
  assert_eq(history.last_diagnostic(), "transaction_open")
  assert_true(history.cancel_transaction())

  let disabled = WorldHistory::new()
  disabled.set_enabled(false)
  called = false
  assert_true(
    !disabled.with_transaction(world, "disabled", () => {
      called = true
      true
    }),
  )
  assert_true(!called)
  assert_eq(disabled.last_diagnostic(), "recording_disabled")
}
