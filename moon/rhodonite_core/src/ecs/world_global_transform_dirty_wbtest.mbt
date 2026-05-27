/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `dirty_test_translation`.
fn dirty_test_translation(x : Float) -> @m44.Matrix44F {
  @m44.Matrix44::translation(
    x,
    (0.0 : Float),
    (0.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
  )
}

///|
/// Implements `dirty_test_set_transform_x`.
fn dirty_test_set_transform_x(
  world : World,
  entity : EntityId,
  x : Float,
) -> Unit {
  if !world.set_transform_trs(
      entity,
      x,
      (0.0 : Float),
      (0.0 : Float),
      0.0,
      0.0,
      0.0,
      1.0,
      (1.0 : Float),
      (1.0 : Float),
      (1.0 : Float),
    ) {
    abort("expected Transform3D set")
  }
}

///|
/// Implements `dirty_test_expect_global_x`.
fn dirty_test_expect_global_x(
  world : World,
  entity : EntityId,
  x : Float,
) -> Unit {
  match world.get_global_transform(entity) {
    Some(m) => if m.at(0, 3) != x { abort("unexpected GlobalTransform x") }
    None => abort("expected GlobalTransform")
  }
}

///|
/// Implements `dirty_test_add_global`.
fn dirty_test_add_global(world : World, entity : EntityId) -> Unit {
  if !world.set_global_transform(entity, @m44.Matrix44F::identity()) {
    abort("expected GlobalTransform add")
  }
}

///|
/// Writes a ChildOf row into a mutable component view.
fn dirty_test_write_child_of_view(
  view : MutArrayView[Byte],
  parent : EntityId,
) -> Unit {
  let bytes = @comp.ChildOf::new(parent.index, parent.generation).to_component_bytes()
  for i = 0; i < bytes.length(); i = i + 1 {
    view[i] = bytes[i]
  }
}

///|
test "dirty transform propagation updates dirty subtree only" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  let root = world.create_entity()
  dirty_test_set_transform_x(world, parent, (10.0 : Float))
  dirty_test_set_transform_x(world, child, (5.0 : Float))
  dirty_test_set_transform_x(world, root, (7.0 : Float))
  assert_true(world.set_child_of(child, parent))
  dirty_test_add_global(world, parent)
  dirty_test_add_global(world, child)
  dirty_test_add_global(world, root)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  assert_true(
    world.set_global_transform(root, dirty_test_translation((99.0 : Float))),
  )
  ignore(world.drain_global_transform_blob_write_views())
  dirty_test_set_transform_x(world, parent, (20.0 : Float))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, parent, (20.0 : Float))
  dirty_test_expect_global_x(world, child, (25.0 : Float))
  dirty_test_expect_global_x(world, root, (99.0 : Float))
  assert_eq(world.transform_dirty_entities.length(), 0)
}

///|
test "dirty transform propagation follows tracked typed query writers" {
  let world = World::new()
  let parent_a = world.create_entity()
  let parent_b = world.create_entity()
  let child = world.create_entity()
  dirty_test_set_transform_x(world, parent_a, (10.0 : Float))
  dirty_test_set_transform_x(world, parent_b, (20.0 : Float))
  dirty_test_set_transform_x(world, child, (5.0 : Float))
  assert_true(world.set_child_of(child, parent_a))
  dirty_test_add_global(world, parent_a)
  dirty_test_add_global(world, parent_b)
  dirty_test_add_global(world, child)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  let history = WorldHistory::new()
  Query::new([world.transform_component(), world.child_of_component()]).for_each(
    world,
    row => {
      if row.entity() == child {
        if !row.write_transform3d_tracked(history, transform => {
            transform.write_position(
              (7.0 : Float),
              (0.0 : Float),
              (0.0 : Float),
            )
          }) {
          abort("expected tracked transform write")
        }
        if !row.write_child_of_tracked(history, parent_b) {
          abort("expected tracked ChildOf write")
        }
      }
    },
  )
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (27.0 : Float))
}

///|
test "dirty transform propagation follows sparse tracked archetype rows" {
  let world = World::new()
  let e0 = world.create_entity()
  let e1 = world.create_entity()
  let e2 = world.create_entity()
  dirty_test_set_transform_x(world, e0, (1.0 : Float))
  dirty_test_set_transform_x(world, e1, (2.0 : Float))
  dirty_test_set_transform_x(world, e2, (3.0 : Float))
  dirty_test_add_global(world, e0)
  dirty_test_add_global(world, e1)
  dirty_test_add_global(world, e2)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  assert_true(
    world.set_global_transform(e1, dirty_test_translation((99.0 : Float))),
  )
  ignore(world.drain_global_transform_blob_write_views())
  let tf = world.transform_component()
  let history = WorldHistory::new()
  RawQuery::new([tf]).for_each_archetype(world, arch => {
    let rows : Array[Int] = []
    for row = 0; row < arch.length(); row = row + 1 {
      let entity = arch.entity(row)
      if entity == e0 || entity == e2 {
        rows.push(row)
      }
    }
    if rows.length() > 0 &&
      !arch.write_column_rows_tracked(history, tf, rows, (row, bytes) => {
        let x = if arch.entity(row) == e0 {
          (10.0 : Float)
        } else {
          (30.0 : Float)
        }
        @comp.Transform3D::write_position_to_component_mut_view(
          bytes,
          x,
          (0.0 : Float),
          (0.0 : Float),
        )
      }) {
      abort("expected sparse tracked column write")
    }
  })
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, e0, (10.0 : Float))
  dirty_test_expect_global_x(world, e1, (99.0 : Float))
  dirty_test_expect_global_x(world, e2, (30.0 : Float))
}

