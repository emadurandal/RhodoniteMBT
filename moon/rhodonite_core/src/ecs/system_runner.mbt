/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `component_array_intersects`.
fn component_array_intersects(
  a : Array[ComponentTypeId],
  b : Array[ComponentTypeId],
) -> Bool {
  for i = 0; i < a.length(); i = i + 1 {
    if component_array_contains(b, a[i]) {
      return true
    }
  }
  false
}

///|
/// Implements `phase_array_contains`.
pub fn phase_array_contains(phases : Array[PhaseKey], phase : PhaseKey) -> Bool {
  for i = 0; i < phases.length(); i = i + 1 {
    if phases[i] == phase {
      return true
    }
  }
  false
}

///|
/// Implements `system_access_conflicts`.
fn system_access_conflicts(a : System, b : System) -> Bool {
  a.structural_write ||
  b.structural_write ||
  component_array_intersects(a.writes, b.writes) ||
  component_array_intersects(a.writes, b.reads) ||
  component_array_intersects(a.reads, b.writes)
}

///|
/// Implements `scheduled_system_batch_conflicts_with`.
fn scheduled_system_batch_conflicts_with(
  batch : Array[ScheduledSystem],
  system : System,
) -> Bool {
  for i = 0; i < batch.length(); i = i + 1 {
    if batch[i].system.conflicts_with(system) {
      return true
    }
  }
  false
}

///|
/// Implements `copy_scheduled_system_array`.
fn copy_scheduled_system_array(
  src : Array[ScheduledSystem],
) -> Array[ScheduledSystem] {
  let out : Array[ScheduledSystem] = []
  for i = 0; i < src.length(); i = i + 1 {
    out.push(src[i])
  }
  out
}

///|
/// Rebuilds the conflict-free batches used by phase execution and planning.
fn SystemRunner::rebuild_phase_batches(
  self : SystemRunner,
  phase : PhaseKey,
) -> Array[SystemBatch] {
  let batches : Array[SystemBatch] = []
  let mut batch : Array[ScheduledSystem] = []
  for i = 0; i < self.systems.length(); i = i + 1 {
    let system = self.systems[i]
    if system.phase == phase {
      if scheduled_system_batch_conflicts_with(batch, system) {
        batches.push({ systems: copy_scheduled_system_array(batch) })
        batch = []
      }
      batch.push({ runner_index: i, system })
    }
  }
  if batch.length() > 0 {
    batches.push({ systems: copy_scheduled_system_array(batch) })
  }
  batches
}

///|
/// Returns cached conflict-free batches for a phase, rebuilding when the runner changed.
fn SystemRunner::phase_batches(
  self : SystemRunner,
  phase : PhaseKey,
) -> Array[SystemBatch] {
  for i = 0; i < self.phase_batch_cache.length(); i = i + 1 {
    let cached = self.phase_batch_cache[i]
    if cached.phase == phase && cached.generation == self.plan_generation {
      return cached.batches
    }
  }
  let batches = self.rebuild_phase_batches(phase)
  self.phase_batch_cache.push({
    phase,
    generation: self.plan_generation,
    batches,
  })
  batches
}

///|
/// Builds a public snapshot for one scheduled system.
fn scheduled_system_plan(
  scheduled : ScheduledSystem,
  batch_index : Int,
) -> SystemPlanSystem {
  let system = scheduled.system
  {
    runner_index: scheduled.runner_index,
    batch_index,
    name: system.name,
    phase: system.phase,
    reads: copy_component_array(system.reads),
    writes: copy_component_array(system.writes),
    structural_write: system.structural_write,
  }
}

///|
/// Builds a public snapshot for one execution batch.
fn system_batch_plan(batch : SystemBatch, batch_index : Int) -> SystemPlanBatch {
  let systems : Array[SystemPlanSystem] = []
  for i = 0; i < batch.systems.length(); i = i + 1 {
    systems.push(scheduled_system_plan(batch.systems[i], batch_index))
  }
  { index: batch_index, systems }
}

