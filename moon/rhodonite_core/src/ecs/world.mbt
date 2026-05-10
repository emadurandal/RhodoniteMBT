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
pub fn World::new() -> World {
  let registry = ComponentRegistry::new()
  let generations : Array[Int] = []
  let alive : Array[Bool] = []
  let free_indices : Array[Int] = []
  let locations : Array[EntityLocation?] = []
  let empty_components : Array[ComponentTypeId] = []
  let archetypes : Array[Archetype] = [
    Archetype::new(empty_components, registry),
  ]
  let gpu_stores : Array[GpuComponentStore?] = []
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
