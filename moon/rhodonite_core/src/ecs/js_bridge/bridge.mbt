///| JS bridge for the ECS TypeScript wrappers.

///|
pub fn entity_id_new(index : Int, generation : Int) -> @ecs.EntityId {
  @ecs.EntityId::new(index, generation)
}

///|
pub fn entity_id_index(entity : @ecs.EntityId) -> Int {
  entity.index
}

///|
pub fn entity_id_generation(entity : @ecs.EntityId) -> Int {
  entity.generation
}

///|
pub fn entity_id_gpu_index(entity : @ecs.EntityId) -> Int {
  entity.gpu_index()
}

///|
pub fn component_type_id_new(index : Int) -> @ecs.ComponentTypeId {
  @ecs.ComponentTypeId::new(index)
}

///|
pub fn component_type_id_index(component : @ecs.ComponentTypeId) -> Int {
  component.index
}

///|
pub fn world_new() -> @ecs.World {
  @ecs.World::new()
}

///|
pub fn world_new_with_global_transform_f16() -> @ecs.World {
  @ecs.World::new_with_global_transform_format(Affine3x4F16)
}

///|
pub fn world_create_entity(world : @ecs.World) -> @ecs.EntityId {
  world.create_entity()
}

///|
pub fn world_destroy_entity(world : @ecs.World, entity : @ecs.EntityId) -> Bool {
  world.destroy_entity(entity)
}

///|
pub fn world_is_alive(world : @ecs.World, entity : @ecs.EntityId) -> Bool {
  world.is_alive(entity)
}

///|
pub fn world_location(
  world : @ecs.World,
  entity : @ecs.EntityId,
) -> @ecs.EntityLocation? {
  world.location(entity)
}

///|
pub fn world_transform_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.transform_component()
}

///|
pub fn world_global_transform_component(
  world : @ecs.World,
) -> @ecs.ComponentTypeId {
  world.global_transform_component()
}

///|
pub fn world_child_of_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.child_of_component()
}

///|
pub fn world_camera_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.camera_component()
}

///|
pub fn world_register_cpu_component(
  world : @ecs.World,
  name : String,
  cpu_stride : Int,
) -> @ecs.ComponentTypeId {
  world.register_cpu_component(name, cpu_stride)
}

///|
pub fn world_register_gpu_component(
  world : @ecs.World,
  name : String,
  gpu_layout : @comp.GpuLayout,
) -> @ecs.ComponentTypeId {
  world.register_gpu_component(name, gpu_layout)
}

///|
pub fn world_component_cpu_stride(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> Int? {
  world.component_cpu_stride(component)
}

///|
pub fn world_component_gpu_layout(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> @comp.GpuLayout? {
  world.component_gpu_layout(component)
}

///|
pub fn world_component_info(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> @ecs.RegisteredComponent? {
  world.component_info(component)
}

///|
pub fn world_component_info_kind(info : @ecs.RegisteredComponent) -> String {
  match info.kind {
    CpuOnly => "CpuOnly"
    GpuVisible => "GpuVisible"
  }
}

///|
pub fn world_component_info_name(info : @ecs.RegisteredComponent) -> String {
  info.name
}

///|
pub fn world_component_info_cpu_stride(info : @ecs.RegisteredComponent) -> Int {
  info.cpu_stride
}

///|
pub fn world_has_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.has_component(entity, component)
}

///|
pub fn world_add_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.add_component(entity, component)
}

///|
pub fn world_add_component_bytes(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  world.add_component_bytes(entity, component, bytes)
}

///|
pub fn world_set_component_bytes(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  world.set_component_bytes(entity, component, bytes)
}

///|
pub fn world_remove_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.remove_component(entity, component)
}

///|
pub fn world_clear_gpu_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.clear_gpu_component(entity, component)
}

