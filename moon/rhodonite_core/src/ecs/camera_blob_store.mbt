///|
fn CameraBlobStore::new() -> CameraBlobStore {
  { store: PackedGpuBlobStore::new() }
}

///|
fn CameraBlobStore::word_capacity(self : CameraBlobStore) -> Int {
  self.store.word_capacity()
}

///|
fn CameraBlobStore::alloc(self : CameraBlobStore) -> Int {
  self.store.alloc_words(@comp.camera_gpu_word_count())
}

///|
fn CameraBlobStore::free(self : CameraBlobStore, word_offset : Int) -> Unit {
  self.store.free_words(word_offset, @comp.camera_gpu_word_count())
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
  self.store.write_words(word_offset, @comp.camera_gpu_word_count(), fn(row) {
    @comp.camera_write_gpu_row(
      row, view, proj, near, far, aspect, projection_kind, flags,
    )
  })
}

///|
fn CameraBlobStore::read_row(
  self : CameraBlobStore,
  word_offset : Int,
) -> FixedArray[Byte]? {
  self.store.read_words(word_offset, @comp.camera_gpu_word_count())
}

///|
fn CameraBlobStore::drain_write_views(
  self : CameraBlobStore,
) -> Array[GpuWriteView] {
  self.store.drain_write_views()
}

///|
fn CameraBlobStore::drain_resize_events(
  self : CameraBlobStore,
) -> Array[PackedGpuBlobResizeEvent] {
  self.store.drain_resize_events()
}
