///|
fn system_phase_rank(phase : SystemPhase) -> Int {
  match phase {
    PreUpdate => 0
    Update => 1
    PostUpdate => 2
    PreRender => 3
    RenderExtract => 4
  }
}

///|
fn system_phase_count() -> Int {
  5
}

///|
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
fn system_access_conflicts(a : System, b : System) -> Bool {
  a.structural_write ||
  b.structural_write ||
  component_array_intersects(a.writes, b.writes) ||
  component_array_intersects(a.writes, b.reads) ||
  component_array_intersects(a.reads, b.writes)
}

///|
pub fn SystemContext::new(
  delta_seconds : Float,
  frame_index : Int,
) -> SystemContext {
  { delta_seconds, frame_index }
}

///|
fn build_system(
  constructor_name : String,
  name : String,
  phase : SystemPhase,
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
pub fn System::new(
  name : String,
  phase : SystemPhase,
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
  phase : SystemPhase,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  run : (World, SystemContext, CommandBuffer) -> Unit,
) -> System {
  build_system(
    "System::new_with_structural_write", name, phase, reads, writes, true, run,
  )
}

///|
pub fn System::name(self : System) -> String {
  self.name
}

///|
pub fn System::phase(self : System) -> SystemPhase {
  self.phase
}

///|
pub fn System::reads(self : System) -> Array[ComponentTypeId] {
  copy_component_array(self.reads)
}

///|
pub fn System::writes(self : System) -> Array[ComponentTypeId] {
  copy_component_array(self.writes)
}

///|
pub fn System::structural_write(self : System) -> Bool {
  self.structural_write
}

///|
/// Returns true if two systems cannot safely run in parallel based on declared component access.
pub fn System::conflicts_with(self : System, other : System) -> Bool {
  system_access_conflicts(self, other)
}

///|
pub fn Schedule::new() -> Schedule {
  let systems : Array[System] = []
  { systems, }
}

///|
pub fn Schedule::len(self : Schedule) -> Int {
  self.systems.length()
}

///|
pub fn Schedule::add_system(self : Schedule, system : System) -> Unit {
  self.systems.push(system)
}

///|
/// Reports whether any two systems in the same phase have read/write or write/write conflicts.
///
/// `Schedule::run` remains single-threaded and registration-ordered; this helper is a scheduling
/// boundary for future parallel batching or validation.
pub fn Schedule::has_parallel_access_conflicts(self : Schedule) -> Bool {
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
pub fn transform_propagation_system(world : World) -> System {
  let tf = world.transform_component()
  let gt = world.global_transform_component()
  let co = world.child_of_component()
  System::new("TransformPropagation", PostUpdate, [tf, co], [gt], (
    system_world,
    _ctx,
    _commands,
  ) => system_world.update_global_transforms_from_transforms())
}

///|
/// Runs systems by phase order, preserving registration order within the same phase.
///
/// A fresh [`CommandBuffer`] is passed to each system and applied immediately after that system
/// returns, so later systems can observe earlier structural changes.
pub fn Schedule::run(
  self : Schedule,
  world : World,
  ctx : SystemContext,
) -> Bool {
  world.lock_component_registration()
  let mut ok = true
  for phase_rank = 0
      phase_rank < system_phase_count()
      phase_rank = phase_rank + 1 {
    for i = 0; i < self.systems.length(); i = i + 1 {
      let system = self.systems[i]
      if system_phase_rank(system.phase) == phase_rank {
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
        if !commands.apply() {
          ok = false
        }
        world.exit_system_access(system_access)
      }
    }
  }
  world.unlock_component_registration()
  ok
}
