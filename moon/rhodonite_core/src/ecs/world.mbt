///|
fn copy_fixed_into_array(
  dst : Array[Byte],
  offset : Int,
  src : FixedArray[Byte],
) -> Unit {
  for i = 0; i < src.length(); i = i + 1 {
    dst[offset + i] = src[i]
  }
}

///|
fn copy_array_range_to_fixed(
  src : Array[Byte],
  offset : Int,
  len : Int,
) -> FixedArray[Byte] {
  let out = FixedArray::make(len, (0 : Byte))
  for i = 0; i < len; i = i + 1 {
    out[i] = src[offset + i]
  }
  out
}

///|
fn append_zero_bytes(dst : Array[Byte], count : Int) -> Unit {
  for i = 0; i < count; i = i + 1 {
    ignore(i)
    dst.push((0 : Byte))
  }
}

///|
fn component_less(a : ComponentTypeId, b : ComponentTypeId) -> Bool {
  a.index < b.index
}

///|
fn component_array_contains(
  components : Array[ComponentTypeId],
  c : ComponentTypeId,
) -> Bool {
  for i = 0; i < components.length(); i = i + 1 {
    if components[i] == c {
      return true
    }
  }
  false
}

///|
fn component_array_contains_all(
  haystack : Array[ComponentTypeId],
  needles : Array[ComponentTypeId],
) -> Bool {
  for i = 0; i < needles.length(); i = i + 1 {
    if !component_array_contains(haystack, needles[i]) {
      return false
    }
  }
  true
}

///|
fn component_arrays_equal(
  a : Array[ComponentTypeId],
  b : Array[ComponentTypeId],
) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
/// Component-type ids are sorted ascending so archetype keys are canonical and comparable.
fn sorted_with_added(
  components : Array[ComponentTypeId],
  added : ComponentTypeId,
) -> Array[ComponentTypeId] {
  let out : Array[ComponentTypeId] = []
  let mut inserted = false
  for i = 0; i < components.length(); i = i + 1 {
    if !inserted && component_less(added, components[i]) {
      out.push(added)
      inserted = true
    }
    if components[i] != added {
      out.push(components[i])
    }
  }
  if !inserted {
    out.push(added)
  }
  out
}

///|
fn sorted_with_removed(
  components : Array[ComponentTypeId],
  removed : ComponentTypeId,
) -> Array[ComponentTypeId] {
  let out : Array[ComponentTypeId] = []
  for i = 0; i < components.length(); i = i + 1 {
    if components[i] != removed {
      out.push(components[i])
    }
  }
  out
}

///|
/// Builds an archetype table for one sorted component signature (empty archetype uses this with zero components).
fn Archetype::new(
  components : Array[ComponentTypeId],
  registry : ComponentRegistry,
) -> Archetype {
  let columns : Array[ComponentColumn] = []
  for i = 0; i < components.length(); i = i + 1 {
    let bytes : Array[Byte] = []
    columns.push({
      component: components[i],
      stride: registry.stride(components[i]),
      bytes,
    })
  }
  let entities : Array[EntityId] = []
  { components, entities, columns }
}

///|
fn Archetype::column_index(
  self : Archetype,
  component : ComponentTypeId,
) -> Int {
  for i = 0; i < self.columns.length(); i = i + 1 {
    if self.columns[i].component == component {
      return i
    }
  }
  -1
}

///|
/// Appends a zeroed component row for every column (SoA append).
fn Archetype::push_empty_row(self : Archetype, entity : EntityId) -> Int {
  let row = self.entities.length()
  self.entities.push(entity)
  for i = 0; i < self.columns.length(); i = i + 1 {
    append_zero_bytes(self.columns[i].bytes, self.columns[i].stride)
  }
  row
}

