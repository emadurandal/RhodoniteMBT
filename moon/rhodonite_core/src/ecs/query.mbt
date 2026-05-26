/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `component_array_index_of`.
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
      "Query::new: duplicate required component. Hint: pass each ComponentTypeId at most once; use QueryRow::read or write with the component id instead of requesting the same row multiple times.",
    )
  }
  { required: copy_component_array(required) }
}

///|
/// Builds a raw query descriptor and rejects duplicate component ids up front.
pub fn RawQuery::new(required : Array[ComponentTypeId]) -> RawQuery {
  if component_array_has_duplicates(required) {
    abort(
      "RawQuery::new: duplicate required component. Hint: pass each ComponentTypeId at most once.",
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
/// Implements `RawQuery::required_components`.
pub fn RawQuery::required_components(self : RawQuery) -> Array[ComponentTypeId] {
  copy_component_array(self.required)
}

///|
/// Implements `Query::assert_registered_components`.
fn Query::assert_registered_components(
  self : Query,
  world : World,
  operation : String,
) -> Unit {
  assert_query_components_registered(self.required, world, operation)
}

///|
/// Implements `assert_query_components_registered`.
fn assert_query_components_registered(
  required : Array[ComponentTypeId],
  world : World,
  operation : String,
) -> Unit {
  for k = 0; k < required.length(); k = k + 1 {
    match world.registry.get(required[k]) {
      Some(_) => ()
      None =>
        abort(
          operation +
          ": unknown " +
          component_id_text(required[k]) +
          ". Hint: use ComponentTypeId values registered in this World, or builtin component accessors such as world.transform_component().",
        )
    }
  }
}

///|
/// Implements `query_archetype_accesses`.
fn query_archetype_accesses(
  required : Array[ComponentTypeId],
  world : World,
  archetype_index : Int,
  operation : String,
) -> Array[QueryArchetypeComponentAccess] {
  let arch = world.archetypes[archetype_index]
  let accesses : Array[QueryArchetypeComponentAccess] = []
  for k = 0; k < required.length(); k = k + 1 {
    let component = required[k]
    match world.registry.get(component) {
      Some(_) => {
        let ci = arch.column_index(component)
        if ci < 0 {
          abort(operation + ": matched archetype is missing CPU column")
        }
        accesses.push({
          component,
          column_index: ci,
          stride: arch.columns[ci].stride,
        })
      }
      None => abort(operation + ": unknown component")
    }
  }
  accesses
}

///|
/// Implements `query_matches_archetype`.
fn query_matches_archetype(
  required : Array[ComponentTypeId],
  world : World,
  archetype_index : Int,
) -> Bool {
  let required_len = required.length()
  if required_len == 0 {
    false
  } else if required_len == 1 {
    component_array_contains(
      world.archetypes[archetype_index].components,
      required[0],
    )
  } else if required_len == 2 {
    let sig = world.archetypes[archetype_index].components
    component_array_contains(sig, required[0]) &&
    component_array_contains(sig, required[1])
  } else {
    component_array_contains_all(
      world.archetypes[archetype_index].components,
      required,
    )
  }
}

///|
/// Implements `build_prepared_query_archetypes`.
fn build_prepared_query_archetypes(
  required : Array[ComponentTypeId],
  world : World,
  operation : String,
) -> Array[PreparedQueryArchetype] {
  let prepared_archetypes : Array[PreparedQueryArchetype] = []
  if required.length() > 0 {
    let candidates = world.query_candidate_archetypes(required)
    for i = 0; i < candidates.length(); i = i + 1 {
      let ai = candidates[i]
      if query_matches_archetype(required, world, ai) {
        prepared_archetypes.push({
          archetype_index: ai,
          accesses: query_archetype_accesses(required, world, ai, operation),
        })
      }
    }
  }
  prepared_archetypes
}

///|
/// Precomputes matched archetypes and component access metadata for repeated chunk iteration.
pub fn Query::prepare(self : Query, world : World) -> PreparedQuery {
  world.assert_system_components_read(self.required, "Query::prepare")
  self.assert_registered_components(world, "Query::prepare")
  {
    required: copy_component_array(self.required),
    archetype_version: world.archetype_version,
    archetypes: build_prepared_query_archetypes(
      self.required,
      world,
      "Query::prepare",
    ),
  }
}

///|
/// Precomputes matched archetypes and component access metadata for repeated raw iteration.
pub fn RawQuery::prepare(self : RawQuery, world : World) -> RawPreparedQuery {
  world.assert_system_components_read(self.required, "RawQuery::prepare")
  assert_query_components_registered(self.required, world, "RawQuery::prepare")
  {
    required: copy_component_array(self.required),
    archetype_version: world.archetype_version,
    archetypes: build_prepared_query_archetypes(
      self.required,
      world,
      "RawQuery::prepare",
    ),
  }
}

///|
/// Runs this query with component-id based row access instead of payload-index access.
pub fn Query::for_each(
  self : Query,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  self.prepare(world).for_each(world, f)
}

///|
/// Runs this raw query with component-id based byte-view row access.
pub fn RawQuery::for_each(
  self : RawQuery,
  world : World,
  f : (RawQueryRow) -> Unit,
) -> Unit {
  self.prepare(world).for_each(world, f)
}

///|
/// Runs this raw query archetype-by-archetype for hot column loops.
pub fn RawQuery::for_each_archetype(
  self : RawQuery,
  world : World,
  f : (RawQueryArchetype) -> Unit,
) -> Unit {
  self.prepare(world).for_each_archetype(world, f)
}

///|
/// Implements `query_row_accesses_from_archetype_accesses`.
fn query_row_accesses_from_archetype_accesses(
  accesses : Array[QueryArchetypeComponentAccess],
) -> Array[QueryRowComponentAccess] {
  let out : Array[QueryRowComponentAccess] = []
  for i = 0; i < accesses.length(); i = i + 1 {
    let access = accesses[i]
    out.push({ column_index: access.column_index, stride: access.stride })
  }
  out
}

///|
/// Runs a prepared query with row callbacks. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn PreparedQuery::for_each(
  self : PreparedQuery,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  world.assert_system_components_read(self.required, "PreparedQuery::for_each")
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
    let accesses = query_row_accesses_from_archetype_accesses(chunk.accesses)
    let arch = world.archetypes[chunk.archetype_index]
    let ents = arch.entities
    for row = 0; row < ents.length(); row = row + 1 {
      f({
        world,
        entity: ents[row],
        components: plan.required,
        accesses,
        archetype_index: chunk.archetype_index,
        row,
      })
    }
  }
  world.query_depth = world.query_depth - 1
}

///|
/// Runs a prepared raw query with row callbacks. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn RawPreparedQuery::for_each(
  self : RawPreparedQuery,
  world : World,
  f : (RawQueryRow) -> Unit,
) -> Unit {
  let plan = if self.archetype_version == world.archetype_version {
    self
  } else {
    RawQuery::new(self.required).prepare(world)
  }
  if plan.required.length() == 0 {
    return
  }
  world.assert_system_components_read(
    plan.required,
    "RawPreparedQuery::for_each",
  )
  world.query_depth = world.query_depth + 1
  for i = 0; i < plan.archetypes.length(); i = i + 1 {
    let chunk = plan.archetypes[i]
    let accesses = query_row_accesses_from_archetype_accesses(chunk.accesses)
    let arch = world.archetypes[chunk.archetype_index]
    let ents = arch.entities
    for row = 0; row < ents.length(); row = row + 1 {
      f({
        world,
        entity: ents[row],
        components: plan.required,
        accesses,
        archetype_index: chunk.archetype_index,
        row,
      })
    }
  }
  world.query_depth = world.query_depth - 1
}

