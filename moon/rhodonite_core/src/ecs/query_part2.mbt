/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Returns true after validating that `index` is a valid raw query payload slot.
pub fn RawQueryRow::has_at(self : RawQueryRow, index : Int) -> Bool {
  self.as_query_row().has_at(index)
}

///|
/// Returns the component id at `index` or aborts with an operation-specific message.
fn QueryRow::component_at_index(
  self : QueryRow,
  index : Int,
  operation : String,
) -> ComponentTypeId {
  if index < 0 || index >= self.components.length() {
    abort(
      operation +
      ": payload index " +
      index.to_string() +
      " is outside this QueryRow required component range.",
    )
  }
  self.components[index]
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
fn QueryRow::component_view_at(
  self : QueryRow,
  payload_index : Int,
  operation : String,
) -> ArrayView[Byte] {
  ignore(self.component_at_index(payload_index, operation))
  let access = self.accesses[payload_index]
  let col = self.world.archetypes[self.archetype_index].columns[access.column_index]
  let base = self.row * access.stride
  col.bytes[base:base + access.stride]
}

///|
/// Builds the requested read-only row view after resolving the component id.
fn QueryRow::component_view(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
) -> ArrayView[Byte] {
  self.component_view_at(
    self.component_payload_index(component, operation),
    operation,
  )
}

///|
/// Builds the requested mutable row view on demand.
fn QueryRow::component_mut_view_at(
  self : QueryRow,
  payload_index : Int,
  operation : String,
) -> MutArrayView[Byte] {
  ignore(self.component_at_index(payload_index, operation))
  let access = self.accesses[payload_index]
  let col = self.world.archetypes[self.archetype_index].columns[access.column_index]
  let base = self.row * access.stride
  col.bytes.mut_view(start=base, end=base + access.stride)
}

///|
/// Builds the requested mutable row view after resolving the component id.
fn QueryRow::component_mut_view(
  self : QueryRow,
  component : ComponentTypeId,
  operation : String,
) -> MutArrayView[Byte] {
  self.component_mut_view_at(
    self.component_payload_index(component, operation),
    operation,
  )
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
  f(
    self.component_view_at(
      self.component_payload_index(component, "QueryRow::read"),
      "QueryRow::read",
    ),
  )
}

///|
/// Runs `f` with a closure-scoped read-only payload view for a pre-resolved payload index.
pub fn QueryRow::read_at(
  self : QueryRow,
  index : Int,
  f : (ArrayView[Byte]) -> Unit,
) -> Unit {
  let component = self.component_at_index(index, "QueryRow::read_at")
  self.world.assert_system_component_read(component, "QueryRow::read_at")
  f(self.component_view_at(index, "QueryRow::read_at"))
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
  f(
    self.component_mut_view_at(
      self.component_payload_index(component, "QueryRow::write"),
      "QueryRow::write",
    ),
  )
  if self.world.component_is_transform_source(component) {
    self.world.mark_transform_dirty(self.entity)
  }
}

///|
/// Runs `f` with a closure-scoped mutable payload view for a pre-resolved payload index.
pub fn QueryRow::write_at(
  self : QueryRow,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  let component = self.component_at_index(index, "QueryRow::write_at")
  self.world.assert_not_history_raw_mutation("QueryRow::write_at")
  self.world.assert_system_component_write(component, "QueryRow::write_at")
  f(self.component_mut_view_at(index, "QueryRow::write_at"))
  if self.world.component_is_transform_source(component) {
    self.world.mark_transform_dirty(self.entity)
  }
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
  let index = self.component_payload_index(component, "QueryRow::write_tracked")
  self.write_tracked_at(history, index, f)
}

///|
/// Runs `f` with a mutable payload view for a pre-resolved index and records one component change.
pub fn QueryRow::write_tracked_at(
  self : QueryRow,
  history : WorldHistory,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  let component = self.component_at_index(index, "QueryRow::write_tracked_at")
  if !history.recording_enabled() || history.applying {
    self.write_at(index, f)
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
    self.write_at(index, f)
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
  self.world.assert_system_component_write(
    component, "QueryRow::write_tracked_at",
  )
  f(self.component_mut_view_at(index, "QueryRow::write_tracked_at"))
  history.end_tracked_world_mutation(self.world)
  let ok = match self.world.component_bytes(self.entity, component) {
    Some(after) => {
      history.push_delta(
        ComponentChanged(self.entity, component, before, after),
      )
      if before != after && self.world.component_is_transform_source(component) {
        self.world.mark_transform_dirty(self.entity)
      }
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
  let index = row.component_payload_index(component, "RawQueryRow::read_view")
  row.world.assert_system_component_read(component, "RawQueryRow::read_view")
  row.component_view_at(index, "RawQueryRow::read_view")
}

///|
/// Implements `RawQueryRow::read_view_at`.
pub fn RawQueryRow::read_view_at(
  self : RawQueryRow,
  index : Int,
) -> ArrayView[Byte] {
  let row = self.as_query_row()
  let component = row.component_at_index(index, "RawQueryRow::read_view_at")
  row.world.assert_system_component_read(component, "RawQueryRow::read_view_at")
  row.component_view_at(index, "RawQueryRow::read_view_at")
}

///|
/// Implements `RawQueryRow::write_view`.
pub fn RawQueryRow::write_view(
  self : RawQueryRow,
  component : ComponentTypeId,
) -> MutArrayView[Byte] {
  let row = self.as_query_row()
  let index = row.component_payload_index(component, "RawQueryRow::write_view")
  row.world.assert_not_history_raw_mutation("RawQueryRow::write_view")
  row.world.assert_system_component_write(component, "RawQueryRow::write_view")
  if row.world.component_is_transform_source(component) {
    row.world.mark_transform_dirty(row.entity)
  }
  row.component_mut_view_at(index, "RawQueryRow::write_view")
}

///|
/// Implements `RawQueryRow::write_view_at`.
pub fn RawQueryRow::write_view_at(
  self : RawQueryRow,
  index : Int,
) -> MutArrayView[Byte] {
  let row = self.as_query_row()
  let component = row.component_at_index(index, "RawQueryRow::write_view_at")
  row.world.assert_not_history_raw_mutation("RawQueryRow::write_view_at")
  row.world.assert_system_component_write(
    component, "RawQueryRow::write_view_at",
  )
  if row.world.component_is_transform_source(component) {
    row.world.mark_transform_dirty(row.entity)
  }
  row.component_mut_view_at(index, "RawQueryRow::write_view_at")
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
/// Runs `f` with a mutable payload view for a pre-resolved index and records one component change.
pub fn RawQueryRow::write_tracked_at(
  self : RawQueryRow,
  history : WorldHistory,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  self.as_query_row().write_tracked_at(history, index, f)
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
  self.world.mark_transform_dirty(self.entity)
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
  self.world.mark_transform_dirty(self.entity)
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
/// Returns true after validating that `index` is a valid archetype payload slot.
pub fn RawQueryArchetype::has_at(self : RawQueryArchetype, index : Int) -> Bool {
  ignore(self.access_at_index(index, "RawQueryArchetype::has_at"))
  true
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
/// Implements `RawQueryArchetype::component_stride_at`.
pub fn RawQueryArchetype::component_stride_at(
  self : RawQueryArchetype,
  index : Int,
) -> Int {
  self.access_at_index(index, "RawQueryArchetype::component_stride_at").stride
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
/// Returns the component access at `index` or aborts with an operation-specific message.
fn RawQueryArchetype::access_at_index(
  self : RawQueryArchetype,
  index : Int,
  operation : String,
) -> QueryArchetypeComponentAccess {
  if index < 0 || index >= self.accesses.length() {
    abort(
      operation +
      ": payload index " +
      index.to_string() +
      " is outside this RawQueryArchetype required component range.",
    )
  }
  self.accesses[index]
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
  self.read_column_at(access_index)
}

///|
/// Returns the contiguous CPU SoA column for a pre-resolved payload index.
pub fn RawQueryArchetype::read_column_at(
  self : RawQueryArchetype,
  index : Int,
) -> ArrayView[Byte] {
  let access = self.access_at_index(index, "RawQueryArchetype::read_column_at")
  self.world.assert_system_component_read(
    access.component,
    "RawQueryArchetype::read_column_at",
  )
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
  self.write_column_at(access_index)
}

///|
/// Returns the contiguous mutable CPU SoA column for a pre-resolved payload index.
pub fn RawQueryArchetype::write_column_at(
  self : RawQueryArchetype,
  index : Int,
) -> MutArrayView[Byte] {
  let access = self.access_at_index(index, "RawQueryArchetype::write_column_at")
  self.world.assert_not_history_raw_mutation(
    "RawQueryArchetype::write_column_at",
  )
  self.world.assert_system_component_write(
    access.component,
    "RawQueryArchetype::write_column_at",
  )
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let logical_end = arch.entities.length() * col.stride
  self.world.mark_transform_dirty_archetype(
    self.archetype_index,
    access.component,
  )
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
  self.write_column_tracked_at(history, access_index, f)
}

///|
/// Runs `f` with a mutable column view for a pre-resolved index and records changed rows.
pub fn RawQueryArchetype::write_column_tracked_at(
  self : RawQueryArchetype,
  history : WorldHistory,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  let access = self.access_at_index(
    index, "RawQueryArchetype::write_column_tracked_at",
  )
  let component = access.component
  if !history.recording_enabled() || history.applying {
    f(self.write_column_at(index))
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
    f(self.write_column_at(index))
    history.end_tracked_world_mutation(self.world)
    history.set_delegate_diagnostic(true, history_diagnostic_none())
    return true
  }
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let row_count = arch.entities.length()
  let logical_end = row_count * col.stride
  let before_column = copy_fixed_range_to_fixed(col.bytes, 0, logical_end)
  let auto = history.begin_auto("raw_query_archetype_write_column")
  history.begin_tracked_world_mutation(self.world)
  self.world.assert_system_component_write(
    component, "RawQueryArchetype::write_column_tracked_at",
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
      if self.world.component_is_transform_source(component) {
        self.world.mark_transform_dirty(arch.entities[row])
      }
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
  self.write_column_rows_tracked_at(history, access_index, rows, f)
}

///|
/// Runs `f` with mutable row views for known changed rows using a pre-resolved payload index.
pub fn RawQueryArchetype::write_column_rows_tracked_at(
  self : RawQueryArchetype,
  history : WorldHistory,
  index : Int,
  rows : Array[Int],
  f : (Int, MutArrayView[Byte]) -> Unit,
) -> Bool {
  let access = self.access_at_index(
    index, "RawQueryArchetype::write_column_rows_tracked_at",
  )
  let component = access.component
  let arch = self.world.archetypes[self.archetype_index]
  let col = arch.columns[access.column_index]
  let row_count = arch.entities.length()
  if !raw_query_rows_valid(rows, row_count) {
    history.set_diagnostic("operation_failed")
    return false
  }
  self.world.mark_transform_dirty_archetype_rows(
    self.archetype_index,
    component,
    rows,
  )
  if !history.recording_enabled() || history.applying {
    let column = self.write_column_at(index)
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
    let column = self.write_column_at(index)
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
    component, "RawQueryArchetype::write_column_rows_tracked_at",
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
      if self.world.component_is_transform_source(component) {
        self.world.mark_transform_dirty(arch.entities[row])
      }
    }
  }
  history.end_tracked_world_mutation(self.world)
  history.finish_auto(auto, true)
  true
}