///|
/// Builds an empty phase execution report.
fn empty_system_run_report(phase : PhaseKey, ok : Bool) -> SystemRunReport {
  {
    phase,
    ok,
    batch_count: 0,
    system_count: 0,
    queued_command_count: 0,
    applied_command_count: 0,
    failed_command_count: 0,
    batches: [],
  }
}

///|
/// Aggregates one batch execution report from per-system command reports.
fn system_run_batch_report(
  batch_index : Int,
  systems : Array[SystemRunSystemReport],
) -> SystemRunBatchReport {
  let mut queued_command_count = 0
  let mut applied_command_count = 0
  let mut failed_command_count = 0
  for i = 0; i < systems.length(); i = i + 1 {
    queued_command_count = queued_command_count +
      systems[i].queued_command_count
    applied_command_count = applied_command_count +
      systems[i].applied_command_count
    failed_command_count = failed_command_count +
      systems[i].failed_command_count
  }
  {
    index: batch_index,
    ok: failed_command_count == 0,
    system_count: systems.length(),
    queued_command_count,
    applied_command_count,
    failed_command_count,
    systems,
  }
}

///|
/// Aggregates one phase execution report from per-batch reports.
fn system_run_report(
  phase : PhaseKey,
  batches : Array[SystemRunBatchReport],
) -> SystemRunReport {
  let mut system_count = 0
  let mut queued_command_count = 0
  let mut applied_command_count = 0
  let mut failed_command_count = 0
  for i = 0; i < batches.length(); i = i + 1 {
    system_count = system_count + batches[i].system_count
    queued_command_count = queued_command_count +
      batches[i].queued_command_count
    applied_command_count = applied_command_count +
      batches[i].applied_command_count
    failed_command_count = failed_command_count +
      batches[i].failed_command_count
  }
  {
    phase,
    ok: failed_command_count == 0,
    batch_count: batches.length(),
    system_count,
    queued_command_count,
    applied_command_count,
    failed_command_count,
    batches,
  }
}

///|
/// Runs one system batch and returns command-buffer apply diagnostics.
fn run_system_batch_report(
  batch : SystemBatch,
  world : World,
  ctx : SystemContext,
  batch_index : Int,
) -> SystemRunBatchReport {
  let command_buffers : Array[CommandBuffer] = []
  for i = 0; i < batch.systems.length(); i = i + 1 {
    let system = batch.systems[i].system
    let commands = CommandBuffer::new_for_system(
      world,
      system.name,
      system.writes,
      system.structural_write,
    )
    let system_access = world.enter_system_access(
      system.name,
      system.reads,
      system.writes,
      system.structural_write,
    )
    (system.run)(world, ctx, commands)
    world.exit_system_access(system_access)
    command_buffers.push(commands)
  }
  let system_reports : Array[SystemRunSystemReport] = []
  for i = 0; i < command_buffers.length(); i = i + 1 {
    let system = batch.systems[i].system
    let system_access = world.enter_system_access(
      system.name,
      system.reads,
      system.writes,
      system.structural_write,
    )
    system_reports.push(
      command_buffers[i].apply_report(
        batch.systems[i].runner_index,
        batch_index,
      ),
    )
    world.exit_system_access(system_access)
  }
  system_run_batch_report(batch_index, system_reports)
}

///|
/// Runs one system batch with tracked command apply diagnostics.
fn run_system_batch_tracked_report(
  batch : SystemBatch,
  world : World,
  ctx : SystemContext,
  history : WorldHistory,
  batch_index : Int,
) -> SystemRunBatchReport {
  let command_buffers : Array[CommandBuffer] = []
  for i = 0; i < batch.systems.length(); i = i + 1 {
    let system = batch.systems[i].system
    let commands = CommandBuffer::new_for_history_system(
      world,
      system.name,
      system.writes,
      system.structural_write,
      history,
    )
    let system_access = world.enter_system_access(
      system.name,
      system.reads,
      system.writes,
      system.structural_write,
    )
    (system.run)(world, ctx, commands)
    world.exit_system_access(system_access)
    command_buffers.push(commands)
  }
  let system_reports : Array[SystemRunSystemReport] = []
  for i = 0; i < command_buffers.length(); i = i + 1 {
    let system = batch.systems[i].system
    let system_access = world.enter_system_access(
      system.name,
      system.reads,
      system.writes,
      system.structural_write,
    )
    system_reports.push(
      command_buffers[i].apply_tracked_report(
        history,
        batch.systems[i].runner_index,
        batch_index,
      ),
    )
    world.exit_system_access(system_access)
  }
  system_run_batch_report(batch_index, system_reports)
}

