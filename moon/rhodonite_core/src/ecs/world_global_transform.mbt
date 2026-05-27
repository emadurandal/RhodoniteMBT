/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `World::global_transform_ref_from_bytes`.
fn World::global_transform_ref_from_bytes(
  self : World,
  bytes : FixedArray[Byte],
) -> GlobalTransformRef {
  ignore(self)
  let (format, word_offset) = @comp.global_transform_ref_from_component_bytes(
    bytes,
  )
  { format, word_offset }
}

///|
/// Implements `World::global_transform_ref_unchecked`.
fn World::global_transform_ref_unchecked(
  self : World,
  entity : EntityId,
) -> GlobalTransformRef? {
  let id = self.global_transform_component_id
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  if !component_array_contains(
      self.archetypes[loc.archetype_index].components,
      id,
    ) {
    return None
  }
  match self.archetypes[loc.archetype_index].component_bytes(loc.row, id) {
    Some(bytes) => Some(self.global_transform_ref_from_bytes(bytes))
    None => None
  }
}

///|
/// Implements `World::global_transform_ref`.
pub fn World::global_transform_ref(
  self : World,
  entity : EntityId,
) -> GlobalTransformRef? {
  let id = self.global_transform_component_id
  self.assert_system_component_read(id, "World::global_transform_ref")
  self.global_transform_ref_unchecked(entity)
}

///|
/// Implements `World::alloc_global_transform_ref`.
fn World::alloc_global_transform_ref(
  self : World,
  format : @comp.GlobalTransformGpuFormat,
  matrix : @m44.Matrix44F,
) -> GlobalTransformRef {
  let word_offset = self.global_transform_blob.alloc(format)
  self.global_transform_blob.write_matrix(format, word_offset, matrix)
  { format, word_offset }
}

///|
/// Implements `World::write_global_transform_ref_component`.
fn World::write_global_transform_ref_component(
  self : World,
  entity : EntityId,
  gt_ref : GlobalTransformRef,
) -> Bool {
  self.set_component_bytes(
    entity,
    self.global_transform_component_id,
    @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset),
  )
}

///|
/// Implements `World::release_global_transform_ref`.
fn World::release_global_transform_ref(self : World, entity : EntityId) -> Unit {
  match self.global_transform_ref_unchecked(entity) {
    Some(gt_ref) =>
      self.global_transform_blob.free(gt_ref.format, gt_ref.word_offset)
    None => ()
  }
}

///|
/// Assigns builtin [`GlobalTransform`] for `entity`; payload is stored in the packed u32 blob.
pub fn World::set_global_transform(
  self : World,
  entity : EntityId,
  m : @m44.Matrix44F,
) -> Bool {
  self.assert_not_history_raw_mutation("World::set_global_transform")
  let id = self.global_transform_component_id
  self.assert_system_component_write(id, "World::set_global_transform")
  match self.global_transform_ref_unchecked(entity) {
    Some(gt_ref) => {
      ignore(
        self.global_transform_blob.write_matrix_if_changed(
          gt_ref.format,
          gt_ref.word_offset,
          m,
        ),
      )
      true
    }
    None => {
      if !self.is_alive(entity) ||
        !self.can_add_missing_component_from_setter(
          id, "World::set_global_transform",
        ) {
        return false
      }
      let gt_ref = self.alloc_global_transform_ref(
        self.global_transform_default_format,
        m,
      )
      self.add_component_bytes(
        entity,
        id,
        @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset),
      )
    }
  }
}

///|
/// Implements `World::set_global_transform_format`.
pub fn World::set_global_transform_format(
  self : World,
  entity : EntityId,
  format : @comp.GlobalTransformGpuFormat,
) -> Bool {
  self.assert_not_history_raw_mutation("World::set_global_transform_format")
  let id = self.global_transform_component_id
  self.assert_system_component_write(id, "World::set_global_transform_format")
  if !self.is_alive(entity) {
    return false
  }
  let (had_component, matrix) = match self.global_transform_ref(entity) {
    Some(old_ref) => {
      if old_ref.format == format {
        return true
      }
      let matrix = match
        self.global_transform_blob.read_matrix(
          old_ref.format,
          old_ref.word_offset,
        ) {
        Some(m) => m
        None => return false
      }
      self.global_transform_blob.free(old_ref.format, old_ref.word_offset)
      (true, matrix)
    }
    None => {
      if !self.can_add_missing_component_from_setter(
          id, "World::set_global_transform_format",
        ) {
        return false
      }
      (false, @m44.Matrix44F::identity())
    }
  }
  let new_ref = self.alloc_global_transform_ref(format, matrix)
  if had_component {
    self.write_global_transform_ref_component(entity, new_ref)
  } else {
    self.add_component_bytes(
      entity,
      id,
      @comp.global_transform_ref_bytes(new_ref.format, new_ref.word_offset),
    )
  }
}

