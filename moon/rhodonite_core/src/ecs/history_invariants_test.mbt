/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Builds a four-byte component payload for history invariant tests.
fn history_invariant_bytes4(
  a : Byte,
  b : Byte,
  c : Byte,
  d : Byte,
) -> FixedArray[Byte] {
  [a, b, c, d]
}

///|
/// Asserts that an entity has an exact CPU component payload.
fn history_invariant_assert_component_bytes(
  world : World,
  entity : EntityId,
  component : ComponentTypeId,
  expected : FixedArray[Byte],
) -> Unit {
  if world.component_bytes(entity, component) != Some(expected) {
    abort("expected component bytes")
  }
}

///|
/// Asserts that an entity does not have a component.
fn history_invariant_assert_component_absent(
  world : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  if world.has_component(entity, component) {
    abort("expected component absence")
  }
}

///|
/// Asserts Transform3D translation components.
fn history_invariant_assert_transform_translation(
  world : World,
  entity : EntityId,
  x : Float,
  y : Float,
  z : Float,
) -> Unit {
  match world.get_transform(entity) {
    Some(transform) =>
      if transform.position.x() != x ||
        transform.position.y() != y ||
        transform.position.z() != z {
        abort("expected Transform3D translation")
      }
    None => abort("expected Transform3D")
  }
}

///|
/// Asserts GlobalTransform format and translation components.
fn history_invariant_assert_global_transform(
  world : World,
  entity : EntityId,
  format : @comp.GlobalTransformGpuFormat,
  x : Float,
  y : Float,
  z : Float,
) -> Unit {
  let refs = world.extract_global_transform_refs([entity])
  let (actual_format, _) = @comp.global_transform_ref_from_component_view(
    refs[0:8],
  )
  if actual_format != format {
    abort("expected GlobalTransform format")
  }
  match world.get_global_transform(entity) {
    Some(matrix) =>
      if matrix.at(0, 3) != x || matrix.at(1, 3) != y || matrix.at(2, 3) != z {
        abort("expected GlobalTransform translation")
      }
    None => abort("expected readable GlobalTransform")
  }
}

///|
/// Asserts representative Camera GPU row fields.
fn history_invariant_assert_camera_row(
  world : World,
  entity : EntityId,
  near : Float,
  aspect : Float,
  flags : Float,
) -> Unit {
  match world.camera_gpu_row(entity) {
    Some(bytes) =>
      if bytes.length() != @comp.camera_gpu_byte_stride() ||
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 268) != near ||
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 276) != aspect ||
        @comp.get_gpu_f32_byte_view(bytes[0:bytes.length()], 284) != flags {
        abort("expected Camera row fields")
      }
    None => abort("expected readable Camera row")
  }
}

///|
/// Builds the standard orbit orthographic camera descriptor used by invariant tests.
fn history_invariant_orbit_desc() -> OrbitOrthographicCameraDesc {
  OrbitOrthographicCameraDesc::new_yz_pitched(
    0.38,
    (2.0 : Float),
    (5.6 : Float),
    (0.1 : Float),
    (50.0 : Float),
    (1.0 : Float),
    (3.8 : Float),
  )
}

///|
/// Asserts all camera-control setup components are present.
fn history_invariant_assert_camera_setup_present(
  world : World,
  camera : EntityId,
) -> Unit {
  if !world.has_component(camera, world.transform_component()) ||
    !world.has_component(camera, world.global_transform_component()) ||
    !world.has_component(camera, world.orbit_camera_controller_component()) ||
    !world.has_component(camera, world.camera_home_transform_component()) ||
    !world.has_component(camera, world.camera_lens_component()) ||
    !world.has_component(camera, world.camera_component()) {
    abort("expected camera-control setup components")
  }
}

///|
/// Asserts all camera-control setup components are absent.
fn history_invariant_assert_camera_setup_absent(
  world : World,
  camera : EntityId,
) -> Unit {
  if world.has_component(camera, world.transform_component()) ||
    world.has_component(camera, world.global_transform_component()) ||
    world.has_component(camera, world.orbit_camera_controller_component()) ||
    world.has_component(camera, world.camera_home_transform_component()) ||
    world.has_component(camera, world.camera_lens_component()) ||
    world.has_component(camera, world.camera_component()) {
    abort("expected camera-control setup component absence")
  }
}

