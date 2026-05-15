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
/// Implements `GlobalTransformBlobStore::read_matrix`.
fn GlobalTransformBlobStore::read_matrix(
  self : GlobalTransformBlobStore,
  format : @comp.GlobalTransformGpuFormat,
  word_offset : Int,
) -> @m44.Matrix44F {
  match
    self.store.read_words(
      word_offset,
      @comp.global_transform_word_count(format),
    ) {
    Some(bytes) =>
      @comp.matrix44f_from_global_transform_gpu_bytes(bytes, format)
    None => @m44.Matrix44F::identity()
  }
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
