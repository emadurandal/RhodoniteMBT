/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `CameraBlobStore::new`.
#cfg(target="js")
fn CameraBlobStore::new() -> CameraBlobStore {
  { store: PackedGpuBlobStore::new() }
}

///|
/// Implements `CameraBlobStore::new`.
#cfg(not(target="js"))
fn CameraBlobStore::new() -> CameraBlobStore {
  {
    store: PackedGpuBlobStore::new(),
    cache_valid: [],
    cache_word_offsets: [],
    cache_words: [],
  }
}

///|
/// Implements `camera_input_cache_word_count`.
#cfg(not(target="js"))
fn camera_input_cache_word_count() -> Int {
  37
}

///|
/// Implements `camera_input_cache_slot`.
#cfg(not(target="js"))
fn camera_input_cache_slot(word_offset : Int) -> Int {
  word_offset / @comp.camera_gpu_word_count()
}

///|
/// Ensures the Camera input cache has storage for `slot`.
#cfg(not(target="js"))
fn CameraBlobStore::ensure_cache_slot(
  self : CameraBlobStore,
  slot : Int,
) -> Unit {
  while self.cache_valid.length() <= slot {
    self.cache_valid.push(false)
    self.cache_word_offsets.push(-1)
    self.cache_words.push(FixedArray::make(camera_input_cache_word_count(), 0U))
  }
}

///|
/// Reports whether cache slot data belongs to `word_offset`.
#cfg(not(target="js"))
fn CameraBlobStore::cache_slot_valid(
  self : CameraBlobStore,
  slot : Int,
  word_offset : Int,
) -> Bool {
  slot >= 0 &&
  slot < self.cache_valid.length() &&
  self.cache_valid[slot] &&
  self.cache_word_offsets[slot] == word_offset
}

///|
/// Invalidates the cached Camera inputs for a blob row.
#cfg(not(target="js"))
fn CameraBlobStore::invalidate_cache(
  self : CameraBlobStore,
  word_offset : Int,
) -> Unit {
  if word_offset < 0 {
    return
  }
  let slot = camera_input_cache_slot(word_offset)
  if slot >= 0 && slot < self.cache_valid.length() {
    self.cache_valid[slot] = false
    self.cache_word_offsets[slot] = -1
  }
}

///|
/// Ignores Camera input cache invalidation on targets without a cache.
#cfg(target="js")
fn CameraBlobStore::invalidate_cache(
  self : CameraBlobStore,
  word_offset : Int,
) -> Unit {
  ignore(self)
  ignore(word_offset)
}

///|
/// Writes one matrix into a Camera input cache word range.
#cfg(not(target="js"))
fn camera_cache_write_matrix(
  words : FixedArray[UInt],
  first : Int,
  matrix : @m44.Matrix44F,
) -> Unit {
  let d = matrix.data
  for i = 0; i < 16; i = i + 1 {
    words[first + i] = d[i].reinterpret_as_uint()
  }
}

///|
/// Updates the cached Camera inputs from caller-provided values.
#cfg(not(target="js"))
fn CameraBlobStore::write_cache_inputs(
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
  if word_offset < 0 {
    return
  }
  let slot = camera_input_cache_slot(word_offset)
  self.ensure_cache_slot(slot)
  let words = self.cache_words[slot]
  camera_cache_write_matrix(words, 0, view)
  camera_cache_write_matrix(words, 16, proj)
  words[32] = near.reinterpret_as_uint()
  words[33] = far.reinterpret_as_uint()
  words[34] = aspect.reinterpret_as_uint()
  words[35] = projection_kind.reinterpret_as_uint()
  words[36] = flags.reinterpret_as_uint()
  self.cache_word_offsets[slot] = word_offset
  self.cache_valid[slot] = true
}

///|
/// Discards Camera input cache updates on targets where cache lookup is not a win.
#cfg(target="js")
fn CameraBlobStore::write_cache_inputs(
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
  ignore(self)
  ignore(word_offset)
  ignore(view)
  ignore(proj)
  ignore(near)
  ignore(far)
  ignore(aspect)
  ignore(projection_kind)
  ignore(flags)
}

