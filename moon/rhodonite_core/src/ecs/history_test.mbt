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
  assert_eq(history.max_undo_records(), 100)
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  assert_true(world.add_component_bytes(entity, component, bytes4(1, 0, 0, 0)))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(2, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(history.redo(world))
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
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
  assert_true(history.undo(world))
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
  assert_true(!history.begin_transaction("disabled-by-limit"))
  assert_true(
    history.set_component_bytes(world, entity, component, bytes4(3, 0, 0, 0)),
  )
  assert_eq(history.undo_len(), 0)
  assert_true(!history.can_undo())
  match world.component_bytes(entity, component) {
    Some(bytes) => assert_true(bytes == bytes4(3, 0, 0, 0))
    None => abort("expected delegated zero-limit value")
  }
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
