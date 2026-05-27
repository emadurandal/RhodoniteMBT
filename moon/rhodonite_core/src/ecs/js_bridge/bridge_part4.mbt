/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `system_runner_has_parallel_access_conflicts`.
pub fn system_runner_has_parallel_access_conflicts(
  runner : @ecs.SystemRunner,
) -> Bool {
  runner.has_parallel_access_conflicts()
}

///|
/// Implements `system_runner_plan_phase`.
pub fn system_runner_plan_phase(
  runner : @ecs.SystemRunner,
  phase : @ecs.PhaseKey,
) -> @ecs.SystemPhasePlan {
  runner.plan_phase(phase)
}

///|
/// Implements `system_phase_plan_phase`.
pub fn system_phase_plan_phase(plan : @ecs.SystemPhasePlan) -> @ecs.PhaseKey {
  plan.phase
}

///|
/// Implements `system_phase_plan_system_count`.
pub fn system_phase_plan_system_count(plan : @ecs.SystemPhasePlan) -> Int {
  plan.system_count
}

///|
/// Implements `system_phase_plan_batches`.
pub fn system_phase_plan_batches(
  plan : @ecs.SystemPhasePlan,
) -> Array[@ecs.SystemPlanBatch] {
  plan.batches
}

///|
/// Implements `system_plan_batch_index`.
pub fn system_plan_batch_index(batch : @ecs.SystemPlanBatch) -> Int {
  batch.index
}

///|
/// Implements `system_plan_batch_systems`.
pub fn system_plan_batch_systems(
  batch : @ecs.SystemPlanBatch,
) -> Array[@ecs.SystemPlanSystem] {
  batch.systems
}

///|
/// Implements `system_plan_system_runner_index`.
pub fn system_plan_system_runner_index(system : @ecs.SystemPlanSystem) -> Int {
  system.runner_index
}

///|
/// Implements `system_plan_system_batch_index`.
pub fn system_plan_system_batch_index(system : @ecs.SystemPlanSystem) -> Int {
  system.batch_index
}

///|
/// Implements `system_plan_system_name`.
pub fn system_plan_system_name(system : @ecs.SystemPlanSystem) -> String {
  system.name
}

///|
/// Implements `system_plan_system_phase`.
pub fn system_plan_system_phase(
  system : @ecs.SystemPlanSystem,
) -> @ecs.PhaseKey {
  system.phase
}

///|
/// Implements `system_plan_system_reads`.
pub fn system_plan_system_reads(
  system : @ecs.SystemPlanSystem,
) -> Array[@ecs.ComponentTypeId] {
  system.reads
}

///|
/// Implements `system_plan_system_writes`.
pub fn system_plan_system_writes(
  system : @ecs.SystemPlanSystem,
) -> Array[@ecs.ComponentTypeId] {
  system.writes
}