///|
/// Implements `World::get_global_transform`.
pub fn World::get_global_transform(
  self : World,
  entity : EntityId,
) -> @m44.Matrix44F? {
  let id = self.global_transform_component_id
  self.assert_system_component_read(id, "World::get_global_transform")
  if !self.is_alive(entity) || !self.has_component(entity, id) {
    return None
  }
  match self.global_transform_ref(entity) {
    Some(gt_ref) =>
      self.global_transform_blob.read_matrix(gt_ref.format, gt_ref.word_offset)
    None => None
  }
}

///|
/// Implements `World::drain_global_transform_blob_write_views`.
pub fn World::drain_global_transform_blob_write_views(
  self : World,
) -> Array[GpuWriteView] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::drain_global_transform_blob_write_views",
  )
  self.global_transform_blob.drain_write_views()
}

///|
/// Reports whether the GlobalTransform packed blob has queued GPU write views.
pub fn World::has_global_transform_blob_write_views(self : World) -> Bool {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::has_global_transform_blob_write_views",
  )
  self.global_transform_blob.has_write_views()
}

///|
/// Implements `World::write_global_transform_blob_range_views`.
pub fn World::write_global_transform_blob_range_views(
  self : World,
  first_word : Int,
  word_count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    gt, "World::write_global_transform_blob_range_views",
  )
  self.global_transform_blob.write_word_range_views(
    first_word, word_count, write,
  )
}

///|
/// Implements `World::drain_global_transform_blob_resize_events`.
pub fn World::drain_global_transform_blob_resize_events(
  self : World,
) -> Array[GlobalTransformBlobResizeEvent] {
  self.assert_system_structural_write(
    "World::drain_global_transform_blob_resize_events",
  )
  self.global_transform_blob.drain_resize_events()
}

///|
/// Implements `World::global_transform_blob_word_capacity`.
pub fn World::global_transform_blob_word_capacity(self : World) -> Int {
  self.global_transform_blob.word_capacity()
}

///|
/// Implements `World::extract_global_transform_refs`.
pub fn World::extract_global_transform_refs(
  self : World,
  entities : Array[EntityId],
) -> FixedArray[Byte] {
  let stride = 8
  let out = FixedArray::make(entities.length() * stride, (0 : Byte))
  for i = 0; i < entities.length(); i = i + 1 {
    match self.global_transform_ref(entities[i]) {
      Some(gt_ref) => {
        @writes.put_u32_le(
          out,
          i * stride,
          @comp.global_transform_format_code(gt_ref.format),
        )
        @writes.put_u32_le(
          out,
          i * stride + 4,
          gt_ref.word_offset.reinterpret_as_uint(),
        )
      }
      None => ()
    }
  }
  out
}

///|
/// Implements `World::write_global_transform_refs_into`.
pub fn World::write_global_transform_refs_into(
  self : World,
  entities : Array[EntityId],
  dst : FixedArray[Byte],
  stride : Int,
  offset : Int,
) -> Unit {
  if stride < offset + 8 {
    abort("World::write_global_transform_refs_into: stride too small")
  }
  if dst.length() < entities.length() * stride {
    abort("World::write_global_transform_refs_into: dst too small")
  }
  for i = 0; i < entities.length(); i = i + 1 {
    match self.global_transform_ref(entities[i]) {
      Some(gt_ref) => {
        @writes.put_u32_le(
          dst,
          i * stride + offset,
          @comp.global_transform_format_code(gt_ref.format),
        )
        @writes.put_u32_le(
          dst,
          i * stride + offset + 4,
          gt_ref.word_offset.reinterpret_as_uint(),
        )
      }
      None => ()
    }
  }
}

///|
/// Extends transform dirty generation storage so `entity.index` can be addressed.
fn World::ensure_transform_dirty_capacity(
  self : World,
  entity : EntityId,
) -> Unit {
  while self.transform_dirty_generations.length() <= entity.index {
    self.transform_dirty_generations.push(-1)
  }
}

///|
/// Returns whether `entity` is currently queued for dirty transform propagation.
fn World::transform_entity_is_dirty(self : World, entity : EntityId) -> Bool {
  entity.index >= 0 &&
  entity.index < self.transform_dirty_generations.length() &&
  self.transform_dirty_generations[entity.index] == entity.generation
}

///|
/// Marks an entity as needing GlobalTransform recomputation on the next dirty propagation pass.
fn World::mark_transform_dirty(self : World, entity : EntityId) -> Unit {
  if entity.index < 0 {
    return
  }
  self.ensure_transform_dirty_capacity(entity)
  if self.transform_dirty_generations[entity.index] != entity.generation {
    self.transform_dirty_generations[entity.index] = entity.generation
    self.transform_dirty_entities.push(entity)
  }
}

