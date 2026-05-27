/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `raw_query_cache_excluded_components`.
pub fn raw_query_cache_excluded_components(
  cache : @ecs.RawQueryCache,
) -> Array[@ecs.ComponentTypeId] {
  cache.excluded_components()
}

///|
/// Implements `raw_query_required_components`.
pub fn raw_query_required_components(
  query : @ecs.RawQuery,
) -> Array[@ecs.ComponentTypeId] {
  query.required_components()
}

///|
/// Implements `raw_query_excluded_components`.
pub fn raw_query_excluded_components(
  query : @ecs.RawQuery,
) -> Array[@ecs.ComponentTypeId] {
  query.excluded_components()
}

///|
/// Implements `raw_query_component_index`.
pub fn raw_query_component_index(
  query : @ecs.RawQuery,
  component : @ecs.ComponentTypeId,
) -> Int {
  query.component_index(component)
}

///|
/// Implements `raw_query_cache_component_index`.
pub fn raw_query_cache_component_index(
  cache : @ecs.RawQueryCache,
  component : @ecs.ComponentTypeId,
) -> Int {
  cache.component_index(component)
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
/// Implements `query_for_each_read_at`.
pub fn query_for_each_read_at(
  query : @ecs.Query,
  world : @ecs.World,
  index : Int,
  f : (@ecs.EntityId, ArrayView[Byte]) -> Unit,
) -> Unit {
  query.for_each_read_at(world, index, f)
}

///|
/// Implements `query_cache_for_each`.
pub fn query_cache_for_each(
  cache : @ecs.QueryCache,
  world : @ecs.World,
  f : (@ecs.QueryRow) -> Unit,
) -> Unit {
  cache.for_each(world, f)
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
/// Implements `raw_query_for_each_read_view_at`.
pub fn raw_query_for_each_read_view_at(
  query : @ecs.RawQuery,
  world : @ecs.World,
  index : Int,
  f : (@ecs.EntityId, ArrayView[Byte]) -> Unit,
) -> Unit {
  query.for_each_read_view_at(world, index, f)
}

///|
/// Implements `raw_query_cache_for_each`.
pub fn raw_query_cache_for_each(
  cache : @ecs.RawQueryCache,
  world : @ecs.World,
  f : (@ecs.RawQueryRow) -> Unit,
) -> Unit {
  cache.for_each(world, f)
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
/// Implements `query_plan`.
pub fn query_plan(query : @ecs.Query, world : @ecs.World) -> @ecs.QueryPlan {
  query.plan(world)
}

///|
/// Implements `query_cache_plan`.
pub fn query_cache_plan(
  cache : @ecs.QueryCache,
  world : @ecs.World,
) -> @ecs.QueryPlan {
  cache.plan(world)
}

///|
/// Implements `query_cache_refresh`.
pub fn query_cache_refresh(cache : @ecs.QueryCache, world : @ecs.World) -> Unit {
  cache.refresh(world)
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
/// Implements `raw_query_plan`.
pub fn raw_query_plan(
  query : @ecs.RawQuery,
  world : @ecs.World,
) -> @ecs.QueryPlan {
  query.plan(world)
}

///|
/// Implements `raw_query_cache_plan`.
pub fn raw_query_cache_plan(
  cache : @ecs.RawQueryCache,
  world : @ecs.World,
) -> @ecs.QueryPlan {
  cache.plan(world)
}

///|
/// Implements `raw_query_cache_refresh`.
pub fn raw_query_cache_refresh(
  cache : @ecs.RawQueryCache,
  world : @ecs.World,
) -> Unit {
  cache.refresh(world)
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
/// Implements `raw_query_cache_for_each_archetype`.
pub fn raw_query_cache_for_each_archetype(
  cache : @ecs.RawQueryCache,
  world : @ecs.World,
  f : (@ecs.RawQueryArchetype) -> Unit,
) -> Unit {
  cache.for_each_archetype(world, f)
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
/// Implements `raw_prepared_query_plan`.
pub fn raw_prepared_query_plan(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
) -> @ecs.QueryPlan {
  query.plan(world)
}

///|
/// Implements `raw_prepared_query_is_stale`.
pub fn raw_prepared_query_is_stale(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
) -> Bool {
  query.is_stale(world)
}

///|
/// Implements `raw_prepared_query_refresh`.
pub fn raw_prepared_query_refresh(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
) -> @ecs.RawPreparedQuery {
  query.refresh(world)
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
/// Implements `prepared_query_for_each_read_at`.
pub fn prepared_query_for_each_read_at(
  query : @ecs.PreparedQuery,
  world : @ecs.World,
  index : Int,
  f : (@ecs.EntityId, ArrayView[Byte]) -> Unit,
) -> Unit {
  query.for_each_read_at(world, index, f)
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
/// Implements `raw_prepared_query_for_each_read_view_at`.
pub fn raw_prepared_query_for_each_read_view_at(
  query : @ecs.RawPreparedQuery,
  world : @ecs.World,
  index : Int,
  f : (@ecs.EntityId, ArrayView[Byte]) -> Unit,
) -> Unit {
  query.for_each_read_view_at(world, index, f)
}

///|
/// Implements `prepared_query_plan`.
pub fn prepared_query_plan(
  query : @ecs.PreparedQuery,
  world : @ecs.World,
) -> @ecs.QueryPlan {
  query.plan(world)
}

///|
/// Implements `prepared_query_is_stale`.
pub fn prepared_query_is_stale(
  query : @ecs.PreparedQuery,
  world : @ecs.World,
) -> Bool {
  query.is_stale(world)
}

///|
/// Implements `prepared_query_refresh`.
pub fn prepared_query_refresh(
  query : @ecs.PreparedQuery,
  world : @ecs.World,
) -> @ecs.PreparedQuery {
  query.refresh(world)
}

///|
/// Implements `query_plan_required_components`.
pub fn query_plan_required_components(
  plan : @ecs.QueryPlan,
) -> Array[@ecs.ComponentTypeId] {
  plan.required
}

///|
/// Implements `query_plan_excluded_components`.
pub fn query_plan_excluded_components(
  plan : @ecs.QueryPlan,
) -> Array[@ecs.ComponentTypeId] {
  plan.excluded
}

///|
/// Implements `query_plan_archetype_version`.
pub fn query_plan_archetype_version(plan : @ecs.QueryPlan) -> Int {
  plan.archetype_version
}

///|
/// Implements `query_plan_candidate_archetype_count`.
pub fn query_plan_candidate_archetype_count(plan : @ecs.QueryPlan) -> Int {
  plan.candidate_archetype_count
}

///|
/// Implements `query_plan_matched_archetype_count`.
pub fn query_plan_matched_archetype_count(plan : @ecs.QueryPlan) -> Int {
  plan.matched_archetype_count
}

///|
/// Implements `query_plan_matched_row_count`.
pub fn query_plan_matched_row_count(plan : @ecs.QueryPlan) -> Int {
  plan.matched_row_count
}

///|
/// Implements `query_plan_stale`.
pub fn query_plan_stale(plan : @ecs.QueryPlan) -> Bool {
  plan.stale
}

///|
/// Implements `query_plan_archetypes`.
pub fn query_plan_archetypes(
  plan : @ecs.QueryPlan,
) -> Array[@ecs.QueryPlanArchetype] {
  plan.archetypes
}

///|
/// Implements `query_plan_archetype_index`.
pub fn query_plan_archetype_index(archetype : @ecs.QueryPlanArchetype) -> Int {
  archetype.archetype_index
}

///|
/// Implements `query_plan_archetype_row_count`.
pub fn query_plan_archetype_row_count(
  archetype : @ecs.QueryPlanArchetype,
) -> Int {
  archetype.row_count
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
/// Implements `query_row_has_at`.
pub fn query_row_has_at(row : @ecs.QueryRow, index : Int) -> Bool {
  row.has_at(index)
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
/// Implements `raw_query_row_has_at`.
pub fn raw_query_row_has_at(row : @ecs.RawQueryRow, index : Int) -> Bool {
  row.has_at(index)
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
/// Implements `raw_query_row_read_view_at`.
pub fn raw_query_row_read_view_at(
  row : @ecs.RawQueryRow,
  index : Int,
) -> ArrayView[Byte] {
  row.read_view_at(index)
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
/// Implements `raw_query_row_write_view_at`.
pub fn raw_query_row_write_view_at(
  row : @ecs.RawQueryRow,
  index : Int,
) -> MutArrayView[Byte] {
  row.write_view_at(index)
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
/// Implements `raw_query_row_write_tracked_at`.
pub fn raw_query_row_write_tracked_at(
  row : @ecs.RawQueryRow,
  history : @ecs.WorldHistory,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  row.write_tracked_at(history, index, f)
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
/// Implements `query_row_read_at`.
pub fn query_row_read_at(
  row : @ecs.QueryRow,
  index : Int,
  f : (ArrayView[Byte]) -> Unit,
) -> Unit {
  row.read_at(index, f)
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
/// Implements `query_row_write_at`.
pub fn query_row_write_at(
  row : @ecs.QueryRow,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Unit {
  row.write_at(index, f)
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
/// Implements `query_row_write_tracked_at`.
pub fn query_row_write_tracked_at(
  row : @ecs.QueryRow,
  history : @ecs.WorldHistory,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  row.write_tracked_at(history, index, f)
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
/// Implements `raw_query_archetype_has_at`.
pub fn raw_query_archetype_has_at(
  arch : @ecs.RawQueryArchetype,
  index : Int,
) -> Bool {
  arch.has_at(index)
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
/// Implements `raw_query_archetype_component_stride_at`.
pub fn raw_query_archetype_component_stride_at(
  arch : @ecs.RawQueryArchetype,
  index : Int,
) -> Int {
  arch.component_stride_at(index)
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
/// Implements `raw_query_archetype_read_column_at`.
pub fn raw_query_archetype_read_column_at(
  arch : @ecs.RawQueryArchetype,
  index : Int,
) -> ArrayView[Byte] {
  arch.read_column_at(index)
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
/// Implements `raw_query_archetype_write_column_at`.
pub fn raw_query_archetype_write_column_at(
  arch : @ecs.RawQueryArchetype,
  index : Int,
) -> MutArrayView[Byte] {
  arch.write_column_at(index)
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
/// Implements `raw_query_archetype_write_column_tracked_at`.
pub fn raw_query_archetype_write_column_tracked_at(
  arch : @ecs.RawQueryArchetype,
  history : @ecs.WorldHistory,
  index : Int,
  f : (MutArrayView[Byte]) -> Unit,
) -> Bool {
  arch.write_column_tracked_at(history, index, f)
}

///|
/// Implements `raw_query_archetype_write_column_rows_tracked`.
pub fn raw_query_archetype_write_column_rows_tracked(
  arch : @ecs.RawQueryArchetype,
  history : @ecs.WorldHistory,
  component : @ecs.ComponentTypeId,
  rows : Array[Int],
  f : (Int, MutArrayView[Byte]) -> Unit,
) -> Bool {
  arch.write_column_rows_tracked(history, component, rows, f)
}

///|
/// Implements `raw_query_archetype_write_column_rows_tracked_at`.
pub fn raw_query_archetype_write_column_rows_tracked_at(
  arch : @ecs.RawQueryArchetype,
  history : @ecs.WorldHistory,
  index : Int,
  rows : Array[Int],
  f : (Int, MutArrayView[Byte]) -> Unit,
) -> Bool {
  arch.write_column_rows_tracked_at(history, index, rows, f)
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
/// Wraps a JS callback into a direct ECS system without a command buffer.
pub fn system_new_direct(
  name : String,
  phase : @ecs.PhaseKey,
  reads : Array[@ecs.ComponentTypeId],
  writes : Array[@ecs.ComponentTypeId],
  run : (@ecs.World, @ecs.SystemContext) -> Unit,
) -> @ecs.System {
  @ecs.System::new_direct(name, phase, reads, writes, run)
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