///|
/// Runs a prepared raw query archetype-by-archetype. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn RawPreparedQuery::for_each_archetype(
  self : RawPreparedQuery,
  world : World,
  f : (RawQueryArchetype) -> Unit,
) -> Unit {
  world.assert_system_components_read(
    self.required,
    "RawPreparedQuery::for_each_archetype",
  )
  let plan = if self.archetype_version == world.archetype_version {
    self
  } else {
    RawQuery::new(self.required).prepare(world)
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
/// Implements `RawQueryRow::entity`.
pub fn RawQueryRow::entity(self : RawQueryRow) -> EntityId {
  self.entity
}

///|
/// Implements `RawQueryRow::has`.
pub fn RawQueryRow::has(
  self : RawQueryRow,
  component : ComponentTypeId,
) -> Bool {
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
      " is not part of this QueryRow. Hint: include this component in Query::new([...]) required components before calling read or write for it.",
    )
  }
  index
}

///|
/// Implements `RawQueryRow::as_query_row`.
fn RawQueryRow::as_query_row(self : RawQueryRow) -> QueryRow {
  {
    world: self.world,
    entity: self.entity,
    components: self.components,
    accesses: self.accesses,
    archetype_index: self.archetype_index,
    row: self.row,
  }
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
  let col = self.world.archetypes[self.archetype_index].columns[access.column_index]
  let base = self.row * access.stride
  col.bytes[base:base + access.stride]
}

