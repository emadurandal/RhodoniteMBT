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
  name : String
  reads : Array[ComponentTypeId]
  writes : Array[ComponentTypeId]
  structural_write : Bool
}

///|
fn World::system_access_snapshot(self : World) -> SystemAccessSnapshot {
  {
    depth: self.system_access_depth,
    name: self.system_access_name,
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
  self.system_access_name = snapshot.name
  self.system_access_reads = snapshot.reads
  self.system_access_writes = snapshot.writes
  self.system_access_structural_write = snapshot.structural_write
}

///|
fn component_id_text(component : ComponentTypeId) -> String {
  "component id " + component.index.to_string()
}

///|
fn World::active_system_text(self : World) -> String {
  if self.system_access_active() {
    "System '" + self.system_access_name + "'"
  } else {
    "no active System"
  }
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
    abort(
      operation +
      " cannot be called while querying ECS component views. Hint: do not mutate archetype/entity structure inside Query::for_each; queue the change in CommandBuffer and apply it after the query callback returns.",
    )
  }
}

///|
/// Blocks component registration while systems are running.
fn World::assert_component_registration_open(
  self : World,
  operation : String,
) -> Unit {
  if self.component_registration_lock_depth > 0 {
    abort(
      operation +
      " cannot be called while schedule execution is active. Hint: register component types before Schedule::run starts, or between schedule runs; systems should use already-registered ComponentTypeId values.",
    )
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
    abort(
      operation +
      " tried to read " +
      component_id_text(component) +
      " while running " +
      self.active_system_text() +
      ", but that component is not declared in reads or writes. Hint: add this component to System::new reads for read-only access, or to writes if the system may mutate it.",
    )
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
    abort(
      operation +
      " tried to write " +
      component_id_text(component) +
      " while running " +
      self.active_system_text() +
      ", but that component is not declared in writes. Hint: add this component to the System::new writes array; writes also permits reading the same component.",
    )
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
    abort(
      operation +
      " tried to mutate entity/archetype structure while running " +
      self.active_system_text() +
      ", but structural_write is false. Hint: create the system with System::new_with_structural_write, and for query callbacks queue structural changes in CommandBuffer instead of calling World mutation APIs directly.",
    )
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
  let reserved : Array[Bool] = []
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
  let system_access_name = ""
  let system_access_reads : Array[ComponentTypeId] = []
  let system_access_writes : Array[ComponentTypeId] = []
  let system_access_structural_write = false
  {
    registry,
    generations,
    alive,
    reserved,
    free_indices,
    locations,
    archetypes,
    gpu_stores,
    resize_events,
    query_depth,
    component_registration_lock_depth,
    system_access_depth,
    system_access_name,
    system_access_reads,
    system_access_writes,
    system_access_structural_write,
    transform_component_id,
    global_transform_component_id,
    child_of_component_id,
  }
}

///|
/// Returns immutable metadata for a component registered in this world.
pub fn World::component_info(
  self : World,
  component : ComponentTypeId,
) -> RegisteredComponent? {
  self.registry.get(component)
}

///|
/// Returns the CPU SoA stride for a registered component, or `None` for an unknown id.
///
/// GpuVisible components report `0` because their payload lives in flat GPU storage.
pub fn World::component_cpu_stride(
  self : World,
  component : ComponentTypeId,
) -> Int? {
  match self.registry.get(component) {
    Some(rc) => Some(rc.cpu_stride)
    None => None
  }
}

///|
/// Returns the GPU layout for a GpuVisible component, or `None` for CPU-only/unknown ids.
pub fn World::component_gpu_layout(
  self : World,
  component : ComponentTypeId,
) -> @comp.GpuLayout? {
  self.registry.gpu_layout(component)
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
  name : String,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  structural_write : Bool,
) -> SystemAccessSnapshot {
  let snapshot = self.system_access_snapshot()
  self.system_access_depth = self.system_access_depth + 1
  self.system_access_name = name
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
fn World::is_reserved_entity(self : World, entity : EntityId) -> Bool {
  entity.index >= 0 &&
  entity.index < self.reserved.length() &&
  self.reserved[entity.index] &&
  self.generations[entity.index] == entity.generation
}

///|
/// Reserves an entity slot for a queued create command without touching archetype rows.
fn World::reserve_entity_for_command(self : World) -> EntityId {
  self.assert_system_structural_write("World::reserve_entity_for_command")
  if self.free_indices.length() > 0 {
    let last = self.free_indices.length() - 1
    let index = self.free_indices[last]
    let _ = self.free_indices.pop()
    self.reserved[index] = true
    EntityId::new(index, self.generations[index])
  } else {
    let index = self.generations.length()
    self.generations.push(0)
    self.alive.push(false)
    self.reserved.push(true)
    self.locations.push(None)
    EntityId::new(index, 0)
  }
}

///|
/// Makes a previously reserved entity alive and inserts it into the empty archetype.
fn World::finalize_reserved_entity(self : World, entity : EntityId) -> Bool {
  self.assert_not_querying("World::finalize_reserved_entity")
  self.assert_system_structural_write("World::finalize_reserved_entity")
  if !self.is_reserved_entity(entity) || self.alive[entity.index] {
    return false
  }
  self.reserved[entity.index] = false
  self.alive[entity.index] = true
  let row = self.archetypes[0].push_empty_row(entity)
  self.locations[entity.index] = Some({ archetype_index: 0, row })
  self.ensure_gpu_capacity(entity.index + 1)
  true
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
    self.reserved[index] = false
    EntityId::new(index, self.generations[index])
  } else {
    let index = self.generations.length()
    self.generations.push(0)
    self.alive.push(true)
    self.reserved.push(false)
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
  self.reserved[entity.index] = false
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
/// Updates an existing component payload without changing archetype ownership.
///
/// CpuOnly components update the archetype SoA row. GpuVisible components update the flat GPU row
/// and mark it dirty. Returns false for dead entities, missing ownership, unknown components, or
/// byte lengths that do not match the registered payload stride.
pub fn World::set_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  self.assert_not_querying("World::set_component_bytes")
  self.assert_system_component_write(component, "World::set_component_bytes")
  let rc = match self.registry.get(component) {
    Some(rc) => rc
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
  match rc.kind {
    CpuOnly => {
      if bytes.length() != rc.cpu_stride {
        return false
      }
      self.archetypes[loc.archetype_index].set_component_bytes(
        loc.row,
        component,
        bytes,
      )
      true
    }
    GpuVisible => {
      let expected_stride = match rc.gpu_layout {
        Some(layout) => layout.stride
        None => return false
      }
      if bytes.length() != expected_stride {
        return false
      }
      match self.ensure_gpu_store_capacity(component, entity.index + 1) {
        Some(store) => {
          store.set_bytes(entity.index, bytes)
          self.replace_gpu_store(store)
          true
        }
        None => false
      }
    }
  }
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
fn component_accepts_add_bytes(
  component : RegisteredComponent,
  bytes : FixedArray[Byte],
) -> Bool {
  match component.kind {
    CpuOnly => bytes.length() == component.cpu_stride
    GpuVisible =>
      if bytes.length() == 0 {
        true
      } else {
        match component.gpu_layout {
          Some(layout) => bytes.length() == layout.stride
          None => false
        }
      }
  }
}

///|
/// Adds a component with a kind-appropriate zero/default payload.
pub fn World::add_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  self.assert_not_querying("World::add_component")
  self.assert_system_structural_write("World::add_component")
  self.assert_system_component_write(component, "World::add_component")
  if !self.is_alive(entity) {
    return false
  }
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => {
          let bytes = FixedArray::make(rc.cpu_stride, (0 : Byte))
          self.add_component_signature(entity, component, bytes)
        }
        GpuVisible =>
          match self.ensure_gpu_store_capacity(component, entity.index + 1) {
            Some(store) => {
              let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
              if !self.add_component_signature(entity, component, empty) {
                false
              } else {
                store.clear_slot(entity.index)
                self.replace_gpu_store(store)
                true
              }
            }
            None => false
          }
      }
    None => false
  }
}

///|
/// Adds a component and initializes its payload bytes.
///
/// CpuOnly bytes initialize the archetype SoA row. GpuVisible bytes initialize the flat GPU row;
/// pass an empty byte array to use the same zero/default behavior as `add_component`.
pub fn World::add_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  self.assert_not_querying("World::add_component_bytes")
  self.assert_system_structural_write("World::add_component_bytes")
  self.assert_system_component_write(component, "World::add_component_bytes")
  if !self.is_alive(entity) {
    return false
  }
  match self.registry.get(component) {
    Some(rc) => {
      if !component_accepts_add_bytes(rc, bytes) {
        return false
      }
      match rc.kind {
        CpuOnly => self.add_component_signature(entity, component, bytes)
        GpuVisible =>
          match self.ensure_gpu_store_capacity(component, entity.index + 1) {
            Some(store) => {
              let empty : FixedArray[Byte] = FixedArray::make(0, (0 : Byte))
              if !self.add_component_signature(entity, component, empty) {
                false
              } else {
                if bytes.length() == 0 {
                  store.clear_slot(entity.index)
                } else {
                  store.set_bytes(entity.index, bytes)
                }
                self.replace_gpu_store(store)
                true
              }
            }
            None => false
          }
      }
    }
    None => false
  }
}

