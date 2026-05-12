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
fn copy_component_array(src : Array[ComponentTypeId]) -> Array[ComponentTypeId] {
  let out : Array[ComponentTypeId] = []
  for i = 0; i < src.length(); i = i + 1 {
    out.push(src[i])
  }
  out
}

///|
priv struct SystemAccessSnapshot {
  depth : Int
  reads : Array[ComponentTypeId]
  writes : Array[ComponentTypeId]
  structural_write : Bool
}

///|
fn World::system_access_snapshot(self : World) -> SystemAccessSnapshot {
  {
    depth: self.system_access_depth,
    reads: copy_component_array(self.system_access_reads),
    writes: copy_component_array(self.system_access_writes),
    structural_write: self.system_access_structural_write,
  }
}

///|
fn World::restore_system_access(
  self : World,
  snapshot : SystemAccessSnapshot,
) -> Unit {
  self.system_access_depth = snapshot.depth
  self.system_access_reads = snapshot.reads
  self.system_access_writes = snapshot.writes
  self.system_access_structural_write = snapshot.structural_write
}

///|
/// Rejects duplicate `required` entries so one callback cannot receive the same component view twice.
fn component_array_has_duplicates(components : Array[ComponentTypeId]) -> Bool {
  for i = 0; i < components.length(); i = i + 1 {
    for j = i + 1; j < components.length(); j = j + 1 {
      if components[i] == components[j] {
        return true
      }
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
/// Blocks structural mutation while a query is active so row views and entity locations stay valid.
fn World::assert_not_querying(self : World, operation : String) -> Unit {
  if self.query_depth > 0 {
    abort(operation + " cannot be called while querying ECS component views")
  }
}

///|
/// Blocks component registration while systems are running.
fn World::assert_component_registration_open(
  self : World,
  operation : String,
) -> Unit {
  if self.component_registration_lock_depth > 0 {
    abort(operation + " cannot be called while schedule execution is active")
  }
}

///|
fn World::system_access_active(self : World) -> Bool {
  self.system_access_depth > 0
}

///|
fn World::assert_system_component_read(
  self : World,
  component : ComponentTypeId,
  operation : String,
) -> Unit {
  if self.system_access_active() &&
    !component_array_contains(self.system_access_reads, component) &&
    !component_array_contains(self.system_access_writes, component) {
    abort(operation + " requires a System reads or writes declaration")
  }
}

///|
fn World::assert_system_component_write(
  self : World,
  component : ComponentTypeId,
  operation : String,
) -> Unit {
  if self.system_access_active() &&
    !component_array_contains(self.system_access_writes, component) {
    abort(operation + " requires a System writes declaration")
  }
}

///|
fn World::assert_system_components_read(
  self : World,
  components : Array[ComponentTypeId],
  operation : String,
) -> Unit {
  for i = 0; i < components.length(); i = i + 1 {
    self.assert_system_component_read(components[i], operation)
  }
}

///|
fn World::assert_system_structural_write(
  self : World,
  operation : String,
) -> Unit {
  if self.system_access_active() && !self.system_access_structural_write {
    abort(operation + " requires a System structural write declaration")
  }
}

///|
fn World::can_add_missing_component_from_setter(
  self : World,
  component : ComponentTypeId,
  operation : String,
) -> Bool {
  self.assert_system_component_write(component, operation)
  !self.system_access_active() || self.system_access_structural_write
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
  let query_depth = 0
  let component_registration_lock_depth = 0
  let system_access_depth = 0
  let system_access_reads : Array[ComponentTypeId] = []
  let system_access_writes : Array[ComponentTypeId] = []
  let system_access_structural_write = false
  {
    registry,
    generations,
    alive,
    free_indices,
    locations,
    archetypes,
    gpu_stores,
    resize_events,
    query_depth,
    component_registration_lock_depth,
    system_access_depth,
    system_access_reads,
    system_access_writes,
    system_access_structural_write,
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
/// Temporarily closes component registration. Schedule execution calls this before running systems.
fn World::lock_component_registration(self : World) -> Unit {
  self.component_registration_lock_depth = self.component_registration_lock_depth +
    1
}

///|
/// Reopens component registration after a matching temporary lock.
fn World::unlock_component_registration(self : World) -> Unit {
  if self.component_registration_lock_depth > 0 {
    self.component_registration_lock_depth = self.component_registration_lock_depth -
      1
  }
}

///|
pub fn World::component_registration_locked(self : World) -> Bool {
  self.component_registration_lock_depth > 0
}

///|
fn World::enter_system_access(
  self : World,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  structural_write : Bool,
) -> SystemAccessSnapshot {
  let snapshot = self.system_access_snapshot()
  self.system_access_depth = self.system_access_depth + 1
  self.system_access_reads = copy_component_array(reads)
  self.system_access_writes = copy_component_array(writes)
  self.system_access_structural_write = structural_write
  snapshot
}

///|
fn World::exit_system_access(
  self : World,
  snapshot : SystemAccessSnapshot,
) -> Unit {
  self.restore_system_access(snapshot)
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
  self.assert_not_querying("World::create_entity")
  self.assert_system_structural_write("World::create_entity")
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
  self.assert_not_querying("World::destroy_entity")
  self.assert_system_structural_write("World::destroy_entity")
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
  self.assert_system_component_read(component, "World::has_component")
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
/// Updates an existing CPU component payload in its current archetype row.
pub fn World::set_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  self.assert_not_querying("World::set_component_bytes")
  self.assert_system_component_write(component, "World::set_component_bytes")
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => ()
        GpuVisible => return false
      }
    None => return false
  }
  if !self.is_alive(entity) {
    return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  if !component_array_contains(
      self.archetypes[loc.archetype_index].components,
      component,
    ) {
    return false
  }
  self.archetypes[loc.archetype_index].set_component_bytes(
    loc.row,
    component,
    bytes,
  )
  true
}

///|
/// Adds one component id to an entity archetype signature and initializes its CPU SoA bytes.
fn World::add_component_signature(
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
    return false
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
/// Adds a new CPU component: migrates the entity to an archetype with an expanded sorted signature.
pub fn World::add_cpu_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  self.assert_not_querying("World::add_cpu_component_bytes")
  self.assert_system_structural_write("World::add_cpu_component_bytes")
  self.assert_system_component_write(
    component, "World::add_cpu_component_bytes",
  )
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => self.add_component_signature(entity, component, bytes)
        GpuVisible => false
      }
    None => false
  }
}

///|
/// Adds a GPU-visible component ownership marker; payload lives in the flat GPU store.
pub fn World::add_gpu_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  self.assert_not_querying("World::add_gpu_component")
  self.assert_system_structural_write("World::add_gpu_component")
  self.assert_system_component_write(component, "World::add_gpu_component")
  if !self.is_alive(entity) {
    return false
  }
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => false
        GpuVisible =>
          match self.ensure_gpu_store_capacity(component, entity.index + 1) {
            Some(_) => {
              let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
              self.add_component_signature(entity, component, empty)
            }
            None => false
          }
      }
    None => false
  }
}

