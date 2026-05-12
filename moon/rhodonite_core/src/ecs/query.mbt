///|
fn copy_component_array(src : Array[ComponentTypeId]) -> Array[ComponentTypeId] {
  let out : Array[ComponentTypeId] = []
  for i = 0; i < src.length(); i = i + 1 {
    out.push(src[i])
  }
  out
}

///|
fn component_array_index_of(
  components : Array[ComponentTypeId],
  component : ComponentTypeId,
) -> Int {
  for i = 0; i < components.length(); i = i + 1 {
    if components[i] == component {
      return i
    }
  }
  -1
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
/// Runs this query with component-id based row access instead of payload-index access.
pub fn Query::for_each_row(
  self : Query,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  world.for_each_entity_with_components(self.required, (e, _sig, views) => {
    f({ world, entity: e, components: self.required, payloads: views })
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

///|
/// Runs this query with component-id based row access and marks selected GPU-visible components
/// dirty after each callback.
pub fn Query::for_each_row_marking_dirty(
  self : Query,
  world : World,
  dirty_gpu_components : Array[ComponentTypeId],
  f : (QueryRow) -> Unit,
) -> Unit {
  world.for_each_entity_with_components_marking_gpu_dirty(
    self.required,
    dirty_gpu_components,
    (e, _sig, views) => {
      f({ world, entity: e, components: self.required, payloads: views })
    },
  )
}

///|
/// Returns the entity for this query row.
pub fn QueryRow::entity(self : QueryRow) -> EntityId {
  self.entity
}

///|
/// Returns true if this row was queried with `component`.
pub fn QueryRow::has(self : QueryRow, component : ComponentTypeId) -> Bool {
  component_array_index_of(self.components, component) >= 0
}

///|
/// Returns the zero-copy payload view for `component`.
///
/// CpuOnly components return their archetype SoA row; GpuVisible components return the flat GPU
/// store row for this entity. The component must be part of the query's required set.
pub fn QueryRow::view(
  self : QueryRow,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  let index = component_array_index_of(self.components, component)
  if index < 0 {
    abort("QueryRow::view: component is not part of this query")
  }
  self.payloads[index]
}

///|
/// Marks a GpuVisible component row dirty after mutating it through [`QueryRow::view`].
pub fn QueryRow::mark_dirty(
  self : QueryRow,
  component : ComponentTypeId,
) -> Bool {
  if !self.has(component) {
    abort("QueryRow::mark_dirty: component is not part of this query")
  }
  match self.world.registry.get(component) {
    None => abort("QueryRow::mark_dirty: unknown component type id")
    Some(rc) =>
      match rc.kind {
        CpuOnly => abort("QueryRow::mark_dirty: component must be GpuVisible")
        GpuVisible =>
          self.world.mark_gpu_component_dirty(self.entity, component)
      }
  }
}
