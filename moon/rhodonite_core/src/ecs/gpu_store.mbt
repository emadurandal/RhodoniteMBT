///|
/// Per-GPU-component flat SoA: one `stride`-byte record per possible `EntityId.index`, plus dirty tracking for partial uploads.
fn GpuComponentStore::new(
  component : ComponentTypeId,
  stride : Int,
) -> GpuComponentStore {
  let bytes : Array[Byte] = []
  let dirty_flags : Array[Bool] = []
  let dirty_indices : Array[Int] = []
  { component, stride, bytes, dirty_flags, dirty_indices }
}

///|
fn GpuComponentStore::capacity(self : GpuComponentStore) -> Int {
  if self.stride == 0 {
    0
  } else {
    self.bytes.length() / self.stride
  }
}

///|
/// Grows the byte array in `stride`-sized steps; returns true if new tail slots were appended.
fn GpuComponentStore::ensure_capacity(
  self : GpuComponentStore,
  capacity : Int,
) -> Bool {
  let old = self.capacity()
  if capacity <= old {
    return false
  }
  for entity_i = old; entity_i < capacity; entity_i = entity_i + 1 {
    ignore(entity_i)
    for byte_i = 0; byte_i < self.stride; byte_i = byte_i + 1 {
      ignore(byte_i)
      self.bytes.push((0 : Byte))
    }
    self.dirty_flags.push(false)
  }
  true
}

///|
/// Queues `entity_index` once for `drain_writes` (idempotent per drain cycle).
fn GpuComponentStore::mark_dirty(self : GpuComponentStore, index : Int) -> Unit {
  if !self.dirty_flags[index] {
    self.dirty_flags[index] = true
    self.dirty_indices.push(index)
  }
}

///|
/// Zero-copy read-only view of one logical GPU row. Returns [`None`] if the row is outside current capacity.
fn GpuComponentStore::entity_row_view(
  self : GpuComponentStore,
  entity_index : Int,
) -> ArrayView[Byte]? {
  if entity_index < 0 || entity_index >= self.capacity() {
    None
  } else {
    let base = entity_index * self.stride
    Some(self.bytes[base:base + self.stride])
  }
}

///|
/// Zero-copy mutable view of one logical GPU row; caller must not retain the view past store mutations.
fn GpuComponentStore::mut_entity_row(
  self : GpuComponentStore,
  entity_index : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  let _ = self.ensure_capacity(entity_index + 1)
  let base = entity_index * self.stride
  let view = self.bytes.mut_view(start=base, end=base + self.stride)
  write(view)
  self.mark_dirty(entity_index)
}

///|
/// Writes one entity slot `[entity_index * stride, ..)` and marks it dirty for GPU upload.
fn GpuComponentStore::set_bytes(
  self : GpuComponentStore,
  entity_index : Int,
  bytes : FixedArray[Byte],
) -> Unit {
  if bytes.length() != self.stride {
    abort("gpu component byte length does not match gpu stride")
  }
  let _ = self.ensure_capacity(entity_index + 1)
  for i = 0; i < bytes.length(); i = i + 1 {
    self.bytes[entity_index * self.stride + i] = bytes[i]
  }
  self.mark_dirty(entity_index)
}

///|
/// Zero-fills one logical GPU entity slot and marks it dirty (used by explicit clears and entity teardown).
fn GpuComponentStore::clear_slot(
  self : GpuComponentStore,
  entity_index : Int,
) -> Unit {
  let _ = self.ensure_capacity(entity_index + 1)
  for i = 0; i < self.stride; i = i + 1 {
    self.bytes[entity_index * self.stride + i] = (0 : Byte)
  }
  self.mark_dirty(entity_index)
}

///|

///|
fn swap_int_array(arr : Array[Int], i : Int, j : Int) -> Unit {
  let t = arr[i]
  arr[i] = arr[j]
  arr[j] = t
}

