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
    abort(
      "Query::new: duplicate required component. Hint: pass each ComponentTypeId at most once; use QueryRow::read_view or write_view with the component id instead of requesting the same row multiple times.",
    )
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
  world.for_each_query_rows(self.required, (e, archetype_index, row) => {
    f({ world, entity: e, components: self.required, archetype_index, row })
  })
}

///|
/// Runs this query archetype-by-archetype. This avoids constructing one [`QueryRow`] per entity
/// and lets hot systems loop over contiguous CPU component columns directly.
pub fn Query::for_each_archetype(
  self : Query,
  world : World,
  f : (QueryArchetype) -> Unit,
) -> Unit {
  world.assert_system_components_read(
    self.required,
    "Query::for_each_archetype",
  )
  world.for_each_query_archetypes(self.required, archetype_index => {
    f({ world, components: self.required, archetype_index })
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
    abort(
      operation +
      ": " +
      component_id_text(component) +
      " is not part of this QueryRow. Hint: include this component in Query::new([...]) required components before calling read_view or write_view for it.",
    )
  }
  index
}

///|
/// Builds the requested read-only row view on demand without growing stores or marking dirty rows.
fn QueryRow::component_view(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
) -> ArrayView[Byte] {
  ignore(self.component_payload_index(component, operation))
  match self.world.registry.get(component) {
    None =>
      abort(
        operation +
        ": unknown " +
        component_id_text(component) +
        ". Hint: use a ComponentTypeId returned by this World's register_*_component or builtin component accessor.",
      )
    Some(rc) =>
      match rc.kind {
        CpuOnly =>
          match
            self.world.archetypes[self.archetype_index].component_byte_view(
              self.row,
              component,
            ) {
            Some(v) => v
            None =>
              abort(
                operation +
                ": required " +
                component_id_text(component) +
                " is missing from the matched archetype. Hint: this indicates an internal ECS archetype signature/column mismatch; report the query and component ids that triggered it.",
              )
          }
        GpuVisible =>
          match self.world.gpu_store(component) {
            Some(store) =>
              match store.entity_row_view(self.entity.index) {
                Some(v) => v
                None =>
                  abort(
                    operation +
                    ": GpuVisible " +
                    component_id_text(component) +
                    " row is outside the current GPU store capacity. Hint: GPU-visible ownership should be initialized through add_component/add_component_bytes before querying.",
                  )
              }
            None =>
              abort(
                operation +
                ": GpuVisible " +
                component_id_text(component) +
                " has no GPU store. Hint: register GPU-visible components through World::register_gpu_component; CPU components should use World::register_cpu_component.",
              )
          }
      }
  }
}

///|
/// Builds the requested mutable row view on demand.
fn QueryRow::component_mut_view(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
  mark_gpu_dirty : Bool,
) -> MutArrayView[Byte] {
  ignore(self.component_payload_index(component, operation))
  match self.world.registry.get(component) {
    None =>
      abort(
        operation +
        ": unknown " +
        component_id_text(component) +
        ". Hint: use a ComponentTypeId returned by this World's register_*_component or builtin component accessor.",
      )
    Some(rc) =>
      match rc.kind {
        CpuOnly =>
          match
            self.world.archetypes[self.archetype_index].component_byte_mut_view(
              self.row,
              component,
            ) {
            Some(v) => v
            None =>
              abort(
                operation +
                ": required " +
                component_id_text(component) +
                " is missing from the matched archetype. Hint: this indicates an internal ECS archetype signature/column mismatch; report the query and component ids that triggered it.",
              )
          }
        GpuVisible =>
          match
            self.world.ensure_gpu_store_capacity(
              component,
              self.entity.index + 1,
            ) {
            Some(store) => {
              if mark_gpu_dirty {
                store.mark_dirty(self.entity.index)
                self.world.replace_gpu_store(store)
              }
              let base = self.entity.index * store.stride
              store.bytes.mut_view(start=base, end=base + store.stride)
            }
            None =>
              abort(
                operation +
                ": GpuVisible " +
                component_id_text(component) +
                " has no GPU store. Hint: register GPU-visible components through World::register_gpu_component; CPU components should use World::register_cpu_component.",
              )
          }
      }
  }
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
  self.component_view(component, "QueryRow::read_view")
}

///|
/// Returns a zero-copy mutable payload view for `component`.
///
/// Schedule execution requires `component` to be declared in the active System's `writes` set.
/// Requesting a mutable view for a GpuVisible component marks that entity row dirty immediately.
pub fn QueryRow::write_view(
  self : QueryRow,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  self.world.assert_system_component_write(component, "QueryRow::write_view")
  self.component_mut_view(component, "QueryRow::write_view", true)
}

///|
pub fn QueryArchetype::length(self : QueryArchetype) -> Int {
  self.world.archetypes[self.archetype_index].entities.length()
}

///|
pub fn QueryArchetype::entity(self : QueryArchetype, row : Int) -> EntityId {
  self.world.archetypes[self.archetype_index].entities[row]
}

///|
pub fn QueryArchetype::has(
  self : QueryArchetype,
  component : ComponentTypeId,
) -> Bool {
  component_array_index_of(self.components, component) >= 0
}

///|
pub fn QueryArchetype::component_stride(
  self : QueryArchetype,
  component : ComponentTypeId,
) -> Int {
  ignore(
    self.component_payload_index(component, "QueryArchetype::component_stride"),
  )
  match self.world.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => self.world.registry.stride(component)
        GpuVisible =>
          match self.world.gpu_store(component) {
            Some(store) => store.stride
            None =>
              abort(
                "QueryArchetype::component_stride: GpuVisible " +
                component_id_text(component) +
                " has no GPU store.",
              )
          }
      }
    None =>
      abort(
        "QueryArchetype::component_stride: unknown " +
        component_id_text(component),
      )
  }
}

