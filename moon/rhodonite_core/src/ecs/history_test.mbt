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
  let a = world.register_cpu_component("HistoryDestroyA", 4)
  let b = world.register_cpu_component("HistoryDestroyB", 4)
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
  let component = world.register_cpu_component("HistorySet", 4)
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
  let component = world.register_cpu_component("HistoryUndoValidate", 4)
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
  let component = world.register_cpu_component("HistoryRedoValidate", 4)
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
  let component = world.register_cpu_component("HistoryCreateAddValidate", 4)
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
  let a = world.register_cpu_component("HistoryArchetypeA", 4)
  let b = world.register_cpu_component("HistoryArchetypeB", 4)
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
  let component = world.register_cpu_component("HistoryCompress", 4)
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
test "WorldHistory undoes and redoes bulk component byte changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryBulkSet", 4)
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
  let component = world.register_cpu_component("HistoryBulkAdd", 4)
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
  let component = world.register_cpu_component("HistoryBatchAuthoringGroup", 4)
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
test "WorldHistory bulk redo uses stored world bytes not caller buffers" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryBulkCopiesAfter", 4)
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
  let component = world.register_cpu_component("HistoryBulkCompress", 4)
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
  let component = world.register_cpu_component("HistoryBulkAtomic", 4)
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
  let component = world.register_cpu_component("HistoryBulkSetDuplicate", 4)
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
  let component = world.register_cpu_component("HistoryBulkAddAtomic", 4)
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
  let component = world.register_cpu_component("HistoryBulkZeroLimit", 4)
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
  let component = world.register_cpu_component("HistoryBulkAddZeroLimit", 4)
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
  let component = world.register_cpu_component("HistoryDisabled", 4)
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
  let component = world.register_cpu_component("HistoryRedoInvalidation", 4)
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
  let component = world.register_cpu_component("HistoryOpenTransaction", 4)
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
  let component = world.register_cpu_component("HistoryLengths", 4)
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
  let component = world.register_cpu_component("HistoryDiagnostics", 4)
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
test "WorldHistory records diagnostics for disabled recording delegates" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryDelegateDiagnostics", 4)
  let entity = world.create_entity()
  history.set_enabled(false)
  assert_eq(history.last_diagnostic(), "none")
  assert_true(
    history.add_component_bytes(world, entity, component, bytes4(1, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "recording_disabled")
}

///|
test "WorldHistory trims old undo records to max_undo_records" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLimit", 4)
  let entity = world.create_entity()
  history.set_max_undo_records(2)
  assert_eq(history.max_undo_records(), 2)
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 2)
  assert_eq(history.last_diagnostic(), "stack_trimmed_record_limit")
  assert_true(history.undo(world))
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after first limited undo")
  }
  assert_true(history.undo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(2, 0, 0, 0))
    None => abort("expected value after second limited undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory trims old records to max_undo_bytes" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryByteLimit", 4)
  let entity = world.create_entity()
  history.set_max_undo_bytes(16)
  assert_eq(history.max_undo_bytes(), 16)
  assert_eq(history.last_diagnostic(), "none")
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 2)
  assert_eq(history.undo_bytes(), 16)
  assert_eq(history.last_diagnostic(), "stack_trimmed_byte_limit")
  assert_true(history.undo(world))
  assert_eq(history.undo_bytes(), 8)
  assert_eq(history.redo_bytes(), 8)
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after byte limited undo")
  }
  assert_true(history.undo(world))
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.redo_bytes(), 16)
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(2, 0, 0, 0))
    None => abort("expected value after second byte limited undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory trims existing stacks when max_undo_bytes is lowered" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLowerByteLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 3)
  history.set_max_undo_bytes(8)
  assert_eq(history.undo_len(), 1)
  assert_eq(history.undo_bytes(), 8)
  assert_eq(history.last_diagnostic(), "stack_trimmed_byte_limit")
  assert_true(history.undo(world))
  assert_eq(history.last_diagnostic(), "none")
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after lowered byte-limit undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory drops oversize record while keeping mutation" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryOversizeByteLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo(world))
  assert_eq(history.redo_len(), 1)
  history.set_max_undo_bytes(4)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.last_diagnostic(), "stack_trimmed_byte_limit")
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 0)
  assert_eq(history.undo_bytes(), 0)
  assert_eq(history.last_diagnostic(), "record_dropped_byte_limit")
  assert_true(!history.can_undo())
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected oversize mutation to remain applied")
  }
}

///|
test "WorldHistory trims existing stacks when max_undo_records is lowered" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLowerLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  history.set_max_undo_records(1)
  assert_eq(history.undo_len(), 1)
  assert_true(history.undo(world))
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected value after lowered-limit undo")
  }
  assert_true(!history.can_undo())
}

///|
test "WorldHistory max_undo_records zero clears and keeps future changes unrecorded" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryZeroLimit", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 1)
  history.set_max_undo_records(0)
  assert_eq(history.max_undo_records(), 0)
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  assert_eq(history.last_diagnostic(), "stack_trimmed_record_limit")
  assert_true(!history.begin_transaction("disabled-by-limit"))
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_eq(history.last_diagnostic(), "recording_disabled")
  assert_eq(history.undo_len(), 0)
  assert_true(!history.can_undo())
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected delegated zero-limit value")
  }
}