///|
/// Copies overlapping components when moving an entity row between archetypes (new row is the pending tail row).
fn Archetype::copy_row_to(self : Archetype, row : Int, dst : Archetype) -> Unit {
  for i = 0; i < self.columns.length(); i = i + 1 {
    let col = self.columns[i]
    let dst_col_index = dst.column_index(col.component)
    if dst_col_index >= 0 {
      let dst_col = dst.columns[dst_col_index]
      let dst_offset = (dst.entities.length() - 1) * dst_col.stride
      let src_offset = row * col.stride
      for b = 0; b < col.stride; b = b + 1 {
        dst_col.bytes[dst_offset + b] = col.bytes[src_offset + b]
      }
    }
  }
}

///|
fn Archetype::set_component_bytes(
  self : Archetype,
  row : Int,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  let col_index = self.column_index(component)
  if col_index < 0 {
    abort("component is not in archetype")
  }
  let col = self.columns[col_index]
  if bytes.length() != col.stride {
    abort("component byte length does not match component stride")
  }
  copy_fixed_into_array(col.bytes, row * col.stride, bytes)
}

///|
fn Archetype::component_bytes(
  self : Archetype,
  row : Int,
  component : ComponentTypeId,
) -> FixedArray[Byte]? {
  let col_index = self.column_index(component)
  if col_index < 0 {
    None
  } else {
    let col = self.columns[col_index]
    Some(copy_array_range_to_fixed(col.bytes, row * col.stride, col.stride))
  }
}

///|
/// Zero-copy **mutable** view of one component row ([`MutArrayView`] over [`ComponentColumn::bytes`]).
fn Archetype::component_byte_mut_view(
  self : Archetype,
  row : Int,
  component : ComponentTypeId,
) -> MutArrayView[Byte]? {
  let col_index = self.column_index(component)
  if col_index < 0 {
    None
  } else {
    let col = self.columns[col_index]
    let base = row * col.stride
    let end = base + col.stride
    Some(col.bytes.mut_view(start=base, end~))
  }
}

///|
/// Dense archetype table helpers (swap-remove keeps rows packed).
fn Archetype::swap_remove_row(self : Archetype, row : Int) -> EntityId? {
  let last = self.entities.length() - 1
  if row < 0 || row > last {
    return None
  }
  let moved = if row != last { Some(self.entities[last]) } else { None }
  if row != last {
    self.entities[row] = self.entities[last]
    for ci = 0; ci < self.columns.length(); ci = ci + 1 {
      let col = self.columns[ci]
      let dst_base = row * col.stride
      let src_base = last * col.stride
      for b = 0; b < col.stride; b = b + 1 {
        col.bytes[dst_base + b] = col.bytes[src_base + b]
      }
    }
  }
  let _ = self.entities.pop()
  for ci = 0; ci < self.columns.length(); ci = ci + 1 {
    let col = self.columns[ci]
    for b = 0; b < col.stride; b = b + 1 {
      ignore(b)
      let _ = col.bytes.pop()
    }
  }
  moved
}

