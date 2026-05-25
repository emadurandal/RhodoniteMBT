/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///| JS bridge for the ECS TypeScript wrappers.

///|
/// Implements `entity_id_new`.
pub fn entity_id_new(index : Int, generation : Int) -> @ecs.EntityId {
  @ecs.EntityId::new(index, generation)
}

///|
/// Implements `entity_id_index`.
pub fn entity_id_index(entity : @ecs.EntityId) -> Int {
  entity.index
}

///|
/// Implements `entity_id_generation`.
pub fn entity_id_generation(entity : @ecs.EntityId) -> Int {
  entity.generation
}

///|
/// Implements `entity_id_gpu_index`.
pub fn entity_id_gpu_index(entity : @ecs.EntityId) -> Int {
  entity.gpu_index()
}

///|
/// Implements `component_type_id_new`.
pub fn component_type_id_new(index : Int) -> @ecs.ComponentTypeId {
  @ecs.ComponentTypeId::new(index)
}

///|
/// Implements `component_type_id_index`.
pub fn component_type_id_index(component : @ecs.ComponentTypeId) -> Int {
  component.index
}

///|
/// Implements `world_new`.
pub fn world_new() -> @ecs.World {
  @ecs.World::new()
}

///|
/// Implements `world_new_with_global_transform_f16`.
pub fn world_new_with_global_transform_f16() -> @ecs.World {
  @ecs.World::new_with_global_transform_format(Affine3x4F16)
}

///|
/// Implements `world_create_entity`.
pub fn world_create_entity(world : @ecs.World) -> @ecs.EntityId {
  world.create_entity()
}

///|
/// Implements `world_destroy_entity`.
pub fn world_destroy_entity(world : @ecs.World, entity : @ecs.EntityId) -> Bool {
  world.destroy_entity(entity)
}

///|
/// Implements `world_is_alive`.
pub fn world_is_alive(world : @ecs.World, entity : @ecs.EntityId) -> Bool {
  world.is_alive(entity)
}

///|
/// Implements `world_location`.
pub fn world_location(
  world : @ecs.World,
  entity : @ecs.EntityId,
) -> @ecs.EntityLocation? {
  world.location(entity)
}

///|
/// Implements `world_transform_component`.
pub fn world_transform_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.transform_component()
}

///|
/// Implements `world_global_transform_component`.
pub fn world_global_transform_component(
  world : @ecs.World,
) -> @ecs.ComponentTypeId {
  world.global_transform_component()
}

///|
/// Implements `world_child_of_component`.
pub fn world_child_of_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.child_of_component()
}

///|
/// Implements `world_camera_component`.
pub fn world_camera_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.camera_component()
}

///|
/// Implements `world_orbit_camera_controller_component`.
pub fn world_orbit_camera_controller_component(
  world : @ecs.World,
) -> @ecs.ComponentTypeId {
  world.orbit_camera_controller_component()
}

///|
/// Implements `world_camera_home_transform_component`.
pub fn world_camera_home_transform_component(
  world : @ecs.World,
) -> @ecs.ComponentTypeId {
  world.camera_home_transform_component()
}

///|
/// Implements `world_camera_lens_component`.
pub fn world_camera_lens_component(world : @ecs.World) -> @ecs.ComponentTypeId {
  world.camera_lens_component()
}

///|
/// Implements `world_register_cpu_component`.
pub fn world_register_cpu_component(
  world : @ecs.World,
  name : String,
  cpu_stride : Int,
) -> @ecs.ComponentTypeId {
  world.register_cpu_component(name, cpu_stride)
}

///|
/// Implements `world_register_cpu_component_with_identity`.
pub fn world_register_cpu_component_with_identity(
  world : @ecs.World,
  name : String,
  cpu_stride : Int,
  stable_key : String,
  schema_version : String?,
  schema_hash : String?,
) -> @ecs.ComponentTypeId {
  world.register_cpu_component_with_identity(
    name, cpu_stride, stable_key, schema_version, schema_hash,
  )
}

///|
/// Implements `world_component_cpu_stride`.
pub fn world_component_cpu_stride(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> Int? {
  world.component_cpu_stride(component)
}

///|
/// Implements `world_component_info`.
pub fn world_component_info(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
) -> @ecs.RegisteredComponent? {
  world.component_info(component)
}

///|
/// Implements `world_component_by_stable_key`.
pub fn world_component_by_stable_key(
  world : @ecs.World,
  stable_key : String,
) -> @ecs.ComponentTypeId? {
  world.component_by_stable_key(stable_key)
}

///|
/// Implements `world_component_matches_identity`.
pub fn world_component_matches_identity(
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
  stable_key : String,
  schema_version : String?,
  schema_hash : String?,
) -> Bool {
  world.component_matches_identity(
    component, stable_key, schema_version, schema_hash,
  )
}

///|
/// Implements `world_component_info_name`.
pub fn world_component_info_name(info : @ecs.RegisteredComponent) -> String {
  info.name
}

///|
/// Implements `world_component_info_cpu_stride`.
pub fn world_component_info_cpu_stride(info : @ecs.RegisteredComponent) -> Int {
  info.cpu_stride
}

///|
/// Implements `world_component_info_stable_key`.
pub fn world_component_info_stable_key(
  info : @ecs.RegisteredComponent,
) -> String? {
  info.stable_key
}

///|
/// Implements `world_component_info_schema_version`.
pub fn world_component_info_schema_version(
  info : @ecs.RegisteredComponent,
) -> String? {
  info.schema_version
}

///|
/// Implements `world_component_info_schema_hash`.
pub fn world_component_info_schema_hash(
  info : @ecs.RegisteredComponent,
) -> String? {
  info.schema_hash
}

///|
/// Implements `world_has_component`.
pub fn world_has_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.has_component(entity, component)
}

///|
/// Implements `world_add_component`.
pub fn world_add_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.add_component(entity, component)
}

///|
/// Implements `world_add_component_bytes`.
pub fn world_add_component_bytes(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  world.add_component_bytes(entity, component, bytes)
}

///|
/// Implements `world_set_component_bytes`.
pub fn world_set_component_bytes(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  world.set_component_bytes(entity, component, bytes)
}

///|
/// Implements `world_remove_component`.
pub fn world_remove_component(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  world.remove_component(entity, component)
}