///|
/// Marks the cached transform hierarchy index stale after [`ChildOf`] relationship changes.
fn World::invalidate_transform_hierarchy_index(self : World) -> Unit {
  self.transform_hierarchy_index_dirty = true
}

///|
/// Invalidates hierarchy cache when `component` owns [`ChildOf`] payload.
fn World::invalidate_transform_hierarchy_index_for_component(
  self : World,
  component : ComponentTypeId,
) -> Unit {
  if component == self.child_of_component_id {
    self.invalidate_transform_hierarchy_index()
  }
}

///|
/// Marks a changed transform source component and invalidates hierarchy cache for [`ChildOf`].
fn World::mark_transform_source_dirty(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  if self.component_is_transform_source(component) {
    self.invalidate_transform_hierarchy_index_for_component(component)
    self.mark_transform_dirty(entity)
  }
}

///|
/// Returns true when a component payload change affects transform propagation inputs or eligibility.
fn World::component_affects_transform_propagation(
  self : World,
  component : ComponentTypeId,
) -> Bool {
  component == self.transform_component_id ||
  component == self.child_of_component_id ||
  component == self.global_transform_component_id
}

///|
/// Returns true when a component payload directly changes transform propagation source data.
fn World::component_is_transform_source(
  self : World,
  component : ComponentTypeId,
) -> Bool {
  component == self.transform_component_id ||
  component == self.child_of_component_id
}

///|
/// Marks `entity` dirty when `component` changes transform propagation state.
fn World::mark_transform_dirty_for_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Unit {
  self.invalidate_transform_hierarchy_index_for_component(component)
  if self.component_affects_transform_propagation(component) {
    self.mark_transform_dirty(entity)
  }
}

///|
/// Marks every entity in an archetype dirty when a source transform column is exposed for mutation.
fn World::mark_transform_dirty_archetype(
  self : World,
  archetype_index : Int,
  component : ComponentTypeId,
) -> Unit {
  if !self.component_is_transform_source(component) {
    return
  }
  self.invalidate_transform_hierarchy_index_for_component(component)
  let arch = self.archetypes[archetype_index]
  for row = 0; row < arch.entities.length(); row = row + 1 {
    self.mark_transform_dirty(arch.entities[row])
  }
}

///|
/// Marks selected rows in an archetype dirty for sparse source transform column mutation.
fn World::mark_transform_dirty_archetype_rows(
  self : World,
  archetype_index : Int,
  component : ComponentTypeId,
  rows : Array[Int],
) -> Unit {
  if !self.component_is_transform_source(component) {
    return
  }
  self.invalidate_transform_hierarchy_index_for_component(component)
  let arch = self.archetypes[archetype_index]
  for i = 0; i < rows.length(); i = i + 1 {
    let row = rows[i]
    if row >= 0 && row < arch.entities.length() {
      self.mark_transform_dirty(arch.entities[row])
    }
  }
}

///|
/// Clears all queued transform dirty generation stamps.
fn World::clear_transform_dirty(self : World) -> Unit {
  for i = 0; i < self.transform_dirty_entities.length(); i = i + 1 {
    let entity = self.transform_dirty_entities[i]
    if entity.index >= 0 &&
      entity.index < self.transform_dirty_generations.length() &&
      self.transform_dirty_generations[entity.index] == entity.generation {
      self.transform_dirty_generations[entity.index] = -1
    }
  }
  self.transform_dirty_entities.clear()
}

///|
/// Ensures the hierarchy index can store children for `parent_index`.
fn World::ensure_transform_children_parent_capacity(
  self : World,
  parent_index : Int,
) -> Unit {
  while self.transform_children_by_parent_index.length() <= parent_index {
    let children : Array[EntityId] = []
    self.transform_children_by_parent_index.push(children)
  }
}

///|
/// Rebuilds cached `parent.index -> children` transform hierarchy buckets from current [`ChildOf`] rows.
fn World::rebuild_transform_hierarchy_index(self : World) -> Unit {
  for i = 0; i < self.transform_children_by_parent_index.length(); i = i + 1 {
    self.transform_children_by_parent_index[i].clear()
  }
  while self.transform_children_by_parent_index.length() <
        self.generations.length() {
    let children : Array[EntityId] = []
    self.transform_children_by_parent_index.push(children)
  }
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    if arch.column_index(self.child_of_component_id) < 0 {
      continue
    }
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let child = arch.entities[row]
      match self.child_of_parent_direct(child) {
        Some(parent) =>
          if parent.index >= 0 && parent.index < self.generations.length() {
            self.ensure_transform_children_parent_capacity(parent.index)
            self.transform_children_by_parent_index[parent.index].push(child)
          }
        None => ()
      }
    }
  }
  self.transform_hierarchy_index_dirty = false
}

///|
/// Rebuilds the transform hierarchy index if any [`ChildOf`] ownership or payload changed.
fn World::ensure_transform_hierarchy_index(self : World) -> Unit {
  if self.transform_hierarchy_index_dirty {
    self.rebuild_transform_hierarchy_index()
  }
}

