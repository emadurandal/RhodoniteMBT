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
/// Implements `system_batch_conflicts_with`.
fn system_batch_conflicts_with(batch : Array[System], system : System) -> Bool {
  for i = 0; i < batch.length(); i = i + 1 {
    if batch[i].conflicts_with(system) {
      return true
    }
  }
  false
}

///|
/// Implements `run_system_batch`.
fn run_system_batch(
  batch : Array[System],
  world : World,
  ctx : SystemContext,
) -> Bool {
  let command_buffers : Array[CommandBuffer] = []
  for i = 0; i < batch.length(); i = i + 1 {
    let system = batch[i]
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
  let mut ok = true
  for i = 0; i < command_buffers.length(); i = i + 1 {
    let system = batch[i]
    let system_access = world.enter_system_access(
      system.name,
      system.reads,
      system.writes,
      system.structural_write,
    )
    if !command_buffers[i].apply() {
      ok = false
    }
    world.exit_system_access(system_access)
  }
  ok
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
  { systems, }
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
  world.lock_component_registration()
  let mut ok = true
  let batch : Array[System] = []
  for i = 0; i < self.systems.length(); i = i + 1 {
    let system = self.systems[i]
    if system.phase == phase {
      if system_batch_conflicts_with(batch, system) {
        if !run_system_batch(batch, world, ctx) {
          ok = false
        }
        while batch.length() > 0 {
          let _ = batch.pop()
        }
      }
      batch.push(system)
    }
  }
  if batch.length() > 0 {
    if !run_system_batch(batch, world, ctx) {
      ok = false
    }
    while batch.length() > 0 {
      let _ = batch.pop()
    }
  }
  world.unlock_component_registration()
  ok
}
