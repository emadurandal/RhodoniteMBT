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
/// Implements `world_propagate_global_transforms_from_transforms_report`.
pub fn world_propagate_global_transforms_from_transforms_report(
  world : @ecs.World,
) -> @ecs.TransformPropagationReport {
  world.propagate_global_transforms_from_transforms_report()
}

///|
/// Implements `transform_propagation_report_ok`.
pub fn transform_propagation_report_ok(
  report : @ecs.TransformPropagationReport,
) -> Bool {
  report.ok
}

///|
/// Implements `transform_propagation_report_used_dirty_path`.
pub fn transform_propagation_report_used_dirty_path(
  report : @ecs.TransformPropagationReport,
) -> Bool {
  report.used_dirty_path
}

///|
/// Implements `transform_propagation_report_used_full_path`.
pub fn transform_propagation_report_used_full_path(
  report : @ecs.TransformPropagationReport,
) -> Bool {
  report.used_full_path
}

///|
/// Implements `transform_propagation_report_fallback_to_full`.
pub fn transform_propagation_report_fallback_to_full(
  report : @ecs.TransformPropagationReport,
) -> Bool {
  report.fallback_to_full
}

///|
/// Implements `transform_propagation_report_dirty_queue_count`.
pub fn transform_propagation_report_dirty_queue_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.dirty_queue_count
}

///|
/// Implements `transform_propagation_report_dirty_root_count`.
pub fn transform_propagation_report_dirty_root_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.dirty_root_count
}

///|
/// Implements `transform_propagation_report_skipped_dirty_entity_count`.
pub fn transform_propagation_report_skipped_dirty_entity_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.skipped_dirty_entity_count
}

///|
/// Implements `transform_propagation_report_visited_entity_count`.
pub fn transform_propagation_report_visited_entity_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.visited_entity_count
}

///|
/// Implements `transform_propagation_report_global_transform_write_count`.
pub fn transform_propagation_report_global_transform_write_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.global_transform_write_count
}

///|
/// Implements `transform_propagation_report_hierarchy_index_rebuilt`.
pub fn transform_propagation_report_hierarchy_index_rebuilt(
  report : @ecs.TransformPropagationReport,
) -> Bool {
  report.hierarchy_index_rebuilt
}

///|
/// Implements `transform_propagation_report_pending_upload_range_count`.
pub fn transform_propagation_report_pending_upload_range_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.pending_upload_range_count
}

///|
/// Implements `transform_propagation_report_failure_reason`.
pub fn transform_propagation_report_failure_reason(
  report : @ecs.TransformPropagationReport,
) -> String {
  match report.failure_reason {
    NoFailure => "none"
    BrokenAncestorChain => "broken_ancestor_chain"
    MissingGlobalTransformRef => "missing_global_transform_ref"
    ArchetypePathUnavailable => "archetype_path_unavailable"
  }
}

///|
/// Implements `transform_propagation_report_failure_count`.
pub fn transform_propagation_report_failure_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.failure_count
}

///|
/// Implements `transform_propagation_report_broken_ancestor_chain_count`.
pub fn transform_propagation_report_broken_ancestor_chain_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.broken_ancestor_chain_count
}

///|
/// Implements `transform_propagation_report_missing_global_transform_ref_count`.
pub fn transform_propagation_report_missing_global_transform_ref_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.missing_global_transform_ref_count
}

