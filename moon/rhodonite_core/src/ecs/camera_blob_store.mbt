/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `CameraBlobStore::new`.
fn CameraBlobStore::new() -> CameraBlobStore {
  { store: PackedGpuBlobStore::new() }
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
/// Implements `CameraBlobStore::inputs_match_row`.
fn CameraBlobStore::inputs_match_row(
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
  let byte_offset = word_offset * 4
  if word_offset < 0 ||
    byte_offset + @comp.camera_gpu_byte_stride() > self.store.bytes.length() {
    return false
  }
  self.matrix_matches_std140_row(byte_offset + 64, view) &&
  self.matrix_matches_std140_row(byte_offset + 128, proj) &&
  self.f32_matches_row(byte_offset + 268, near) &&
  self.f32_matches_row(byte_offset + 272, far) &&
  self.f32_matches_row(byte_offset + 276, aspect) &&
  self.f32_matches_row(byte_offset + 280, projection_kind) &&
  self.f32_matches_row(byte_offset + 284, flags)
}

///|
/// Writes one Camera row only when the caller-visible Camera inputs changed.
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
  if self.inputs_match_row(
      word_offset, view, proj, near, far, aspect, projection_kind, flags,
    ) {
    return false
  }
  self.write_matrices(
    word_offset, view, proj, near, far, aspect, projection_kind, flags,
  )
  true
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