///|
test "WorldHistory exposes undo and redo labels for UI state" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLabels", 4)
  let entity = world.create_entity()
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction("Move Entity"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  assert_true(history.commit_transaction())
  assert_true(history.undo_label() is Some("Move Entity"))
  assert_true(history.redo_label() is None)
  assert_true(history.begin_transaction("Rename Entity"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.undo_label() is Some("Rename Entity"))
  assert_true(history.undo(world))
  assert_true(history.undo_label() is Some("Move Entity"))
  assert_true(history.redo_label() is Some("Rename Entity"))
  assert_true(history.redo(world))
  assert_true(history.undo_label() is Some("Rename Entity"))
  assert_true(history.redo_label() is None)
}

///|
test "WorldHistory clears labels with history state" {
  let world = World::new()
  let history = WorldHistory::new()
  let component = world.register_cpu_component("HistoryLabelClears", 4)
  let entity = world.create_entity()
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(history.begin_transaction(""))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_true(history.commit_transaction())
  assert_true(history.undo_label() is Some(""))
  history.clear()
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_true(history.undo_label() is Some("set_component_bytes"))
  history.set_enabled(false)
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
  history.set_enabled(true)
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(4, 0, 0, 0)),
  )
  assert_true(history.undo_label() is Some("set_component_bytes"))
  history.set_max_undo_records(0)
  assert_true(history.undo_label() is None)
  assert_true(history.redo_label() is None)
}

///|
test "WorldHistory restores destroyed GlobalTransform presence for recompute" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(
    world.set_transform_trs(
      entity,
      (4.0 : Float),
      (5.0 : Float),
      (6.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  assert_true(history.destroy_entity(world, entity))
  assert_true(!world.is_alive(entity))
  assert_true(history.undo(world))
  assert_true(world.is_alive(entity))
  assert_true(world.has_component(entity, world.transform_component()))
  assert_true(world.has_component(entity, world.global_transform_component()))
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(entity) {
    Some(m) => {
      assert_eq(m.at(0, 3), (4.0 : Float))
      assert_eq(m.at(1, 3), (5.0 : Float))
      assert_eq(m.at(2, 3), (6.0 : Float))
    }
    None => abort("expected recomputed GlobalTransform")
  }
}

///|
test "WorldHistory restores removed GlobalTransform as fresh recomputable blob" {
  let world = World::new()
  let history = WorldHistory::new()
  let entity = world.create_entity()
  assert_true(
    world.set_transform_trs(
      entity,
      (9.0 : Float),
      (2.0 : Float),
      (-3.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_true(world.set_global_transform(entity, @m44.Matrix44F::identity()))
  let _ = world.drain_global_transform_blob_write_views()
  let global_transform = world.global_transform_component()
  assert_true(history.remove_component(world, entity, global_transform))
  assert_true(!world.has_component(entity, global_transform))
  assert_true(history.undo(world))
  assert_true(world.has_component(entity, global_transform))
  world.update_global_transforms_from_transforms()
  match world.get_global_transform(entity) {
    Some(m) => {
      assert_eq(m.at(0, 3), (9.0 : Float))
      assert_eq(m.at(1, 3), (2.0 : Float))
      assert_eq(m.at(2, 3), (-3.0 : Float))
    }
    None => abort("expected recomputed GlobalTransform after remove undo")
  }
}

///|
test "WorldHistory restores destroyed Camera presence with readable blob row" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let _ = world.drain_camera_blob_write_views()
  assert_true(history.destroy_entity(world, camera))
  assert_true(!world.is_alive(camera))
  assert_true(history.undo(world))
  assert_true(world.is_alive(camera))
  assert_true(world.has_component(camera, world.camera_component()))
  match world.camera_gpu_row(camera) {
    Some(bytes) => assert_eq(bytes.length(), @comp.camera_gpu_byte_stride())
    None => abort("expected restored Camera GPU row")
  }
  let writes = world.drain_camera_blob_write_views()
  assert_true(writes.length() > 0)
}

///|
test "WorldHistory tracks Camera matrix add undo and redo" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let after = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected tracked Camera row")
  }
  assert_true(world.has_component(camera, world.camera_component()))
  assert_true(history.undo(world))
  assert_true(!world.has_component(camera, world.camera_component()))
  assert_true(history.redo(world))
  assert_true(world.camera_gpu_row(camera) == Some(after))
}

///|
test "WorldHistory tracks Camera matrix row changes" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    world.set_camera_matrices(
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.1 : Float),
      (100.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  let before = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected original Camera row")
  }
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.25 : Float),
      (500.0 : Float),
      (1.5 : Float),
      (0.0 : Float),
      (2.0 : Float),
    ),
  )
  let after = match world.camera_gpu_row(camera) {
    Some(bytes) => bytes
    None => abort("expected changed Camera row")
  }
  assert_true(before != after)
  assert_true(history.undo(world))
  assert_true(world.camera_gpu_row(camera) == Some(before))
  assert_true(history.redo(world))
  assert_true(world.camera_gpu_row(camera) == Some(after))
}

///|
test "WorldHistory Camera tracking disabled and zero limit delegate" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  history.set_enabled(false)
  assert_true(
    history.set_camera_matrices(
      world,
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
  assert_true(world.has_component(camera, world.camera_component()))
  assert_true(!history.can_undo())
  history.set_enabled(true)
  history.set_max_undo_records(0)
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (20.0 : Float),
      (2.0 : Float),
      (0.0 : Float),
      (1.0 : Float),
    ),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(!history.can_undo())
}
