///|
/// Implements `component_less`.
fn component_less(a : ComponentTypeId, b : ComponentTypeId) -> Bool {
  a.index < b.index
}

///|
/// Implements `component_array_contains`.
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
/// Implements `component_array_contains_all`.
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
/// Implements `copy_component_array`.
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
/// Implements `World::system_access_snapshot`.
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
/// Implements `World::restore_system_access`.
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
/// Implements `World::bump_archetype_version`.
fn World::bump_archetype_version(self : World) -> Unit {
  self.archetype_version = self.archetype_version + 1
}

///|
/// Implements `component_id_text`.
fn component_id_text(component : ComponentTypeId) -> String {
  "component id " + component.index.to_string()
}

///|
/// Implements `World::active_system_text`.
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
/// Implements `component_arrays_equal`.
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
/// Implements `component_signature_hash`.
fn component_signature_hash(components : Array[ComponentTypeId]) -> Int {
  let mut h = components.length()
  for i = 0; i < components.length(); i = i + 1 {
    h = h + components[i].index + 1
  }
  h
}

///|
/// Implements `World::remember_archetype_signature`.
fn World::remember_archetype_signature(
  self : World,
  components : Array[ComponentTypeId],
  archetype_index : Int,
) -> Unit {
  let hash = component_signature_hash(components)
  for i = 0; i < self.archetype_signature_cache.length(); i = i + 1 {
    let entry = self.archetype_signature_cache[i]
    if entry.hash == hash &&
      component_arrays_equal(entry.components, components) {
      self.archetype_signature_cache[i] = {
        hash,
        components: copy_component_array(components),
        archetype_index,
      }
      return
    }
  }
  self.archetype_signature_cache.push({
    hash,
    components: copy_component_array(components),
    archetype_index,
  })
}

///|
/// Implements `World::ensure_component_archetype_slot`.
fn World::ensure_component_archetype_slot(
  self : World,
  component : ComponentTypeId,
) -> Unit {
  while self.component_archetypes.length() <= component.index {
    let archetypes : Array[Int] = []
    self.component_archetypes.push(archetypes)
  }
}

///|
/// Implements `World::index_archetype_components`.
fn World::index_archetype_components(
  self : World,
  archetype_index : Int,
) -> Unit {
  let components = self.archetypes[archetype_index].components
  for i = 0; i < components.length(); i = i + 1 {
    let component = components[i]
    self.ensure_component_archetype_slot(component)
    self.component_archetypes[component.index].push(archetype_index)
  }
}

///|
/// Implements `World::query_candidate_archetypes`.
fn World::query_candidate_archetypes(
  self : World,
  required : Array[ComponentTypeId],
) -> Array[Int] {
  let empty : Array[Int] = []
  if required.length() == 0 {
    return empty
  }
  let mut best_component_index = -1
  let mut best_len = 0
  for i = 0; i < required.length(); i = i + 1 {
    let component = required[i]
    if component.index < 0 ||
      component.index >= self.component_archetypes.length() {
      return empty
    }
    let candidate_len = self.component_archetypes[component.index].length()
    if candidate_len == 0 {
      return empty
    }
    if best_component_index < 0 || candidate_len < best_len {
      best_component_index = component.index
      best_len = candidate_len
    }
  }
  self.component_archetypes[best_component_index]
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
/// Implements `sorted_with_removed`.
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
      " cannot be called while system runner execution is active. Hint: register component types before SystemRunner::run_phase starts, or between runner calls; systems should use already-registered ComponentTypeId values.",
    )
  }
}

///|
/// Implements `World::system_access_active`.
fn World::system_access_active(self : World) -> Bool {
  self.system_access_depth > 0
}

///|
/// Implements `World::assert_system_component_read`.
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
/// Implements `World::assert_system_component_write`.
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
/// Implements `World::assert_system_components_read`.
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
/// Implements `World::assert_system_structural_write`.
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
/// Implements `World::can_add_missing_component_from_setter`.
fn World::can_add_missing_component_from_setter(
  self : World,
  component : ComponentTypeId,
  operation : String,
) -> Bool {
  self.assert_system_component_write(component, operation)
  !self.system_access_active() || self.system_access_structural_write
}

