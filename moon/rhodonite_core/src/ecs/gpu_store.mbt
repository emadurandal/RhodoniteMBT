///|
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
fn GpuComponentStore::mark_dirty(self : GpuComponentStore, index : Int) -> Unit {
  if !self.dirty_flags[index] {
    self.dirty_flags[index] = true
    self.dirty_indices.push(index)
  }
}

///|
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
fn sort_ints(values : Array[Int]) -> Array[Int] {
  let out : Array[Int] = []
  for i = 0; i < values.length(); i = i + 1 {
    let v = values[i]
    let mut inserted = false
    for j = 0; j < out.length(); j = j + 1 {
      if !inserted && v < out[j] {
        out.insert(j, v)
        inserted = true
      }
    }
    if !inserted {
      out.push(v)
    }
  }
  out
}

///|
fn GpuComponentStore::range_bytes(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> GpuWrite {
  let count = last - first + 1
  let len = count * self.stride
  let out = FixedArray::make(len, (0 : Byte))
  let src_base = first * self.stride
  for i = 0; i < len; i = i + 1 {
    out[i] = self.bytes[src_base + i]
  }
  { byte_offset: src_base, bytes: out }
}

///|
fn GpuComponentStore::drain_writes(self : GpuComponentStore) -> Array[GpuWrite] {
  let writes : Array[GpuWrite] = []
  if self.dirty_indices.length() == 0 {
    return writes
  }
  let sorted = sort_ints(self.dirty_indices)
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
pub fn World::register_cpu_component(
  self : World,
  name : String,
  cpu_stride : Int,
) -> ComponentTypeId {
  let id = self.registry.register_cpu(name, cpu_stride)
  self.gpu_stores.push(None)
  id
}

///|
pub fn World::register_gpu_component(
  self : World,
  name : String,
  cpu_stride : Int,
  gpu_layout : GpuLayout,
) -> ComponentTypeId {
  if !gpu_layout.is_valid() {
    abort("invalid gpu layout")
  }
  let id = self.registry.register_gpu(name, cpu_stride, gpu_layout)
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
fn World::ensure_gpu_capacity(self : World, capacity : Int) -> Unit {
  for i = 0; i < self.gpu_stores.length(); i = i + 1 {
    match self.gpu_stores[i] {
      Some(store) =>
        if store.ensure_capacity(capacity) {
          self.resize_events.push({
            component: store.component,
            required_capacity: capacity,
            needs_full_upload: true,
          })
          self.replace_gpu_store({
            component: store.component,
            stride: store.stride,
            bytes: store.bytes,
            dirty_flags: store.dirty_flags,
            dirty_indices: store.dirty_indices,
          })
        }
      None => ()
    }
  }
}

///|
fn World::clear_gpu_slots(self : World, entity_index : Int) -> Unit {
  for i = 0; i < self.gpu_stores.length(); i = i + 1 {
    match self.gpu_stores[i] {
      Some(store) => {
        store.clear_slot(entity_index)
        self.replace_gpu_store(store)
      }
      None => ()
    }
  }
}

///|
pub fn World::set_gpu_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  match self.gpu_store(component) {
    Some(store) => {
      store.set_bytes(entity.index, bytes)
      self.replace_gpu_store(store)
      true
    }
    None => false
  }
}

///|
pub fn World::clear_gpu_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  match self.gpu_store(component) {
    Some(store) => {
      store.clear_slot(entity.index)
      self.replace_gpu_store(store)
      true
    }
    None => false
  }
}

///|
pub fn World::gpu_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> FixedArray[Byte]? {
  if !self.is_alive(entity) {
    return None
  }
  match self.gpu_store(component) {
    Some(store) =>
      Some(
        copy_array_range_to_fixed(
          store.bytes,
          entity.index * store.stride,
          store.stride,
        ),
      )
    None => None
  }
}

///|
pub fn World::drain_gpu_writes(
  self : World,
  component : ComponentTypeId,
) -> Array[GpuWrite] {
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
pub fn World::drain_resize_events(self : World) -> Array[GpuResizeEvent] {
  let out : Array[GpuResizeEvent] = []
  for i = 0; i < self.resize_events.length(); i = i + 1 {
    out.push(self.resize_events[i])
  }
  while self.resize_events.length() > 0 {
    let _ = self.resize_events.pop()
  }
  out
}