///|
/// New worlds start with archetype 0 = empty signature (no CPU components); entities land there until components are added.
/// Builtin [`Transform3D`] is registered first (`ComponentTypeId.index == 0`) as [`CpuOnly`] SoA storage.
/// Builtin [`GlobalTransform`] follows at index `1` with flat GPU storage only.
/// Builtin [`ChildOf`] is registered at index `2` as [`CpuOnly`] (parent entity index/generation).
pub fn World::new() -> World {
  let registry = ComponentRegistry::new()
  let tf_layout = @comp.transform3d_gpu_layout()
  if !tf_layout.is_valid() {
    abort("builtin Transform3D layout invalid")
  }
  let transform_component_id = registry.register_cpu(
    "Transform3D",
    tf_layout.stride,
  )
  let gt_layout = @comp.global_transform_gpu_layout()
  if !gt_layout.is_valid() {
    abort("builtin GlobalTransform layout invalid")
  }
  let global_transform_component_id = registry.register_gpu(
    "GlobalTransform", gt_layout,
  )
  let co_layout = @comp.child_of_cpu_layout()
  if !co_layout.is_valid() {
    abort("builtin ChildOf layout invalid")
  }
  let child_of_component_id = registry.register_cpu("ChildOf", co_layout.stride)
  let gpu_stores : Array[GpuComponentStore?] = [
    None,
    Some(
      GpuComponentStore::new(global_transform_component_id, gt_layout.stride),
    ),
    None,
  ]
  let generations : Array[Int] = []
  let alive : Array[Bool] = []
  let free_indices : Array[Int] = []
  let locations : Array[EntityLocation?] = []
  let empty_components : Array[ComponentTypeId] = []
  let archetypes : Array[Archetype] = [
    Archetype::new(empty_components, registry),
  ]
  let resize_events : Array[GpuResizeEvent] = []
  {
    registry,
    generations,
    alive,
    free_indices,
    locations,
    archetypes,
    gpu_stores,
    resize_events,
    transform_component_id,
    global_transform_component_id,
    child_of_component_id,
  }
}

///|
pub fn World::registry(self : World) -> ComponentRegistry {
  self.registry
}

///|
/// Linear scan for an archetype whose sorted signature matches `components` (small archetype count expected).
fn World::find_archetype(
  self : World,
  components : Array[ComponentTypeId],
) -> Int {
  for i = 0; i < self.archetypes.length(); i = i + 1 {
    if component_arrays_equal(self.archetypes[i].components, components) {
      return i
    }
  }
  -1
}

///|
fn World::ensure_archetype(
  self : World,
  components : Array[ComponentTypeId],
) -> Int {
  let existing = self.find_archetype(components)
  if existing >= 0 {
    existing
  } else {
    let idx = self.archetypes.length()
    self.archetypes.push(Archetype::new(components, self.registry))
    idx
  }
}

///|
/// Updates `locations` for the entity swapped into `row` after a removal (keeps archetype tables dense).
fn World::update_moved_location(
  self : World,
  moved : EntityId?,
  archetype_index : Int,
  row : Int,
) -> Unit {
  match moved {
    Some(entity) =>
      self.locations[entity.index] = Some({ archetype_index, row })
    None => ()
  }
}

///|
pub fn World::is_alive(self : World, entity : EntityId) -> Bool {
  entity.index >= 0 &&
  entity.index < self.alive.length() &&
  self.alive[entity.index] &&
  self.generations[entity.index] == entity.generation
}

///|
/// Allocates or recycles a slot; bumps GPU backing capacity so flat stores can address `entity.index`.
pub fn World::create_entity(self : World) -> EntityId {
  let entity = if self.free_indices.length() > 0 {
    let last = self.free_indices.length() - 1
    let index = self.free_indices[last]
    let _ = self.free_indices.pop()
    self.alive[index] = true
    EntityId::new(index, self.generations[index])
  } else {
    let index = self.generations.length()
    self.generations.push(0)
    self.alive.push(true)
    self.locations.push(None)
    EntityId::new(index, 0)
  }
  let row = self.archetypes[0].push_empty_row(entity)
  self.locations[entity.index] = Some({ archetype_index: 0, row })
  self.ensure_gpu_capacity(entity.index + 1)
  entity
}

///|
/// Removes the entity from its archetype (swap-remove), clears GPU slots at `entity.index`, frees the slot for reuse.
pub fn World::destroy_entity(self : World, entity : EntityId) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  let moved = self.archetypes[loc.archetype_index].swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  self.clear_gpu_slots(entity.index)
  self.alive[entity.index] = false
  self.generations[entity.index] = self.generations[entity.index] + 1
  self.locations[entity.index] = None
  self.free_indices.push(entity.index)
  true
}

///|
pub fn World::location(self : World, entity : EntityId) -> EntityLocation? {
  if self.is_alive(entity) {
    self.locations[entity.index]
  } else {
    None
  }
}