///|
/// Builds the requested mutable row view on demand.
fn QueryRow::component_mut_view(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
) -> MutArrayView[Byte] {
  ignore(operation)
  let payload_index = self.component_payload_index(component, operation)
  let access = self.accesses[payload_index]
  let col = self.world.archetypes[self.archetype_index].columns[access.column_index]
  let base = self.row * access.stride
  col.bytes.mut_view(start=base, end=base + access.stride)
}

///|
/// Runs `f` with a closure-scoped read-only payload view for `component`.
///
/// Components return their archetype SoA row. The component must be part of the query's required set.
pub fn QueryRow::read(
  self : QueryRow,
  component : ComponentTypeId,
  f : (ArrayView[Byte]) -> Unit,
) -> Unit {
  self.world.assert_system_component_read(component, "QueryRow::read")
  f(self.component_view(component, "QueryRow::read"))
}

///|
/// Runs `f` with a closure-scoped mutable payload view for `component`.
///
/// SystemRunner execution requires `component` to be declared in the active System's `writes` set.
pub fn QueryRow::write(
  self : QueryRow,
  component : ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  self.world.assert_not_history_raw_mutation("QueryRow::write")
  self.world.assert_system_component_write(component, "QueryRow::write")
  f(self.component_mut_view(component, "QueryRow::write"))
}

///|
/// Runs `f` with a mutable payload view and records one component change through `history`.
///
/// When history recording is disabled, this delegates to `QueryRow::write` without copying
/// before/after bytes.
pub fn QueryRow::write_tracked(
  self : QueryRow,
  history : WorldHistory,
  component : ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  ignore(self.component_payload_index(component, "QueryRow::write_tracked"))
  if !history.recording_enabled() || history.applying {
    self.write(component, f)
    let reason = if !history.recording_enabled() {
      "recording_disabled"
    } else {
      "applying"
    }
    history.set_delegate_diagnostic(true, reason)
    return true
  }
  if self.world.history_blob_ref_component(component) {
    history.begin_tracked_world_mutation(self.world)
    self.write(component, f)
    history.end_tracked_world_mutation(self.world)
    history.set_delegate_diagnostic(true, history_diagnostic_none())
    return true
  }
  let before = match self.world.component_bytes(self.entity, component) {
    Some(bytes) => bytes
    None => {
      history.set_diagnostic("operation_failed")
      return false
    }
  }
  let auto = history.begin_auto("query_row_write")
  history.begin_tracked_world_mutation(self.world)
  self.world.assert_system_component_write(component, "QueryRow::write_tracked")
  f(self.component_mut_view(component, "QueryRow::write_tracked"))
  history.end_tracked_world_mutation(self.world)
  let ok = match self.world.component_bytes(self.entity, component) {
    Some(after) => {
      history.push_delta(
        ComponentChanged(self.entity, component, before, after),
      )
      true
    }
    None => false
  }
  history.finish_auto(auto, ok)
  ok
}

///|
/// Implements `RawQueryRow::read_view`.
pub fn RawQueryRow::read_view(
  self : RawQueryRow,
  component : ComponentTypeId,
) -> ArrayView[Byte] {
  let row = self.as_query_row()
  row.world.assert_system_component_read(component, "RawQueryRow::read_view")
  row.component_view(component, "RawQueryRow::read_view")
}

///|
/// Implements `RawQueryRow::write_view`.
pub fn RawQueryRow::write_view(
  self : RawQueryRow,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  let row = self.as_query_row()
  row.world.assert_not_history_raw_mutation("RawQueryRow::write_view")
  row.world.assert_system_component_write(component, "RawQueryRow::write_view")
  row.component_mut_view(component, "RawQueryRow::write_view")
}

///|
/// Runs `f` with a mutable payload view and records one component change through `history`.
pub fn RawQueryRow::write_tracked(
  self : RawQueryRow,
  history : WorldHistory,
  component : ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  self.as_query_row().write_tracked(history, component, f)
}