///|
/// Removes a component: migrates to a smaller archetype (signature loses one id).
///
/// Removing a GpuVisible component also zero-clears that entity's flat GPU slot and marks it
/// dirty so stale payload bytes are not visible after ownership is dropped.
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
  let gpu_store_to_clear = match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => None
        GpuVisible =>
          match self.ensure_gpu_store_capacity(component, entity.index + 1) {
            Some(store) => Some(store)
            None => return false
          }
      }
    None => return false
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
  match gpu_store_to_clear {
    Some(store) => {
      store.clear_slot(entity.index)
      self.replace_gpu_store(store)
    }
    None => ()
  }
  true
}

///|
/// Looks up component bytes for a living entity that owns `component`.
///
/// CpuOnly components return their archetype SoA row. GpuVisible components return their flat GPU
/// row at `EntityId.index`.
pub fn World::component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> FixedArray[Byte]? {
  self.assert_system_component_read(component, "World::component_bytes")
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  if !component_array_contains(
      self.archetypes[loc.archetype_index].components,
      component,
    ) {
    return None
  }
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly =>
          self.archetypes[loc.archetype_index].component_bytes(
            loc.row,
            component,
          )
        GpuVisible =>
          match self.gpu_store(component) {
            Some(store) => {
              if entity.index >= store.capacity() {
                return None
              }
              Some(
                copy_array_range_to_fixed(
                  store.bytes,
                  entity.index * store.stride,
                  store.stride,
                ),
              )
            }
            None => None
          }
      }
    None => None
  }
}

