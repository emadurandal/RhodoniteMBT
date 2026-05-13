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
fn Query::assert_registered_components(
  self : Query,
  world : World,
  operation : String,
) -> Unit {
  for k = 0; k < self.required.length(); k = k + 1 {
    match world.registry.get(self.required[k]) {
      Some(_) => ()
      None =>
        abort(
          operation +
          ": unknown " +
          component_id_text(self.required[k]) +
          ". Hint: use ComponentTypeId values registered in this World, or builtin component accessors such as world.transform_component().",
        )
    }
  }
}

///|
fn Query::archetype_accesses(
  self : Query,
  world : World,
  archetype_index : Int,
  operation : String,
) -> Array[QueryArchetypeComponentAccess] {
  let arch = world.archetypes[archetype_index]
  let accesses : Array[QueryArchetypeComponentAccess] = []
  for k = 0; k < self.required.length(); k = k + 1 {
    let component = self.required[k]
    match world.registry.get(component) {
      Some(rc) =>
        match rc.kind {
          CpuOnly => {
            let ci = arch.column_index(component)
            if ci < 0 {
              abort(operation + ": matched archetype is missing CPU column")
            }
            accesses.push({
              component,
              kind: CpuOnly,
              column_index: ci,
              stride: arch.columns[ci].stride,
            })
          }
          GpuVisible => {
            let stride = match world.gpu_store(component) {
              Some(store) => store.stride
              None =>
                abort(
                  operation +
                  ": GpuVisible " +
                  component_id_text(component) +
                  " has no GPU store.",
                )
            }
            accesses.push({
              component,
              kind: GpuVisible,
              column_index: -1,
              stride,
            })
          }
        }
      None => abort(operation + ": unknown component")
    }
  }
  accesses
}

///|
fn Query::matches_archetype(
  self : Query,
  world : World,
  archetype_index : Int,
) -> Bool {
  let required_len = self.required.length()
  if required_len == 0 {
    false
  } else if required_len == 1 {
    component_array_contains(
      world.archetypes[archetype_index].components,
      self.required[0],
    )
  } else if required_len == 2 {
    let sig = world.archetypes[archetype_index].components
    component_array_contains(sig, self.required[0]) &&
    component_array_contains(sig, self.required[1])
  } else {
    component_array_contains_all(
      world.archetypes[archetype_index].components,
      self.required,
    )
  }
}

///|
/// Precomputes matched archetypes and component access metadata for repeated chunk iteration.
pub fn Query::prepare(self : Query, world : World) -> PreparedQuery {
  world.assert_system_components_read(self.required, "Query::prepare")
  self.assert_registered_components(world, "Query::prepare")
  let prepared_archetypes : Array[PreparedQueryArchetype] = []
  if self.required.length() > 0 {
    for ai = 0; ai < world.archetypes.length(); ai = ai + 1 {
      if self.matches_archetype(world, ai) {
        prepared_archetypes.push({
          archetype_index: ai,
          accesses: self.archetype_accesses(world, ai, "Query::prepare"),
        })
      }
    }
  }
  {
    required: copy_component_array(self.required),
    archetype_version: world.archetype_version,
    archetypes: prepared_archetypes,
  }
}

///|
/// Runs this query with component-id based row access instead of payload-index access.
pub fn Query::for_each(
  self : Query,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  world.assert_system_components_read(self.required, "Query::for_each")
  if self.required.length() == 0 {
    return
  }
  self.assert_registered_components(world, "Query::for_each")
  world.query_depth = world.query_depth + 1
  for ai = 0; ai < world.archetypes.length(); ai = ai + 1 {
    let arch = world.archetypes[ai]
    if component_array_contains_all(arch.components, self.required) {
      let accesses : Array[QueryRowComponentAccess] = []
      for k = 0; k < self.required.length(); k = k + 1 {
        let component = self.required[k]
        match world.registry.get(component) {
          Some(rc) =>
            match rc.kind {
              CpuOnly => {
                let ci = arch.column_index(component)
                if ci < 0 {
                  abort(
                    "Query::for_each: matched archetype is missing CPU column",
                  )
                }
                accesses.push({
                  kind: CpuOnly,
                  column_index: ci,
                  stride: arch.columns[ci].stride,
                })
              }
              GpuVisible =>
                accesses.push({ kind: GpuVisible, column_index: -1, stride: 0 })
            }
          None => abort("Query::for_each: unknown component")
        }
      }
      let ents = arch.entities
      for row = 0; row < ents.length(); row = row + 1 {
        f({
          world,
          entity: ents[row],
          components: self.required,
          accesses,
          archetype_index: ai,
          row,
        })
      }
    }
  }
  world.query_depth = world.query_depth - 1
}