///|
fn QueryArchetype::component_payload_index(
  self : QueryArchetype,
  component : ComponentTypeId,
  operation : String,
) -> Int {
  let index = component_array_index_of(self.components, component)
  if index < 0 {
    abort(
      operation +
      ": " +
      component_id_text(component) +
      " is not part of this QueryArchetype.",
    )
  }
  index
}

///|
/// Returns the contiguous CPU SoA column for `component`. GPU-visible components are flat by
/// `EntityId.index` instead of archetype row, so use row views or component-specific APIs for them.
pub fn QueryArchetype::read_column(
  self : QueryArchetype,
  component : ComponentTypeId,
) -> ArrayView[Byte] {
  self.world.assert_system_component_read(
    component, "QueryArchetype::read_column",
  )
  ignore(self.component_payload_index(component, "QueryArchetype::read_column"))
  match self.world.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => {
          let arch = self.world.archetypes[self.archetype_index]
          let ci = arch.column_index(component)
          if ci < 0 {
            abort("QueryArchetype::read_column: missing CPU column")
          }
          let col = arch.columns[ci]
          col.bytes[:]
        }
        GpuVisible =>
          abort(
            "QueryArchetype::read_column: GpuVisible columns are flat by EntityId.index, not archetype row.",
          )
      }
    None =>
      abort(
        "QueryArchetype::read_column: unknown " + component_id_text(component),
      )
  }
}

///|
/// Returns the contiguous mutable CPU SoA column for `component`.
pub fn QueryArchetype::write_column(
  self : QueryArchetype,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  self.world.assert_system_component_write(
    component, "QueryArchetype::write_column",
  )
  ignore(
    self.component_payload_index(component, "QueryArchetype::write_column"),
  )
  match self.world.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => {
          let arch = self.world.archetypes[self.archetype_index]
          let ci = arch.column_index(component)
          if ci < 0 {
            abort("QueryArchetype::write_column: missing CPU column")
          }
          let col = arch.columns[ci]
          col.bytes.mut_view(start=0, end=col.bytes.length())
        }
        GpuVisible =>
          abort(
            "QueryArchetype::write_column: GpuVisible columns are flat by EntityId.index, not archetype row.",
          )
      }
    None =>
      abort(
        "QueryArchetype::write_column: unknown " + component_id_text(component),
      )
  }
}
