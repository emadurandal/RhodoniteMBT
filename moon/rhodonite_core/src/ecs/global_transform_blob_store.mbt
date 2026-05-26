/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `GlobalTransformBlobStore::new`.
fn GlobalTransformBlobStore::new() -> GlobalTransformBlobStore {
  { store: PackedGpuBlobStore::new() }
}

///|
/// Implements `GlobalTransformBlobStore::word_capacity`.
fn GlobalTransformBlobStore::word_capacity(
  self : GlobalTransformBlobStore,
) -> Int {
  self.store.word_capacity()
}

///|
/// Implements `GlobalTransformBlobStore::alloc`.
fn GlobalTransformBlobStore::alloc(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
) -> Int {
  self.store.alloc_words(@comp.global_transform_word_count(format))
}

///|
/// Implements `GlobalTransformBlobStore::free`.
fn GlobalTransformBlobStore::free(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
) -> Unit {
  self.store.free_words(word_offset, @comp.global_transform_word_count(format))
}

///|
/// Implements `GlobalTransformBlobStore::write_matrix`.
fn GlobalTransformBlobStore::write_matrix(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
  matrix : @m44.Matrix44F,
) -> Unit {
  let words = @comp.global_transform_word_count(format)
  self.store.write_words(word_offset, words, fn(row) {
    @comp.matrix44f_write_global_transform_to_gpu_row(matrix, row, format)
  })
}

///|
/// Implements `GlobalTransformBlobStore::row_word_matches`.
fn GlobalTransformBlobStore::row_word_matches(
  self : GlobalTransformBlobStore,
  byte_offset : Int,
  expected : UInt,
) -> Bool {
  @writes.get_u32_le(self.store.bytes, byte_offset) == expected
}

///|
/// Implements `GlobalTransformBlobStore::matrix_matches`.
fn GlobalTransformBlobStore::matrix_matches(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
  matrix : @m44.Matrix44F,
) -> Bool {
  let words = @comp.global_transform_word_count(format)
  let byte_offset = word_offset * 4
  if word_offset < 0 || byte_offset + words * 4 > self.store.bytes.length() {
    return false
  }
  let d = matrix.data
  match format {
    Affine3x4F32 =>
      self.row_word_matches(byte_offset + 0, d[0].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 4, d[4].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 8, d[8].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 12, d[12].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 16, d[1].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 20, d[5].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 24, d[9].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 28, d[13].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 32, d[2].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 36, d[6].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 40, d[10].reinterpret_as_uint()) &&
      self.row_word_matches(byte_offset + 44, d[14].reinterpret_as_uint())
    Affine3x4F16 => {
      let w0 = @comp.global_transform_f32_to_f16_bits(d[0]) |
        (@comp.global_transform_f32_to_f16_bits(d[4]) << 16)
      let w1 = @comp.global_transform_f32_to_f16_bits(d[8]) |
        (@comp.global_transform_f32_to_f16_bits(d[12]) << 16)
      let w2 = @comp.global_transform_f32_to_f16_bits(d[1]) |
        (@comp.global_transform_f32_to_f16_bits(d[5]) << 16)
      let w3 = @comp.global_transform_f32_to_f16_bits(d[9]) |
        (@comp.global_transform_f32_to_f16_bits(d[13]) << 16)
      let w4 = @comp.global_transform_f32_to_f16_bits(d[2]) |
        (@comp.global_transform_f32_to_f16_bits(d[6]) << 16)
      let w5 = @comp.global_transform_f32_to_f16_bits(d[10]) |
        (@comp.global_transform_f32_to_f16_bits(d[14]) << 16)
      self.row_word_matches(byte_offset + 0, w0) &&
      self.row_word_matches(byte_offset + 4, w1) &&
      self.row_word_matches(byte_offset + 8, w2) &&
      self.row_word_matches(byte_offset + 12, w3) &&
      self.row_word_matches(byte_offset + 16, w4) &&
      self.row_word_matches(byte_offset + 20, w5)
    }
  }
}

///|
/// Writes one GlobalTransform row only when the encoded GPU payload changes.
fn GlobalTransformBlobStore::write_matrix_if_changed(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
  matrix : @m44.Matrix44F,
) -> Bool {
  if self.matrix_matches(format, word_offset, matrix) {
    return false
  }
  self.write_matrix(format, word_offset, matrix)
  true
}

///|
/// Implements `GlobalTransformBlobStore::read_matrix`.
fn GlobalTransformBlobStore::read_matrix(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
) -> @m44.Matrix44F? {
  match
    self.store.read_words(
      word_offset,
      @comp.global_transform_word_count(format),
    ) {
    Some(bytes) =>
      Some(@comp.matrix44f_from_global_transform_gpu_bytes(bytes, format))
    None => None
  }
}

///|
/// Reads one packed GlobalTransform row as stored bytes.
fn GlobalTransformBlobStore::read_row_bytes(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
) -> FixedArray[Byte]? {
  self.store.read_words(word_offset, @comp.global_transform_word_count(format))
}

///|
/// Writes one packed GlobalTransform row from stored bytes.
fn GlobalTransformBlobStore::write_row_bytes(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
  bytes : FixedArray[Byte],
) -> Bool {
  let word_count = @comp.global_transform_word_count(format)
  if bytes.length() != word_count * 4 {
    return false
  }
  self.store.write_words(word_offset, word_count, row => {
    for i = 0; i < bytes.length(); i = i + 1 {
      row[i] = bytes[i]
    }
  })
  true
}

///|
/// Implements `GlobalTransformBlobStore::write_word_range_views`.
fn GlobalTransformBlobStore::write_word_range_views(
  self : GlobalTransformBlobStore,
  first_word : Int,
  word_count : Int,
  write : (MutArrayView[Byte]) -> Unit,
) -> Array[GpuWriteView] {
  self.store.write_word_range_views(first_word, word_count, write)
}

///|
/// Implements `GlobalTransformBlobStore::has_write_views`.
fn GlobalTransformBlobStore::has_write_views(
  self : GlobalTransformBlobStore,
) -> Bool {
  self.store.has_dirty_words()
}

///|
/// Implements `GlobalTransformBlobStore::drain_write_views`.
fn GlobalTransformBlobStore::drain_write_views(
  self : GlobalTransformBlobStore,
) -> Array[GpuWriteView] {
  self.store.drain_write_views()
}

///|
/// Implements `GlobalTransformBlobStore::drain_resize_events`.
fn GlobalTransformBlobStore::drain_resize_events(
  self : GlobalTransformBlobStore,
) -> Array[GlobalTransformBlobResizeEvent] {
  self.store.drain_resize_events()
}