///|
/// Returns true if `entity` has already been visited in this dirty propagation pass.
fn transform_processed_contains(
  processed_generations : FixedArray[Int],
  entity : EntityId,
) -> Bool {
  entity.index >= 0 &&
  entity.index < processed_generations.length() &&
  processed_generations[entity.index] == entity.generation
}

///|
/// Marks `entity` visited in this dirty propagation pass.
fn transform_processed_mark(
  processed_generations : FixedArray[Int],
  entity : EntityId,
) -> Unit {
  if entity.index >= 0 && entity.index < processed_generations.length() {
    processed_generations[entity.index] = entity.generation
  }
}

///|
/// Builds a public immutable transform propagation report from a mutable accumulator.
fn TransformPropagationReportDraft::finish(
  self : TransformPropagationReportDraft,
) -> TransformPropagationReport {
  {
    ok: self.ok,
    used_dirty_path: self.used_dirty_path,
    used_full_path: self.used_full_path,
    fallback_to_full: self.fallback_to_full,
    dirty_queue_count: self.dirty_queue_count,
    dirty_root_count: self.dirty_root_count,
    skipped_dirty_entity_count: self.skipped_dirty_entity_count,
    visited_entity_count: self.visited_entity_count,
    global_transform_write_count: self.global_transform_write_count,
    hierarchy_index_rebuilt: self.hierarchy_index_rebuilt,
    pending_upload_range_count: self.pending_upload_range_count,
    failure_reason: self.failure_reason,
    failure_count: self.failure_count,
    broken_ancestor_chain_count: self.broken_ancestor_chain_count,
    missing_global_transform_ref_count: self.missing_global_transform_ref_count,
    archetype_path_unavailable_count: self.archetype_path_unavailable_count,
  }
}

///|
/// Records one transform propagation failure while preserving the first failure reason.
/// `NoFailure` is ignored so diagnostic counters stay internally consistent.
fn TransformPropagationReportDraft::record_failure(
  self : TransformPropagationReportDraft,
  reason : TransformPropagationFailureReason,
) -> Unit {
  if reason is NoFailure {
    return
  }
  if self.failure_count == 0 {
    self.failure_reason = reason
  }
  self.failure_count = self.failure_count + 1
  self.ok = false
  match reason {
    BrokenAncestorChain =>
      self.broken_ancestor_chain_count = self.broken_ancestor_chain_count + 1
    MissingGlobalTransformRef =>
      self.missing_global_transform_ref_count = self.missing_global_transform_ref_count +
        1
    ArchetypePathUnavailable =>
      self.archetype_path_unavailable_count = self.archetype_path_unavailable_count +
        1
    NoFailure => ()
  }
}

///|
/// Creates an empty transform propagation diagnostic accumulator.
fn transform_propagation_report_draft(
  dirty_queue_count : Int,
) -> TransformPropagationReportDraft {
  {
    ok: true,
    used_dirty_path: false,
    used_full_path: false,
    fallback_to_full: false,
    dirty_queue_count,
    dirty_root_count: 0,
    skipped_dirty_entity_count: 0,
    visited_entity_count: 0,
    global_transform_write_count: 0,
    hierarchy_index_rebuilt: false,
    pending_upload_range_count: 0,
    failure_reason: NoFailure,
    failure_count: 0,
    broken_ancestor_chain_count: 0,
    missing_global_transform_ref_count: 0,
    archetype_path_unavailable_count: 0,
  }
}

///|
/// Writes `matrix` into `entity`'s GlobalTransform blob slot when present.
fn World::write_global_transform_matrix_if_present(
  self : World,
  entity : EntityId,
  matrix : @m44.Matrix44F,
) -> Bool {
  match self.global_transform_ref(entity) {
    Some(gt_ref) => {
      ignore(
        self.global_transform_blob.write_matrix_if_changed(
          gt_ref.format,
          gt_ref.word_offset,
          matrix,
        ),
      )
      true
    }
    None => true
  }
}

///|
/// Writes `matrix` into `entity`'s GlobalTransform blob slot and reports whether bytes changed.
fn World::write_global_transform_matrix_if_present_report(
  self : World,
  entity : EntityId,
  matrix : @m44.Matrix44F,
) -> (Bool, Bool) {
  match self.global_transform_ref(entity) {
    Some(gt_ref) => {
      let changed = self.global_transform_blob.write_matrix_if_changed(
        gt_ref.format,
        gt_ref.word_offset,
        matrix,
      )
      (true, changed)
    }
    None => (true, false)
  }
}