///|
pub fn World::has_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  match self.locations[entity.index] {
    Some(loc) =>
      component_array_contains(
        self.archetypes[loc.archetype_index].components,
        component,
      )
    None => false
  }
}

///|
/// Adds or updates a CPU component: may migrate the entity to a new archetype with an expanded sorted signature.
pub fn World::add_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  if self.has_component(entity, component) {
    self.archetypes[loc.archetype_index].set_component_bytes(
      loc.row,
      component,
      bytes,
    )
    return true
  }
  let old_arch = self.archetypes[loc.archetype_index]
  let new_components = sorted_with_added(old_arch.components, component)
  let new_arch_index = self.ensure_archetype(new_components)
  let new_arch = self.archetypes[new_arch_index]
  let new_row = new_arch.push_empty_row(entity)
  old_arch.copy_row_to(loc.row, new_arch)
  new_arch.set_component_bytes(new_row, component, bytes)
  self.locations[entity.index] = Some({
    archetype_index: new_arch_index,
    row: new_row,
  })
  let moved = old_arch.swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  true
}

///|
/// Removes a CPU component: migrates to a smaller archetype (signature loses one id); GPU flat stores are unaffected by archetype row moves.
pub fn World::remove_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  if !self.is_alive(entity) || !self.has_component(entity, component) {
    return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  let old_arch = self.archetypes[loc.archetype_index]
  let new_components = sorted_with_removed(old_arch.components, component)
  let new_arch_index = self.ensure_archetype(new_components)
  let new_arch = self.archetypes[new_arch_index]
  let new_row = new_arch.push_empty_row(entity)
  old_arch.copy_row_to(loc.row, new_arch)
  self.locations[entity.index] = Some({
    archetype_index: new_arch_index,
    row: new_row,
  })
  let moved = old_arch.swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  true
}

///|
/// Looks up CPU component bytes from the archetype SoA for this entity row.
pub fn World::component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> FixedArray[Byte]? {
  if !self.is_alive(entity) {
    return None
  }
  match self.locations[entity.index] {
    Some(loc) =>
      self.archetypes[loc.archetype_index].component_bytes(loc.row, component)
    None => None
  }
}

///|
pub fn World::transform_component(self : World) -> ComponentTypeId {
  self.transform_component_id
}

///|
pub fn World::global_transform_component(self : World) -> ComponentTypeId {
  self.global_transform_component_id
}

///|
pub fn World::child_of_component(self : World) -> ComponentTypeId {
  self.child_of_component_id
}

///|
/// Assigns builtin [`ChildOf`] for `entity` (CPU archetype SoA only).
pub fn World::set_child_of(
  self : World,
  entity : EntityId,
  parent : EntityId,
) -> Bool {
  let c = @comp.ChildOf::new(parent.index, parent.generation)
  self.add_component_bytes(
    entity,
    self.child_of_component_id,
    c.to_component_bytes(),
  )
}

///|
pub fn World::get_child_of(self : World, entity : EntityId) -> EntityId? {
  let id = self.child_of_component_id
  if !self.is_alive(entity) || !self.has_component(entity, id) {
    return None
  }
  match self.component_bytes(entity, id) {
    Some(bytes) => {
      let c = @comp.ChildOf::from_component_bytes(bytes)
      Some(EntityId::new(c.parent_index, c.parent_generation))
    }
    None => None
  }
}

///|
/// Walks [`ChildOf`] links upward from `start` (includes `start`). Returns [`None`] on cycle,
/// out-of-range indices, or missing/dead parent link.
fn World::build_child_of_ancestor_chain(
  self : World,
  start : EntityId,
) -> Array[EntityId]? {
  let chain : Array[EntityId] = []
  let slot_count = self.generations.length()
  let visited = FixedArray::make(slot_count, false)
  let mut cur = start
  let mut walking = true
  while walking {
    if cur.index < 0 || cur.index >= slot_count {
      return None
    }
    if visited[cur.index] {
      return None
    }
    visited[cur.index] = true
    chain.push(cur)
    match self.get_child_of(cur) {
      None => walking = false
      Some(parent) =>
        if !self.is_alive(parent) {
          return None
        } else {
          cur = parent
        }
    }
  }
  Some(chain)
}