///|
/// Runs this query archetype-by-archetype. This avoids constructing one [`QueryRow`] per entity
/// and lets hot systems loop over contiguous CPU component columns directly.
pub fn Query::for_each_archetype(
  self : Query,
  world : World,
  f : (QueryArchetype) -> Unit,
) -> Unit {
  self.prepare(world).for_each_archetype(world, f)
}

///|
/// Runs a prepared query archetype-by-archetype. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn PreparedQuery::for_each_archetype(
  self : PreparedQuery,
  world : World,
  f : (QueryArchetype) -> Unit,
) -> Unit {
  world.assert_system_components_read(
    self.required,
    "PreparedQuery::for_each_archetype",
  )
  let plan = if self.archetype_version == world.archetype_version {
    self
  } else {
    Query::new(self.required).prepare(world)
  }
  if plan.required.length() == 0 {
    return
  }
  world.query_depth = world.query_depth + 1
  for i = 0; i < plan.archetypes.length(); i = i + 1 {
    let chunk = plan.archetypes[i]
    f({
      world,
      accesses: chunk.accesses,
      archetype_index: chunk.archetype_index,
    })
  }
  world.query_depth = world.query_depth - 1
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
  let payload_index = self.component_payload_index(component, operation)
  let access = self.accesses[payload_index]
  match access.kind {
    CpuOnly => {
      let col = self.world.archetypes[self.archetype_index].columns[access.column_index]
      let base = self.row * access.stride
      col.bytes[base:base + access.stride]
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

///|
/// Builds the requested mutable row view on demand.
fn QueryRow::component_mut_view(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
  mark_gpu_dirty : Bool,
) -> MutArrayView[Byte] {
  let payload_index = self.component_payload_index(component, operation)
  let access = self.accesses[payload_index]
  match access.kind {
    CpuOnly => {
      let col = self.world.archetypes[self.archetype_index].columns[access.column_index]
      let base = self.row * access.stride
      col.bytes.mut_view(start=base, end=base + access.stride)
    }
    GpuVisible =>
      match
        self.world.ensure_gpu_store_capacity(component, self.entity.index + 1) {
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
  self.component_access_index(component) >= 0
}

///|
pub fn QueryArchetype::component_stride(
  self : QueryArchetype,
  component : ComponentTypeId,
) -> Int {
  let index = self.component_payload_index(
    component, "QueryArchetype::component_stride",
  )
  self.accesses[index].stride
}

///|
fn QueryArchetype::component_access_index(
  self : QueryArchetype,
  component : ComponentTypeId,
) -> Int {
  for i = 0; i < self.accesses.length(); i = i + 1 {
    if self.accesses[i].component == component {
      return i
    }
  }
  -1
}

///|
fn QueryArchetype::component_payload_index(
  self : QueryArchetype,
  component : ComponentTypeId,
  operation : String,
) -> Int {
  let index = self.component_access_index(component)
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
  let access_index = self.component_payload_index(
    component, "QueryArchetype::read_column",
  )
  let access = self.accesses[access_index]
  match access.kind {
    CpuOnly => {
      let arch = self.world.archetypes[self.archetype_index]
      let col = arch.columns[access.column_index]
      let logical_end = arch.entities.length() * col.stride
      col.bytes[0:logical_end]
    }
    GpuVisible =>
      abort(
        "QueryArchetype::read_column: GpuVisible columns are flat by EntityId.index, not archetype row.",
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
  let access_index = self.component_payload_index(
    component, "QueryArchetype::write_column",
  )
  let access = self.accesses[access_index]
  match access.kind {
    CpuOnly => {
      let arch = self.world.archetypes[self.archetype_index]
      let col = arch.columns[access.column_index]
      let logical_end = arch.entities.length() * col.stride
      col.bytes.mut_view(start=0, end=logical_end)
    }
    GpuVisible =>
      abort(
        "QueryArchetype::write_column: GpuVisible columns are flat by EntityId.index, not archetype row.",
      )
  }
}