///|
/// Implements `world_component_bytes_copy`.
pub fn world_component_bytes_copy(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> FixedArray[Byte]? {
  world.component_bytes(entity, component)
}

///|
/// Implements `world_set_transform_trs`.
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
/// Implements `world_set_child_of`.
pub fn world_set_child_of(
  world : @ecs.World,
  entity : @ecs.EntityId,
  parent : @ecs.EntityId,
) -> Bool {
  world.set_child_of(entity, parent)
}

///|
/// Builds a Matrix44F from 16 column-major floats passed through the JS bridge.
fn matrix44f_from_col_major_array(data : FixedArray[Float]) -> @m44.Matrix44F {
  if data.length() != 16 {
    abort("matrix44f_from_col_major_array: length mismatch")
  }
  @m44.Matrix44::new_col_major(
    data[0],
    data[1],
    data[2],
    data[3],
    data[4],
    data[5],
    data[6],
    data[7],
    data[8],
    data[9],
    data[10],
    data[11],
    data[12],
    data[13],
    data[14],
    data[15],
  )
}

///|
/// Implements `world_set_global_transform_col_major`.
pub fn world_set_global_transform_col_major(
  world : @ecs.World,
  entity : @ecs.EntityId,
  matrix_col_major : FixedArray[Float],
) -> Bool {
  world.set_global_transform(
    entity,
    matrix44f_from_col_major_array(matrix_col_major),
  )
}

///|
/// Implements `world_get_global_transform_col_major`.
pub fn world_get_global_transform_col_major(
  world : @ecs.World,
  entity : @ecs.EntityId,
) -> FixedArray[Float]? {
  match world.get_global_transform(entity) {
    Some(matrix) => Some(matrix.data())
    None => None
  }
}

///|
/// Implements `world_set_camera_matrices_col_major`.
pub fn world_set_camera_matrices_col_major(
  world : @ecs.World,
  entity : @ecs.EntityId,
  view_col_major : FixedArray[Float],
  proj_col_major : FixedArray[Float],
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  world.set_camera_matrices(
    entity,
    matrix44f_from_col_major_array(view_col_major),
    matrix44f_from_col_major_array(proj_col_major),
    near,
    far,
    aspect,
    projection_kind,
    flags,
  )
}

///|
/// Implements `world_camera_gpu_row_copy`.
pub fn world_camera_gpu_row_copy(
  world : @ecs.World,
  entity : @ecs.EntityId,
) -> FixedArray[Byte]? {
  world.camera_gpu_row(entity)
}

///|
/// Implements `world_update_global_transforms_from_transforms`.
pub fn world_update_global_transforms_from_transforms(
  world : @ecs.World,
) -> Unit {
  world.update_global_transforms_from_transforms()
}

///|
/// Implements `world_set_global_transform_format`.
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
/// Implements `world_write_global_transforms_dense_range_views`.
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
/// Implements `world_drain_global_transform_blob_write_views`.
pub fn world_drain_global_transform_blob_write_views(
  world : @ecs.World,
) -> Array[@ecs.GpuWriteView] {
  world.drain_global_transform_blob_write_views()
}

///|
/// Implements `world_write_global_transform_blob_range_views`.
pub fn world_write_global_transform_blob_range_views(
  world : @ecs.World,
  first_word : Int,
  word_count : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Array[@ecs.GpuWriteView] {
  world.write_global_transform_blob_range_views(first_word, word_count, f)
}

///|
/// Implements `world_global_transform_blob_word_capacity`.
pub fn world_global_transform_blob_word_capacity(world : @ecs.World) -> Int {
  world.global_transform_blob_word_capacity()
}

///|
/// Implements `world_drain_camera_blob_write_views`.
pub fn world_drain_camera_blob_write_views(
  world : @ecs.World,
) -> Array[@ecs.GpuWriteView] {
  world.drain_camera_blob_write_views()
}

///|
/// Implements `world_camera_blob_word_capacity`.
pub fn world_camera_blob_word_capacity(world : @ecs.World) -> Int {
  world.camera_blob_word_capacity()
}

///|
/// Implements `world_extract_global_transform_refs`.
pub fn world_extract_global_transform_refs(
  world : @ecs.World,
  entities : Array[@ecs.EntityId],
) -> FixedArray[Byte] {
  world.extract_global_transform_refs(entities)
}

///|
/// Implements `world_spawn_transform_global_batch_identity`.
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
/// Implements `world_reserve_batch_capacity`.
pub fn world_reserve_batch_capacity(
  world : @ecs.World,
  components : Array[@ecs.ComponentTypeId],
  additional_rows : Int,
) -> Bool {
  world.reserve_batch_capacity(components, additional_rows)
}

///|
/// Implements `world_spawn_batch`.
pub fn world_spawn_batch(
  world : @ecs.World,
  components : Array[@ecs.ComponentTypeId],
  count : Int,
  f : (Int, @ecs.EntityId, @ecs.SpawnBatchRow) -> Unit,
) -> Array[@ecs.EntityId] {
  world.spawn_batch(components, count, f)
}

///|
/// Implements `world_history_new`.
pub fn world_history_new() -> @ecs.WorldHistory {
  @ecs.WorldHistory::new()
}

///|
/// Implements `world_history_enabled`.
pub fn world_history_enabled(history : @ecs.WorldHistory) -> Bool {
  history.enabled()
}

///|
/// Implements `world_history_set_enabled`.
pub fn world_history_set_enabled(
  history : @ecs.WorldHistory,
  enabled : Bool,
) -> Unit {
  history.set_enabled(enabled)
}

///|
/// Implements `world_history_raw_mutation_guard_enabled`.
pub fn world_history_raw_mutation_guard_enabled(
  history : @ecs.WorldHistory,
) -> Bool {
  history.raw_mutation_guard_enabled()
}

///|
/// Implements `world_history_set_raw_mutation_guard_enabled`.
pub fn world_history_set_raw_mutation_guard_enabled(
  history : @ecs.WorldHistory,
  enabled : Bool,
) -> Unit {
  history.set_raw_mutation_guard_enabled(enabled)
}

///|
/// Implements `world_history_max_undo_records`.
pub fn world_history_max_undo_records(history : @ecs.WorldHistory) -> Int {
  history.max_undo_records()
}

///|
/// Implements `world_history_max_undo_bytes`.
pub fn world_history_max_undo_bytes(history : @ecs.WorldHistory) -> Int {
  history.max_undo_bytes()
}

///|
/// Implements `world_history_set_max_undo_records`.
pub fn world_history_set_max_undo_records(
  history : @ecs.WorldHistory,
  limit : Int,
) -> Unit {
  history.set_max_undo_records(limit)
}

///|
/// Implements `world_history_set_max_undo_bytes`.
pub fn world_history_set_max_undo_bytes(
  history : @ecs.WorldHistory,
  limit : Int,
) -> Unit {
  history.set_max_undo_bytes(limit)
}

///|
/// Implements `world_history_clear`.
pub fn world_history_clear(history : @ecs.WorldHistory) -> Unit {
  history.clear()
}

///|
/// Implements `world_history_undo_len`.
pub fn world_history_undo_len(history : @ecs.WorldHistory) -> Int {
  history.undo_len()
}

///|
/// Implements `world_history_redo_len`.
pub fn world_history_redo_len(history : @ecs.WorldHistory) -> Int {
  history.redo_len()
}

///|
/// Implements `world_history_undo_bytes`.
pub fn world_history_undo_bytes(history : @ecs.WorldHistory) -> Int {
  history.undo_bytes()
}

///|
/// Implements `world_history_redo_bytes`.
pub fn world_history_redo_bytes(history : @ecs.WorldHistory) -> Int {
  history.redo_bytes()
}

///|
/// Implements `world_history_undo_summary`.
pub fn world_history_undo_summary(
  history : @ecs.WorldHistory,
) -> Array[@ecs.WorldHistoryRecordSummary] {
  history.undo_summary()
}

///|
/// Implements `world_history_redo_summary`.
pub fn world_history_redo_summary(
  history : @ecs.WorldHistory,
) -> Array[@ecs.WorldHistoryRecordSummary] {
  history.redo_summary()
}

///|
/// Implements `world_history_undo_serialization_report`.
pub fn world_history_undo_serialization_report(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> @ecs.WorldHistorySerializationReport {
  history.undo_serialization_report(world)
}

///|
/// Implements `world_history_redo_serialization_report`.
pub fn world_history_redo_serialization_report(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> @ecs.WorldHistorySerializationReport {
  history.redo_serialization_report(world)
}

///|
/// Implements `world_history_export_undo_stack`.
pub fn world_history_export_undo_stack(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> @ecs.WorldHistoryExport? {
  history.export_undo_stack(world)
}

///|
/// Implements `world_history_export_redo_stack`.
pub fn world_history_export_redo_stack(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> @ecs.WorldHistoryExport? {
  history.export_redo_stack(world)
}

///|
/// Implements `world_history_import_undo_stack`.
pub fn world_history_import_undo_stack(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  exported : @ecs.WorldHistoryExport,
) -> Bool {
  history.import_undo_stack(world, exported)
}

///|
/// Implements `world_history_import_redo_stack`.
pub fn world_history_import_redo_stack(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  exported : @ecs.WorldHistoryExport,
) -> Bool {
  history.import_redo_stack(world, exported)
}

///|
/// Implements `world_history_serialization_report_serializable`.
pub fn world_history_serialization_report_serializable(
  report : @ecs.WorldHistorySerializationReport,
) -> Bool {
  report.serializable
}

///|
/// Implements `world_history_serialization_report_record_count`.
pub fn world_history_serialization_report_record_count(
  report : @ecs.WorldHistorySerializationReport,
) -> Int {
  report.record_count
}

///|
/// Implements `world_history_serialization_report_records`.
pub fn world_history_serialization_report_records(
  report : @ecs.WorldHistorySerializationReport,
) -> Array[@ecs.WorldHistorySerializationRecordReport] {
  report.records
}

///|
/// Implements `world_history_serialization_record_report_label`.
pub fn world_history_serialization_record_report_label(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> String {
  report.label
}

///|
/// Implements `world_history_serialization_record_report_serializable`.
pub fn world_history_serialization_record_report_serializable(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Bool {
  report.serializable
}

///|
/// Implements `world_history_serialization_record_report_reason`.
pub fn world_history_serialization_record_report_reason(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_serialization_record_report_delta_count`.
pub fn world_history_serialization_record_report_delta_count(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Int {
  report.delta_count
}

///|
/// Implements `world_history_serialization_record_report_payload_bytes`.
pub fn world_history_serialization_record_report_payload_bytes(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Int {
  report.payload_bytes
}

///|
/// Implements `world_history_serialization_record_report_deltas`.
pub fn world_history_serialization_record_report_deltas(
  report : @ecs.WorldHistorySerializationRecordReport,
) -> Array[@ecs.WorldHistorySerializationDeltaReport] {
  report.deltas
}

///|
/// Implements `world_history_serialization_delta_report_kind`.
pub fn world_history_serialization_delta_report_kind(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> String {
  report.kind
}

///|
/// Implements `world_history_serialization_delta_report_entity`.
pub fn world_history_serialization_delta_report_entity(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> @ecs.EntityId? {
  report.entity
}

///|
/// Implements `world_history_serialization_delta_report_component`.
pub fn world_history_serialization_delta_report_component(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> @ecs.ComponentTypeId? {
  report.component
}

///|
/// Implements `world_history_serialization_delta_report_component_count`.
pub fn world_history_serialization_delta_report_component_count(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Int {
  report.component_count
}

///|
/// Implements `world_history_serialization_delta_report_serializable`.
pub fn world_history_serialization_delta_report_serializable(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Bool {
  report.serializable
}

///|
/// Implements `world_history_serialization_delta_report_reason`.
pub fn world_history_serialization_delta_report_reason(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_serialization_delta_report_payload_bytes`.
pub fn world_history_serialization_delta_report_payload_bytes(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Int {
  report.payload_bytes
}

///|
/// Implements `world_history_serialization_delta_report_components`.
pub fn world_history_serialization_delta_report_components(
  report : @ecs.WorldHistorySerializationDeltaReport,
) -> Array[@ecs.WorldHistorySerializationComponentReport] {
  report.components
}

///|
/// Implements `world_history_serialization_component_report_component`.
pub fn world_history_serialization_component_report_component(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> @ecs.ComponentTypeId {
  report.component
}

///|
/// Implements `world_history_serialization_component_report_serializable`.
pub fn world_history_serialization_component_report_serializable(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> Bool {
  report.serializable
}

///|
/// Implements `world_history_serialization_component_report_reason`.
pub fn world_history_serialization_component_report_reason(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_serialization_component_report_stable_key`.
pub fn world_history_serialization_component_report_stable_key(
  report : @ecs.WorldHistorySerializationComponentReport,
) -> String? {
  report.stable_key
}

///|
/// Implements `world_history_export_format_version`.
pub fn world_history_export_format_version(
  exported : @ecs.WorldHistoryExport,
) -> Int {
  exported.format_version
}

///|
/// Implements `world_history_export_record_count`.
pub fn world_history_export_record_count(
  exported : @ecs.WorldHistoryExport,
) -> Int {
  exported.record_count
}

///|
/// Implements `world_history_export_records`.
pub fn world_history_export_records(
  exported : @ecs.WorldHistoryExport,
) -> Array[@ecs.WorldHistoryExportRecord] {
  exported.records
}

///|
/// Implements `world_history_export_record_label`.
pub fn world_history_export_record_label(
  record : @ecs.WorldHistoryExportRecord,
) -> String {
  record.label
}

///|
/// Implements `world_history_export_record_delta_count`.
pub fn world_history_export_record_delta_count(
  record : @ecs.WorldHistoryExportRecord,
) -> Int {
  record.delta_count
}

///|
/// Implements `world_history_export_record_deltas`.
pub fn world_history_export_record_deltas(
  record : @ecs.WorldHistoryExportRecord,
) -> Array[@ecs.WorldHistoryExportDelta] {
  record.deltas
}

///|
/// Implements `world_history_export_delta_kind`.
pub fn world_history_export_delta_kind(
  delta : @ecs.WorldHistoryExportDelta,
) -> String {
  delta.kind
}

///|
/// Implements `world_history_export_delta_entity`.
pub fn world_history_export_delta_entity(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.EntityId? {
  delta.entity
}

///|
/// Implements `world_history_export_delta_component`.
pub fn world_history_export_delta_component(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.WorldHistoryExportComponentIdentity? {
  delta.component
}

///|
/// Implements `world_history_export_delta_before`.
pub fn world_history_export_delta_before(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.WorldHistoryExportPayload? {
  delta.before
}

///|
/// Implements `world_history_export_delta_after`.
pub fn world_history_export_delta_after(
  delta : @ecs.WorldHistoryExportDelta,
) -> @ecs.WorldHistoryExportPayload? {
  delta.after
}

///|
/// Implements `world_history_export_delta_components`.
pub fn world_history_export_delta_components(
  delta : @ecs.WorldHistoryExportDelta,
) -> Array[@ecs.WorldHistoryExportComponentSnapshot] {
  delta.components
}

///|
/// Implements `world_history_export_component_identity_local_component`.
pub fn world_history_export_component_identity_local_component(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> @ecs.ComponentTypeId {
  identity.local_component
}

///|
/// Implements `world_history_export_component_identity_key`.
pub fn world_history_export_component_identity_key(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> String {
  identity.key
}

///|
/// Implements `world_history_export_component_identity_builtin`.
pub fn world_history_export_component_identity_builtin(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> Bool {
  identity.builtin
}

///|
/// Implements `world_history_export_component_identity_schema_version`.
pub fn world_history_export_component_identity_schema_version(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> String? {
  identity.schema_version
}

///|
/// Implements `world_history_export_component_identity_schema_hash`.
pub fn world_history_export_component_identity_schema_hash(
  identity : @ecs.WorldHistoryExportComponentIdentity,
) -> String? {
  identity.schema_hash
}

///|
/// Implements `world_history_export_payload_global_transform_format`.
pub fn world_history_export_payload_global_transform_format(
  payload : @ecs.WorldHistoryExportPayload,
) -> Int? {
  payload.global_transform_format
}

///|
/// Implements `world_history_export_payload_bytes`.
pub fn world_history_export_payload_bytes(
  payload : @ecs.WorldHistoryExportPayload,
) -> FixedArray[Byte] {
  payload.bytes
}

///|
/// Implements `world_history_export_component_snapshot_component`.
pub fn world_history_export_component_snapshot_component(
  snapshot : @ecs.WorldHistoryExportComponentSnapshot,
) -> @ecs.WorldHistoryExportComponentIdentity {
  snapshot.component
}

///|
/// Implements `world_history_export_component_snapshot_bytes`.
pub fn world_history_export_component_snapshot_bytes(
  snapshot : @ecs.WorldHistoryExportComponentSnapshot,
) -> FixedArray[Byte] {
  snapshot.bytes
}

///|
/// Implements `world_history_export_component_identity_new`.
pub fn world_history_export_component_identity_new(
  local_component : @ecs.ComponentTypeId,
  key : String,
  builtin : Bool,
  schema_version : String?,
  schema_hash : String?,
) -> @ecs.WorldHistoryExportComponentIdentity {
  { local_component, key, builtin, schema_version, schema_hash }
}

///|
/// Implements `world_history_export_payload_new`.
pub fn world_history_export_payload_new(
  global_transform_format : Int?,
  bytes : FixedArray[Byte],
) -> @ecs.WorldHistoryExportPayload {
  { global_transform_format, bytes }
}

///|
/// Implements `world_history_export_component_snapshot_new`.
pub fn world_history_export_component_snapshot_new(
  component : @ecs.WorldHistoryExportComponentIdentity,
  bytes : FixedArray[Byte],
) -> @ecs.WorldHistoryExportComponentSnapshot {
  { component, bytes }
}

///|
/// Implements `world_history_export_delta_new`.
pub fn world_history_export_delta_new(
  kind : String,
  entity : @ecs.EntityId?,
  component : @ecs.WorldHistoryExportComponentIdentity?,
  before : @ecs.WorldHistoryExportPayload?,
  after : @ecs.WorldHistoryExportPayload?,
  components : Array[@ecs.WorldHistoryExportComponentSnapshot],
) -> @ecs.WorldHistoryExportDelta {
  { kind, entity, component, before, after, components }
}

///|
/// Implements `world_history_export_record_new`.
pub fn world_history_export_record_new(
  label : String,
  delta_count : Int,
  deltas : Array[@ecs.WorldHistoryExportDelta],
) -> @ecs.WorldHistoryExportRecord {
  { label, delta_count, deltas }
}

///|
/// Implements `world_history_export_new`.
pub fn world_history_export_new(
  format_version : Int,
  record_count : Int,
  records : Array[@ecs.WorldHistoryExportRecord],
) -> @ecs.WorldHistoryExport {
  { format_version, record_count, records }
}

///|
/// Implements `world_history_record_summary_label`.
pub fn world_history_record_summary_label(
  summary : @ecs.WorldHistoryRecordSummary,
) -> String {
  summary.label
}

///|
/// Implements `world_history_record_summary_delta_count`.
pub fn world_history_record_summary_delta_count(
  summary : @ecs.WorldHistoryRecordSummary,
) -> Int {
  summary.delta_count
}

///|
/// Implements `world_history_record_summary_payload_bytes`.
pub fn world_history_record_summary_payload_bytes(
  summary : @ecs.WorldHistoryRecordSummary,
) -> Int {
  summary.payload_bytes
}

///|
/// Implements `world_history_record_summary_deltas`.
pub fn world_history_record_summary_deltas(
  summary : @ecs.WorldHistoryRecordSummary,
) -> Array[@ecs.WorldHistoryDeltaSummary] {
  summary.deltas
}

///|
/// Implements `world_history_delta_summary_kind`.
pub fn world_history_delta_summary_kind(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> String {
  summary.kind
}

///|
/// Implements `world_history_delta_summary_entity`.
pub fn world_history_delta_summary_entity(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> @ecs.EntityId? {
  summary.entity
}

///|
/// Implements `world_history_delta_summary_component`.
pub fn world_history_delta_summary_component(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> @ecs.ComponentTypeId? {
  summary.component
}

///|
/// Implements `world_history_delta_summary_component_count`.
pub fn world_history_delta_summary_component_count(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Int {
  summary.component_count
}

///|
/// Implements `world_history_delta_summary_payload_bytes`.
pub fn world_history_delta_summary_payload_bytes(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Int {
  summary.payload_bytes
}

///|
/// Implements `world_history_delta_summary_before_present`.
pub fn world_history_delta_summary_before_present(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Bool {
  summary.before_present
}

///|
/// Implements `world_history_delta_summary_after_present`.
pub fn world_history_delta_summary_after_present(
  summary : @ecs.WorldHistoryDeltaSummary,
) -> Bool {
  summary.after_present
}

///|
/// Implements `world_history_last_diagnostic`.
pub fn world_history_last_diagnostic(history : @ecs.WorldHistory) -> String {
  history.last_diagnostic()
}

///|
/// Implements `world_history_undo_label`.
pub fn world_history_undo_label(history : @ecs.WorldHistory) -> String? {
  history.undo_label()
}

///|
/// Implements `world_history_redo_label`.
pub fn world_history_redo_label(history : @ecs.WorldHistory) -> String? {
  history.redo_label()
}

///|
/// Implements `world_history_begin_transaction`.
pub fn world_history_begin_transaction(
  history : @ecs.WorldHistory,
  label : String,
) -> Bool {
  history.begin_transaction(label)
}

///|
/// Implements `world_history_begin_guarded_transaction`.
pub fn world_history_begin_guarded_transaction(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  label : String,
) -> Bool {
  history.begin_guarded_transaction(world, label)
}

///|
/// Implements `world_history_commit_transaction`.
pub fn world_history_commit_transaction(history : @ecs.WorldHistory) -> Bool {
  history.commit_transaction()
}

///|
/// Implements `world_history_cancel_transaction`.
pub fn world_history_cancel_transaction(history : @ecs.WorldHistory) -> Bool {
  history.cancel_transaction()
}

///|
/// Implements `world_history_cancel_transaction_reverting`.
pub fn world_history_cancel_transaction_reverting(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> Bool {
  history.cancel_transaction_reverting(world)
}

///|
/// Implements `world_history_can_undo`.
pub fn world_history_can_undo(history : @ecs.WorldHistory) -> Bool {
  history.can_undo()
}

///|
/// Implements `world_history_can_redo`.
pub fn world_history_can_redo(history : @ecs.WorldHistory) -> Bool {
  history.can_redo()
}

///|
/// Implements `world_history_undo`.
pub fn world_history_undo(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> Bool {
  history.undo(world)
}

///|
/// Implements `world_history_redo`.
pub fn world_history_redo(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> Bool {
  history.redo(world)
}

///|
/// Implements `world_history_create_entity`.
pub fn world_history_create_entity(
  history : @ecs.WorldHistory,
  world : @ecs.World,
) -> @ecs.EntityId {
  history.create_entity(world)
}

///|
/// Implements `world_history_create_entities`.
pub fn world_history_create_entities(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  count : Int,
) -> Array[@ecs.EntityId] {
  history.create_entities(world, count)
}

///|
/// Implements `world_history_spawn_batch`.
pub fn world_history_spawn_batch(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  components : Array[@ecs.ComponentTypeId],
  count : Int,
  f : (Int, @ecs.EntityId, @ecs.SpawnBatchRow) -> Unit,
) -> Array[@ecs.EntityId] {
  history.spawn_batch(world, components, count, f)
}

///|
/// Implements `world_history_destroy_entity`.
pub fn world_history_destroy_entity(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
) -> Bool {
  history.destroy_entity(world, entity)
}

///|
/// Implements `world_history_add_component`.
pub fn world_history_add_component(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  history.add_component(world, entity, component)
}

///|
/// Implements `world_history_add_component_bytes`.
pub fn world_history_add_component_bytes(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  history.add_component_bytes(world, entity, component, bytes)
}

///|
/// Implements `world_history_add_component_bytes_many`.
pub fn world_history_add_component_bytes_many(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
  entities : Array[@ecs.EntityId],
  bytes_list : Array[FixedArray[Byte]],
) -> Bool {
  history.add_component_bytes_many(world, component, entities, bytes_list)
}

///|
/// Implements `world_history_set_component_bytes`.
pub fn world_history_set_component_bytes(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  history.set_component_bytes(world, entity, component, bytes)
}

///|
/// Implements `world_history_set_component_bytes_many`.
pub fn world_history_set_component_bytes_many(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  component : @ecs.ComponentTypeId,
  entities : Array[@ecs.EntityId],
  bytes_list : Array[FixedArray[Byte]],
) -> Bool {
  history.set_component_bytes_many(world, component, entities, bytes_list)
}

///|
/// Implements `world_history_remove_component`.
pub fn world_history_remove_component(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Bool {
  history.remove_component(world, entity, component)
}

///|
/// Implements `world_history_set_transform_trs`.
pub fn world_history_set_transform_trs(
  history : @ecs.WorldHistory,
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
  history.set_transform_trs(
    world, entity, px, py, pz, qx, qy, qz, qw, sx, sy, sz,
  )
}

///|
/// Implements `world_history_set_global_transform_col_major`.
pub fn world_history_set_global_transform_col_major(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  matrix_col_major : FixedArray[Float],
) -> Bool {
  history.set_global_transform(
    world,
    entity,
    matrix44f_from_col_major_array(matrix_col_major),
  )
}

///|
/// Implements `world_history_set_global_transform_format`.
pub fn world_history_set_global_transform_format(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  format_code : UInt,
) -> Bool {
  history.set_global_transform_format(
    world,
    entity,
    @comp.global_transform_format_from_code(format_code),
  )
}

///|
/// Implements `world_history_set_child_of`.
pub fn world_history_set_child_of(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  parent : @ecs.EntityId,
) -> Bool {
  history.set_child_of(world, entity, parent)
}

///|
/// Implements `world_history_set_camera_matrices_col_major`.
pub fn world_history_set_camera_matrices_col_major(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  entity : @ecs.EntityId,
  view_col_major : FixedArray[Float],
  proj_col_major : FixedArray[Float],
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Bool {
  history.set_camera_matrices(
    world,
    entity,
    matrix44f_from_col_major_array(view_col_major),
    matrix44f_from_col_major_array(proj_col_major),
    near,
    far,
    aspect,
    projection_kind,
    flags,
  )
}

///|
/// Implements `spawn_batch_row_entity`.
pub fn spawn_batch_row_entity(row : @ecs.SpawnBatchRow) -> @ecs.EntityId {
  row.entity()
}

///|
/// Implements `spawn_batch_row_write_view`.
pub fn spawn_batch_row_write_view(
  row : @ecs.SpawnBatchRow,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  row.write_view(component)
}

///|
/// Implements `spawn_batch_row_write`.
pub fn spawn_batch_row_write(
  row : @ecs.SpawnBatchRow,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  row.write(component, f)
}

///|
/// Implements `query_new`.
pub fn query_new(required : Array[@ecs.ComponentTypeId]) -> @ecs.Query {
  @ecs.Query::new(required)
}

///|
/// Implements `raw_query_new`.
pub fn raw_query_new(required : Array[@ecs.ComponentTypeId]) -> @ecs.RawQuery {
  @ecs.RawQuery::new(required)
}

///|
/// Implements `query_required_components`.
pub fn query_required_components(
  query : @ecs.Query,
) -> Array[@ecs.ComponentTypeId] {
  query.required_components()
}

///|
/// Implements `query_for_each`.
pub fn query_for_each(
  query : @ecs.Query,
  world : @ecs.World,
  f : (@ecs.QueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
/// Implements `raw_query_for_each`.
pub fn raw_query_for_each(
  query : @ecs.RawQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
/// Implements `query_prepare`.
pub fn query_prepare(
  query : @ecs.Query,
  world : @ecs.World,
) -> @ecs.PreparedQuery {
  query.prepare(world)
}

///|
/// Implements `raw_query_prepare`.
pub fn raw_query_prepare(
  query : @ecs.RawQuery,
  world : @ecs.World,
) -> @ecs.RawPreparedQuery {
  query.prepare(world)
}

///|
/// Implements `raw_query_for_each_archetype`.
pub fn raw_query_for_each_archetype(
  query : @ecs.RawQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryArchetype) -> Unit,
) -> Unit {
  query.for_each_archetype(world, f)
}

///|
/// Implements `raw_prepared_query_for_each_archetype`.
pub fn raw_prepared_query_for_each_archetype(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryArchetype) -> Unit,
) -> Unit {
  query.for_each_archetype(world, f)
}

///|
/// Implements `prepared_query_for_each`.
pub fn prepared_query_for_each(
  query : @ecs.PreparedQuery,
  world : @ecs.World,
  f : (@ecs.QueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
/// Implements `raw_prepared_query_for_each`.
pub fn raw_prepared_query_for_each(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
  f : (@ecs.RawQueryRow) -> Unit,
) -> Unit {
  query.for_each(world, f)
}

///|
/// Implements `query_row_entity`.
pub fn query_row_entity(row : @ecs.QueryRow) -> @ecs.EntityId {
  row.entity()
}

///|
/// Implements `raw_query_row_entity`.
pub fn raw_query_row_entity(row : @ecs.RawQueryRow) -> @ecs.EntityId {
  row.entity()
}

///|
/// Implements `query_row_has`.
pub fn query_row_has(
  row : @ecs.QueryRow,
  component : @ecs.ComponentTypeId,
) -> Bool {
  row.has(component)
}

///|
/// Implements `raw_query_row_has`.
pub fn raw_query_row_has(
  row : @ecs.RawQueryRow,
  component : @ecs.ComponentTypeId,
) -> Bool {
  row.has(component)
}

///|
/// Implements `raw_query_row_read_view`.
pub fn raw_query_row_read_view(
  row : @ecs.RawQueryRow,
  component : @ecs.ComponentTypeId,
) -> ArrayView[Byte] {
  row.read_view(component)
}

///|
/// Implements `raw_query_row_write_view`.
pub fn raw_query_row_write_view(
  row : @ecs.RawQueryRow,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  row.write_view(component)
}

///|
/// Implements `raw_query_row_write_tracked`.
pub fn raw_query_row_write_tracked(
  row : @ecs.RawQueryRow,
  history : @ecs.WorldHistory,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  row.write_tracked(history, component, f)
}

///|
/// Implements `query_row_read`.
pub fn query_row_read(
  row : @ecs.QueryRow,
  component : @ecs.ComponentTypeId,
  f : (ArrayView[Byte]) -> Unit,
) -> Unit {
  row.read(component, f)
}

///|
/// Implements `query_row_write`.
pub fn query_row_write(
  row : @ecs.QueryRow,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  row.write(component, f)
}

///|
/// Implements `query_row_write_tracked`.
pub fn query_row_write_tracked(
  row : @ecs.QueryRow,
  history : @ecs.WorldHistory,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  row.write_tracked(history, component, f)
}

///|
/// Implements `raw_query_archetype_length`.
pub fn raw_query_archetype_length(arch : @ecs.RawQueryArchetype) -> Int {
  arch.length()
}

///|
/// Implements `raw_query_archetype_entity`.
pub fn raw_query_archetype_entity(
  arch : @ecs.RawQueryArchetype,
  row : Int,
) -> @ecs.EntityId {
  arch.entity(row)
}

///|
/// Implements `raw_query_archetype_has`.
pub fn raw_query_archetype_has(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> Bool {
  arch.has(component)
}

///|
/// Implements `raw_query_archetype_component_stride`.
pub fn raw_query_archetype_component_stride(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> Int {
  arch.component_stride(component)
}

///|
/// Implements `raw_query_archetype_read_column`.
pub fn raw_query_archetype_read_column(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> ArrayView[Byte] {
  arch.read_column(component)
}

///|
/// Implements `raw_query_archetype_write_column`.
pub fn raw_query_archetype_write_column(
  arch : @ecs.RawQueryArchetype,
  component : @ecs.ComponentTypeId,
) -> MutArrayView[Byte] {
  arch.write_column(component)
}

///|
/// Implements `raw_query_archetype_write_column_tracked`.
pub fn raw_query_archetype_write_column_tracked(
  arch : @ecs.RawQueryArchetype,
  history : @ecs.WorldHistory,
  component : @ecs.ComponentTypeId,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  arch.write_column_tracked(history, component, f)
}

///|
/// Implements `phase_key_new`.
pub fn phase_key_new(name : String) -> @ecs.PhaseKey {
  @ecs.PhaseKey::new(name)
}

///|
/// Implements `phase_key_name`.
pub fn phase_key_name(phase : @ecs.PhaseKey) -> String {
  phase.name()
}

///|
/// Implements `system_context_new`.
pub fn system_context_new(
  delta_seconds : Float,
  frame_index : Int,
) -> @ecs.SystemContext {
  @ecs.SystemContext::new(delta_seconds, frame_index)
}

///|
/// Implements `system_context_delta_seconds`.
pub fn system_context_delta_seconds(ctx : @ecs.SystemContext) -> Float {
  ctx.delta_seconds
}

///|
/// Implements `system_context_frame_index`.
pub fn system_context_frame_index(ctx : @ecs.SystemContext) -> Int {
  ctx.frame_index
}

///|
/// Implements `command_buffer_len`.
pub fn command_buffer_len(commands : @ecs.CommandBuffer) -> Int {
  commands.len()
}

///|
/// Implements `command_buffer_is_empty`.
pub fn command_buffer_is_empty(commands : @ecs.CommandBuffer) -> Bool {
  commands.is_empty()
}

///|
/// Implements `command_buffer_create_entity`.
pub fn command_buffer_create_entity(
  commands : @ecs.CommandBuffer,
) -> @ecs.EntityId {
  commands.create_entity()
}

///|
/// Implements `command_buffer_destroy_entity`.
pub fn command_buffer_destroy_entity(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
) -> Unit {
  commands.destroy_entity(entity)
}

///|
/// Implements `command_buffer_add_component`.
pub fn command_buffer_add_component(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Unit {
  commands.add_component(entity, component)
}

///|
/// Implements `command_buffer_add_component_bytes`.
pub fn command_buffer_add_component_bytes(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  commands.add_component_bytes(entity, component, bytes)
}

///|
/// Implements `command_buffer_set_component_bytes`.
pub fn command_buffer_set_component_bytes(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Unit {
  commands.set_component_bytes(entity, component, bytes)
}

///|
/// Implements `command_buffer_set_global_transform_col_major`.
pub fn command_buffer_set_global_transform_col_major(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  matrix_col_major : FixedArray[Float],
) -> Unit {
  commands.set_global_transform(
    entity,
    matrix44f_from_col_major_array(matrix_col_major),
  )
}

///|
/// Implements `command_buffer_set_global_transform_format`.
pub fn command_buffer_set_global_transform_format(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  format_code : UInt,
) -> Unit {
  commands.set_global_transform_format(
    entity,
    @comp.global_transform_format_from_code(format_code),
  )
}

///|
/// Implements `command_buffer_set_camera_matrices_col_major`.
pub fn command_buffer_set_camera_matrices_col_major(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  view_col_major : FixedArray[Float],
  proj_col_major : FixedArray[Float],
  near : Float,
  far : Float,
  aspect : Float,
  projection_kind : Float,
  flags : Float,
) -> Unit {
  commands.set_camera_matrices(
    entity,
    matrix44f_from_col_major_array(view_col_major),
    matrix44f_from_col_major_array(proj_col_major),
    near,
    far,
    aspect,
    projection_kind,
    flags,
  )
}

///|
/// Implements `command_buffer_remove_component`.
pub fn command_buffer_remove_component(
  commands : @ecs.CommandBuffer,
  entity : @ecs.EntityId,
  component : @ecs.ComponentTypeId,
) -> Unit {
  commands.remove_component(entity, component)
}

///|
/// Wraps a JS callback into an ECS system.
pub fn system_new(
  name : String,
  phase : @ecs.PhaseKey,
  reads : Array[@ecs.ComponentTypeId],
  writes : Array[@ecs.ComponentTypeId],
  run : (@ecs.World, @ecs.SystemContext, @ecs.CommandBuffer) -> Unit,
) -> @ecs.System {
  @ecs.System::new(name, phase, reads, writes, run)
}

///|
/// Wraps a JS callback into an ECS system that may queue structural changes.
pub fn system_new_with_structural_write(
  name : String,
  phase : @ecs.PhaseKey,
  reads : Array[@ecs.ComponentTypeId],
  writes : Array[@ecs.ComponentTypeId],
  run : (@ecs.World, @ecs.SystemContext, @ecs.CommandBuffer) -> Unit,
) -> @ecs.System {
  @ecs.System::new_with_structural_write(name, phase, reads, writes, run)
}

///|
/// Implements `system_name`.
pub fn system_name(system : @ecs.System) -> String {
  system.name()
}

///|
/// Implements `system_phase`.
pub fn system_phase(system : @ecs.System) -> @ecs.PhaseKey {
  system.phase()
}

///|
/// Implements `system_reads`.
pub fn system_reads(system : @ecs.System) -> Array[@ecs.ComponentTypeId] {
  system.reads()
}

///|
/// Implements `system_writes`.
pub fn system_writes(system : @ecs.System) -> Array[@ecs.ComponentTypeId] {
  system.writes()
}

///|
/// Implements `system_structural_write`.
pub fn system_structural_write(system : @ecs.System) -> Bool {
  system.structural_write()
}

///|
/// Implements `system_conflicts_with`.
pub fn system_conflicts_with(system : @ecs.System, other : @ecs.System) -> Bool {
  system.conflicts_with(other)
}

///|
/// Implements `transform_propagation_system`.
pub fn transform_propagation_system(
  world : @ecs.World,
  phase : @ecs.PhaseKey,
) -> @ecs.System {
  @ecs.transform_propagation_system(world, phase)
}

///|
/// Implements `orbit_camera_transform_command_system`.
pub fn orbit_camera_transform_command_system(
  world : @ecs.World,
  phase : @ecs.PhaseKey,
  orbit_component : @ecs.ComponentTypeId,
  home_component : @ecs.ComponentTypeId,
) -> @ecs.System {
  @ecs.orbit_camera_transform_command_system(
    world, phase, orbit_component, home_component,
  )
}

///|
/// Implements `camera_blob_sync_command_system`.
pub fn camera_blob_sync_command_system(
  world : @ecs.World,
  phase : @ecs.PhaseKey,
  lens_component : @ecs.ComponentTypeId,
) -> @ecs.System {
  @ecs.camera_blob_sync_command_system(world, phase, lens_component)
}

///|
/// Implements `orbit_camera_blob_sync_command_system`.
pub fn orbit_camera_blob_sync_command_system(
  world : @ecs.World,
  phase : @ecs.PhaseKey,
  orbit_component : @ecs.ComponentTypeId,
  lens_component : @ecs.ComponentTypeId,
) -> @ecs.System {
  @ecs.orbit_camera_blob_sync_command_system(
    world, phase, orbit_component, lens_component,
  )
}

///|
/// Implements `system_runner_new`.
pub fn system_runner_new() -> @ecs.SystemRunner {
  @ecs.SystemRunner::new()
}

///|
/// Implements `system_runner_len`.
pub fn system_runner_len(runner : @ecs.SystemRunner) -> Int {
  runner.len()
}

///|
/// Implements `system_runner_add_system`.
pub fn system_runner_add_system(
  runner : @ecs.SystemRunner,
  system : @ecs.System,
) -> Unit {
  runner.add_system(system)
}

///|
/// Implements `system_runner_has_parallel_access_conflicts`.
pub fn system_runner_has_parallel_access_conflicts(
  runner : @ecs.SystemRunner,
) -> Bool {
  runner.has_parallel_access_conflicts()
}

///|
/// Implements `system_runner_run_phase`.
pub fn system_runner_run_phase(
  runner : @ecs.SystemRunner,
  world : @ecs.World,
  ctx : @ecs.SystemContext,
  phase : @ecs.PhaseKey,
) -> Bool {
  runner.run_phase(world, ctx, phase)
}

///|
/// Implements `world_history_run_system_phase`.
pub fn world_history_run_system_phase(
  history : @ecs.WorldHistory,
  runner : @ecs.SystemRunner,
  world : @ecs.World,
  ctx : @ecs.SystemContext,
  phase : @ecs.PhaseKey,
  label : String,
) -> Bool {
  history.run_system_phase(runner, world, ctx, phase, label)
}

///|
/// Implements `gpu_layout_empty`.
pub fn gpu_layout_empty(stride : Int) -> @comp.GpuLayout {
  @comp.GpuLayout::empty(stride)
}

///|
/// Implements `gpu_layout_transform3d`.
pub fn gpu_layout_transform3d() -> @comp.GpuLayout {
  @comp.transform3d_gpu_layout()
}

///|
/// Implements `gpu_layout_global_transform`.
pub fn gpu_layout_global_transform() -> @comp.GpuLayout {
  @comp.global_transform_gpu_layout()
}

///|
/// Implements `gpu_layout_global_transform_f16`.
pub fn gpu_layout_global_transform_f16() -> @comp.GpuLayout {
  @comp.global_transform_gpu_layout_f16()
}

///|
/// Implements `gpu_layout_child_of`.
pub fn gpu_layout_child_of() -> @comp.GpuLayout {
  @comp.child_of_cpu_layout()
}

///|
/// Implements `gpu_layout_camera`.
pub fn gpu_layout_camera() -> @comp.GpuLayout {
  @comp.camera_ref_cpu_layout()
}

///|
/// Implements `gpu_layout_stride`.
pub fn gpu_layout_stride(layout : @comp.GpuLayout) -> Int {
  layout.stride
}

///|
/// Implements `gpu_layout_align`.
pub fn gpu_layout_align(layout : @comp.GpuLayout) -> Int {
  layout.align
}

///|
/// Implements `gpu_layout_is_valid`.
pub fn gpu_layout_is_valid(layout : @comp.GpuLayout) -> Bool {
  layout.is_valid()
}

///|
/// Implements `gpu_layout_fields`.
pub fn gpu_layout_fields(layout : @comp.GpuLayout) -> Array[@comp.GpuField] {
  layout.fields
}

///|
/// Implements `gpu_field_name`.
pub fn gpu_field_name(field : @comp.GpuField) -> String {
  field.name
}

///|
/// Implements `gpu_field_kind_name`.
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
/// Implements `gpu_field_offset`.
pub fn gpu_field_offset(field : @comp.GpuField) -> Int {
  field.offset
}

///|
/// Implements `gpu_field_size`.
pub fn gpu_field_size(field : @comp.GpuField) -> Int {
  field.size
}

///|
/// Implements `gpu_field_align`.
pub fn gpu_field_align(field : @comp.GpuField) -> Int {
  field.align
}

///|
/// Implements `gpu_write_view_byte_offset`.
pub fn gpu_write_view_byte_offset(write : @ecs.GpuWriteView) -> Int {
  write.byte_offset
}

///|
/// Implements `gpu_write_view_bytes`.
pub fn gpu_write_view_bytes(write : @ecs.GpuWriteView) -> ArrayView[Byte] {
  write.bytes
}

///|
/// Implements `gpu_write_copy_byte_offset`.
pub fn gpu_write_copy_byte_offset(write : @ecs.GpuWrite) -> Int {
  write.byte_offset
}

///|
/// Implements `gpu_write_copy_bytes`.
pub fn gpu_write_copy_bytes(write : @ecs.GpuWrite) -> FixedArray[Byte] {
  write.bytes
}

///|
/// Implements `bytes_get_f32`.
pub fn bytes_get_f32(bytes : FixedArray[Byte], offset : Int) -> Float {
  @comp.get_gpu_f32(bytes, offset)
}

///|
/// Implements `bytes_put_f32`.
pub fn bytes_put_f32(
  bytes : FixedArray[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @comp.put_gpu_f32(bytes, offset, value)
}

///|
/// Implements `bytes_view_get_f32`.
pub fn bytes_view_get_f32(bytes : ArrayView[Byte], offset : Int) -> Float {
  @comp.get_gpu_f32_byte_view(bytes, offset)
}

///|
/// Implements `bytes_mut_view_get_f32`.
pub fn bytes_mut_view_get_f32(
  bytes : MutArrayView[Byte],
  offset : Int,
) -> Float {
  @comp.get_gpu_f32_mut_view(bytes, offset)
}

///|
/// Implements `bytes_mut_view_put_f32`.
pub fn bytes_mut_view_put_f32(
  bytes : MutArrayView[Byte],
  offset : Int,
  value : Double,
) -> Unit {
  @comp.put_gpu_f32_mut_view(bytes, offset, value)
}

///|
/// Implements `main {`.
fn main {
  ()
}