///|
/// Adds a component using the registry kind. Prefer `add_cpu_component_bytes` or `add_gpu_component`
/// in new code so CPU payload and GPU-visible ownership are explicit.
pub fn World::add_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => self.add_cpu_component_bytes(entity, component, bytes)
        GpuVisible =>
          if bytes.length() == 0 {
            self.add_gpu_component(entity, component)
          } else {
            false
          }
      }
    None => false
  }
}

///|
/// Removes a CPU component: migrates to a smaller archetype (signature loses one id); GPU flat stores are unaffected by archetype row moves.
pub fn World::remove_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  self.assert_not_querying("World::remove_component")
  self.assert_system_structural_write("World::remove_component")
  self.assert_system_component_write(component, "World::remove_component")
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
  self.assert_system_component_read(component, "World::component_bytes")
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
/// Internal row iterator used by [`Query`]. This intentionally performs no system access check;
/// [`QueryRow::read_view`] and [`QueryRow::write_view`] enforce access at the point where the
/// callback asks for a read-only or mutable view.
fn World::for_each_query_row_payloads(
  self : World,
  required : Array[ComponentTypeId],
  f : (EntityId, Array[ComponentTypeId], Array[MutArrayView[Byte]]) -> Unit,
) -> Unit {
  if required.length() == 0 {
    return
  }
  if component_array_has_duplicates(required) {
    abort("Query::for_each: duplicate required component")
  }
  // Nested query depth lets structural APIs detect and reject invalid mutation during iteration.
  self.query_depth = self.query_depth + 1
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
            None => abort("Query::for_each: unknown component type id")
            Some(rc) =>
              match rc.kind {
                CpuOnly =>
                  match arch.component_byte_mut_view(j, required[k]) {
                    Some(v) => payloads.push(v)
                    None =>
                      abort(
                        "Query::for_each: required component missing from archetype",
                      )
                  }
                GpuVisible =>
                  match
                    self.ensure_gpu_store_capacity(
                      required[k],
                      entity.index + 1,
                    ) {
                    Some(store) => {
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
                        "Query::for_each: GpuVisible component has no gpu store",
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
  // Restore the outer mutation state after the query finishes.
  self.query_depth = self.query_depth - 1
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