///|
/// Updates the cached Camera inputs from a full Camera GPU row.
#cfg(not(target="js"))
fn CameraBlobStore::refresh_cache_from_row_bytes(
  self : CameraBlobStore,
  word_offset : Int,
  bytes : FixedArray[Byte],
) -> Unit {
  if bytes.length() != @comp.camera_gpu_byte_stride() || word_offset < 0 {
    self.invalidate_cache(word_offset)
    return
  }
  let slot = camera_input_cache_slot(word_offset)
  self.ensure_cache_slot(slot)
  let words = self.cache_words[slot]
  for i = 0; i < 16; i = i + 1 {
    words[i] = @writes.get_u32_le(bytes, 64 + i * 4)
    words[16 + i] = @writes.get_u32_le(bytes, 128 + i * 4)
  }
  words[32] = @writes.get_u32_le(bytes, 268)
  words[33] = @writes.get_u32_le(bytes, 272)
  words[34] = @writes.get_u32_le(bytes, 276)
  words[35] = @writes.get_u32_le(bytes, 280)
  words[36] = @writes.get_u32_le(bytes, 284)
  self.cache_word_offsets[slot] = word_offset
  self.cache_valid[slot] = true
}

///|
/// Skips Camera input cache refresh on targets that do not use the cache.
#cfg(target="js")
fn CameraBlobStore::refresh_cache_from_row_bytes(
  self : CameraBlobStore,
  word_offset : Int,
  bytes : FixedArray[Byte],
) -> Unit {
  ignore(self)
  ignore(word_offset)
  ignore(bytes)
}

///|
/// Reports whether one cached Camera matrix equals the requested matrix.
#cfg(not(target="js"))
fn CameraBlobStore::cache_matrix_matches(
  self : CameraBlobStore,
  slot : Int,
  first : Int,
  matrix : @m44.Matrix44F,
) -> Bool {
  let words = self.cache_words[slot]
  let d = matrix.data
  for i = 0; i < 16; i = i + 1 {
    if words[first + i] != d[i].reinterpret_as_uint() {
      return false
    }
  }
  true
}

///|
/// Reports whether cached Camera view/projection inputs match requested matrices.
#cfg(not(target="js"))
fn CameraBlobStore::cache_view_proj_matches(
  self : CameraBlobStore,
  slot : Int,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
) -> Bool {
  self.cache_matrix_matches(slot, 0, view) &&
  self.cache_matrix_matches(slot, 16, proj)
}

///|
/// Returns the first and last cached scalar GPU words that differ from requested inputs.
#cfg(not(target="js"))
fn CameraBlobStore::changed_scalar_word_bounds_from_cache(
  self : CameraBlobStore,
  slot : Int,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> (Int, Int)? {
  let words = self.cache_words[slot]
  let mut first = -1
  let mut last = -1
  if words[32] != near.reinterpret_as_uint() {
    first = 67
    last = 67
  }
  if words[33] != far.reinterpret_as_uint() {
    if first < 0 {
      first = 68
    }
    last = 68
  }
  if words[34] != aspect.reinterpret_as_uint() {
    if first < 0 {
      first = 69
    }
    last = 69
  }
  if words[35] != projection_kind.reinterpret_as_uint() {
    if first < 0 {
      first = 70
    }
    last = 70
  }
  if words[36] != flags.reinterpret_as_uint() {
    if first < 0 {
      first = 71
    }
    last = 71
  }
  if first < 0 {
    None
  } else {
    Some((first, last))
  }
}

///|
/// Implements `CameraBlobStore::word_capacity`.
fn CameraBlobStore::word_capacity(self : CameraBlobStore) -> Int {
  self.store.word_capacity()
}

///|
/// Implements `CameraBlobStore::alloc`.
fn CameraBlobStore::alloc(self : CameraBlobStore) -> Int {
  self.store.alloc_words(@comp.camera_gpu_word_count())
}

///|
/// Implements `CameraBlobStore::free`.
fn CameraBlobStore::free(self : CameraBlobStore, word_offset : Int) -> Unit {
  if word_offset < 0 {
    return
  }
  self.invalidate_cache(word_offset)
  let words = @comp.camera_gpu_word_count()
  self.store.write_words(word_offset, words, fn(row) {
    for i = 0; i < row.length(); i = i + 1 {
      row[i] = (0 : Byte)
    }
  })
  self.store.free_words(word_offset, words)
}

///|
/// Implements `CameraBlobStore::write_matrices`.
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
  self.store.write_words(word_offset, @comp.camera_gpu_word_count(), fn(row) {
    @comp.camera_write_gpu_row(
      row, view, proj, near, far, aspect, projection_kind, flags,
    )
  })
  self.write_cache_inputs(
    word_offset, view, proj, near, far, aspect, projection_kind, flags,
  )
}