///|
/// Implements `QueryRow::read_transform3d`.
pub fn QueryRow::read_transform3d(self : QueryRow) -> @comp.Transform3DRow {
  let component = self.world.transform_component_id
  self.world.assert_system_component_read(
    component, "QueryRow::read_transform3d",
  )
  @comp.Transform3DRow::from_component_view(
    self.component_view(component, "QueryRow::read_transform3d"),
  )
}

///|
/// Implements `QueryRow::write_transform3d`.
pub fn QueryRow::write_transform3d(
  self : QueryRow,
  f : (@comp.Transform3DMutRow) -> Unit,
) -> Unit {
  let component = self.world.transform_component_id
  self.world.assert_not_history_raw_mutation("QueryRow::write_transform3d")
  self.world.assert_system_component_write(
    component, "QueryRow::write_transform3d",
  )
  f(
    @comp.Transform3DMutRow::from_component_mut_view(
      self.component_mut_view(component, "QueryRow::write_transform3d"),
    ),
  )
}

///|
/// Runs `f` with a mutable Transform3D row and records the change through `history`.
pub fn QueryRow::write_transform3d_tracked(
  self : QueryRow,
  history : WorldHistory,
  f : (@comp.Transform3DMutRow) -> Unit,
) -> Bool {
  let component = self.world.transform_component_id
  self.write_tracked(history, component, bytes => {
    f(@comp.Transform3DMutRow::from_component_mut_view(bytes))
  })
}

///|
/// Implements `QueryRow::read_child_of`.
pub fn QueryRow::read_child_of(self : QueryRow) -> EntityId {
  let component = self.world.child_of_component_id
  self.world.assert_system_component_read(component, "QueryRow::read_child_of")
  let c = @comp.ChildOf::from_component_view(
    self.component_view(component, "QueryRow::read_child_of"),
  )
  EntityId::new(c.parent_index, c.parent_generation)
}

///|
/// Implements `QueryRow::write_child_of`.
pub fn QueryRow::write_child_of(self : QueryRow, parent : EntityId) -> Unit {
  let component = self.world.child_of_component_id
  self.world.assert_not_history_raw_mutation("QueryRow::write_child_of")
  self.world.assert_system_component_write(
    component, "QueryRow::write_child_of",
  )
  let row = @comp.ChildOfMutRow::from_component_mut_view(
    self.component_mut_view(component, "QueryRow::write_child_of"),
  )
  row.write_parent(parent.index, parent.generation)
}

///|
/// Writes ChildOf through `history`.
pub fn QueryRow::write_child_of_tracked(
  self : QueryRow,
  history : WorldHistory,
  parent : EntityId,
) -> Bool {
  let component = self.world.child_of_component_id
  self.write_tracked(history, component, bytes => {
    let row = @comp.ChildOfMutRow::from_component_mut_view(bytes)
    row.write_parent(parent.index, parent.generation)
  })
}

///|
/// Implements `QueryRow::write_global_transform`.
pub fn QueryRow::write_global_transform(
  self : QueryRow,
  f : (@comp.GlobalTransformGpuMutRow) -> Unit,
) -> Unit {
  let component = self.world.global_transform_component_id
  self.world.assert_not_history_raw_mutation("QueryRow::write_global_transform")
  self.world.assert_system_component_write(
    component, "QueryRow::write_global_transform",
  )
  let format = match self.world.global_transform_ref(self.entity) {
    Some(gt_ref) => gt_ref.format
    None => self.world.global_transform_default_format
  }
  let row_bytes = FixedArray::make(
    @comp.global_transform_word_count(format) * 4,
    (0 : Byte),
  )
  let current = match self.world.get_global_transform(self.entity) {
    Some(m) => m
    None => @m44.Matrix44F::identity()
  }
  @comp.matrix44f_write_global_transform_to_gpu_row(
    current,
    row_bytes.mut_view(start=0, end=row_bytes.length()),
    format,
  )
  f(
    @comp.GlobalTransformGpuMutRow::from_gpu_row_format(
      row_bytes.mut_view(start=0, end=row_bytes.length()),
      format,
    ),
  )
  let next = @comp.matrix44f_from_global_transform_gpu_bytes(row_bytes, format)
  ignore(self.world.set_global_transform(self.entity, next))
}