///|
/// Implements `SystemContext::new`.
pub fn SystemContext::new(
  delta_seconds : Float,
  frame_index : Int,
) -> SystemContext {
  { delta_seconds, frame_index }
}

///|
/// Implements `PhaseKey::new`.
pub fn PhaseKey::new(name : String) -> PhaseKey {
  { name, }
}

///|
/// Implements `PhaseKey::name`.
pub fn PhaseKey::name(self : PhaseKey) -> String {
  self.name
}

///|
/// Implements `build_system`.
fn build_system(
  constructor_name : String,
  name : String,
  phase : PhaseKey,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  structural_write : Bool,
  run : (World, SystemContext, CommandBuffer) -> Unit,
) -> System {
  if component_array_has_duplicates(reads) {
    abort(
      constructor_name +
      " for System '" +
      name +
      "': duplicate read component. Hint: list each ComponentTypeId at most once in reads; if the system also writes it, put it only in writes.",
    )
  }
  if component_array_has_duplicates(writes) {
    abort(
      constructor_name +
      " for System '" +
      name +
      "': duplicate write component. Hint: list each ComponentTypeId at most once in writes; writes already permits reading that component.",
    )
  }
  if component_array_intersects(reads, writes) {
    abort(
      constructor_name +
      " for System '" +
      name +
      "': reads and writes overlap. Hint: if a system may mutate a component, put that ComponentTypeId only in writes; writes also allows read access.",
    )
  }
  {
    name,
    phase,
    reads: copy_component_array(reads),
    writes: copy_component_array(writes),
    structural_write,
    run,
  }
}

///|
/// Implements `System::new`.
pub fn System::new(
  name : String,
  phase : PhaseKey,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  run : (World, SystemContext, CommandBuffer) -> Unit,
) -> System {
  build_system("System::new", name, phase, reads, writes, false, run)
}

///|
/// Builds a system that may create or destroy entities in addition to its declared component access.
pub fn System::new_with_structural_write(
  name : String,
  phase : PhaseKey,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  run : (World, SystemContext, CommandBuffer) -> Unit,
) -> System {
  build_system(
    "System::new_with_structural_write", name, phase, reads, writes, true, run,
  )
}

///|
/// Implements `System::name`.
pub fn System::name(self : System) -> String {
  self.name
}

///|
/// Implements `System::phase`.
pub fn System::phase(self : System) -> PhaseKey {
  self.phase
}

///|
/// Implements `System::reads`.
pub fn System::reads(self : System) -> Array[ComponentTypeId] {
  copy_component_array(self.reads)
}

///|
/// Implements `System::writes`.
pub fn System::writes(self : System) -> Array[ComponentTypeId] {
  copy_component_array(self.writes)
}

///|
/// Implements `System::structural_write`.
pub fn System::structural_write(self : System) -> Bool {
  self.structural_write
}

///|
/// Returns true if two systems cannot safely run in parallel based on declared component access.
pub fn System::conflicts_with(self : System, other : System) -> Bool {
  system_access_conflicts(self, other)
}

///|
/// Implements `SystemRunner::new`.
pub fn SystemRunner::new() -> SystemRunner {
  let systems : Array[System] = []
  let phase_batch_cache : Array[SystemPhaseBatchCache] = []
  { systems, plan_generation: 0, phase_batch_cache }
}

///|
/// Implements `SystemRunner::len`.
pub fn SystemRunner::len(self : SystemRunner) -> Int {
  self.systems.length()
}

///|
/// Implements `SystemRunner::add_system`.
pub fn SystemRunner::add_system(self : SystemRunner, system : System) -> Unit {
  self.systems.push(system)
  self.plan_generation = self.plan_generation + 1
  self.phase_batch_cache = []
}