///|
/// Recomputes a dirty subtree using parent-first matrix propagation.
fn World::recompute_transform_dirty_subtree(
  self : World,
  root : EntityId,
  root_world_matrix : @m44.Matrix44F,
  processed_generations : FixedArray[Int],
) -> Bool {
  let tf = self.transform_component_id
  let mut ok = true
  let stack_entities : Array[EntityId] = [root]
  let stack_matrices : Array[@m44.Matrix44F] = [root_world_matrix]
  while stack_entities.length() > 0 {
    let last = stack_entities.length() - 1
    let entity = stack_entities[last]
    let world_matrix = stack_matrices[last]
    ignore(stack_entities.pop())
    ignore(stack_matrices.pop())
    if !self.is_alive(entity) ||
      transform_processed_contains(processed_generations, entity) {
      continue
    }
    transform_processed_mark(processed_generations, entity)
    if !self.has_component(entity, tf) {
      continue
    }
    if !self.write_global_transform_matrix_if_present(entity, world_matrix) {
      ok = false
    }
    if entity.index < 0 ||
      entity.index >= self.transform_children_by_parent_index.length() {
      continue
    }
    let children = self.transform_children_by_parent_index[entity.index]
    for i = 0; i < children.length(); i = i + 1 {
      let child = children[i]
      if !self.is_alive(child) ||
        transform_processed_contains(processed_generations, child) {
        continue
      }
      match self.child_of_parent_direct(child) {
        Some(parent) =>
          if parent == entity && self.has_component(child, tf) {
            match self.get_transform(child) {
              Some(local_tf) => {
                stack_entities.push(child)
                stack_matrices.push(
                  world_matrix.mat_mul(local_tf.to_local_matrix()),
                )
              }
              None => ()
            }
          }
        None => ()
      }
    }
  }
  ok
}

///|
/// Recomputes a dirty subtree and accumulates diagnostic counters.
fn World::recompute_transform_dirty_subtree_report(
  self : World,
  root : EntityId,
  root_world_matrix : @m44.Matrix44F,
  processed_generations : FixedArray[Int],
  report : TransformPropagationReportDraft,
) -> Bool {
  let tf = self.transform_component_id
  let mut ok = true
  let stack_entities : Array[EntityId] = [root]
  let stack_matrices : Array[@m44.Matrix44F] = [root_world_matrix]
  while stack_entities.length() > 0 {
    let last = stack_entities.length() - 1
    let entity = stack_entities[last]
    let world_matrix = stack_matrices[last]
    ignore(stack_entities.pop())
    ignore(stack_matrices.pop())
    if !self.is_alive(entity) ||
      transform_processed_contains(processed_generations, entity) {
      continue
    }
    transform_processed_mark(processed_generations, entity)
    if !self.has_component(entity, tf) {
      continue
    }
    report.visited_entity_count = report.visited_entity_count + 1
    let (write_ok, changed) = self.write_global_transform_matrix_if_present_report(
      entity, world_matrix,
    )
    if !write_ok {
      ok = false
    }
    if changed {
      report.global_transform_write_count = report.global_transform_write_count +
        1
    }
    if entity.index < 0 ||
      entity.index >= self.transform_children_by_parent_index.length() {
      continue
    }
    let children = self.transform_children_by_parent_index[entity.index]
    for i = 0; i < children.length(); i = i + 1 {
      let child = children[i]
      if !self.is_alive(child) ||
        transform_processed_contains(processed_generations, child) {
        continue
      }
      match self.child_of_parent_direct(child) {
        Some(parent) =>
          if parent == entity && self.has_component(child, tf) {
            match self.get_transform(child) {
              Some(local_tf) => {
                stack_entities.push(child)
                stack_matrices.push(
                  world_matrix.mat_mul(local_tf.to_local_matrix()),
                )
              }
              None => ()
            }
          }
        None => ()
      }
    }
  }
  ok
}

