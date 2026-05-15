///|
fn CameraBlobStore::new() -> CameraBlobStore {
  {
    bytes: FixedArray::make(0, (0 : Byte)),
    next_word_offset: 0,
    free_offsets: [],
    dirty_word_first: [],
    dirty_word_last: [],
    resize_events: [],
  }
}

///|
fn CameraBlobStore::word_capacity(self : CameraBlobStore) -> Int {
  self.bytes.length() / 4
}

///|
fn CameraBlobStore::ensure_word_capacity(
  self : CameraBlobStore,
  required_words : Int,
) -> Unit {
  if required_words <= self.word_capacity() {
    return
  }
  let old_words = self.word_capacity()
  let mut next_words = if old_words > 0 { old_words * 2 } else { 72 }
  while next_words < required_words {
    next_words = next_words * 2
  }
  let next_bytes = FixedArray::make(next_words * 4, (0 : Byte))
  for i = 0; i < self.bytes.length(); i = i + 1 {
    next_bytes[i] = self.bytes[i]
  }
  self.bytes = next_bytes
  self.resize_events.push({
    required_word_capacity: next_words,
    needs_full_upload: true,
  })
}

///|
fn CameraBlobStore::mark_dirty_words(
  self : CameraBlobStore,
  first_word : Int,
  word_count : Int,
) -> Unit {
  if word_count <= 0 {
    return
  }
  self.dirty_word_first.push(first_word)
  self.dirty_word_last.push(first_word + word_count - 1)
}

///|
fn CameraBlobStore::alloc(self : CameraBlobStore) -> Int {
  if self.free_offsets.length() > 0 {
    let last = self.free_offsets.length() - 1
    let offset = self.free_offsets[last]
    let _ = self.free_offsets.pop()
    self.ensure_word_capacity(offset + @comp.camera_gpu_word_count())
    offset
  } else {
    let offset = self.next_word_offset
    self.next_word_offset = self.next_word_offset +
      @comp.camera_gpu_word_count()
    self.ensure_word_capacity(self.next_word_offset)
    offset
  }
}

///|
fn CameraBlobStore::free(self : CameraBlobStore, word_offset : Int) -> Unit {
  if word_offset < 0 {
    return
  }
  self.ensure_word_capacity(word_offset + @comp.camera_gpu_word_count())
  let byte_first = word_offset * 4
  let byte_last = byte_first + @comp.camera_gpu_byte_stride()
  for i = byte_first; i < byte_last; i = i + 1 {
    self.bytes[i] = (0 : Byte)
  }
  self.mark_dirty_words(word_offset, @comp.camera_gpu_word_count())
  self.free_offsets.push(word_offset)
}

///|
fn CameraBlobStore::write_matrices(
  self : CameraBlobStore,
  word_offset : Int,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Unit {
  self.ensure_word_capacity(word_offset + @comp.camera_gpu_word_count())
  let byte_first = word_offset * 4
  @comp.camera_write_gpu_row(
    self.bytes.mut_view(
      start=byte_first,
      end=byte_first + @comp.camera_gpu_byte_stride(),
    ),
    view,
    proj,
    near,
    far,
    aspect,
    projection_kind,
    flags,
  )
  self.mark_dirty_words(word_offset, @comp.camera_gpu_word_count())
}

///|
fn CameraBlobStore::read_row(
  self : CameraBlobStore,
  word_offset : Int,
) -> FixedArray[Byte]? {
  if word_offset < 0 ||
    word_offset + @comp.camera_gpu_word_count() > self.word_capacity() {
    None
  } else {
    Some(
      copy_fixed_range_to_fixed(
        self.bytes,
        word_offset * 4,
        @comp.camera_gpu_byte_stride(),
      ),
    )
  }
}

///|
fn CameraBlobStore::drain_write_views(
  self : CameraBlobStore,
) -> Array[GpuWriteView] {
  let writes : Array[GpuWriteView] = []
  for i = 0; i < self.dirty_word_first.length(); i = i + 1 {
    let first = self.dirty_word_first[i]
    let last = self.dirty_word_last[i]
    writes.push({
      byte_offset: first * 4,
      bytes: self.bytes[first * 4:(last + 1) * 4],
    })
  }
  self.dirty_word_first.clear()
  self.dirty_word_last.clear()
  writes
}

///|
fn CameraBlobStore::drain_resize_events(
  self : CameraBlobStore,
) -> Array[GlobalTransformBlobResizeEvent] {
  let out : Array[GlobalTransformBlobResizeEvent] = []
  for i = 0; i < self.resize_events.length(); i = i + 1 {
    out.push(self.resize_events[i])
  }
  self.resize_events.clear()
  out
}