///|
/// Runs `f` with a mutable GlobalTransform GPU row and records the logical matrix change through `history`.
pub fn QueryRow::write_global_transform_tracked(
  self : QueryRow,
  history : WorldHistory,
  f : (@comp.GlobalTransformGpuMutRow) -> Unit,
) -> Bool {
  let component = self.world.global_transform_component_id
  ignore(
    self.component_payload_index(
      component, "QueryRow::write_global_transform_tracked",
    ),
  )
  self.world.assert_system_component_write(
    component, "QueryRow::write_global_transform_tracked",
  )
  let format = match self.world.global_transform_ref(self.entity) {
    Some(gt_ref) => gt_ref.format
    None => self.world.global_transform_default_format
  }
  let row_bytes = FixedArray::make(
    @comp.global_transform_word_count(format) * 4,
    (0 : Byte),
  )
  let current = match self.world.get_global_transform(self.entity) {
    Some(m) => m
    None => @m44.Matrix44F::identity()
  }
  @comp.matrix44f_write_global_transform_to_gpu_row(
    current,
    row_bytes.mut_view(start=0, end=row_bytes.length()),
    format,
  )
  f(
    @comp.GlobalTransformGpuMutRow::from_gpu_row_format(
      row_bytes.mut_view(start=0, end=row_bytes.length()),
      format,
    ),
  )
  let next = @comp.matrix44f_from_global_transform_gpu_bytes(row_bytes, format)
  history.set_global_transform(self.world, self.entity, next)
}

///|
/// Implements `RawQueryArchetype::length`.
pub fn RawQueryArchetype::length(self : RawQueryArchetype) -> Int {
  self.world.archetypes[self.archetype_index].entities.length()
}

///|
/// Implements `RawQueryArchetype::entity`.
pub fn RawQueryArchetype::entity(
  self : RawQueryArchetype,
  row : Int,
) -> EntityId {
  self.world.archetypes[self.archetype_index].entities[row]
}

///|
/// Implements `RawQueryArchetype::has`.
pub fn RawQueryArchetype::has(
  self : RawQueryArchetype,
  component : ComponentTypeId,
) -> Bool {
  self.component_access_index(component) >= 0
}

///|
/// Implements `RawQueryArchetype::component_stride`.
pub fn RawQueryArchetype::component_stride(
  self : RawQueryArchetype,
  component : ComponentTypeId,
) -> Int {
  let index = self.component_payload_index(
    component, "RawQueryArchetype::component_stride",
  )
  self.accesses[index].stride
}