///|
/// New worlds start with archetype 0 = empty signature (no components); entities land there until components are added.
/// Builtin [`Transform3D`] is registered first (`ComponentTypeId.index == 0`) as SoA storage.
/// Builtin [`GlobalTransform`] follows at index `1` with CPU ref storage only;
/// matrix payloads live in the world's packed u32 GlobalTransform blob.
/// Builtin [`ChildOf`] is registered at index `2` as parent entity index/generation.
/// Builtin [`Camera`] is registered at index `3` as CPU ref storage;
/// matrix payloads live in the world's packed u32 Camera blob.
pub fn World::new_with_global_transform_format(
  global_transform_gpu_format : @comp.GlobalTransformGpuFormat,
) -> World {
  let registry = ComponentRegistry::new()
  let tf_layout = @comp.transform3d_gpu_layout()
  if !tf_layout.is_valid() {
    abort("builtin Transform3D layout invalid")
  }
  let transform_component_id = registry.register_cpu(
    "Transform3D",
    tf_layout.stride,
  )
  let gt_layout = @comp.global_transform_ref_cpu_layout()
  if !gt_layout.is_valid() {
    abort("builtin GlobalTransform layout invalid")
  }
  let global_transform_component_id = registry.register_cpu(
    "GlobalTransform",
    gt_layout.stride,
  )
  let co_layout = @comp.child_of_cpu_layout()
  if !co_layout.is_valid() {
    abort("builtin ChildOf layout invalid")
  }
  let child_of_component_id = registry.register_cpu("ChildOf", co_layout.stride)
  let cam_layout = @comp.camera_ref_cpu_layout()
  if !cam_layout.is_valid() {
    abort("builtin Camera layout invalid")
  }
  let camera_component_id = registry.register_cpu("Camera", cam_layout.stride)
  let global_transform_blob = GlobalTransformBlobStore::new()
  let camera_blob = CameraBlobStore::new()
  let generations : Array[Int] = []
  let alive : Array[Bool] = []
  let reserved : Array[Bool] = []
  let free_indices : Array[Int] = []
  let locations : Array[EntityLocation?] = []
  let empty_components : Array[ComponentTypeId] = []
  let archetypes : Array[Archetype] = [
    Archetype::new(empty_components, registry),
  ]
  let archetype_version = 0
  let archetype_signature_cache : Array[ArchetypeSignatureCacheEntry] = [
    {
      hash: component_signature_hash(empty_components),
      components: copy_component_array(empty_components),
      archetype_index: 0,
    },
  ]
  let transform_archetypes : Array[Int] = []
  let global_transform_archetypes : Array[Int] = []
  let child_of_archetypes : Array[Int] = []
  let camera_archetypes : Array[Int] = []
  let component_archetypes : Array[Array[Int]] = [
    transform_archetypes, global_transform_archetypes, child_of_archetypes, camera_archetypes,
  ]
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
    archetype_version,
    archetype_signature_cache,
    component_archetypes,
    global_transform_blob,
    camera_blob,
    query_depth,
    component_registration_lock_depth,
    system_access_depth,
    system_access_name,
    system_access_reads,
    system_access_writes,
    system_access_structural_write,
    transform_component_id,
    global_transform_component_id,
    global_transform_default_format: global_transform_gpu_format,
    child_of_component_id,
    camera_component_id,
  }
}

///|
/// Implements `World::new`.
pub fn World::new() -> World {
  World::new_with_global_transform_format(Affine3x4F32)
}