///|
/// Removed dense row API. Use blob refs plus `drain_global_transform_blob_write_views`.
pub fn World::write_global_transforms_dense(
  self : World,
  count : Int,
  write : (Int, MutArrayView[Byte]) -> Unit,
) -> Array[GpuWrite] {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Bulk-writes dense GlobalTransform rows `[0, count)` and returns borrowed upload ranges.
pub fn World::write_global_transforms_dense_views(
  self : World,
  count : Int,
  write : (Int, MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense_views: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Removed dense row API. Use blob refs plus `drain_global_transform_blob_write_views`.
pub fn World::write_global_transforms_dense_range_views(
  self : World,
  count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense_range_views: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Bulk-writes dense GlobalTransform rows into the raw wasm backing store.
///
/// This non-GC wasm fast path lets a host upload the same linear-memory buffer
/// returned by `global_transform_wasm_gpu_bytes_payload_ptr`, avoiding both
/// `MutArrayView` wrapper traffic and host-side transform recomputation. It is
/// intended for immediate full-buffer host upload and does not enqueue drain
/// ranges.

///|
/// Implements `World::write_global_transforms_dense_wasm_bytes_range`.
#cfg(target="wasm")
pub fn World::write_global_transforms_dense_wasm_bytes_range(
  self : World,
  count : Int,
  write : (FixedArray[Byte], Int, Int) -> Unit,
) -> Bool {
  ignore(self)
  ignore(count)
  ignore(write)
  abort(
    "World::write_global_transforms_dense_wasm_bytes_range: removed; use packed GlobalTransform blob APIs",
  )
}

///|
/// Returns the linear-memory payload pointer for the builtin GlobalTransform GPU store.
///
/// This is only available on the non-GC wasm backend, where JavaScript can create
/// a `Uint8Array` view over the exported wasm memory and upload the ECS GPU store
/// without recomputing the transform data on the host side. The pointer is valid
/// until the GlobalTransform GPU store grows and reallocates.

///|
/// Implements `World::global_transform_wasm_gpu_bytes_payload_ptr`.
#cfg(target="wasm")
pub fn World::global_transform_wasm_gpu_bytes_payload_ptr(self : World) -> Int {
  ignore(self)
  0
}

///|
/// Returns the byte length of the builtin GlobalTransform GPU store payload.

///|
/// Implements `World::global_transform_wasm_gpu_bytes_len`.
#cfg(target="wasm")
pub fn World::global_transform_wasm_gpu_bytes_len(self : World) -> Int {
  ignore(self)
  0
}

///|
/// `leaf_local_matrix`: when [`Some`], used for `leaf` instead of [`get_transform`] (TF+GT bulk row path).
fn World::multiply_world_chain_matrix(
  self : World,
  leaf : EntityId,
  chain : Array[EntityId],
  leaf_local_matrix : @m44.Matrix44F?,
) -> @m44.Matrix44F? {
  let mut world_m = @m44.Matrix44F::identity()
  let mut i = chain.length() - 1
  while i >= 0 {
    let e = chain[i]
    let local_m : @m44.Matrix44F = if e == leaf {
      match leaf_local_matrix {
        Some(m) => m
        None =>
          match self.get_transform(e) {
            Some(t) => t.to_local_matrix()
            None => return None
          }
      }
    } else {
      match self.get_transform(e) {
        Some(t) => t.to_local_matrix()
        None => return None
      }
    }
    world_m = world_m.mat_mul(local_m)
    i = i - 1
  }
  Some(world_m)
}

///|
/// Computes world-space matrix from [`Transform3D`] along [`ChildOf`] ancestors (root → entity).
/// Returns [`None`] when `entity` is dead, lacks [`Transform3D`], an ancestor lacks [`Transform3D`],
/// a [`ChildOf`] parent is not alive, or a parent cycle is detected.
pub fn World::compute_global_transform(
  self : World,
  entity : EntityId,
) -> @m44.Matrix44F? {
  self.assert_system_component_read(
    self.transform_component_id,
    "World::compute_global_transform",
  )
  self.assert_system_component_read(
    self.child_of_component_id,
    "World::compute_global_transform",
  )
  if !self.is_alive(entity) {
    return None
  }
  match self.locations[entity.index] {
    None => None
    Some(loc) => {
      let sig = self.archetypes[loc.archetype_index].components
      let tf_id = self.transform_component_id
      if !component_array_contains(sig, tf_id) {
        return None
      }
      let co_id = self.child_of_component_id
      if !component_array_contains(sig, co_id) {
        match self.get_transform(entity) {
          None => None
          Some(tf) => Some(tf.to_local_matrix())
        }
      } else {
        match self.build_child_of_ancestor_chain(entity) {
          None => None
          Some(chain) => self.multiply_world_chain_matrix(entity, chain, None)
        }
      }
    }
  }
}

///|
/// Used only by [`update_global_transforms_from_transforms`]: entity comes from a TF+GT query row and
/// `leaf_local_matrix` was decoded from that row's Transform SoA view (no [`get_transform`] on the leaf).
/// Writes the world matrix into the entity's packed GlobalTransform blob slot.
fn World::compute_global_transform_for_tf_gt_bulk_row(
  self : World,
  entity : EntityId,
  has_child_of : Bool,
  leaf_local_matrix : @m44.Matrix44F,
) -> Bool {
  let world_m = if !has_child_of {
    Some(leaf_local_matrix)
  } else {
    match self.build_child_of_ancestor_chain(entity) {
      None => None
      Some(chain) =>
        self.multiply_world_chain_matrix(entity, chain, Some(leaf_local_matrix))
    }
  }
  match world_m {
    Some(m) =>
      match self.global_transform_ref(entity) {
        Some(gt_ref) => {
          ignore(
            self.global_transform_blob.write_matrix_if_changed(
              gt_ref.format,
              gt_ref.word_offset,
              m,
            ),
          )
          true
        }
        None => false
      }
    None => false
  }
}

///|
/// Computes and writes one TF+GT bulk row while accumulating report counters.
fn World::compute_global_transform_for_tf_gt_bulk_row_report(
  self : World,
  entity : EntityId,
  has_child_of : Bool,
  leaf_local_matrix : @m44.Matrix44F,
  report : TransformPropagationReportDraft,
) -> Bool {
  let world_m = if !has_child_of {
    leaf_local_matrix
  } else {
    match self.build_child_of_ancestor_chain(entity) {
      None => {
        report.skipped_dirty_entity_count = report.skipped_dirty_entity_count +
          1
        report.record_failure(BrokenAncestorChain)
        return false
      }
      Some(chain) =>
        match
          self.multiply_world_chain_matrix(
            entity,
            chain,
            Some(leaf_local_matrix),
          ) {
          Some(matrix) => matrix
          None => {
            report.skipped_dirty_entity_count = report.skipped_dirty_entity_count +
              1
            report.record_failure(BrokenAncestorChain)
            return false
          }
        }
    }
  }
  match self.global_transform_ref(entity) {
    Some(gt_ref) => {
      report.visited_entity_count = report.visited_entity_count + 1
      if self.global_transform_blob.write_matrix_if_changed(
          gt_ref.format,
          gt_ref.word_offset,
          world_m,
        ) {
        report.global_transform_write_count = report.global_transform_write_count +
          1
      }
      true
    }
    None => {
      report.record_failure(MissingGlobalTransformRef)
      false
    }
  }
}

///|

///|
/// Implements `put_f32_array_le`.
#cfg(not(target="js"))
fn put_f32_array_le(bytes : FixedArray[Byte], off : Int, v : Float) -> Unit {
  let u = v.reinterpret_as_uint()
  bytes[off] = (u & 0xFFU).to_byte()
  bytes[off + 1] = ((u >> 8) & 0xFFU).to_byte()
  bytes[off + 2] = ((u >> 16) & 0xFFU).to_byte()
  bytes[off + 3] = ((u >> 24) & 0xFFU).to_byte()
}

///|
/// Fallback for transform propagation that walks archetypes directly and writes packed blob slots.
fn World::try_update_global_transforms_from_transforms_archetype_path(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
) -> Bool {
  let mut matched = false
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    matched = true
    let tf_col_index = arch.column_index(tf)
    if tf_col_index < 0 {
      return false
    }
    if arch.columns[tf_col_index].stride != 48 {
      return false
    }
  }
  if !matched {
    return false
  }
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    let has_co = component_array_contains(comps, co)
    let tf_col = arch.columns[arch.column_index(tf)]
    let tf_bytes = tf_col.bytes
    let tf_stride = tf_col.stride
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let e = arch.entities[row]
      let tf_base = row * tf_stride
      let local_m = @comp.Transform3D::local_matrix_from_component_view(
        tf_bytes[tf_base:tf_base + tf_stride],
      )
      ignore(
        self.compute_global_transform_for_tf_gt_bulk_row(e, has_co, local_m),
      )
    }
  }
  true
}

///|
/// Fallback full propagation path with diagnostics for every TF+GT row.
fn World::try_update_global_transforms_from_transforms_archetype_path_report(
  self : World,
  tf : ComponentTypeId,
  gt : ComponentTypeId,
  co : ComponentTypeId,
  report : TransformPropagationReportDraft,
) -> Bool {
  let mut matched = false
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    matched = true
    let tf_col_index = arch.column_index(tf)
    if tf_col_index < 0 {
      report.record_failure(ArchetypePathUnavailable)
      return false
    }
    if arch.columns[tf_col_index].stride != 48 {
      report.record_failure(ArchetypePathUnavailable)
      return false
    }
  }
  if !matched {
    report.record_failure(ArchetypePathUnavailable)
    return false
  }
  report.used_full_path = true
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let arch = self.archetypes[ai]
    let comps = arch.components
    if !component_array_contains(comps, tf) ||
      !component_array_contains(comps, gt) {
      continue
    }
    let has_co = component_array_contains(comps, co)
    let tf_col = arch.columns[arch.column_index(tf)]
    let tf_bytes = tf_col.bytes
    let tf_stride = tf_col.stride
    for row = 0; row < arch.entities.length(); row = row + 1 {
      let e = arch.entities[row]
      let tf_base = row * tf_stride
      let local_m = @comp.Transform3D::local_matrix_from_component_view(
        tf_bytes[tf_base:tf_base + tf_stride],
      )
      ignore(
        self.compute_global_transform_for_tf_gt_bulk_row_report(
          e, has_co, local_m, report,
        ),
      )
    }
  }
  true
}

