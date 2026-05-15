///|
fn World::camera_ref_from_bytes(
  self : World,
  bytes : FixedArray[Byte],
) -> CameraRef {
  ignore(self)
  { word_offset: @comp.camera_ref_from_component_bytes(bytes) }
}

///|
fn World::camera_ref_unchecked(self : World, entity : EntityId) -> CameraRef? {
  let id = self.camera_component_id
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  if !component_array_contains(
      self.archetypes[loc.archetype_index].components,
      id,
    ) {
    return None
  }
  match self.archetypes[loc.archetype_index].component_bytes(loc.row, id) {
    Some(bytes) => Some(self.camera_ref_from_bytes(bytes))
    None => None
  }
}

///|
pub fn World::camera_ref(self : World, entity : EntityId) -> CameraRef? {
  let id = self.camera_component_id
  self.assert_system_component_read(id, "World::camera_ref")
  self.camera_ref_unchecked(entity)
}

///|
fn World::alloc_camera_ref(
  self : World,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> CameraRef {
  let word_offset = self.camera_blob.alloc()
  self.camera_blob.write_matrices(
    word_offset, view, proj, near, far, aspect, projection_kind, flags,
  )
  { word_offset, }
}

///|
fn World::release_camera_ref(self : World, entity : EntityId) -> Unit {
  match self.camera_ref_unchecked(entity) {
    Some(camera_ref) => self.camera_blob.free(camera_ref.word_offset)
    None => ()
  }
}

///|
pub fn World::set_camera_matrices(
  self : World,
  entity : EntityId,
  view : @m44.Matrix44F,
  proj : @m44.Matrix44F,
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  let id = self.camera_component_id
  self.assert_system_component_write(id, "World::set_camera_matrices")
  if !self.has_component(entity, id) {
    if !self.can_add_missing_component_from_setter(
        id, "World::set_camera_matrices",
      ) {
      return false
    }
    let camera_ref = self.alloc_camera_ref(
      view, proj, near, far, aspect, projection_kind, flags,
    )
    self.add_component_bytes(
      entity,
      id,
      @comp.camera_ref_bytes(camera_ref.word_offset),
    )
  } else {
    match self.camera_ref(entity) {
      Some(camera_ref) => {
        self.camera_blob.write_matrices(
          camera_ref.word_offset,
          view,
          proj,
          near,
          far,
          aspect,
          projection_kind,
          flags,
        )
        true
      }
      None => false
    }
  }
}

///|
pub fn World::camera_gpu_row(
  self : World,
  entity : EntityId,
) -> FixedArray[Byte]? {
  let id = self.camera_component_id
  self.assert_system_component_read(id, "World::camera_gpu_row")
  match self.camera_ref(entity) {
    Some(camera_ref) => self.camera_blob.read_row(camera_ref.word_offset)
    None => None
  }
}

///|
pub fn World::camera_blob_word_capacity(self : World) -> Int {
  self.camera_blob.word_capacity()
}

///|
pub fn World::drain_camera_blob_write_views(
  self : World,
) -> Array[GpuWriteView] {
  let id = self.camera_component_id
  self.assert_system_component_write(id, "World::drain_camera_blob_write_views")
  self.camera_blob.drain_write_views()
}

///|
pub fn World::drain_camera_blob_resize_events(
  self : World,
) -> Array[GlobalTransformBlobResizeEvent] {
  self.assert_system_structural_write("World::drain_camera_blob_resize_events")
  self.camera_blob.drain_resize_events()
}

///|
pub fn World::update_camera_views_from_global_transforms(self : World) -> Unit {
  let camera = self.camera_component_id
  let gt = self.global_transform_component_id
  self.assert_system_component_write(
    camera, "World::update_camera_views_from_global_transforms",
  )
  self.assert_system_component_read(
    gt, "World::update_camera_views_from_global_transforms",
  )
  Query::new([camera, gt]).for_each(self, fn(row) {
    let entity = row.entity()
    let world_m = match self.get_global_transform(entity) {
      Some(m) => m
      None => @m44.Matrix44F::identity()
    }
    let view = match world_m.inverse() {
      Some(m) => m
      None => @m44.Matrix44F::identity()
    }
    match self.camera_ref(entity) {
      Some(camera_ref) =>
        match self.camera_blob.read_row(camera_ref.word_offset) {
          Some(bytes) => {
            let proj = @m44.Matrix44F::{
              data: (
                [
                  @comp.get_gpu_f32(bytes, 128),
                  @comp.get_gpu_f32(bytes, 132),
                  @comp.get_gpu_f32(bytes, 136),
                  @comp.get_gpu_f32(bytes, 140),
                  @comp.get_gpu_f32(bytes, 144),
                  @comp.get_gpu_f32(bytes, 148),
                  @comp.get_gpu_f32(bytes, 152),
                  @comp.get_gpu_f32(bytes, 156),
                  @comp.get_gpu_f32(bytes, 160),
                  @comp.get_gpu_f32(bytes, 164),
                  @comp.get_gpu_f32(bytes, 168),
                  @comp.get_gpu_f32(bytes, 172),
                  @comp.get_gpu_f32(bytes, 176),
                  @comp.get_gpu_f32(bytes, 180),
                  @comp.get_gpu_f32(bytes, 184),
                  @comp.get_gpu_f32(bytes, 188),
                ] : FixedArray[Float]),
            }
            let near = @comp.get_gpu_f32(bytes, 268)
            let far = @comp.get_gpu_f32(bytes, 272)
            let aspect = @comp.get_gpu_f32(bytes, 276)
            let projection_kind = @comp.get_gpu_f32(bytes, 280)
            let flags = @comp.get_gpu_f32(bytes, 284)
            self.camera_blob.write_matrices(
              camera_ref.word_offset,
              view,
              proj,
              near,
              far,
              aspect,
              projection_kind,
              flags,
            )
          }
          None => ()
        }
      None => ()
    }
  })
}