///|
/// Copies column-major [`@m44.Matrix44F`] into a [`@m44ref.Matrix44RefF`] (same layout).
fn matrix44f_copy_to_ref(
  dst : @m44ref.Matrix44RefF,
  m : @m44.Matrix44F,
) -> Unit {
  for c = 0; c < 4; c = c + 1 {
    for r = 0; r < 4; r = r + 1 {
      dst.set_at(r, c, m.data[c * 4 + r])
    }
  }
}

///|
/// `leaf_tf`: when [`Some`], used for `leaf` instead of [`get_transform`] (TF+GT bulk row path).
fn World::multiply_world_chain_matrix(
  self : World,
  leaf : EntityId,
  chain : Array[EntityId],
  leaf_tf : @comp.Transform3D?,
) -> @m44.Matrix44F? {
  let mut world_m = @m44.Matrix44F::identity()
  let mut i = chain.length() - 1
  while i >= 0 {
    let e = chain[i]
    let tf : @comp.Transform3D = if e == leaf {
      match leaf_tf {
        Some(ptf) => ptf
        None =>
          match self.get_transform(e) {
            Some(t) => t
            None => return None
          }
      }
    } else {
      match self.get_transform(e) {
        Some(t) => t
        None => return None
      }
    }
    world_m = world_m.mat_mul(tf.to_local_matrix())
    i = i - 1
  }
  Some(world_m)
}

///|
/// `leaf_tf`: when [`Some`], used for `leaf` instead of [`get_transform`] (TF+GT bulk row path).
fn World::multiply_world_from_chain(
  self : World,
  leaf : EntityId,
  chain : Array[EntityId],
  leaf_tf : @comp.Transform3D?,
) -> @m44.Matrix44F? {
  self.multiply_world_chain_matrix(leaf, chain, leaf_tf)
}

///|
/// Computes world-space matrix from [`Transform3D`] along [`ChildOf`] ancestors (root → entity).
/// Returns [`None`] when `entity` is dead, lacks [`Transform3D`], an ancestor lacks [`Transform3D`],
/// a [`ChildOf`] parent is not alive, or a parent cycle is detected.
pub fn World::compute_global_transform(
  self : World,
  entity : EntityId,
) -> @m44.Matrix44F? {
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
          Some(chain) => self.multiply_world_from_chain(entity, chain, None)
        }
      }
    }
  }
}

///|
/// Used only by [`update_global_transforms_from_transforms`]: entity comes from a TF+GT query row and
/// `leaf_tf` was decoded from that row's Transform SoA view (no [`get_transform`] on the leaf).
/// Writes the world matrix into `gt_gpu_row` and returns whether a matrix was written.
fn World::compute_global_transform_for_tf_gt_bulk_row(
  self : World,
  entity : EntityId,
  archetype_components : Array[ComponentTypeId],
  leaf_tf : @comp.Transform3D,
  gt : @comp.GlobalTransform,
) -> Bool {
  let co_id = self.child_of_component_id
  if !component_array_contains(archetype_components, co_id) {
    matrix44f_copy_to_ref(gt.matrix, leaf_tf.to_local_matrix())
    true
  } else {
    match self.build_child_of_ancestor_chain(entity) {
      None => false
      Some(chain) =>
        match self.multiply_world_chain_matrix(entity, chain, Some(leaf_tf)) {
          None => false
          Some(world_m) => {
            matrix44f_copy_to_ref(gt.matrix, world_m)
            true
          }
        }
    }
  }
}

