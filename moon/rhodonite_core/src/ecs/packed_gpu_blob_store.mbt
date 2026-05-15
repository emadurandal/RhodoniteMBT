///|
fn PackedGpuBlobStore::new() -> PackedGpuBlobStore {
  {
    bytes: FixedArray::make(0, (0 : Byte)),
    next_word_offset: 0,
    free_word_offsets: [],
    free_word_counts: [],
    dirty_word_first: [],
    dirty_word_last: [],
    resize_events: [],
  }
}

///|
fn PackedGpuBlobStore::word_capacity(self : PackedGpuBlobStore) -> Int {
  self.bytes.length() / 4
}

///|
fn PackedGpuBlobStore::ensure_word_capacity(
  self : PackedGpuBlobStore,
  required_words : Int,
) -> Unit {
  if required_words <= self.word_capacity() {
    return
  }
  let old_byte_len = self.bytes.length()
  let old_words = self.word_capacity()
  let mut next_words = if old_words > 0 {
    old_words * 2
  } else {
    required_words
  }
  while next_words < required_words {
    next_words = next_words * 2
  }
  let next_bytes = FixedArray::make(next_words * 4, (0 : Byte))
  for i = 0; i < old_byte_len; i = i + 1 {
    next_bytes[i] = self.bytes[i]
  }
  self.bytes = next_bytes
  self.resize_events.push({
    required_word_capacity: next_words,
    needs_full_upload: true,
  })
}

///|
fn PackedGpuBlobStore::mark_dirty_words(
  self : PackedGpuBlobStore,
  first : Int,
  count : Int,
) -> Unit {
  if first < 0 || count <= 0 {
    return
  }
  let last = first + count - 1
  let n = self.dirty_word_first.length()
  if n > 0 &&
    first <= self.dirty_word_last[n - 1] + 1 &&
    last >= self.dirty_word_first[n - 1] - 1 {
    if first < self.dirty_word_first[n - 1] {
      self.dirty_word_first[n - 1] = first
    }
    if last > self.dirty_word_last[n - 1] {
      self.dirty_word_last[n - 1] = last
    }
  } else {
    self.dirty_word_first.push(first)
    self.dirty_word_last.push(last)
  }
}

///|
fn PackedGpuBlobStore::alloc_words(
  self : PackedGpuBlobStore,
  word_count : Int,
) -> Int {
  if word_count <= 0 {
    abort("PackedGpuBlobStore::alloc_words: word_count must be positive")
  }
  for i = 0; i < self.free_word_counts.length(); i = i + 1 {
    if self.free_word_counts[i] == word_count {
      let off = self.free_word_offsets[i]
      let last = self.free_word_counts.length() - 1
      self.free_word_offsets[i] = self.free_word_offsets[last]
      self.free_word_counts[i] = self.free_word_counts[last]
      let _ = self.free_word_offsets.pop()
      let _ = self.free_word_counts.pop()
      self.ensure_word_capacity(off + word_count)
      return off
    }
  }
  let off = self.next_word_offset
  self.ensure_word_capacity(off + word_count)
  self.next_word_offset = off + word_count
  off
}

///|
fn PackedGpuBlobStore::free_words(
  self : PackedGpuBlobStore,
  word_offset : Int,
  word_count : Int,
) -> Unit {
  if word_offset < 0 || word_count <= 0 {
    return
  }
  self.free_word_offsets.push(word_offset)
  self.free_word_counts.push(word_count)
}

///|
fn PackedGpuBlobStore::clear_words(
  self : PackedGpuBlobStore,
  word_offset : Int,
  word_count : Int,
) -> Unit {
  if word_offset < 0 || word_count <= 0 {
    return
  }
  self.ensure_word_capacity(word_offset + word_count)
  let start = word_offset * 4
  let end = start + word_count * 4
  for i = start; i < end; i = i + 1 {
    self.bytes[i] = (0 : Byte)
  }
  self.mark_dirty_words(word_offset, word_count)
}

///|
fn PackedGpuBlobStore::write_words(
  self : PackedGpuBlobStore,
  word_offset : Int,
  word_count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  if word_offset < 0 || word_count < 0 {
    abort("PackedGpuBlobStore::write_words: invalid range")
  }
  self.ensure_word_capacity(word_offset + word_count)
  let start = word_offset * 4
  let end = start + word_count * 4
  write(self.bytes.mut_view(start~, end~))
  self.mark_dirty_words(word_offset, word_count)
}

///|
fn PackedGpuBlobStore::read_words(
  self : PackedGpuBlobStore,
  word_offset : Int,
  word_count : Int,
) -> FixedArray[Byte]? {
  if word_offset < 0 ||
    word_count < 0 ||
    word_offset + word_count > self.word_capacity() {
    None
  } else {
    Some(copy_fixed_range_to_fixed(self.bytes, word_offset * 4, word_count * 4))
  }
}

///|
fn PackedGpuBlobStore::write_word_range_views(
  self : PackedGpuBlobStore,
  first_word : Int,
  word_count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  self.write_words(first_word, word_count, write)
  self.drain_write_views()
}

///|
fn PackedGpuBlobStore::drain_write_views(
  self : PackedGpuBlobStore,
) -> Array[GpuWriteView] {
  let writes : Array[GpuWriteView] = []
  for i = 0; i < self.dirty_word_first.length(); i = i + 1 {
    let start = self.dirty_word_first[i] * 4
    let end = (self.dirty_word_last[i] + 1) * 4
    writes.push({ byte_offset: start, bytes: self.bytes[start:end] })
  }
  self.dirty_word_first.clear()
  self.dirty_word_last.clear()
  writes
}

///|
fn PackedGpuBlobStore::drain_writes(
  self : PackedGpuBlobStore,
) -> Array[GpuWrite] {
  let writes : Array[GpuWrite] = []
  for i = 0; i < self.dirty_word_first.length(); i = i + 1 {
    let start = self.dirty_word_first[i] * 4
    let end = (self.dirty_word_last[i] + 1) * 4
    writes.push({
      byte_offset: start,
      bytes: copy_fixed_range_to_fixed(self.bytes, start, end - start),
    })
  }
  self.dirty_word_first.clear()
  self.dirty_word_last.clear()
  writes
}

///|
fn PackedGpuBlobStore::drain_resize_events(
  self : PackedGpuBlobStore,
) -> Array[GlobalTransformBlobResizeEvent] {
  let out : Array[GlobalTransformBlobResizeEvent] = []
  for i = 0; i < self.resize_events.length(); i = i + 1 {
    out.push(self.resize_events[i])
  }
  self.resize_events.clear()
  out
}