///|
/// Internal row iterator used by [`Query`]. This intentionally performs no system access check;
/// [`QueryRow::read_view`] and [`QueryRow::write_view`] enforce access and build row views lazily
/// at the point where the callback asks for a read-only or mutable view.
fn World::for_each_query_rows(
  self : World,
  required : Array[ComponentTypeId],
  f : (EntityId, Int, Int) -> Unit,
) -> Unit {
  if required.length() == 0 {
    return
  }
  if component_array_has_duplicates(required) {
    abort(
      "Query::for_each: duplicate required component. Hint: construct queries through Query::new and pass each ComponentTypeId at most once.",
    )
  }
  for k = 0; k < required.length(); k = k + 1 {
    match self.registry.get(required[k]) {
      Some(_) => ()
      None =>
        abort(
          "Query::for_each: unknown " +
          component_id_text(required[k]) +
          ". Hint: use ComponentTypeId values registered in this World, or builtin component accessors such as world.transform_component().",
        )
    }
  }
  // Nested query depth lets structural APIs detect and reject invalid mutation during iteration.
  self.query_depth = self.query_depth + 1
  for ai = 0; ai < self.archetypes.length(); ai = ai + 1 {
    let sig = self.archetypes[ai].components
    if component_array_contains_all(sig, required) {
      let arch = self.archetypes[ai]
      let ents = arch.entities
      for j = 0; j < ents.length(); j = j + 1 {
        f(ents[j], ai, j)
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