///|
pub fn world_component_bytes_copy(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> FixedArray[Byte]? {
  world.component_bytes(entity, component)
}

///|
pub fn world_drain_gpu_write_views(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> Array[@ecs.GpuWriteView] {
  world.drain_gpu_write_views(component)
}

///|
pub fn world_drain_gpu_writes_copy(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> Array[@ecs.GpuWrite] {
  world.drain_gpu_writes(component)
}

///|
pub fn world_drain_resize_events(
  world : @ecs.World,
) -> Array[@ecs.GpuResizeEvent] {
  world.drain_resize_events()
}

///|
pub fn world_gpu_component_active_indices(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> Array[Int] {
  world.gpu_component_active_indices(component)
}

///|
pub fn world_set_transform_trs(
  world : @ecs.World,
  entity : @ecs.EntityId,
  px : Float,
  py : Float,
  pz : Float,
  qx : Double,
  qy : Double,
  qz : Double,
  qw : Double,
  sx : Float,
  sy : Float,
  sz : Float,
) -> Bool {
  world.set_transform_trs(entity, px, py, pz, qx, qy, qz, qw, sx, sy, sz)
}

///|
pub fn world_update_global_transforms_from_transforms(
  world : @ecs.World,
) -> Unit {
  world.update_global_transforms_from_transforms()
}

///|
pub fn world_set_global_transform_format(
  world : @ecs.World,
  entity : @ecs.EntityId,
  format_code : UInt,
) -> Bool {
  world.set_global_transform_format(
    entity,
    @comp.global_transform_format_from_code(format_code),
  )
}

///|
pub fn world_write_global_transforms_dense_range_views(
  world : @ecs.World,
  count : Int,
  f : (MutArrayView[Byte], Int, Int, Int) -> Unit,
) -> Array[@ecs.GpuWriteView] {
  ignore(world)
  ignore(count)
  ignore(f)
  abort(
    "world_write_global_transforms_dense_range_views: removed; use packed GlobalTransform blob APIs",
  )
}

///|
pub fn world_drain_global_transform_blob_write_views(
  world : @ecs.World,
) -> Array[@ecs.GpuWriteView] {
  world.drain_global_transform_blob_write_views()
}

///|
pub fn world_write_global_transform_blob_range_views(
  world : @ecs.World,
  first_word : Int,
  word_count : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Array[@ecs.GpuWriteView] {
  world.write_global_transform_blob_range_views(first_word, word_count, f)
}

///|
pub fn world_global_transform_blob_word_capacity(world : @ecs.World) -> Int {
  world.global_transform_blob_word_capacity()
}

///|
pub fn world_drain_camera_blob_write_views(
  world : @ecs.World,
) -> Array[@ecs.GpuWriteView] {
  world.drain_camera_blob_write_views()
}

///|
pub fn world_camera_blob_word_capacity(world : @ecs.World) -> Int {
  world.camera_blob_word_capacity()
}

///|
pub fn world_extract_global_transform_refs(
  world : @ecs.World,
  entities : Array[@ecs.EntityId],
) -> FixedArray[Byte] {
  world.extract_global_transform_refs(entities)
}

///|
pub fn world_spawn_transform_global_batch_identity(
  world : @ecs.World,
  count : Int,
) -> Array[@ecs.EntityId] {
  world.spawn_transform_global_batch(count, fn(_i, _entity, tf_row, _gt_row) {
    @comp.Transform3D::write_trs_to_component_mut_view(
      tf_row, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0,
    )
  })
}

///|
pub fn world_spawn_batch(
  world : @ecs.World,
  components : Array[@ecs.ComponentTypeId],
  count : Int,
  f : (Int, @ecs.EntityId, @ecs.SpawnBatchRow) -> Unit,
) -> Array[@ecs.EntityId] {
  world.spawn_batch(components, count, f)
}

///|
pub fn spawn_batch_row_entity(row : @ecs.SpawnBatchRow) -> @ecs.EntityId {
  row.entity()
}

///|
pub fn spawn_batch_row_write_view(
  row : @ecs.SpawnBatchRow,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  row.write_view(component)
}

///|
pub fn spawn_batch_row_write(
  row : @ecs.SpawnBatchRow,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  row.write(component, f)
}

///|
pub fn query_new(required : Array[@ecs.ComponentTypeId]) -> @ecs.Query {
  @ecs.Query::new(required)
}

///|
pub fn raw_query_new(required : Array[@ecs.ComponentTypeId]) -> @ecs.RawQuery {
  @ecs.RawQuery::new(required)
}

///|
pub fn query_required_components(
  query : @ecs.Query,
) -> Array[@ecs.ComponentTypeId] {
  query.required_components()
}

///|
pub fn query_for_each(
  query : @ecs.Query,
  world : @ecs.World,
  f : (@ecs.QueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
pub fn raw_query_for_each(
  query : @ecs.RawQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
pub fn query_prepare(
  query : @ecs.Query,
  world : @ecs.World,
) -> @ecs.PreparedQuery {
  query.prepare(world)
}

///|
pub fn raw_query_prepare(
  query : @ecs.RawQuery,
  world : @ecs.World,
) -> @ecs.RawPreparedQuery {
  query.prepare(world)
}

///|
pub fn raw_query_for_each_archetype(
  query : @ecs.RawQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryArchetype) -> Unit,
) -> Unit {
  query.for_each_archetype(world, f)
}

///|
pub fn raw_prepared_query_for_each_archetype(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryArchetype) -> Unit,
) -> Unit {
  query.for_each_archetype(world, f)
}

///|
pub fn prepared_query_for_each(
  query : @ecs.PreparedQuery,
  world : @ecs.World,
  f : (@ecs.QueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
pub fn raw_prepared_query_for_each(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
pub fn query_row_entity(row : @ecs.QueryRow) -> @ecs.EntityId {
  row.entity()
}

///|
pub fn raw_query_row_entity(row : @ecs.RawQueryRow) -> @ecs.EntityId {
  row.entity()
}

///|
pub fn query_row_has(
  row : @ecs.QueryRow,
  component : @ecs.ComponentTypeId,
) -> Bool {
  row.has(component)
}

///|
pub fn raw_query_row_has(
  row : @ecs.RawQueryRow,
  component : @ecs.ComponentTypeId,
) -> Bool {
  row.has(component)
}

///|
pub fn raw_query_row_read_view(
  row : @ecs.RawQueryRow,
  component : @ecs.ComponentTypeId,
) -> ArrayView[Byte] {
  row.read_view(component)
}

///|
pub fn raw_query_row_write_view(
  row : @ecs.RawQueryRow,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  row.write_view(component)
}

///|
pub fn query_row_read(
  row : @ecs.QueryRow,
  component : @ecs.ComponentTypeId,
  f : (ArrayView[Byte]) -> Unit,
) -> Unit {
  row.read(component, f)
}

///|
pub fn query_row_write(
  row : @ecs.QueryRow,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  row.write(component, f)
}

///|
pub fn raw_query_archetype_length(arch : @ecs.RawQueryArchetype) -> Int {
  arch.length()
}

///|
pub fn raw_query_archetype_entity(
  arch : @ecs.RawQueryArchetype,
  row : Int,
) -> @ecs.EntityId {
  arch.entity(row)
}

///|
pub fn raw_query_archetype_has(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> Bool {
  arch.has(component)
}

///|
pub fn raw_query_archetype_component_stride(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> Int {
  arch.component_stride(component)
}

///|
pub fn raw_query_archetype_read_column(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> ArrayView[Byte] {
  arch.read_column(component)
}

///|
pub fn raw_query_archetype_write_column(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  arch.write_column(component)
}

///|
pub fn gpu_layout_empty(stride : Int) -> @comp.GpuLayout {
  @comp.GpuLayout::empty(stride)
}

///|
pub fn gpu_layout_transform3d() -> @comp.GpuLayout {
  @comp.transform3d_gpu_layout()
}

///|
pub fn gpu_layout_global_transform() -> @comp.GpuLayout {
  @comp.global_transform_gpu_layout()
}

///|
pub fn gpu_layout_global_transform_f16() -> @comp.GpuLayout {
  @comp.global_transform_gpu_layout_f16()
}

///|
pub fn gpu_layout_child_of() -> @comp.GpuLayout {
  @comp.child_of_cpu_layout()
}

///|
pub fn gpu_layout_camera() -> @comp.GpuLayout {
  @comp.camera_ref_cpu_layout()
}

///|
pub fn gpu_layout_stride(layout : @comp.GpuLayout) -> Int {
  layout.stride
}

///|
pub fn gpu_layout_align(layout : @comp.GpuLayout) -> Int {
  layout.align
}

///|
pub fn gpu_layout_is_valid(layout : @comp.GpuLayout) -> Bool {
  layout.is_valid()
}

///|
pub fn gpu_layout_fields(layout : @comp.GpuLayout) -> Array[@comp.GpuField] {
  layout.fields
}

///|
pub fn gpu_field_name(field : @comp.GpuField) -> String {
  field.name
}

///|
pub fn gpu_field_kind_name(field : @comp.GpuField) -> String {
  match field.kind {
    F32 => "F32"
    U32 => "U32"
    Vec2F32 => "Vec2F32"
    Vec3F32Packed => "Vec3F32Packed"
    Vec3F32 => "Vec3F32"
    Vec4F32 => "Vec4F32"
    Vec4F16 => "Vec4F16"
    Mat4x4F32 => "Mat4x4F32"
  }
}

///|
pub fn gpu_field_offset(field : @comp.GpuField) -> Int {
  field.offset
}

///|
pub fn gpu_field_size(field : @comp.GpuField) -> Int {
  field.size
}

///|
pub fn gpu_field_align(field : @comp.GpuField) -> Int {
  field.align
}

///|
pub fn gpu_write_view_byte_offset(write : @ecs.GpuWriteView) -> Int {
  write.byte_offset
}

///|
pub fn gpu_write_view_bytes(write : @ecs.GpuWriteView) -> ArrayView[Byte] {
  write.bytes
}

///|
pub fn gpu_write_copy_byte_offset(write : @ecs.GpuWrite) -> Int {
  write.byte_offset
}

///|
pub fn gpu_write_copy_bytes(write : @ecs.GpuWrite) -> FixedArray[Byte] {
  write.bytes
}

///|
pub fn gpu_resize_event_component(
  event : @ecs.GpuResizeEvent,
) -> @ecs.ComponentTypeId {
  event.component
}

///|
pub fn gpu_resize_event_required_capacity(event : @ecs.GpuResizeEvent) -> Int {
  event.required_capacity
}

///|
pub fn gpu_resize_event_needs_full_upload(event : @ecs.GpuResizeEvent) -> Bool {
  event.needs_full_upload
}

///|
pub fn bytes_get_f32(bytes : FixedArray[Byte], offset : Int) -> Float {
  @comp.get_gpu_f32(bytes, offset)
}

///|
pub fn bytes_put_f32(
  bytes : FixedArray[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @comp.put_gpu_f32(bytes, offset, value)
}

///|
pub fn bytes_view_get_f32(bytes : ArrayView[Byte], offset : Int) -> Float {
  @comp.get_gpu_f32_byte_view(bytes, offset)
}

///|
pub fn bytes_mut_view_get_f32(
  bytes : MutArrayView[Byte],
  offset : Int,
) -> Float {
  @comp.get_gpu_f32_mut_view(bytes, offset)
}

///|
pub fn bytes_mut_view_put_f32(
  bytes : MutArrayView[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @comp.put_gpu_f32_mut_view(bytes, offset, value)
}

///|
fn main {
  ()
}
