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
/// Implements `CameraBlobStore::read_row`.
fn CameraBlobStore::read_row(
  self : CameraBlobStore,
  word_offset : Int,
) -> FixedArray[Byte]? {
  self.store.read_words(word_offset, @comp.camera_gpu_word_count())
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