///|
test "WorldHistory compound transaction preserves round-trip invariants" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryInvariantCpu", 4)
  let bulk = world.register_cpu_component("HistoryInvariantBulk", 4)
  let removed = world.register_cpu_component("HistoryInvariantRemoved", 4)
  let removed_entity = world.create_entity()
  let bulk0 = world.create_entity()
  let bulk1 = world.create_entity()
  assert_true(
    world.add_component_bytes(
      removed_entity,
      removed,
      history_invariant_bytes4(9, 0, 0, 0),
    ),
  )
  assert_true(
    world.add_component_bytes(bulk0, bulk, history_invariant_bytes4(1, 0, 0, 0)),
  )
  assert_true(
    world.add_component_bytes(bulk1, bulk, history_invariant_bytes4(2, 0, 0, 0)),
  )
  assert_true(history.begin_transaction("History Invariant Compound"))
  let parent = history.create_entity(world)
  let entity = history.create_entity(world)
  let camera = history.create_entity(world)
  assert_true(
    history.add_component_bytes(
      world,
      entity,
      cpu,
      history_invariant_bytes4(1, 0, 0, 0),
    ),
  )
  assert_true(
    history.set_component_bytes(
      world,
      entity,
      cpu,
      history_invariant_bytes4(2, 0, 0, 0),
    ),
  )
  assert_true(history.remove_component(world, removed_entity, removed))
  assert_true(
    history.set_component_bytes_many(world, bulk, [bulk0, bulk1], [
      history_invariant_bytes4(3, 0, 0, 0),
      history_invariant_bytes4(4, 0, 0, 0),
    ]),
  )
  assert_true(
    history.set_transform_trs(
      world,
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
  assert_true(history.set_child_of(world, entity, parent))
  assert_true(
    history.set_global_transform(
      world,
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
  assert_true(history.set_global_transform_format(world, entity, Affine3x4F16))
  assert_true(
    history.set_camera_matrices(
      world,
      camera,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.25 : Float),
      (100.0 : Float),
      (1.5 : Float),
      (0.0 : Float),
      (2.0 : Float),
    ),
  )
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  history_invariant_assert_component_absent(world, removed_entity, removed)
  history_invariant_assert_component_bytes(
    world,
    bulk0,
    bulk,
    history_invariant_bytes4(3, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    bulk1,
    bulk,
    history_invariant_bytes4(4, 0, 0, 0),
  )
  history_invariant_assert_transform_translation(
    world,
    entity,
    (4.0 : Float),
    (5.0 : Float),
    (6.0 : Float),
  )
  assert_true(world.get_child_of(entity) == Some(parent))
  history_invariant_assert_global_transform(
    world,
    entity,
    Affine3x4F16,
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
  )
  history_invariant_assert_camera_row(
    world,
    camera,
    (0.25 : Float),
    (1.5 : Float),
    (2.0 : Float),
  )
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(!world.is_alive(parent))
  assert_true(!world.is_alive(entity))
  assert_true(!world.is_alive(camera))
  history_invariant_assert_component_bytes(
    world,
    removed_entity,
    removed,
    history_invariant_bytes4(9, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    bulk0,
    bulk,
    history_invariant_bytes4(1, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    bulk1,
    bulk,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  assert_true(history.redo(world))
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  assert_true(world.is_alive(parent))
  assert_true(world.is_alive(entity))
  assert_true(world.is_alive(camera))
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  history_invariant_assert_component_absent(world, removed_entity, removed)
  history_invariant_assert_global_transform(
    world,
    entity,
    Affine3x4F16,
    (1.0 : Float),
    (2.0 : Float),
    (3.0 : Float),
  )
  history_invariant_assert_camera_row(
    world,
    camera,
    (0.25 : Float),
    (1.5 : Float),
    (2.0 : Float),
  )
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  assert_true(!world.is_alive(parent))
  assert_true(!world.is_alive(entity))
  assert_true(!world.is_alive(camera))
}

///|
test "WorldHistory entity ids and blob rows survive create destroy round trips" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryInvariantDestroyCpu", 4)
  let victim = world.create_entity()
  assert_true(
    world.add_component_bytes(victim, cpu, history_invariant_bytes4(7, 0, 0, 0)),
  )
  assert_true(
    world.set_global_transform(
      victim,
      @m44.Matrix44::translation(
        (7.0 : Float),
        (8.0 : Float),
        (9.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
      ),
    ),
  )
  assert_true(
    world.set_camera_matrices(
      victim,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.5 : Float),
      (250.0 : Float),
      (2.0 : Float),
      (1.0 : Float),
      (3.0 : Float),
    ),
  )
  assert_true(history.begin_transaction("History Invariant Entity Round Trip"))
  let created = history.create_entities(world, 2)
  assert_eq(created.length(), 2)
  assert_true(history.destroy_entity(world, victim))
  assert_true(history.commit_transaction())
  assert_true(world.is_alive(created[0]))
  assert_true(world.is_alive(created[1]))
  assert_true(!world.is_alive(victim))
  assert_true(history.undo(world))
  assert_true(!world.is_alive(created[0]))
  assert_true(!world.is_alive(created[1]))
  assert_true(world.is_alive(victim))
  assert_eq(victim.generation, 0)
  history_invariant_assert_component_bytes(
    world,
    victim,
    cpu,
    history_invariant_bytes4(7, 0, 0, 0),
  )
  let refs = world.extract_global_transform_refs([victim])
  let (format, _) = @comp.global_transform_ref_from_component_view(refs[0:8])
  assert_true(format == Affine3x4F32)
  match world.get_global_transform(victim) {
    Some(_) => ()
    None => abort("expected restored GlobalTransform blob row")
  }
  match world.camera_gpu_row(victim) {
    Some(bytes) => assert_eq(bytes.length(), @comp.camera_gpu_byte_stride())
    None => abort("expected restored Camera blob row")
  }
  assert_true(history.redo(world))
  assert_true(world.is_alive(created[0]))
  assert_true(world.is_alive(created[1]))
  assert_eq(created[0].generation, 0)
  assert_eq(created[1].generation, 0)
  assert_true(!world.is_alive(victim))
  assert_true(history.undo(world))
  assert_true(!world.is_alive(created[0]))
  assert_true(!world.is_alive(created[1]))
  assert_true(world.is_alive(victim))
  match world.camera_gpu_row(victim) {
    Some(bytes) => assert_eq(bytes.length(), @comp.camera_gpu_byte_stride())
    None => abort("expected restored Camera blob row")
  }
}

///|
test "WorldHistory tracked query transaction preserves round-trip invariants" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryInvariantQueryCpu", 4)
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  assert_true(
    world.add_component_bytes(e0, cpu, history_invariant_bytes4(1, 0, 0, 0)),
  )
  assert_true(
    world.add_component_bytes(e1, cpu, history_invariant_bytes4(2, 0, 0, 0)),
  )
  assert_true(
    world.add_component_bytes(e2, cpu, history_invariant_bytes4(3, 0, 0, 0)),
  )
  assert_true(history.begin_transaction("History Invariant Query Writes"))
  Query::new([cpu]).for_each(world, row => {
    if !row.write_tracked(history, cpu, bytes => bytes[0] = (4 : Byte)) {
      abort("expected tracked query row write")
    }
  })
  RawQuery::new([cpu]).for_each_archetype(world, arch => {
    if !arch.write_column_tracked(history, cpu, col => col[0] = (5 : Byte)) {
      abort("expected tracked column write")
    }
    if !arch.write_column_rows_tracked(history, cpu, [1, 2], (row, bytes) => {
        bytes[0] = (row + 5).to_byte()
      }) {
      abort("expected tracked sparse row column write")
    }
  })
  assert_true(history.commit_transaction())
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    e0,
    cpu,
    history_invariant_bytes4(5, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e1,
    cpu,
    history_invariant_bytes4(6, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e2,
    cpu,
    history_invariant_bytes4(7, 0, 0, 0),
  )
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  history_invariant_assert_component_bytes(
    world,
    e0,
    cpu,
    history_invariant_bytes4(1, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e1,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e2,
    cpu,
    history_invariant_bytes4(3, 0, 0, 0),
  )
  assert_true(history.redo(world))
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    e0,
    cpu,
    history_invariant_bytes4(5, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e1,
    cpu,
    history_invariant_bytes4(6, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e2,
    cpu,
    history_invariant_bytes4(7, 0, 0, 0),
  )
}

///|
test "WorldHistory bulk validation failures preserve world and stacks" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryInvariantBulkFailureCpu", 4)
  let marker = world.register_cpu_component(
    "HistoryInvariantBulkFailureMarker", 4,
  )
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let missing = world.create_entity()
  assert_true(
    world.add_component_bytes(e0, cpu, history_invariant_bytes4(1, 0, 0, 0)),
  )
  assert_true(
    world.add_component_bytes(e1, cpu, history_invariant_bytes4(2, 0, 0, 0)),
  )
  assert_true(
    !history.set_component_bytes_many(world, cpu, [e0, e0], [
      history_invariant_bytes4(3, 0, 0, 0),
      history_invariant_bytes4(4, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    e0,
    cpu,
    history_invariant_bytes4(1, 0, 0, 0),
  )
  history_invariant_assert_component_bytes(
    world,
    e1,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  assert_true(
    !history.add_component_bytes_many(world, marker, [missing, missing], [
      history_invariant_bytes4(5, 0, 0, 0),
      history_invariant_bytes4(6, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_absent(world, missing, marker)
  assert_true(
    !history.set_component_bytes_many(world, cpu, [e0, missing], [
      history_invariant_bytes4(7, 0, 0, 0),
      history_invariant_bytes4(8, 0, 0, 0),
    ]),
  )
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    e0,
    cpu,
    history_invariant_bytes4(1, 0, 0, 0),
  )
  history_invariant_assert_component_absent(world, missing, cpu)
}

///|
test "WorldHistory tracked orbit camera setup preserves round-trip invariants" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  assert_true(
    setup_orbit_orthographic_camera_tracked(
      history,
      world,
      camera,
      history_invariant_orbit_desc(),
    ),
  )
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_camera_setup_present(world, camera)
  history_invariant_assert_camera_row(
    world,
    camera,
    (0.1 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  history_invariant_assert_camera_setup_absent(world, camera)
  assert_true(history.redo(world))
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_camera_setup_present(world, camera)
  history_invariant_assert_camera_row(
    world,
    camera,
    (0.1 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
}

///|
test "WorldHistory failed tracked orbit camera setup preserves world and stacks" {
  let world = World::new()
  let history = WorldHistory::new()
  let camera = world.create_entity()
  let orbit = world.orbit_camera_controller_component()
  assert_true(add_orbit_camera_controller(world, camera, orbit, 0.0, 0.0))
  assert_true(
    !setup_orbit_orthographic_camera_tracked(
      history,
      world,
      camera,
      history_invariant_orbit_desc(),
    ),
  )
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  assert_true(world.has_component(camera, orbit))
  assert_true(!world.has_component(camera, world.transform_component()))
  assert_true(!world.has_component(camera, world.global_transform_component()))
  assert_true(
    !world.has_component(camera, world.camera_home_transform_component()),
  )
  assert_true(!world.has_component(camera, world.camera_lens_component()))
  assert_true(!world.has_component(camera, world.camera_component()))
}

///|
test "WorldHistory cancel_transaction_reverting restores compound tracked mutations" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryInvariantCancelCpu", 4)
  let entity = world.create_entity()
  assert_true(
    world.add_component_bytes(entity, cpu, history_invariant_bytes4(1, 0, 0, 0)),
  )
  assert_true(history.begin_transaction("History Invariant Cancel"))
  assert_true(
    history.set_component_bytes(
      world,
      entity,
      cpu,
      history_invariant_bytes4(2, 0, 0, 0),
    ),
  )
  assert_true(
    history.set_global_transform(
      world,
      entity,
      @m44.Matrix44::translation(
        (2.0 : Float),
        (0.0 : Float),
        (0.0 : Float),
        (1.0 : Float),
        (0.0 : Float),
      ),
    ),
  )
  assert_true(
    history.set_camera_matrices(
      world,
      entity,
      @m44.Matrix44F::identity(),
      @m44.Matrix44F::identity(),
      (0.2 : Float),
      (20.0 : Float),
      (1.25 : Float),
      (1.0 : Float),
      (0.0 : Float),
    ),
  )
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  assert_true(world.has_component(entity, world.global_transform_component()))
  assert_true(world.has_component(entity, world.camera_component()))
  assert_true(history.cancel_transaction_reverting(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(1, 0, 0, 0),
  )
  history_invariant_assert_component_absent(
    world,
    entity,
    world.global_transform_component(),
  )
  history_invariant_assert_component_absent(
    world,
    entity,
    world.camera_component(),
  )
}

///|
test "WorldHistory failed run_system_phase keeps successful commands undoable" {
  let world = World::new()
  let history = WorldHistory::new()
  let cpu = world.register_cpu_component("HistoryInvariantCommandCpu", 4)
  let entity = world.create_entity()
  let missing = EntityId::new(entity.index + 100, 0)
  let phase = PhaseKey::new("history-invariant-command-failure")
  assert_true(
    world.add_component_bytes(entity, cpu, history_invariant_bytes4(1, 0, 0, 0)),
  )
  let runner = SystemRunner::new()
  runner.add_system(
    System::new_with_structural_write(
      "history-invariant-command-failure-system",
      phase,
      [],
      [cpu],
      (_w, _ctx, commands) => {
        commands.set_component_bytes(
          entity,
          cpu,
          history_invariant_bytes4(2, 0, 0, 0),
        )
        commands.destroy_entity(missing)
      },
    ),
  )
  assert_true(
    !history.run_system_phase(
      runner,
      world,
      SystemContext::new((0.016 : Float), 1),
      phase,
      "History Invariant Command Failure",
    ),
  )
  assert_eq(history.undo_len(), 1)
  assert_eq(history.redo_len(), 0)
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
  assert_true(history.undo(world))
  assert_eq(history.undo_len(), 0)
  assert_eq(history.redo_len(), 1)
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(1, 0, 0, 0),
  )
  assert_true(history.redo(world))
  history_invariant_assert_component_bytes(
    world,
    entity,
    cpu,
    history_invariant_bytes4(2, 0, 0, 0),
  )
}