///|
/// Recomputes packed GlobalTransform blob rows for entities marked dirty since the last pass.
fn World::update_global_transforms_from_transforms_dirty(self : World) -> Bool {
  if self.transform_dirty_entities.length() == 0 {
    return true
  }
  self.ensure_transform_hierarchy_index()
  let tf = self.transform_component_id
  let processed_generations = FixedArray::make(self.generations.length(), -1)
  let mut ok = true
  for i = 0; i < self.transform_dirty_entities.length(); i = i + 1 {
    let entity = self.transform_dirty_entities[i]
    if !self.transform_entity_is_dirty(entity) || !self.is_alive(entity) {
      continue
    }
    if transform_processed_contains(processed_generations, entity) ||
      !self.has_component(entity, tf) {
      continue
    }
    match self.compute_global_transform(entity) {
      Some(matrix) =>
        if !self.recompute_transform_dirty_subtree(
            entity, matrix, processed_generations,
          ) {
          ok = false
        }
      None => ()
    }
  }
  self.clear_transform_dirty()
  ok
}

///|
/// Recomputes dirty transform rows and accumulates diagnostic counters.
fn World::update_global_transforms_from_transforms_dirty_report(
  self : World,
  report : TransformPropagationReportDraft,
) -> Bool {
  if self.transform_dirty_entities.length() == 0 {
    return true
  }
  report.used_dirty_path = true
  if self.transform_hierarchy_index_dirty {
    report.hierarchy_index_rebuilt = true
  }
  self.ensure_transform_hierarchy_index()
  let tf = self.transform_component_id
  let processed_generations = FixedArray::make(self.generations.length(), -1)
  let mut ok = true
  for i = 0; i < self.transform_dirty_entities.length(); i = i + 1 {
    let entity = self.transform_dirty_entities[i]
    if !self.transform_entity_is_dirty(entity) || !self.is_alive(entity) {
      report.skipped_dirty_entity_count = report.skipped_dirty_entity_count + 1
      continue
    }
    if transform_processed_contains(processed_generations, entity) ||
      !self.has_component(entity, tf) {
      report.skipped_dirty_entity_count = report.skipped_dirty_entity_count + 1
      continue
    }
    match self.compute_global_transform(entity) {
      Some(matrix) => {
        report.dirty_root_count = report.dirty_root_count + 1
        if !self.recompute_transform_dirty_subtree_report(
            entity, matrix, processed_generations, report,
          ) {
          ok = false
        }
      }
      None => {
        report.skipped_dirty_entity_count = report.skipped_dirty_entity_count +
          1
        report.record_failure(BrokenAncestorChain)
      }
    }
  }
  self.clear_transform_dirty()
  ok
}

