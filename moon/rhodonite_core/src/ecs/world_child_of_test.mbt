///|
test "ChildOf roundtrips parent EntityId" {
  let world = World::new()
  let parent = world.create_entity()
  let child = world.create_entity()
  assert_true(world.set_child_of(child, parent))
  match world.get_child_of(child) {
    Some(p) => {
      assert_eq(p.index, parent.index)
      assert_eq(p.generation, parent.generation)
    }
    None => abort("expected ChildOf")
  }
}