///|
/// Max-heap sink for indices `[0, heap_size)` (0-based indexing).
fn sift_down_max_heap(arr : Array[Int], heap_size : Int, root : Int) -> Unit {
  let mut i = root
  while true {
    let left = i * 2 + 1
    let right = i * 2 + 2
    let mut largest = i
    if left < heap_size && arr[left] > arr[largest] {
      largest = left
    }
    if right < heap_size && arr[right] > arr[largest] {
      largest = right
    }
    if largest == i {
      break
    }
    swap_int_array(arr, i, largest)
    i = largest
  }
}

///|
/// In-place ascending sort. Avoids merge-sort’s O(n log n) allocations (GC + WASM slowdown in
/// [`GpuComponentStore::drain_writes`]).
fn heap_sort_ints_asc(arr : Array[Int]) -> Unit {
  let n = arr.length()
  if n <= 1 {
    return
  }
  let mut i = n / 2 - 1
  while i >= 0 {
    sift_down_max_heap(arr, n, i)
    i = i - 1
  }
  let mut end = n - 1
  while end > 0 {
    swap_int_array(arr, 0, end)
    sift_down_max_heap(arr, end, 0)
    end = end - 1
  }
}

///|
/// Copies bytes for entity indices `[first..=last]` into one payload; `byte_offset` is `first * stride`.
fn GpuComponentStore::range_bytes(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> GpuWrite {
  let count = last - first + 1
  let len = count * self.stride
  let out = FixedArray::make(len, (0 : Byte))
  let src_base = first * self.stride
  let src_view = self.bytes[src_base:src_base + len]
  let mut i = 0
  while i + 4 <= len {
    let u = @writes.get_u32_le_byte_view(src_view, i)
    @writes.put_u32_le(out, i, u)
    i = i + 4
  }
  while i < len {
    out[i] = src_view[i]
    i = i + 1
  }
  { byte_offset: src_base, bytes: out }
}

///|
/// Sorts dirty indices, merges consecutive runs into minimal `GpuWrite` spans, then clears dirty state.
fn GpuComponentStore::drain_writes(self : GpuComponentStore) -> Array[GpuWrite] {
  let writes : Array[GpuWrite] = []
  if self.dirty_indices.length() == 0 {
    return writes
  }
  heap_sort_ints_asc(self.dirty_indices)
  let sorted = self.dirty_indices
  let mut first = sorted[0]
  let mut prev = sorted[0]
  for i = 1; i < sorted.length(); i = i + 1 {
    let idx = sorted[i]
    if idx == prev + 1 {
      prev = idx
    } else {
      writes.push(self.range_bytes(first, prev))
      first = idx
      prev = idx
    }
  }
  writes.push(self.range_bytes(first, prev))
  for i = 0; i < self.dirty_indices.length(); i = i + 1 {
    self.dirty_flags[self.dirty_indices[i]] = false
  }
  while self.dirty_indices.length() > 0 {
    let _ = self.dirty_indices.pop()
  }
  writes
}

///|
/// Reserves a parallel `gpu_stores` slot (`None`) aligned with registry indices.
pub fn World::register_cpu_component(
  self : World,
  name : String,
  cpu_stride : Int,
) -> ComponentTypeId {
  self.assert_not_querying("World::register_cpu_component")
  self.assert_component_registration_open("World::register_cpu_component")
  let id = self.registry.register_cpu(name, cpu_stride)
  self.gpu_stores.push(None)
  id
}

///|
/// Allocates a flat store whose stride matches `gpu_layout.stride` (must pass `GpuLayout::is_valid`).
/// GPU-visible components never allocate archetype SoA payload bytes (`cpu_stride` is always `0`).
pub fn World::register_gpu_component(
  self : World,
  name : String,
  gpu_layout : @comp.GpuLayout,
) -> ComponentTypeId {
  self.assert_not_querying("World::register_gpu_component")
  self.assert_component_registration_open("World::register_gpu_component")
  if !gpu_layout.is_valid() {
    abort("invalid gpu layout")
  }
  let id = self.registry.register_gpu(name, gpu_layout)
  self.gpu_stores.push(Some(GpuComponentStore::new(id, gpu_layout.stride)))
  id
}

///|
fn World::gpu_store(
  self : World,
  component : ComponentTypeId,
) -> GpuComponentStore? {
  if component.index < 0 || component.index >= self.gpu_stores.length() {
    None
  } else {
    self.gpu_stores[component.index]
  }
}

///|
fn World::replace_gpu_store(self : World, store : GpuComponentStore) -> Unit {
  self.gpu_stores[store.component.index] = Some(store)
}

///|
/// Ensures one GPU store has at least `capacity` entity slots and emits a resize event on growth.
fn World::ensure_gpu_store_capacity(
  self : World,
  component : ComponentTypeId,
  capacity : Int,
) -> GpuComponentStore? {
  match self.gpu_store(component) {
    Some(store) => {
      if store.ensure_capacity(capacity) {
        self.resize_events.push({
          component: store.component,
          required_capacity: capacity,
          needs_full_upload: true,
        })
        self.replace_gpu_store(store)
      }
      self.gpu_store(component)
    }
    None => None
  }
}

///|
/// Ensures every GPU store has at least `capacity` entity slots (may emit resize events for buffer recreation).
fn World::ensure_gpu_capacity(self : World, capacity : Int) -> Unit {
  for i = 0; i < self.gpu_stores.length(); i = i + 1 {
    match self.gpu_stores[i] {
      Some(store) =>
        ignore(self.ensure_gpu_store_capacity(store.component, capacity))
      None => ()
    }
  }
}

///|
/// Zeros all GPU-visible slots for one entity index (e.g. on destroy so reused indices do not leak old GPU data).
fn World::clear_gpu_slots(self : World, entity_index : Int) -> Unit {
  for i = 0; i < self.gpu_stores.length(); i = i + 1 {
    match self.gpu_stores[i] {
      Some(store) => {
        let store = match
          self.ensure_gpu_store_capacity(store.component, entity_index + 1) {
          Some(grown_store) => grown_store
          None => store
        }
        store.clear_slot(entity_index)
        self.replace_gpu_store(store)
      }
      None => ()
    }
  }
}

///|
/// Clears one GPU slot to zeros and marks it dirty (same as destroy-side scrubbing but callable explicitly).
pub fn World::clear_gpu_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  self.assert_not_querying("World::clear_gpu_component")
  self.assert_system_component_write(component, "World::clear_gpu_component")
  if !self.is_alive(entity) {
    return false
  }
  if !self.has_component(entity, component) {
    return false
  }
  match self.ensure_gpu_store_capacity(component, entity.index + 1) {
    Some(store) => {
      store.clear_slot(entity.index)
      self.replace_gpu_store(store)
      true
    }
    None => false
  }
}

///|
/// Returns batched byte slices suitable for `write_buffer_from_fixed_array`; consumes pending dirties for this component.
pub fn World::drain_gpu_writes(
  self : World,
  component : ComponentTypeId,
) -> Array[GpuWrite] {
  self.assert_system_component_write(component, "World::drain_gpu_writes")
  match self.gpu_store(component) {
    Some(store) => {
      let writes = store.drain_writes()
      self.replace_gpu_store(store)
      writes
    }
    None => []
  }
}

///|
/// Drains resize notifications after GPU backing arrays grow.
///
/// Schedule execution treats this as structural access to the world's event queue; systems that
/// drain resize events must be built with `System::new_with_structural_write`.
pub fn World::drain_resize_events(self : World) -> Array[GpuResizeEvent] {
  self.assert_system_structural_write("World::drain_resize_events")
  let out : Array[GpuResizeEvent] = []
  for i = 0; i < self.resize_events.length(); i = i + 1 {
    out.push(self.resize_events[i])
  }
  while self.resize_events.length() > 0 {
    let _ = self.resize_events.pop()
  }
  out
}