///|
/// Implements `CameraBlobStore::matrix_matches_std140_row`.
fn CameraBlobStore::matrix_matches_std140_row(
  self : CameraBlobStore,
  byte_offset : Int,
  matrix : @m44.Matrix44F,
) -> Bool {
  if byte_offset < 0 || byte_offset + 64 > self.store.bytes.length() {
    return false
  }
  let d = matrix.data
  for i = 0; i < 16; i = i + 1 {
    if @writes.get_u32_le(self.store.bytes, byte_offset + i * 4) !=
      d[i].reinterpret_as_uint() {
      return false
    }
  }
  true
}

///|
/// Implements `CameraBlobStore::f32_matches_row`.
fn CameraBlobStore::f32_matches_row(
  self : CameraBlobStore,
  byte_offset : Int,
  value : Float,
) -> Bool {
  if byte_offset < 0 || byte_offset + 4 > self.store.bytes.length() {
    return false
  }
  @writes.get_u32_le(self.store.bytes, byte_offset) ==
  value.reinterpret_as_uint()
}

///|
/// Returns the first and last scalar GPU words that differ from the requested Camera inputs.
fn CameraBlobStore::changed_scalar_word_bounds(
  self : CameraBlobStore,
  byte_offset : Int,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> (Int, Int)? {
  let mut first = -1
  let mut last = -1
  if !self.f32_matches_row(byte_offset + 268, near) {
    first = 67
    last = 67
  }
  if !self.f32_matches_row(byte_offset + 272, far) {
    if first < 0 {
      first = 68
    }
    last = 68
  }
  if !self.f32_matches_row(byte_offset + 276, aspect) {
    if first < 0 {
      first = 69
    }
    last = 69
  }
  if !self.f32_matches_row(byte_offset + 280, projection_kind) {
    if first < 0 {
      first = 70
    }
    last = 70
  }
  if !self.f32_matches_row(byte_offset + 284, flags) {
    if first < 0 {
      first = 71
    }
    last = 71
  }
  if first < 0 {
    None
  } else {
    Some((first, last))
  }
}

///|
/// Returns the Camera scalar value stored in a row-relative GPU word.
fn camera_scalar_value_for_word(
  word : Int,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Float {
  if word == 67 {
    near
  } else if word == 68 {
    far
  } else if word == 69 {
    aspect
  } else if word == 70 {
    projection_kind
  } else {
    flags
  }
}

///|
/// Writes a contiguous Camera scalar word range and marks only that range dirty.
fn CameraBlobStore::write_scalar_word_range(
  self : CameraBlobStore,
  word_offset : Int,
  first_word : Int,
  last_word : Int,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Unit {
  self.store.write_words(word_offset + first_word, last_word - first_word + 1, fn(
    row,
  ) {
    for word = first_word; word <= last_word; word = word + 1 {
      @comp.put_gpu_f32_mut_view(
        row,
        (word - first_word) * 4,
        camera_scalar_value_for_word(
          word, near, far, aspect, projection_kind, flags,
        ).to_double(),
      )
    }
  })
}

///|
/// Refreshes cached Camera scalar inputs after a partial scalar row write.
#cfg(not(target="js"))
fn CameraBlobStore::write_cache_scalars(
  self : CameraBlobStore,
  word_offset : Int,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Unit {
  let slot = camera_input_cache_slot(word_offset)
  if !self.cache_slot_valid(slot, word_offset) {
    return
  }
  let words = self.cache_words[slot]
  words[32] = near.reinterpret_as_uint()
  words[33] = far.reinterpret_as_uint()
  words[34] = aspect.reinterpret_as_uint()
  words[35] = projection_kind.reinterpret_as_uint()
  words[36] = flags.reinterpret_as_uint()
}

///|
/// Reports whether the stored Camera blob range is readable.
fn CameraBlobStore::valid_row_range(
  self : CameraBlobStore,
  word_offset : Int,
) -> Bool {
  let byte_offset = word_offset * 4
  word_offset >= 0 &&
  byte_offset + @comp.camera_gpu_byte_stride() <= self.store.bytes.length()
}

///|
/// Writes one Camera row only when the caller-visible Camera inputs changed.
#cfg(not(target="js"))
fn CameraBlobStore::write_matrices_if_changed(
  self : CameraBlobStore,
  word_offset : Int,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  if !self.valid_row_range(word_offset) {
    self.write_matrices(
      word_offset, view, proj, near, far, aspect, projection_kind, flags,
    )
    return true
  }
  let slot = camera_input_cache_slot(word_offset)
  if self.cache_slot_valid(slot, word_offset) {
    if !self.cache_view_proj_matches(slot, view, proj) {
      self.write_matrices(
        word_offset, view, proj, near, far, aspect, projection_kind, flags,
      )
      return true
    }
    match
      self.changed_scalar_word_bounds_from_cache(
        slot, near, far, aspect, projection_kind, flags,
      ) {
      Some((first_word, last_word)) => {
        self.write_scalar_word_range(
          word_offset, first_word, last_word, near, far, aspect, projection_kind,
          flags,
        )
        self.write_cache_scalars(
          word_offset, near, far, aspect, projection_kind, flags,
        )
        true
      }
      None => false
    }
  } else {
    let byte_offset = word_offset * 4
    if !self.matrix_matches_std140_row(byte_offset + 64, view) ||
      !self.matrix_matches_std140_row(byte_offset + 128, proj) {
      self.write_matrices(
        word_offset, view, proj, near, far, aspect, projection_kind, flags,
      )
      return true
    }
    match
      self.changed_scalar_word_bounds(
        byte_offset, near, far, aspect, projection_kind, flags,
      ) {
      Some((first_word, last_word)) => {
        self.write_scalar_word_range(
          word_offset, first_word, last_word, near, far, aspect, projection_kind,
          flags,
        )
        self.write_cache_inputs(
          word_offset, view, proj, near, far, aspect, projection_kind, flags,
        )
        true
      }
      None => {
        self.write_cache_inputs(
          word_offset, view, proj, near, far, aspect, projection_kind, flags,
        )
        false
      }
    }
  }
}

///|
/// Writes one Camera row only when Camera inputs changed, using the lean JS path.
#cfg(target="js")
fn CameraBlobStore::write_matrices_if_changed(
  self : CameraBlobStore,
  word_offset : Int,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  if !self.valid_row_range(word_offset) {
    self.write_matrices(
      word_offset, view, proj, near, far, aspect, projection_kind, flags,
    )
    return true
  }
  let byte_offset = word_offset * 4
  if !self.matrix_matches_std140_row(byte_offset + 64, view) ||
    !self.matrix_matches_std140_row(byte_offset + 128, proj) {
    self.write_matrices(
      word_offset, view, proj, near, far, aspect, projection_kind, flags,
    )
    return true
  }
  match
    self.changed_scalar_word_bounds(
      byte_offset, near, far, aspect, projection_kind, flags,
    ) {
    Some((first_word, last_word)) => {
      self.write_scalar_word_range(
        word_offset, first_word, last_word, near, far, aspect, projection_kind, flags,
      )
      true
    }
    None => false
  }
}

///|
/// Writes one captured Camera GPU row back into the packed blob.
fn CameraBlobStore::write_row_bytes(
  self : CameraBlobStore,
  word_offset : Int,
  bytes : FixedArray[Byte],
) -> Unit {
  if bytes.length() != @comp.camera_gpu_byte_stride() {
    abort("CameraBlobStore::write_row_bytes: length mismatch")
  }
  self.store.write_words(word_offset, @comp.camera_gpu_word_count(), fn(row) {
    for i = 0; i < bytes.length(); i = i + 1 {
      row[i] = bytes[i]
    }
  })
  self.refresh_cache_from_row_bytes(word_offset, bytes)
}

///|
/// Implements `CameraBlobStore::read_row`.
fn CameraBlobStore::read_row(
  self : CameraBlobStore,
  word_offset : Int,
) -> FixedArray[Byte]? {
  self.store.read_words(word_offset, @comp.camera_gpu_word_count())
}

///|
/// Implements `CameraBlobStore::has_write_views`.
fn CameraBlobStore::has_write_views(self : CameraBlobStore) -> Bool {
  self.store.has_dirty_words()
}

///|
/// Implements `CameraBlobStore::drain_write_views`.
fn CameraBlobStore::drain_write_views(
  self : CameraBlobStore,
) -> Array[GpuWriteView] {
  self.store.drain_write_views()
}

///|
/// Implements `CameraBlobStore::drain_resize_events`.
fn CameraBlobStore::drain_resize_events(
  self : CameraBlobStore,
) -> Array[PackedGpuBlobResizeEvent] {
  self.store.drain_resize_events()
}