///|
/// Recomputes [`GlobalTransform`] GPU payloads from [`Transform3D`] (and optional [`ChildOf`] hierarchy)
/// for every entity that currently has **both** builtin transforms.
pub fn World::update_global_transforms_from_transforms(self : World) -> Unit {
  let tf = self.transform_component_id
  let gt = self.global_transform_component_id
  let co = self.child_of_component_id
  self.assert_system_component_read(
    tf, "World::update_global_transforms_from_transforms",
  )
  self.assert_system_component_read(
    co, "World::update_global_transforms_from_transforms",
  )
  self.assert_system_component_write(
    gt, "World::update_global_transforms_from_transforms",
  )
  if self.try_update_global_transforms_from_transforms_archetype_path(
      tf, gt, co,
    ) {
    self.clear_transform_dirty()
    return
  }
  abort(
    "World::update_global_transforms_from_transforms: archetype path unavailable",
  )
}

///|
/// Recomputes pending dirty transforms and returns diagnostic counters without draining upload views.
///
/// When the dirty path cannot complete, this falls back to the same full recompute path used by
/// [`World::update_global_transforms_from_transforms`] and marks the fallback in the report.
pub fn World::propagate_global_transforms_from_transforms_report(
  self : World,
) -> TransformPropagationReport {
  let tf = self.transform_component_id
  let gt = self.global_transform_component_id
  let co = self.child_of_component_id
  self.assert_system_component_read(
    tf, "World::propagate_global_transforms_from_transforms_report",
  )
  self.assert_system_component_read(
    co, "World::propagate_global_transforms_from_transforms_report",
  )
  self.assert_system_component_write(
    gt, "World::propagate_global_transforms_from_transforms_report",
  )
  let report = transform_propagation_report_draft(
    self.transform_dirty_entities.length(),
  )
  if self.transform_dirty_entities.length() == 0 {
    report.pending_upload_range_count = self.global_transform_blob.pending_write_view_count()
    return report.finish()
  }
  let dirty_ok = self.update_global_transforms_from_transforms_dirty_report(
    report,
  )
  if !dirty_ok {
    report.fallback_to_full = true
    report.ok = true
    if self.try_update_global_transforms_from_transforms_archetype_path_report(
        tf, gt, co, report,
      ) {
      self.clear_transform_dirty()
    } else {
      report.ok = false
    }
  }
  report.pending_upload_range_count = self.global_transform_blob.pending_write_view_count()
  report.finish()
}
