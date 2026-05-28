/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `run_history_suite`.
fn run_history_suite(count : Int) -> Unit {
  run_case(
    "history_raw_set_component_bytes", count, bench_history_raw_set_component_bytes,
  )
  run_case(
    "history_disabled_set_component_bytes", count, bench_history_disabled_set_component_bytes,
  )
  run_case(
    "history_enabled_transaction_set_component_bytes", count, bench_history_enabled_transaction_set_component_bytes,
  )
  run_case(
    "history_guarded_transaction_set_component_bytes", count, bench_history_guarded_transaction_set_component_bytes,
  )
  run_case(
    "history_query_row_tracked_disabled", count, bench_history_query_row_tracked_disabled,
  )
  run_case(
    "history_query_row_tracked_enabled", count, bench_history_query_row_tracked_enabled,
  )
  run_case(
    "history_archetype_column_tracked_disabled", count, bench_history_archetype_column_tracked_disabled,
  )
  run_case(
    "history_archetype_column_tracked_enabled", count, bench_history_archetype_column_tracked_enabled,
  )
  run_case(
    "history_archetype_column_raw_noop", count, bench_history_archetype_column_raw_noop,
  )
  run_case(
    "history_archetype_column_tracked_noop", count, bench_history_archetype_column_tracked_noop,
  )
  run_case(
    "history_archetype_column_rows_tracked_noop", count, bench_history_archetype_column_rows_tracked_noop,
  )
  run_case(
    "history_archetype_column_raw_sparse", count, bench_history_archetype_column_raw_sparse,
  )
  run_case(
    "history_archetype_column_tracked_sparse", count, bench_history_archetype_column_tracked_sparse,
  )
  run_case(
    "history_archetype_column_rows_tracked_sparse", count, bench_history_archetype_column_rows_tracked_sparse,
  )
  run_case("history_command_raw_phase", count, bench_history_command_raw_phase)
  run_case(
    "history_command_tracked_phase", count, bench_history_command_tracked_phase,
  )
}