///|
/// Implements `transform_propagation_report_archetype_path_unavailable_count`.
pub fn transform_propagation_report_archetype_path_unavailable_count(
  report : @ecs.TransformPropagationReport,
) -> Int {
  report.archetype_path_unavailable_count
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
/// Implements `world_history_validate_import_undo_stack`.
pub fn world_history_validate_import_undo_stack(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  exported : @ecs.WorldHistoryExport,
) -> @ecs.WorldHistoryImportValidationReport {
  history.validate_import_undo_stack(world, exported)
}

///|
/// Implements `world_history_validate_import_redo_stack`.
pub fn world_history_validate_import_redo_stack(
  history : @ecs.WorldHistory,
  world : @ecs.World,
  exported : @ecs.WorldHistoryExport,
) -> @ecs.WorldHistoryImportValidationReport {
  history.validate_import_redo_stack(world, exported)
}

///|
/// Implements `world_history_import_validation_report_valid`.
pub fn world_history_import_validation_report_valid(
  report : @ecs.WorldHistoryImportValidationReport,
) -> Bool {
  report.valid
}

///|
/// Implements `world_history_import_validation_report_reason`.
pub fn world_history_import_validation_report_reason(
  report : @ecs.WorldHistoryImportValidationReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_import_validation_report_format_version`.
pub fn world_history_import_validation_report_format_version(
  report : @ecs.WorldHistoryImportValidationReport,
) -> Int {
  report.format_version
}

///|
/// Implements `world_history_import_validation_report_record_count`.
pub fn world_history_import_validation_report_record_count(
  report : @ecs.WorldHistoryImportValidationReport,
) -> Int {
  report.record_count
}

///|
/// Implements `world_history_import_validation_report_records`.
pub fn world_history_import_validation_report_records(
  report : @ecs.WorldHistoryImportValidationReport,
) -> Array[@ecs.WorldHistoryImportValidationRecordReport] {
  report.records
}

///|
/// Implements `world_history_import_validation_record_report_index`.
pub fn world_history_import_validation_record_report_index(
  report : @ecs.WorldHistoryImportValidationRecordReport,
) -> Int {
  report.index
}

///|
/// Implements `world_history_import_validation_record_report_label`.
pub fn world_history_import_validation_record_report_label(
  report : @ecs.WorldHistoryImportValidationRecordReport,
) -> String {
  report.label
}

///|
/// Implements `world_history_import_validation_record_report_valid`.
pub fn world_history_import_validation_record_report_valid(
  report : @ecs.WorldHistoryImportValidationRecordReport,
) -> Bool {
  report.valid
}

///|
/// Implements `world_history_import_validation_record_report_reason`.
pub fn world_history_import_validation_record_report_reason(
  report : @ecs.WorldHistoryImportValidationRecordReport,
) -> String {
  report.reason
}

///|
/// Implements `world_history_import_validation_record_report_delta_count`.
pub fn world_history_import_validation_record_report_delta_count(
  report : @ecs.WorldHistoryImportValidationRecordReport,
) -> Int {
  report.delta_count
}

///|
/// Implements `world_history_import_validation_record_report_deltas`.
pub fn world_history_import_validation_record_report_deltas(
  report : @ecs.WorldHistoryImportValidationRecordReport,
) -> Array[@ecs.WorldHistoryImportValidationDeltaReport] {
  report.deltas
}

///|
/// Implements `world_history_import_validation_delta_report_index`.
pub fn world_history_import_validation_delta_report_index(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> Int {
  report.index
}

///|
/// Implements `world_history_import_validation_delta_report_kind`.
pub fn world_history_import_validation_delta_report_kind(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> String {
  report.kind
}

///|
/// Implements `world_history_import_validation_delta_report_entity`.
pub fn world_history_import_validation_delta_report_entity(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> @ecs.EntityId? {
  report.entity
}

///|
/// Implements `world_history_import_validation_delta_report_component`.
pub fn world_history_import_validation_delta_report_component(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> @ecs.ComponentTypeId? {
  report.component
}

///|
/// Implements `world_history_import_validation_delta_report_component_key`.
pub fn world_history_import_validation_delta_report_component_key(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> String? {
  report.component_key
}

///|
/// Implements `world_history_import_validation_delta_report_valid`.
pub fn world_history_import_validation_delta_report_valid(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> Bool {
  report.valid
}

///|
/// Implements `world_history_import_validation_delta_report_reason`.
pub fn world_history_import_validation_delta_report_reason(
  report : @ecs.WorldHistoryImportValidationDeltaReport,
) -> String {
  report.reason
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
