///|
fn GlobalTransformBlobStore::new() -> GlobalTransformBlobStore {
  {
    bytes: FixedArray::make(0, (0 : Byte)),
    next_word_offset: 0,
    free_f16_offsets: [],
    free_f32_offsets: [],
    dirty_word_first: [],
    dirty_word_last: [],
    resize_events: [],
  }
}

///|
fn GlobalTransformBlobStore::word_capacity(
  self : GlobalTransformBlobStore,
) -> Int {
  self.bytes.length() / 4
}

///|
fn GlobalTransformBlobStore::ensure_word_capacity(
  self : GlobalTransformBlobStore,
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
fn GlobalTransformBlobStore::mark_dirty_words(
  self : GlobalTransformBlobStore,
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
fn GlobalTransformBlobStore::alloc(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
) -> Int {
  match format {
    Affine3x4F16 =>
      if self.free_f16_offsets.length() > 0 {
        let last = self.free_f16_offsets.length() - 1
        let off = self.free_f16_offsets[last]
        let _ = self.free_f16_offsets.pop()
        return off
      }
    Affine3x4F32 =>
      if self.free_f32_offsets.length() > 0 {
        let last = self.free_f32_offsets.length() - 1
        let off = self.free_f32_offsets[last]
        let _ = self.free_f32_offsets.pop()
        return off
      }
  }
  let words = @comp.global_transform_word_count(format)
  let off = self.next_word_offset
  self.ensure_word_capacity(off + words)
  self.next_word_offset = off + words
  off
}

///|
fn GlobalTransformBlobStore::free(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
) -> Unit {
  if word_offset < 0 {
    return
  }
  match format {
    Affine3x4F16 => self.free_f16_offsets.push(word_offset)
    Affine3x4F32 => self.free_f32_offsets.push(word_offset)
  }
}

///|
fn GlobalTransformBlobStore::write_matrix(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
  matrix : @m44.Matrix44F,
) -> Unit {
  let words = @comp.global_transform_word_count(format)
  self.ensure_word_capacity(word_offset + words)
  @comp.matrix44f_write_global_transform_to_word_blob(
    matrix,
    self.bytes.mut_view(start=0, end=self.bytes.length()),
    word_offset,
    format,
  )
  self.mark_dirty_words(word_offset, words)
}

///|
fn GlobalTransformBlobStore::read_matrix(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
) -> @m44.Matrix44F {
  @comp.matrix44f_from_global_transform_word_blob(
    self.bytes,
    word_offset,
    format,
  )
}

///|
fn GlobalTransformBlobStore::write_word_range_views(
  self : GlobalTransformBlobStore,
  first_word : Int,
  word_count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  if first_word < 0 || word_count < 0 {
    abort("GlobalTransformBlobStore::write_word_range_views: invalid range")
  }
  self.ensure_word_capacity(first_word + word_count)
  let start = first_word * 4
  let end = start + word_count * 4
  write(self.bytes.mut_view(start~, end~))
  self.mark_dirty_words(first_word, word_count)
  self.drain_write_views()
}

///|
fn GlobalTransformBlobStore::drain_write_views(
  self : GlobalTransformBlobStore,
) -> Array[GpuWriteView] {
  let writes : Array[GpuWriteView] = []
  for i = 0; i < self.dirty_word_first.length(); i = i + 1 {
    let start = self.dirty_word_first[i] * 4
    let end = (self.dirty_word_last[i] + 1) * 4
    writes.push({ byte_offset: start, bytes: self.bytes[start:end] })
  }
  while self.dirty_word_first.length() > 0 {
    let _ = self.dirty_word_first.pop()
  }
  while self.dirty_word_last.length() > 0 {
    let _ = self.dirty_word_last.pop()
  }
  writes
}

///|
fn GlobalTransformBlobStore::drain_writes(
  self : GlobalTransformBlobStore,
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
  while self.dirty_word_first.length() > 0 {
    let _ = self.dirty_word_first.pop()
  }
  while self.dirty_word_last.length() > 0 {
    let _ = self.dirty_word_last.pop()
  }
  writes
}

///|
fn GlobalTransformBlobStore::drain_resize_events(
  self : GlobalTransformBlobStore,
) -> Array[GlobalTransformBlobResizeEvent] {
  let out : Array[GlobalTransformBlobResizeEvent] = []
  for i = 0; i < self.resize_events.length(); i = i + 1 {
    out.push(self.resize_events[i])
  }
  while self.resize_events.length() > 0 {
    let _ = self.resize_events.pop()
  }
  out
}