///|
/// Implements `RawQueryArchetype::component_access_index`.
fn RawQueryArchetype::component_access_index(
  self : RawQueryArchetype,
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
/// Implements `RawQueryArchetype::component_payload_index`.
fn RawQueryArchetype::component_payload_index(
  self : RawQueryArchetype,
  component : ComponentTypeId,
  operation : String,
) -> Int {
  let index = self.component_access_index(component)
  if index < 0 {
    abort(
      operation +
      ": " +
      component_id_text(component) +
      " is not part of this RawQueryArchetype.",
    )
  }
  index
}

///|
/// Returns the contiguous CPU SoA column for `component`.
pub fn RawQueryArchetype::read_column(
  self : RawQueryArchetype,
  component : ComponentTypeId,
) -> ArrayView[Byte] {
  self.world.assert_system_component_read(
    component, "RawQueryArchetype::read_column",
  )
  let access_index = self.component_payload_index(
    component, "RawQueryArchetype::read_column",
  )
  let access = self.accesses[access_index]
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let logical_end = arch.entities.length() * col.stride
  col.bytes[0:logical_end]
}

///|
/// Returns the contiguous mutable CPU SoA column for `component`.
pub fn RawQueryArchetype::write_column(
  self : RawQueryArchetype,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  self.world.assert_not_history_raw_mutation("RawQueryArchetype::write_column")
  self.world.assert_system_component_write(
    component, "RawQueryArchetype::write_column",
  )
  let access_index = self.component_payload_index(
    component, "RawQueryArchetype::write_column",
  )
  let access = self.accesses[access_index]
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let logical_end = arch.entities.length() * col.stride
  col.bytes.mut_view(start=0, end=logical_end)
}

///|
/// Runs `f` with a mutable column view and records changed rows through `history`.
///
/// When history recording is disabled, this delegates to `RawQueryArchetype::write_column`
/// without copying before/after bytes.
pub fn RawQueryArchetype::write_column_tracked(
  self : RawQueryArchetype,
  history : WorldHistory,
  component : ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  let access_index = self.component_payload_index(
    component, "RawQueryArchetype::write_column_tracked",
  )
  if !history.recording_enabled() || history.applying {
    f(self.write_column(component))
    let reason = if !history.recording_enabled() {
      "recording_disabled"
    } else {
      "applying"
    }
    history.set_delegate_diagnostic(true, reason)
    return true
  }
  if self.world.history_blob_ref_component(component) {
    history.begin_tracked_world_mutation(self.world)
    f(self.write_column(component))
    history.end_tracked_world_mutation(self.world)
    history.set_delegate_diagnostic(true, history_diagnostic_none())
    return true
  }
  let access = self.accesses[access_index]
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let row_count = arch.entities.length()
  let logical_end = row_count * col.stride
  let before_column = copy_fixed_range_to_fixed(col.bytes, 0, logical_end)
  let auto = history.begin_auto("raw_query_archetype_write_column")
  history.begin_tracked_world_mutation(self.world)
  self.world.assert_system_component_write(
    component, "RawQueryArchetype::write_column_tracked",
  )
  f(col.bytes.mut_view(start=0, end=logical_end))
  history.end_tracked_world_mutation(self.world)
  for row = 0; row < row_count; row = row + 1 {
    let offset = row * col.stride
    if !fixed_ranges_equal(before_column, offset, col.bytes, offset, col.stride) {
      let before = copy_fixed_range_to_fixed(before_column, offset, col.stride)
      let after = copy_fixed_range_to_fixed(col.bytes, offset, col.stride)
      history.push_delta(
        ComponentChanged(arch.entities[row], component, before, after),
      )
    }
  }
  history.finish_auto(auto, true)
  true
}

///|
/// Returns whether every row index is valid for this archetype length.
fn raw_query_rows_valid(rows : Array[Int], row_count : Int) -> Bool {
  for i = 0; i < rows.length(); i = i + 1 {
    if rows[i] < 0 || rows[i] >= row_count {
      return false
    }
  }
  true
}

///|
/// Runs `f` with mutable row views for known changed rows and records those rows through `history`.
///
/// This is the sparse counterpart to `write_column_tracked`: callers provide the candidate row
/// indices up front, so unchanged rows outside that set are never snapshotted or scanned.
pub fn RawQueryArchetype::write_column_rows_tracked(
  self : RawQueryArchetype,
  history : WorldHistory,
  component : ComponentTypeId,
  rows : Array[Int],
  f : (Int, MutArrayView[Byte]) -> Unit,
) -> Bool {
  let access_index = self.component_payload_index(
    component, "RawQueryArchetype::write_column_rows_tracked",
  )
  let access = self.accesses[access_index]
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let row_count = arch.entities.length()
  if !raw_query_rows_valid(rows, row_count) {
    history.set_diagnostic("operation_failed")
    return false
  }
  if !history.recording_enabled() || history.applying {
    let column = self.write_column(component)
    for i = 0; i < rows.length(); i = i + 1 {
      let row = rows[i]
      let offset = row * col.stride
      f(row, column.mut_view(start=offset, end=offset + col.stride))
    }
    let reason = if !history.recording_enabled() {
      "recording_disabled"
    } else {
      "applying"
    }
    history.set_delegate_diagnostic(true, reason)
    return true
  }
  if self.world.history_blob_ref_component(component) {
    history.begin_tracked_world_mutation(self.world)
    let column = self.write_column(component)
    for i = 0; i < rows.length(); i = i + 1 {
      let row = rows[i]
      let offset = row * col.stride
      f(row, column.mut_view(start=offset, end=offset + col.stride))
    }
    history.end_tracked_world_mutation(self.world)
    history.set_delegate_diagnostic(true, history_diagnostic_none())
    return true
  }
  let auto = history.begin_auto("raw_query_archetype_write_column_rows")
  history.begin_tracked_world_mutation(self.world)
  self.world.assert_system_component_write(
    component, "RawQueryArchetype::write_column_rows_tracked",
  )
  for i = 0; i < rows.length(); i = i + 1 {
    let row = rows[i]
    let offset = row * col.stride
    let before = copy_fixed_range_to_fixed(col.bytes, offset, col.stride)
    f(row, col.bytes.mut_view(start=offset, end=offset + col.stride))
    let after = copy_fixed_range_to_fixed(col.bytes, offset, col.stride)
    if before != after {
      history.push_delta(
        ComponentChanged(arch.entities[row], component, before, after),
      )
    }
  }
  history.end_tracked_world_mutation(self.world)
  history.finish_auto(auto, true)
  true
}