///|
test "dirty transform propagation updates deep chain parent first" {
  let world = World::new()
  let root = world.create_entity()
  let middle = world.create_entity()
  let leaf = world.create_entity()
  dirty_test_set_transform_x(world, root, (1.0 : Float))
  dirty_test_set_transform_x(world, middle, (2.0 : Float))
  dirty_test_set_transform_x(world, leaf, (3.0 : Float))
  assert_true(world.set_child_of(middle, root))
  assert_true(world.set_child_of(leaf, middle))
  dirty_test_add_global(world, root)
  dirty_test_add_global(world, middle)
  dirty_test_add_global(world, leaf)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  dirty_test_set_transform_x(world, root, (10.0 : Float))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, root, (10.0 : Float))
  dirty_test_expect_global_x(world, middle, (12.0 : Float))
  dirty_test_expect_global_x(world, leaf, (15.0 : Float))
}

///|
test "dirty transform hierarchy index follows reparent and old parent no longer owns child" {
  let world = World::new()
  let parent_a = world.create_entity()
  let parent_b = world.create_entity()
  let child = world.create_entity()
  dirty_test_set_transform_x(world, parent_a, (10.0 : Float))
  dirty_test_set_transform_x(world, parent_b, (20.0 : Float))
  dirty_test_set_transform_x(world, child, (5.0 : Float))
  assert_true(world.set_child_of(child, parent_a))
  dirty_test_add_global(world, parent_a)
  dirty_test_add_global(world, parent_b)
  dirty_test_add_global(world, child)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  assert_true(world.set_child_of(child, parent_b))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (25.0 : Float))
  assert_true(
    world.set_global_transform(child, dirty_test_translation((99.0 : Float))),
  )
  ignore(world.drain_global_transform_blob_write_views())
  dirty_test_set_transform_x(world, parent_a, (30.0 : Float))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (99.0 : Float))
  dirty_test_set_transform_x(world, parent_b, (40.0 : Float))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (45.0 : Float))
}

///|
test "dirty transform hierarchy index follows ChildOf removal" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  dirty_test_set_transform_x(world, parent, (10.0 : Float))
  dirty_test_set_transform_x(world, child, (5.0 : Float))
  assert_true(world.set_child_of(child, parent))
  dirty_test_add_global(world, parent)
  dirty_test_add_global(world, child)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  assert_true(world.remove_component(child, world.child_of_component()))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (5.0 : Float))
  assert_true(
    world.set_global_transform(child, dirty_test_translation((99.0 : Float))),
  )
  ignore(world.drain_global_transform_blob_write_views())
  dirty_test_set_transform_x(world, parent, (20.0 : Float))
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (99.0 : Float))
}

///|
test "dirty transform hierarchy index rejects stale parent generation after reuse" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  dirty_test_set_transform_x(world, parent, (10.0 : Float))
  dirty_test_set_transform_x(world, child, (5.0 : Float))
  assert_true(world.set_child_of(child, parent))
  dirty_test_add_global(world, parent)
  dirty_test_add_global(world, child)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  assert_true(world.destroy_entity(parent))
  let reused_parent = world.create_entity()
  assert_eq(reused_parent.index, parent.index)
  assert_true(reused_parent.generation != parent.generation)
  dirty_test_set_transform_x(world, reused_parent, (100.0 : Float))
  dirty_test_add_global(world, reused_parent)
  assert_true(
    world.set_global_transform(child, dirty_test_translation((99.0 : Float))),
  )
  ignore(world.drain_global_transform_blob_write_views())
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (99.0 : Float))
}

///|
test "dirty transform hierarchy index follows sparse tracked ChildOf archetype rows" {
  let world = World::new()
  let parent_a = world.create_entity()
  let parent_b = world.create_entity()
  let child = world.create_entity()
  dirty_test_set_transform_x(world, parent_a, (10.0 : Float))
  dirty_test_set_transform_x(world, parent_b, (20.0 : Float))
  dirty_test_set_transform_x(world, child, (5.0 : Float))
  assert_true(world.set_child_of(child, parent_a))
  dirty_test_add_global(world, parent_a)
  dirty_test_add_global(world, parent_b)
  dirty_test_add_global(world, child)
  world.update_global_transforms_from_transforms()
  ignore(world.drain_global_transform_blob_write_views())
  let co = world.child_of_component()
  let history = WorldHistory::new()
  RawQuery::new([co]).for_each_archetype(world, arch => {
    let rows : Array[Int] = []
    for row = 0; row < arch.length(); row = row + 1 {
      if arch.entity(row) == child {
        rows.push(row)
      }
    }
    if rows.length() > 0 &&
      !arch.write_column_rows_tracked(history, co, rows, (_row, bytes) => {
        dirty_test_write_child_of_view(bytes, parent_b)
      }) {
      abort("expected sparse tracked ChildOf write")
    }
  })
  assert_true(world.update_global_transforms_from_transforms_dirty())
  dirty_test_expect_global_x(world, child, (25.0 : Float))
}