///|
/// Implements `system_plan_system_structural_write`.
pub fn system_plan_system_structural_write(
  system : @ecs.SystemPlanSystem,
) -> Bool {
  system.structural_write
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
/// Implements `system_runner_run_phase_report`.
pub fn system_runner_run_phase_report(
  runner : @ecs.SystemRunner,
  world : @ecs.World,
  ctx : @ecs.SystemContext,
  phase : @ecs.PhaseKey,
) -> @ecs.SystemRunReport {
  runner.run_phase_report(world, ctx, phase)
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
/// Implements `world_history_run_system_phase_report`.
pub fn world_history_run_system_phase_report(
  history : @ecs.WorldHistory,
  runner : @ecs.SystemRunner,
  world : @ecs.World,
  ctx : @ecs.SystemContext,
  phase : @ecs.PhaseKey,
  label : String,
) -> @ecs.SystemRunReport {
  history.run_system_phase_report(runner, world, ctx, phase, label)
}

///|
/// Implements `system_run_report_phase`.
pub fn system_run_report_phase(report : @ecs.SystemRunReport) -> @ecs.PhaseKey {
  report.phase
}

///|
/// Implements `system_run_report_ok`.
pub fn system_run_report_ok(report : @ecs.SystemRunReport) -> Bool {
  report.ok
}

///|
/// Implements `system_run_report_batch_count`.
pub fn system_run_report_batch_count(report : @ecs.SystemRunReport) -> Int {
  report.batch_count
}

///|
/// Implements `system_run_report_system_count`.
pub fn system_run_report_system_count(report : @ecs.SystemRunReport) -> Int {
  report.system_count
}

///|
/// Implements `system_run_report_queued_command_count`.
pub fn system_run_report_queued_command_count(
  report : @ecs.SystemRunReport,
) -> Int {
  report.queued_command_count
}

///|
/// Implements `system_run_report_applied_command_count`.
pub fn system_run_report_applied_command_count(
  report : @ecs.SystemRunReport,
) -> Int {
  report.applied_command_count
}

///|
/// Implements `system_run_report_failed_command_count`.
pub fn system_run_report_failed_command_count(
  report : @ecs.SystemRunReport,
) -> Int {
  report.failed_command_count
}

///|
/// Implements `system_run_report_batches`.
pub fn system_run_report_batches(
  report : @ecs.SystemRunReport,
) -> Array[@ecs.SystemRunBatchReport] {
  report.batches
}

///|
/// Implements `system_run_batch_report_index`.
pub fn system_run_batch_report_index(report : @ecs.SystemRunBatchReport) -> Int {
  report.index
}

///|
/// Implements `system_run_batch_report_ok`.
pub fn system_run_batch_report_ok(report : @ecs.SystemRunBatchReport) -> Bool {
  report.ok
}

///|
/// Implements `system_run_batch_report_system_count`.
pub fn system_run_batch_report_system_count(
  report : @ecs.SystemRunBatchReport,
) -> Int {
  report.system_count
}

///|
/// Implements `system_run_batch_report_queued_command_count`.
pub fn system_run_batch_report_queued_command_count(
  report : @ecs.SystemRunBatchReport,
) -> Int {
  report.queued_command_count
}

///|
/// Implements `system_run_batch_report_applied_command_count`.
pub fn system_run_batch_report_applied_command_count(
  report : @ecs.SystemRunBatchReport,
) -> Int {
  report.applied_command_count
}

///|
/// Implements `system_run_batch_report_failed_command_count`.
pub fn system_run_batch_report_failed_command_count(
  report : @ecs.SystemRunBatchReport,
) -> Int {
  report.failed_command_count
}

///|
/// Implements `system_run_batch_report_systems`.
pub fn system_run_batch_report_systems(
  report : @ecs.SystemRunBatchReport,
) -> Array[@ecs.SystemRunSystemReport] {
  report.systems
}

///|
/// Implements `system_run_system_report_runner_index`.
pub fn system_run_system_report_runner_index(
  report : @ecs.SystemRunSystemReport,
) -> Int {
  report.runner_index
}

///|
/// Implements `system_run_system_report_batch_index`.
pub fn system_run_system_report_batch_index(
  report : @ecs.SystemRunSystemReport,
) -> Int {
  report.batch_index
}

///|
/// Implements `system_run_system_report_name`.
pub fn system_run_system_report_name(
  report : @ecs.SystemRunSystemReport,
) -> String {
  report.name
}

///|
/// Implements `system_run_system_report_queued_command_count`.
pub fn system_run_system_report_queued_command_count(
  report : @ecs.SystemRunSystemReport,
) -> Int {
  report.queued_command_count
}

///|
/// Implements `system_run_system_report_applied_command_count`.
pub fn system_run_system_report_applied_command_count(
  report : @ecs.SystemRunSystemReport,
) -> Int {
  report.applied_command_count
}

///|
/// Implements `system_run_system_report_failed_command_count`.
pub fn system_run_system_report_failed_command_count(
  report : @ecs.SystemRunSystemReport,
) -> Int {
  report.failed_command_count
}

///|
/// Implements `system_run_system_report_failures`.
pub fn system_run_system_report_failures(
  report : @ecs.SystemRunSystemReport,
) -> Array[@ecs.CommandBufferCommandFailure] {
  report.failures
}

///|
/// Implements `command_buffer_command_failure_command_index`.
pub fn command_buffer_command_failure_command_index(
  failure : @ecs.CommandBufferCommandFailure,
) -> Int {
  failure.command_index
}

///|
/// Implements `command_buffer_command_failure_command_kind`.
pub fn command_buffer_command_failure_command_kind(
  failure : @ecs.CommandBufferCommandFailure,
) -> String {
  failure.command_kind
}

///|
/// Implements `command_buffer_command_failure_reason`.
pub fn command_buffer_command_failure_reason(
  failure : @ecs.CommandBufferCommandFailure,
) -> String {
  failure.reason
}

///|
/// Implements `command_buffer_command_failure_entity`.
pub fn command_buffer_command_failure_entity(
  failure : @ecs.CommandBufferCommandFailure,
) -> @ecs.EntityId {
  failure.entity
}

///|
/// Implements `command_buffer_command_failure_component`.
pub fn command_buffer_command_failure_component(
  failure : @ecs.CommandBufferCommandFailure,
) -> @ecs.ComponentTypeId {
  failure.component
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