///|
/// Iterates every living entity whose archetype signature **includes all** `required`
/// [`ComponentTypeId`]s (superset match). When `required` is empty, invokes nothing.
///
/// The callback receives the entity, that row's **full sorted archetype component list**, and one
/// [`MutArrayView`] per entry in `required` (same order): a **non-copying** mutable view into that
/// component's payload at this entity.
///
/// * **`CpuOnly`**: view over archetype SoA column bytes (`stride` bytes per row).
/// * **`GpuVisible`**: view over this entity's row in [`GpuComponentStore`] (`gpu_layout.stride`
///   bytes; **not** archetype SoA bytes). After the callback returns, the world persists each
///   touched GPU store with `replace_gpu_store` only (no automatic dirty queue). If you mutate a
///   GPU row, call [`World::mark_gpu_component_dirty`] so [`drain_gpu_writes`] picks it up. If the
///   store grew, a [`GpuResizeEvent`] is queued before invoking the callback (same shape as
///   [`ensure_gpu_capacity`]).
pub fn World::for_each_entity_with_components(
  self : World,
  required : Array[ComponentTypeId],
  f : (EntityId, Array[ComponentTypeId], Array[MutArrayView[Byte]]) -> Unit,
) -> Unit {
  if required.length() == 0 {
    return
  }
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let sig = self.archetypes[ai].components
    if component_array_contains_all(sig, required) {
      let arch = self.archetypes[ai]
      let ents = arch.entities
      for j = 0; j < ents.length(); j = j + 1 {
        let entity = ents[j]
        let payloads : Array[MutArrayView[Byte]] = []
        let gpu_flush : Array[GpuComponentStore] = []
        for k = 0; k < required.length(); k = k + 1 {
          match self.registry.get(required[k]) {
            None =>
              abort(
                "for_each_entity_with_components: unknown component type id",
              )
            Some(rc) =>
              match rc.kind {
                CpuOnly =>
                  match arch.component_byte_mut_view(j, required[k]) {
                    Some(v) => payloads.push(v)
                    None =>
                      abort(
                        "for_each_entity_with_components: required component missing from archetype",
                      )
                  }
                GpuVisible =>
                  match self.gpu_store(required[k]) {
                    Some(store) => {
                      let grew = store.ensure_capacity(entity.index + 1)
                      if grew {
                        self.resize_events.push({
                          component: store.component,
                          required_capacity: entity.index + 1,
                          needs_full_upload: true,
                        })
                      }
                      let base = entity.index * store.stride
                      let view = store.bytes.mut_view(
                        start=base,
                        end=base + store.stride,
                      )
                      payloads.push(view)
                      gpu_flush.push(store)
                    }
                    None =>
                      abort(
                        "for_each_entity_with_components: GpuVisible component has no gpu store",
                      )
                  }
              }
          }
        }
        f(entity, sig, payloads)
        for gi = 0; gi < gpu_flush.length(); gi = gi + 1 {
          let st = gpu_flush[gi]
          self.replace_gpu_store(st)
        }
      }
    }
  }
}

///|
/// Recomputes [`GlobalTransform`] GPU payloads from [`Transform3D`] (and optional [`ChildOf`] hierarchy)
/// for every entity that currently has **both** builtin transforms.
pub fn World::update_global_transforms_from_transforms(self : World) -> Unit {
  let tf = self.transform_component_id
  let gt = self.global_transform_component_id
  let required : Array[ComponentTypeId] = [tf, gt]
  self.for_each_entity_with_components(required, (e, sig, payloads) => {
    let local_tf = @comp.Transform3D::from_component_mut_view(payloads[0])
    let global_tf = @comp.GlobalTransform::view_std140_gpu_row(payloads[1])
    if self.compute_global_transform_for_tf_gt_bulk_row(
        e, sig, local_tf, global_tf,
      ) {
      let _ = self.mark_gpu_component_dirty(e, gt)
    }
  })
}
