///|
fn copy_component_array(src : Array[ComponentTypeId]) -> Array[ComponentTypeId] {
  let out : Array[ComponentTypeId] = []
  for i = 0; i < src.length(); i = i + 1 {
    out.push(src[i])
  }
  out
}

///|
/// Builds a query descriptor and rejects duplicate component ids up front.
pub fn Query::new(required : Array[ComponentTypeId]) -> Query {
  if component_array_has_duplicates(required) {
    abort("Query::new: duplicate required component")
  }
  { required: copy_component_array(required) }
}

///|
/// Returns a copy of the required component ids in callback payload order.
pub fn Query::required_components(self : Query) -> Array[ComponentTypeId] {
  copy_component_array(self.required)
}

///|
/// Runs this query without exposing the full archetype signature.
pub fn Query::for_each(
  self : Query,
  world : World,
  f : (EntityId, Array[MutArrayView[Byte]]) -> Unit,
) -> Unit {
  world.for_each_entity_with_components(self.required, (e, _sig, views) => {
    f(e, views)
  })
}

///|
/// Runs this query and marks selected GPU-visible components dirty after each callback.
pub fn Query::for_each_marking_gpu_dirty(
  self : Query,
  world : World,
  dirty_gpu_components : Array[ComponentTypeId],
  f : (EntityId, Array[MutArrayView[Byte]]) -> Unit,
) -> Unit {
  world.for_each_entity_with_components_marking_gpu_dirty(
    self.required,
    dirty_gpu_components,
    (e, _sig, views) => f(e, views),
  )
}
