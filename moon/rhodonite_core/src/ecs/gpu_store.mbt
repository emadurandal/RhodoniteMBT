///|
/// Per-GPU-component flat SoA: one `stride`-byte record per possible `EntityId.index`, plus dirty tracking for partial uploads.
fn GpuComponentStore::new(
  component : ComponentTypeId,
  stride : Int,
) -> GpuComponentStore {
  let bytes = FixedArray::make(0, (0 : Byte))
  let dirty_flags : Array[Bool] = []
  let dirty_indices : Array[Int] = []
  let dirty_range_first : Array[Int] = []
  let dirty_range_last : Array[Int] = []
  let sort_bucket : Array[Bool] = []
  let active_flags : Array[Bool] = []
  let active_indices : Array[Int] = []
  let active_positions : Array[Int] = []
  {
    component,
    stride,
    bytes,
    dirty_flags,
    dirty_indices,
    dirty_range_first,
    dirty_range_last,
    sort_bucket,
    active_flags,
    active_indices,
    active_positions,
  }
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
#cfg(target="wasm")
fn fixedarray_object_ptr(bytes : FixedArray[Byte]) -> Int = "%identity"

///|
#cfg(target="wasm")
fn GpuComponentStore::wasm_bytes_payload_ptr(self : GpuComponentStore) -> Int {
  // MoonBit's current wasm array layout stores the byte payload after an 8-byte header.
  fixedarray_object_ptr(self.bytes) + 8
}

///|
#cfg(target="wasm")
fn GpuComponentStore::wasm_bytes_len(self : GpuComponentStore) -> Int {
  self.bytes.length()
}

///|
/// Grows the byte array in `stride`-sized steps; returns true if new tail slots were appended.
#cfg(target="js")
extern "js" fn ensure_gpu_store_capacity_js(
  store : GpuComponentStore,
  capacity : Int,
) -> Bool =
  #| (store, capacity) => {
  #|   const stride = store.stride;
  #|   const old = stride === 0 ? 0 : Math.floor(store.bytes.length / stride);
  #|   if (capacity <= old) return false;
  #|   let nextCapacity = old > 0 ? old * 2 : capacity;
  #|   while (nextCapacity < capacity) nextCapacity *= 2;
  #|   const next = new Uint8Array(nextCapacity * stride);
  #|   next.set(store.bytes);
  #|   store.bytes = next;
  #|   while (store.dirty_flags.length < nextCapacity) {
  #|     store.dirty_flags.push(false);
  #|   }
  #|   while (store.active_flags.length < nextCapacity) {
  #|     store.active_flags.push(false);
  #|     store.active_positions.push(-1);
  #|   }
  #|   return true;
  #| }

///|
/// Grows the byte array in `stride`-sized steps; returns true if new tail slots were appended.
#cfg(target="js")
fn GpuComponentStore::ensure_capacity(
  self : GpuComponentStore,
  capacity : Int,
) -> Bool {
  ensure_gpu_store_capacity_js(self, capacity)
}

///|
/// Grows the byte array in `stride`-sized steps; returns true if new tail slots were appended.
#cfg(not(target="js"))
fn GpuComponentStore::ensure_capacity(
  self : GpuComponentStore,
  capacity : Int,
) -> Bool {
  let old = self.capacity()
  if capacity <= old {
    return false
  }
  let mut next_capacity = if old > 0 { old * 2 } else { capacity }
  while next_capacity < capacity {
    next_capacity = next_capacity * 2
  }
  let next_bytes = FixedArray::make(next_capacity * self.stride, (0 : Byte))
  for i = 0; i < self.bytes.length(); i = i + 1 {
    next_bytes[i] = self.bytes[i]
  }
  self.bytes = next_bytes
  for entity_i = old; entity_i < next_capacity; entity_i = entity_i + 1 {
    ignore(entity_i)
    self.dirty_flags.push(false)
    self.active_flags.push(false)
    self.active_positions.push(-1)
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
/// Adds one entity index to this GPU-visible component's packed active set.
fn GpuComponentStore::activate_slot(
  self : GpuComponentStore,
  index : Int,
) -> Unit {
  let _ = self.ensure_capacity(index + 1)
  if !self.active_flags[index] {
    self.active_flags[index] = true
    self.active_positions[index] = self.active_indices.length()
    self.active_indices.push(index)
  }
}

///|
/// Removes one entity index from this GPU-visible component's packed active set.
fn GpuComponentStore::deactivate_slot(
  self : GpuComponentStore,
  index : Int,
) -> Unit {
  if index < 0 ||
    index >= self.active_flags.length() ||
    !self.active_flags[index] {
    return
  }
  let pos = self.active_positions[index]
  let last_pos = self.active_indices.length() - 1
  let last_index = self.active_indices[last_pos]
  if pos != last_pos {
    self.active_indices[pos] = last_index
    self.active_positions[last_index] = pos
  }
  let _ = self.active_indices.pop()
  self.active_flags[index] = false
  self.active_positions[index] = -1
}

///|
/// Queues a contiguous dirty range without expanding it into one index per entity.
#cfg(target="js")
extern "js" fn GpuComponentStore::mark_dirty_range_js(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> Unit =
  #| (store, first, last) => {
  #|   if (first < 0 || last < first) return;
  #|   const ranges = store.__rhodonite_dirty_ranges ||
  #|     (store.__rhodonite_dirty_ranges = []);
  #|   const prev = ranges[ranges.length - 1];
  #|   if (prev && first <= prev.last + 1) {
  #|     if (last > prev.last) prev.last = last;
  #|   } else {
  #|     ranges.push({ first, last });
  #|   }
  #| }

///|
/// Queues a contiguous dirty range without expanding it into one index per entity.
#cfg(target="js")
fn GpuComponentStore::mark_dirty_range(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> Unit {
  self.mark_dirty_range_js(first, last)
}

///|
/// Queues a contiguous dirty range without expanding it into one index per entity.
#cfg(not(target="js"))
fn GpuComponentStore::mark_dirty_range(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> Unit {
  if first < 0 || last < first {
    return
  }
  let n = self.dirty_range_first.length()
  if n > 0 && first <= self.dirty_range_last[n - 1] + 1 {
    if last > self.dirty_range_last[n - 1] {
      self.dirty_range_last[n - 1] = last
    }
  } else {
    self.dirty_range_first.push(first)
    self.dirty_range_last.push(last)
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
/// Borrows a contiguous mutable GPU component range and marks it dirty as one range.
fn GpuComponentStore::mut_range(
  self : GpuComponentStore,
  first_entity_index : Int,
  count : Int,
  write : (GpuComponentWriteRange) -> Unit,
) -> Unit {
  if count <= 0 {
    return
  }
  let _ = self.ensure_capacity(first_entity_index + count)
  let start = first_entity_index * self.stride
  let end = start + count * self.stride
  write({
    bytes: self.bytes.mut_view(start~, end~),
    stride: self.stride,
    first_entity_index,
    count,
  })
  self.mark_dirty_range(first_entity_index, first_entity_index + count - 1)
}

///|
pub fn GpuComponentWriteRange::bytes(
  self : GpuComponentWriteRange,
) -> MutArrayView[Byte] {
  self.bytes
}

///|
pub fn GpuComponentWriteRange::stride(self : GpuComponentWriteRange) -> Int {
  self.stride
}

///|
pub fn GpuComponentWriteRange::first_entity_index(
  self : GpuComponentWriteRange,
) -> Int {
  self.first_entity_index
}

///|
pub fn GpuComponentWriteRange::count(self : GpuComponentWriteRange) -> Int {
  self.count
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
#cfg(not(target="js"))
fn swap_int_array(arr : Array[Int], i : Int, j : Int) -> Unit {
  let t = arr[i]
  arr[i] = arr[j]
  arr[j] = t
}

///|
/// Max-heap sink for indices `[0, heap_size)` (0-based indexing).
#cfg(not(target="js"))
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
#cfg(not(target="js"))
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
/// Sorts `dirty_indices` ascending in place. Uses counting sort when the index span is dense (typical
/// for full-GPU flushes like [`World::update_global_transforms_from_transforms`]); falls back to
/// heap sort for sparse index sets.
#cfg(not(target="js"))
fn GpuComponentStore::sort_dirty_indices_for_drain(
  self : GpuComponentStore,
) -> Unit {
  let n = self.dirty_indices.length()
  if n <= 1 {
    return
  }
  let mut min_v = self.dirty_indices[0]
  let mut max_v = self.dirty_indices[0]
  for i = 1; i < n; i = i + 1 {
    let v = self.dirty_indices[i]
    if v < min_v {
      min_v = v
    }
    if v > max_v {
      max_v = v
    }
  }
  let span = max_v - min_v + 1
  let use_counting = span <= n * 32 && span <= 1_000_000
  if !use_counting {
    heap_sort_ints_asc(self.dirty_indices)
    return
  }
  while self.sort_bucket.length() < span {
    self.sort_bucket.push(false)
  }
  for k = 0; k < span; k = k + 1 {
    self.sort_bucket[k] = false
  }
  for i = 0; i < n; i = i + 1 {
    let v = self.dirty_indices[i]
    self.sort_bucket[v - min_v] = true
  }
  let mut w = 0
  for k = 0; k < span; k = k + 1 {
    if self.sort_bucket[k] {
      self.dirty_indices[w] = min_v + k
      w = w + 1
    }
  }
  if w != n {
    heap_sort_ints_asc(self.dirty_indices)
  }
}

///|
/// Sorts and merges dirty ranges so drain cursors can skip overlaps in one forward pass.
#cfg(not(target="js"))
fn GpuComponentStore::sort_dirty_ranges_for_drain(
  self : GpuComponentStore,
) -> Unit {
  let n = self.dirty_range_first.length()
  if n <= 1 {
    return
  }
  for i = 1; i < n; i = i + 1 {
    let first = self.dirty_range_first[i]
    let last = self.dirty_range_last[i]
    let mut j = i - 1
    while j >= 0 && self.dirty_range_first[j] > first {
      self.dirty_range_first[j + 1] = self.dirty_range_first[j]
      self.dirty_range_last[j + 1] = self.dirty_range_last[j]
      j = j - 1
    }
    self.dirty_range_first[j + 1] = first
    self.dirty_range_last[j + 1] = last
  }
  let mut write = 0
  for i = 1; i < n; i = i + 1 {
    let first = self.dirty_range_first[i]
    let last = self.dirty_range_last[i]
    if first <= self.dirty_range_last[write] + 1 {
      if last > self.dirty_range_last[write] {
        self.dirty_range_last[write] = last
      }
    } else {
      write = write + 1
      self.dirty_range_first[write] = first
      self.dirty_range_last[write] = last
    }
  }
  while self.dirty_range_first.length() > write + 1 {
    let _ = self.dirty_range_first.pop()
    let _ = self.dirty_range_last.pop()
  }
}

///|
/// Copies bytes for entity indices `[first..=last]` into one payload; `byte_offset` is `first * stride`.
#cfg(not(target="js"))
fn GpuComponentStore::range_bytes(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> GpuWrite {
  let count = last - first + 1
  let len = count * self.stride
  let out = FixedArray::make(len, (0 : Byte))
  let src_base = first * self.stride
  let mut i = 0
  while i < len {
    out[i] = self.bytes[src_base + i]
    i = i + 1
  }
  { byte_offset: src_base, bytes: out }
}

///|
/// Borrows bytes for entity indices `[first..=last]`; `byte_offset` is `first * stride`.
#cfg(not(target="js"))
fn GpuComponentStore::range_view(
  self : GpuComponentStore,
  first : Int,
  last : Int,
) -> GpuWriteView {
  let start = first * self.stride
  let end = (last + 1) * self.stride
  { byte_offset: start, bytes: self.bytes[start:end] }
}

///|
/// Installs the shared JS dirty-span drain helper used by owned and borrowed drain paths.
#cfg(target="js")
extern "js" fn ensure_gpu_store_drain_spans_js() -> Unit =
  #| () => {
  #|   if (globalThis.__rhodonite_drain_gpu_store_write_spans) return;
  #|   globalThis.__rhodonite_drain_gpu_store_write_spans = (store, makeBytes) => {
  #|       const dirty = store.dirty_indices;
  #|       const pendingRanges = store.__rhodonite_dirty_ranges || [];
  #|       if (dirty.length === 0 && pendingRanges.length === 0) return [];
  #|       let sorted = true;
  #|       for (let i = 1; i < dirty.length; i++) {
  #|         if (dirty[i] < dirty[i - 1]) {
  #|           sorted = false;
  #|           break;
  #|         }
  #|       }
  #|       if (!sorted) dirty.sort((a, b) => a - b);
  #|       const stride = store.stride;
  #|       const writes = [];
  #|       const mergedRanges = [];
  #|       if (pendingRanges.length > 0) {
  #|         pendingRanges.sort((a, b) => a.first - b.first);
  #|         for (let i = 0; i < pendingRanges.length; i++) {
  #|           const r = pendingRanges[i];
  #|           const first = r.first | 0;
  #|           const last = r.last | 0;
  #|           if (last < first) continue;
  #|           const prev = mergedRanges[mergedRanges.length - 1];
  #|           if (prev && first <= prev.last + 1) {
  #|             if (last > prev.last) prev.last = last;
  #|           } else {
  #|             mergedRanges.push({ first, last });
  #|           }
  #|         }
  #|         pendingRanges.length = 0;
  #|       }
  #|       const pushSpan = (first, last) => {
  #|         writes.push({ byte_offset: first * stride, bytes: makeBytes(first, last) });
  #|       };
  #|       for (let i = 0; i < mergedRanges.length; i++) {
  #|         const r = mergedRanges[i];
  #|         pushSpan(r.first, r.last);
  #|       }
  #|       let rangeCursor = 0;
  #|       const pushDirtyRunOutsidePendingRanges = (first, last) => {
  #|         let cur = first;
  #|         while (cur <= last) {
  #|           while (rangeCursor < mergedRanges.length && mergedRanges[rangeCursor].last < cur) {
  #|             rangeCursor++;
  #|           }
  #|           if (rangeCursor >= mergedRanges.length || mergedRanges[rangeCursor].first > last) {
  #|             pushSpan(cur, last);
  #|             break;
  #|           }
  #|           const r = mergedRanges[rangeCursor];
  #|           if (r.first > cur) {
  #|             pushSpan(cur, Math.min(last, r.first - 1));
  #|           }
  #|           cur = Math.max(cur, r.last + 1);
  #|         }
  #|       };
  #|       if (dirty.length > 0) {
  #|         let first = dirty[0];
  #|         let prev = dirty[0];
  #|         for (let i = 1; i < dirty.length; i++) {
  #|           const idx = dirty[i];
  #|           if (idx === prev) continue;
  #|           if (idx === prev + 1) {
  #|             prev = idx;
  #|           } else {
  #|             pushDirtyRunOutsidePendingRanges(first, prev);
  #|             first = idx;
  #|             prev = idx;
  #|           }
  #|         }
  #|         pushDirtyRunOutsidePendingRanges(first, prev);
  #|         for (let i = 0; i < dirty.length; i++) {
  #|           store.dirty_flags[dirty[i]] = false;
  #|         }
  #|       }
  #|       dirty.length = 0;
  #|       return writes;
  #|     };
  #| }

///|
/// Sorts dirty indices, merges consecutive runs into minimal `GpuWrite` spans, then clears dirty state.
#cfg(target="js")
extern "js" fn GpuComponentStore::drain_writes_js(
  self : GpuComponentStore,
) -> Array[GpuWrite] =
  #| (store) => {
  #|   const stride = store.stride;
  #|   const src = store.bytes;
  #|   const rangeBytes = (first, last) => {
  #|     const start = first * stride;
  #|     const len = (last - first + 1) * stride;
  #|     if (ArrayBuffer.isView(src) && typeof src.slice === "function") {
  #|       return src.slice(start, start + len);
  #|     }
  #|     const out = new Uint8Array(len);
  #|     out.set(src.slice(start, start + len));
  #|     return out;
  #|   };
  #|   const drainSpans = globalThis.__rhodonite_drain_gpu_store_write_spans;
  #|   return drainSpans(store, rangeBytes);
  #| }

///|
/// Sorts dirty indices, merges consecutive runs into minimal `GpuWrite` spans, then clears dirty state.
#cfg(target="js")
fn GpuComponentStore::drain_writes(self : GpuComponentStore) -> Array[GpuWrite] {
  ensure_gpu_store_drain_spans_js()
  self.drain_writes_js()
}

///|
/// Drains dirty spans once and delegates payload construction to `push_span`.
#cfg(not(target="js"))
fn GpuComponentStore::drain_write_spans(
  self : GpuComponentStore,
  push_span : (Int, Int) -> Unit,
) -> Unit {
  if self.dirty_indices.length() == 0 && self.dirty_range_first.length() == 0 {
    return
  }
  self.sort_dirty_ranges_for_drain()
  for ri = 0; ri < self.dirty_range_first.length(); ri = ri + 1 {
    push_span(self.dirty_range_first[ri], self.dirty_range_last[ri])
  }
  if self.dirty_indices.length() > 0 {
    self.sort_dirty_indices_for_drain()
    let sorted = self.dirty_indices
    let mut first = sorted[0]
    let mut prev = sorted[0]
    let mut range_cursor = 0
    let push_run = fn(first : Int, last : Int) {
      let mut cur = first
      while cur <= last {
        while range_cursor < self.dirty_range_first.length() &&
              self.dirty_range_last[range_cursor] < cur {
          range_cursor = range_cursor + 1
        }
        if range_cursor >= self.dirty_range_first.length() ||
          self.dirty_range_first[range_cursor] > last {
          push_span(cur, last)
          return
        }
        let rf = self.dirty_range_first[range_cursor]
        let rl = self.dirty_range_last[range_cursor]
        if rf > cur {
          let emit_last = if rf - 1 < last { rf - 1 } else { last }
          push_span(cur, emit_last)
        }
        cur = if rl + 1 > cur { rl + 1 } else { cur + 1 }
      }
    }
    for i = 1; i < sorted.length(); i = i + 1 {
      let idx = sorted[i]
      if idx == prev + 1 {
        prev = idx
      } else {
        push_run(first, prev)
        first = idx
        prev = idx
      }
    }
    push_run(first, prev)
    for i = 0; i < self.dirty_indices.length(); i = i + 1 {
      self.dirty_flags[self.dirty_indices[i]] = false
    }
  }
  while self.dirty_indices.length() > 0 {
    let _ = self.dirty_indices.pop()
  }
  while self.dirty_range_first.length() > 0 {
    let _ = self.dirty_range_first.pop()
  }
  while self.dirty_range_last.length() > 0 {
    let _ = self.dirty_range_last.pop()
  }
}

///|
/// Sorts dirty indices, merges consecutive runs into minimal `GpuWrite` spans, then clears dirty state.
#cfg(not(target="js"))
fn GpuComponentStore::drain_writes(self : GpuComponentStore) -> Array[GpuWrite] {
  let writes : Array[GpuWrite] = []
  self.drain_write_spans(fn(first, last) {
    writes.push(self.range_bytes(first, last))
  })
  writes
}

///|
/// Sorts dirty indices, merges consecutive runs into borrowed `GpuWriteView` spans, then clears dirty state.
#cfg(target="js")
extern "js" fn GpuComponentStore::drain_write_views_js(
  self : GpuComponentStore,
) -> Array[GpuWriteView] =
  #| (store) => {
  #|   const stride = store.stride;
  #|   const src = store.bytes;
  #|   const rangeView = (first, last) => {
  #|     const start = first * stride;
  #|     const end = (last + 1) * stride;
  #|     return { buf: src, start, end };
  #|   };
  #|   const drainSpans = globalThis.__rhodonite_drain_gpu_store_write_spans;
  #|   return drainSpans(store, rangeView);
  #| }

///|
/// Sorts dirty indices, merges consecutive runs into borrowed `GpuWriteView` spans, then clears dirty state.
#cfg(target="js")
fn GpuComponentStore::drain_write_views(
  self : GpuComponentStore,
) -> Array[GpuWriteView] {
  ensure_gpu_store_drain_spans_js()
  self.drain_write_views_js()
}

///|
/// Sorts dirty indices, merges consecutive runs into borrowed `GpuWriteView` spans, then clears dirty state.
#cfg(not(target="js"))
fn GpuComponentStore::drain_write_views(
  self : GpuComponentStore,
) -> Array[GpuWriteView] {
  let writes : Array[GpuWriteView] = []
  self.drain_write_spans(fn(first, last) {
    writes.push(self.range_view(first, last))
  })
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
  let archetypes : Array[Int] = []
  self.component_archetypes.push(archetypes)
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
  let archetypes : Array[Int] = []
  self.component_archetypes.push(archetypes)
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
          required_capacity: store.capacity(),
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
        store.deactivate_slot(entity_index)
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
/// Returns borrowed batched byte slices suitable for immediate GPU upload; consumes pending dirties for this component.
pub fn World::drain_gpu_write_views(
  self : World,
  component : ComponentTypeId,
) -> Array[GpuWriteView] {
  self.assert_system_component_write(component, "World::drain_gpu_write_views")
  match self.gpu_store(component) {
    Some(store) => {
      let writes = store.drain_write_views()
      self.replace_gpu_store(store)
      writes
    }
    None => []
  }
}

///|
/// Borrows a contiguous GPU-visible component range for bulk writes and marks it dirty once.
pub fn World::with_gpu_component_write_range(
  self : World,
  component : ComponentTypeId,
  first_entity_index : Int,
  count : Int,
  write : (GpuComponentWriteRange) -> Unit,
) -> Bool {
  self.assert_system_component_write(
    component, "World::with_gpu_component_write_range",
  )
  if first_entity_index < 0 || count < 0 {
    return false
  }
  if count == 0 {
    return true
  }
  match self.registry.get(component) {
    Some(rc) =>
      match rc.kind {
        CpuOnly => false
        GpuVisible =>
          match
            self.ensure_gpu_store_capacity(
              component,
              first_entity_index + count,
            ) {
            Some(store) => {
              self.query_depth = self.query_depth + 1
              store.mut_range(first_entity_index, count, write)
              self.query_depth = self.query_depth - 1
              self.replace_gpu_store(store)
              true
            }
            None => false
          }
      }
    None => false
  }
}

///|
/// Returns the packed active entity indices for a GPU-visible component.
///
/// The returned array is a copy; callers can sort or retain it without affecting storage.
pub fn World::gpu_component_active_indices(
  self : World,
  component : ComponentTypeId,
) -> Array[Int] {
  self.assert_system_component_read(
    component, "World::gpu_component_active_indices",
  )
  match self.gpu_store(component) {
    Some(store) => {
      let out : Array[Int] = []
      for i = 0; i < store.active_indices.length(); i = i + 1 {
        out.push(store.active_indices[i])
      }
      out
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