///|
/// Implements `World::global_transform_gpu_format`.
pub fn World::global_transform_gpu_format(
  self : World,
) -> @comp.GlobalTransformGpuFormat {
  self.global_transform_default_format
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
/// Temporarily closes component registration. SystemRunner execution calls this before running systems.
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
/// Implements `World::component_registration_locked`.
pub fn World::component_registration_locked(self : World) -> Bool {
  self.component_registration_lock_depth > 0
}

///|
/// Implements `World::enter_system_access`.
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
/// Implements `World::exit_system_access`.
fn World::exit_system_access(
  self : World,
  snapshot : SystemAccessSnapshot,
) -> Unit {
  self.restore_system_access(snapshot)
}

///|
/// Returns an archetype whose sorted signature matches `components`.
fn World::find_archetype(
  self : World,
  components : Array[ComponentTypeId],
) -> Int {
  let hash = component_signature_hash(components)
  for i = 0; i < self.archetype_signature_cache.length(); i = i + 1 {
    let entry = self.archetype_signature_cache[i]
    if entry.hash == hash &&
      component_arrays_equal(entry.components, components) {
      return entry.archetype_index
    }
  }
  for i = 0; i < self.archetypes.length(); i = i + 1 {
    if component_arrays_equal(self.archetypes[i].components, components) {
      self.remember_archetype_signature(components, i)
      return i
    }
  }
  -1
}

///|
/// Implements `World::ensure_archetype`.
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
    self.remember_archetype_signature(components, idx)
    self.index_archetype_components(idx)
    self.bump_archetype_version()
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
/// Implements `World::is_alive`.
pub fn World::is_alive(self : World, entity : EntityId) -> Bool {
  entity.index >= 0 &&
  entity.index < self.alive.length() &&
  self.alive[entity.index] &&
  self.generations[entity.index] == entity.generation
}

///|
/// Implements `World::is_reserved_entity`.
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
  true
}

///|
/// Allocates or recycles a slot.
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
  entity
}

///|
/// Removes the entity from its archetype (swap-remove) and frees the slot for reuse.
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
  self.release_global_transform_ref(entity)
  self.release_camera_ref(entity)
  let moved = self.archetypes[loc.archetype_index].swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  self.alive[entity.index] = false
  self.reserved[entity.index] = false
  self.generations[entity.index] = self.generations[entity.index] + 1
  self.locations[entity.index] = None
  self.free_indices.push(entity.index)
  true
}

///|
/// Implements `World::location`.
pub fn World::location(self : World, entity : EntityId) -> EntityLocation? {
  if self.is_alive(entity) {
    self.locations[entity.index]
  } else {
    None
  }
}

///|
/// Implements `World::has_component`.
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
/// Components update the archetype SoA row. Returns false for dead entities, missing ownership, unknown components, or
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
/// Implements `component_accepts_add_bytes`.
fn component_accepts_add_bytes(
  component : RegisteredComponent,
  bytes : FixedArray[Byte],
) -> Bool {
  bytes.length() == component.cpu_stride
}

///|
/// Adds a component with a zero/default payload.
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
    Some(rc) => {
      let bytes = if component == self.global_transform_component_id {
        let gt_ref = self.alloc_global_transform_ref(
          self.global_transform_default_format,
          @m44.Matrix44F::identity(),
        )
        @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset)
      } else if component == self.camera_component_id {
        let camera_ref = self.alloc_camera_ref(
          @m44.Matrix44F::identity(),
          @m44.Matrix44F::identity(),
          (0.1 : Float),
          (1000.0 : Float),
          (1.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
        )
        @comp.camera_ref_bytes(camera_ref.word_offset)
      } else {
        FixedArray::make(rc.cpu_stride, (0 : Byte))
      }
      self.add_component_signature(entity, component, bytes)
    }
    None => false
  }
}

///|
/// Adds a component and initializes its payload bytes.
///
/// Bytes initialize the archetype SoA row.
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
      self.add_component_signature(entity, component, bytes)
    }
    None => false
  }
}

///|
/// Removes a component: migrates to a smaller archetype (signature loses one id).
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
  match self.registry.get(component) {
    Some(_) => ()
    None => return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  if component == self.global_transform_component_id {
    self.release_global_transform_ref(entity)
  } else if component == self.camera_component_id {
    self.release_camera_ref(entity)
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
/// Looks up component bytes for a living entity that owns `component`.
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
    Some(_) =>
      self.archetypes[loc.archetype_index].component_bytes(loc.row, component)
    None => None
  }
}

///|
/// Implements `World::transform_component`.
pub fn World::transform_component(self : World) -> ComponentTypeId {
  self.transform_component_id
}

///|
/// Implements `World::global_transform_component`.
pub fn World::global_transform_component(self : World) -> ComponentTypeId {
  self.global_transform_component_id
}

///|
/// Implements `World::child_of_component`.
pub fn World::child_of_component(self : World) -> ComponentTypeId {
  self.child_of_component_id
}

///|
/// Implements `World::camera_component`.
pub fn World::camera_component(self : World) -> ComponentTypeId {
  self.camera_component_id
}
