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
/// Runs this query with component-id based row access instead of payload-index access.
pub fn Query::for_each(
  self : Query,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  world.assert_system_components_read(self.required, "Query::for_each")
  world.for_each_query_row_payloads(self.required, (e, _sig, views) => {
    f({ world, entity: e, components: self.required, payloads: views })
  })
}

///|
/// Runs this query and marks selected GPU-visible components dirty after each callback.
pub fn Query::for_each_marking_gpu_dirty(
  self : Query,
  world : World,
  dirty_gpu_components : Array[ComponentTypeId],
  f : (QueryRow) -> Unit,
) -> Unit {
  if component_array_has_duplicates(dirty_gpu_components) {
    abort("Query::for_each_marking_gpu_dirty: duplicate dirty component")
  }
  for i = 0; i < dirty_gpu_components.length(); i = i + 1 {
    if component_array_index_of(self.required, dirty_gpu_components[i]) < 0 {
      abort(
        "Query::for_each_marking_gpu_dirty: dirty component must be part of this query",
      )
    }
    match world.registry.get(dirty_gpu_components[i]) {
      None =>
        abort(
          "Query::for_each_marking_gpu_dirty: unknown dirty component type id",
        )
      Some(rc) =>
        match rc.kind {
          CpuOnly =>
            abort(
              "Query::for_each_marking_gpu_dirty: dirty component must be GpuVisible",
            )
          GpuVisible => ()
        }
    }
  }
  world.assert_system_components_read(
    self.required,
    "Query::for_each_marking_gpu_dirty",
  )
  world.for_each_query_row_payloads(self.required, (e, _sig, views) => {
    f({ world, entity: e, components: self.required, payloads: views })
    for i = 0; i < dirty_gpu_components.length(); i = i + 1 {
      let _ = world.mark_gpu_component_dirty(e, dirty_gpu_components[i])
    }
  })
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
/// Returns the query payload index for `component`.
fn QueryRow::component_payload_index(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
) -> Int {
  let index = component_array_index_of(self.components, component)
  if index < 0 {
    abort(operation + ": component is not part of this query")
  }
  index
}

///|
/// Returns a zero-copy read-only payload view for `component`.
///
/// CpuOnly components return their archetype SoA row; GpuVisible components return the flat GPU
/// store row for this entity. The component must be part of the query's required set.
pub fn QueryRow::read_view(
  self : QueryRow,
  component : ComponentTypeId,
) -> ArrayView[Byte] {
  self.world.assert_system_component_read(component, "QueryRow::read_view")
  let index = self.component_payload_index(component, "QueryRow::read_view")
  self.payloads[index].view()
}

///|
/// Returns a zero-copy mutable payload view for `component`.
///
/// Schedule execution requires `component` to be declared in the active System's `writes` set.
pub fn QueryRow::write_view(
  self : QueryRow,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  self.world.assert_system_component_write(component, "QueryRow::write_view")
  let index = self.component_payload_index(component, "QueryRow::write_view")
  self.payloads[index]
}

///|
/// Marks a GpuVisible component row dirty after mutating it through [`QueryRow::write_view`].
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