///|
/// Implements `run_suite`.
fn run_suite(count : Int) -> Unit {
  run_case("query_row", count, bench_query_row)
  run_case("query_row_indexed", count, bench_query_row_indexed)
  run_case("query_archetype", count, bench_query_archetype)
  run_case("query_archetype_offset", count, bench_query_archetype_offset)
  run_case("query_archetype_indexed", count, bench_query_archetype_indexed)
  run_case(
    "query_archetype_indexed_offset", count, bench_query_archetype_indexed_offset,
  )
  run_case(
    "query_archetype_chunked_64", count, bench_query_archetype_chunked_64,
  )
  run_case(
    "query_archetype_chunked_256", count, bench_query_archetype_chunked_256,
  )
  run_case(
    "query_archetype_chunked_indexed_64", count, bench_query_archetype_chunked_indexed_64,
  )
  run_case(
    "query_archetype_chunked_indexed_256", count, bench_query_archetype_chunked_indexed_256,
  )
  run_case(
    "query_archetype_chunked_span_64", count, bench_query_archetype_chunked_span_64,
  )
  run_case(
    "query_archetype_chunked_span_256", count, bench_query_archetype_chunked_span_256,
  )
  run_case(
    "query_archetype_chunked_span_1024", count, bench_query_archetype_chunked_span_1024,
  )
  run_case(
    "query_archetype_chunked_indexed_span_64", count, bench_query_archetype_chunked_indexed_span_64,
  )
  run_case(
    "query_archetype_chunked_indexed_span_256", count, bench_query_archetype_chunked_indexed_span_256,
  )
  run_case(
    "query_archetype_chunked_indexed_span_1024", count, bench_query_archetype_chunked_indexed_span_1024,
  )
  run_case(
    "query_many_archetypes_plan", count, bench_query_many_archetypes_plan,
  )
  run_case(
    "query_many_archetypes_prepare", count, bench_query_many_archetypes_prepare,
  )
  run_case("query_many_archetypes_row", count, bench_query_many_archetypes_row)
  run_case(
    "query_many_archetypes_archetype", count, bench_query_many_archetypes_archetype,
  )
  run_case(
    "query_many_archetypes_without_plan", count, bench_query_many_archetypes_without_plan,
  )
  run_case(
    "query_many_archetypes_without_row", count, bench_query_many_archetypes_without_row,
  )
  run_case(
    "query_many_archetypes_without_archetype", count, bench_query_many_archetypes_without_archetype,
  )
  run_case(
    "prepared_query_many_archetypes_reuse", count, bench_prepared_query_many_archetypes_reuse,
  )
  run_case(
    "prepared_query_tiny_rows_many_archetypes_repeated", count, bench_prepared_query_tiny_rows_many_archetypes_repeated,
  )
  run_case(
    "prepared_query_tiny_rows_many_archetypes_repeated_read_at", count, bench_prepared_query_tiny_rows_many_archetypes_repeated_read_at,
  )
  run_case(
    "raw_prepared_query_tiny_rows_many_archetypes_repeated", count, bench_raw_prepared_query_tiny_rows_many_archetypes_repeated,
  )
  run_case(
    "raw_prepared_query_tiny_rows_many_archetypes_repeated_read_view_at", count,
    bench_raw_prepared_query_tiny_rows_many_archetypes_repeated_read_view_at,
  )
  run_case(
    "prepared_query_many_archetypes_rebuild", count, bench_prepared_query_many_archetypes_rebuild,
  )
  run_case(
    "prepared_query_many_archetypes_is_stale_fresh", count, bench_prepared_query_many_archetypes_is_stale_fresh,
  )
  run_case(
    "prepared_query_many_archetypes_refresh_fresh", count, bench_prepared_query_many_archetypes_refresh_fresh,
  )
  run_case(
    "prepared_query_many_archetypes_refresh_stale", count, bench_prepared_query_many_archetypes_refresh_stale,
  )
  run_case(
    "prepared_query_many_archetypes_refresh_then_reuse", count, bench_prepared_query_many_archetypes_refresh_then_reuse,
  )
  run_case(
    "query_cache_many_archetypes_reuse", count, bench_query_cache_many_archetypes_reuse,
  )
  run_case(
    "query_cache_many_archetypes_refresh_after_structural_change", count, bench_query_cache_many_archetypes_refresh_after_structural_change,
  )
  run_case(
    "raw_query_cache_many_archetypes_archetype_reuse", count, bench_raw_query_cache_many_archetypes_archetype_reuse,
  )
  run_case("builtin_positions", count, bench_builtin_positions)
  run_case("global_transform_drain", count, bench_global_and_drain)
  run_case("global_transform_drain_views", count, bench_global_and_drain_views)
  run_case(
    "transform_propagation_dirty_noop_flat", count, bench_transform_propagation_dirty_noop_flat,
  )
  run_case(
    "transform_propagation_dirty_one_flat", count, bench_transform_propagation_dirty_one_flat,
  )
  run_case(
    "transform_propagation_full_one_flat", count, bench_transform_propagation_full_one_flat,
  )
  run_case(
    "transform_propagation_dirty_broad_root", count, bench_transform_propagation_dirty_broad_root,
  )
  run_case(
    "transform_propagation_full_broad_root", count, bench_transform_propagation_full_broad_root,
  )
  run_case(
    "global_transform_dense_range_write", count, bench_global_transform_dense_range_write,
  )
  run_case(
    "global_transform_by_refs_write", count, bench_global_transform_by_refs_write,
  )
  run_case(
    "global_transform_blob_reverse_row_drain", count, bench_global_transform_blob_reverse_row_drain,
  )
  run_case(
    "set_global_transform_changed", count, bench_set_global_transform_changed,
  )
  run_case(
    "set_global_transform_unchanged", count, bench_set_global_transform_unchanged,
  )
  run_case(
    "set_camera_matrices_changed", count, bench_set_camera_matrices_changed,
  )
  run_case(
    "set_camera_matrices_unchanged", count, bench_set_camera_matrices_unchanged,
  )
  run_case(
    "camera_blob_sync_row_query", count, bench_camera_blob_sync_row_query,
  )
  run_case(
    "camera_blob_sync_raw_cache", count, bench_camera_blob_sync_raw_cache,
  )
  run_case(
    "camera_blob_sync_system_phase", count, bench_camera_blob_sync_system_phase,
  )
  run_case(
    "camera_blob_sync_system_phase_clean", count, bench_camera_blob_sync_system_phase_clean,
  )
  run_case(
    "camera_blob_sync_command_system_phase", count, bench_camera_blob_sync_command_system_phase,
  )
  run_case(
    "orbit_camera_transform_row_query", count, bench_orbit_camera_transform_row_query,
  )
  run_case(
    "orbit_camera_transform_raw_cache", count, bench_orbit_camera_transform_raw_cache,
  )
  run_case(
    "orbit_camera_transform_system_phase", count, bench_orbit_camera_transform_system_phase,
  )
  run_case("make_world_batch", count, bench_make_world_batch)
  run_case("system_runner_phase_empty", count, bench_system_runner_phase_empty)
  run_case(
    "system_runner_phase_plan_cached_many_systems", count, bench_system_runner_phase_plan_cached_many_systems,
  )
  run_case(
    "system_runner_phase_run_cached_many_systems", count, bench_system_runner_phase_run_cached_many_systems,
  )
  run_case(
    "system_runner_phase_no_command_direct_write", count, bench_system_runner_phase_no_command_direct_write,
  )
  run_case(
    "system_runner_phase_command_buffer", count, bench_system_runner_phase_command_buffer,
  )
  run_history_suite(count)
}

///|
/// Implements `run_transform_propagation_shape_suite`.
fn run_transform_propagation_shape_suite() -> Unit {
  run_case(
    "transform_propagation_dirty_chain_root", 128, bench_transform_propagation_dirty_chain_root,
  )
  run_case(
    "transform_propagation_full_chain_root", 128, bench_transform_propagation_full_chain_root,
  )
  run_case(
    "transform_propagation_dirty_chain_root", 256, bench_transform_propagation_dirty_chain_root,
  )
  run_case(
    "transform_propagation_full_chain_root", 256, bench_transform_propagation_full_chain_root,
  )
  run_case(
    "transform_propagation_dirty_chain_root", 512, bench_transform_propagation_dirty_chain_root,
  )
  run_case(
    "transform_propagation_full_chain_root", 512, bench_transform_propagation_full_chain_root,
  )
}

///|
/// Runs the fixed ECS microbench suite.
fn main {
  println("ecs_bench: fixed ECS microbench suite (warmup=1 measured=5)")
  run_suite(1000)
  run_suite(10000)
  run_transform_propagation_shape_suite()
}