///|
/// Returns the conflict-free batches that `run_phase` would execute for `phase`.
///
/// The returned plan is a snapshot: mutating its arrays does not change the runner.
pub fn SystemRunner::plan_phase(
  self : SystemRunner,
  phase : PhaseKey,
) -> SystemPhasePlan {
  let batches = self.phase_batches(phase)
  let plan_batches : Array[SystemPlanBatch] = []
  let mut system_count = 0
  for i = 0; i < batches.length(); i = i + 1 {
    system_count = system_count + batches[i].systems.length()
    plan_batches.push(system_batch_plan(batches[i], i))
  }
  { phase, system_count, batches: plan_batches }
}

///|
/// Reports whether any two systems in the same phase have read/write or write/write conflicts.
///
/// `SystemRunner::run_phase` remains single-threaded and registration-ordered; this helper is a
/// scheduling boundary for future parallel batching or validation.
pub fn SystemRunner::has_parallel_access_conflicts(self : SystemRunner) -> Bool {
  for i = 0; i < self.systems.length(); i = i + 1 {
    for j = i + 1; j < self.systems.length(); j = j + 1 {
      if self.systems[i].phase == self.systems[j].phase &&
        self.systems[i].conflicts_with(self.systems[j]) {
        return true
      }
    }
  }
  false
}

///|
/// Builtin system that mirrors [`World::update_global_transforms_from_transforms`].
pub fn transform_propagation_system(world : World, phase : PhaseKey) -> System {
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let co = world.child_of_component()
  System::new("TransformPropagation", phase, [tf, co], [gt], (
    system_world,
    _ctx,
    _commands,
  ) => system_world.update_global_transforms_from_transforms())
}

///|
/// Runs systems in one phase, preserving registration order within the phase.
///
/// Within each phase, systems are greedily split into conflict-free batches. A fresh
/// [`CommandBuffer`] is passed to each system; commands from a batch are applied only after every
/// system in that batch has returned, preserving registration order for apply. Later batches can
/// observe earlier batch commands, while systems in the same batch cannot observe each other's
/// queued changes.
pub fn SystemRunner::run_phase(
  self : SystemRunner,
  world : World,
  ctx : SystemContext,
  phase : PhaseKey,
) -> Bool {
  self.run_phase_report_with_operation(
    world, ctx, phase, "SystemRunner::run_phase",
  ).ok
}

///|
/// Runs systems in one phase and returns command-buffer apply diagnostics.
pub fn SystemRunner::run_phase_report(
  self : SystemRunner,
  world : World,
  ctx : SystemContext,
  phase : PhaseKey,
) -> SystemRunReport {
  self.run_phase_report_with_operation(
    world, ctx, phase, "SystemRunner::run_phase_report",
  )
}

///|
/// Runs one phase with a caller-specific raw-mutation guard operation label.
fn SystemRunner::run_phase_report_with_operation(
  self : SystemRunner,
  world : World,
  ctx : SystemContext,
  phase : PhaseKey,
  operation : String,
) -> SystemRunReport {
  world.assert_not_history_raw_mutation(operation)
  world.lock_component_registration()
  let batches = self.phase_batches(phase)
  let batch_reports : Array[SystemRunBatchReport] = []
  for i = 0; i < batches.length(); i = i + 1 {
    batch_reports.push(run_system_batch_report(batches[i], world, ctx, i))
  }
  world.unlock_component_registration()
  system_run_report(phase, batch_reports)
}

///|
/// Runs systems in one phase with tracked command-buffer diagnostics.
fn SystemRunner::run_phase_tracked_report(
  self : SystemRunner,
  world : World,
  ctx : SystemContext,
  phase : PhaseKey,
  history : WorldHistory,
) -> SystemRunReport {
  world.lock_component_registration()
  let batches = self.phase_batches(phase)
  let batch_reports : Array[SystemRunBatchReport] = []
  for i = 0; i < batches.length(); i = i + 1 {
    batch_reports.push(
      run_system_batch_tracked_report(batches[i], world, ctx, history, i),
    )
  }
  world.unlock_component_registration()
  system_run_report(phase, batch_reports)
}
