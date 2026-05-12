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
pub fn SystemContext::new(
  delta_seconds : Float,
  frame_index : Int,
) -> SystemContext {
  { delta_seconds, frame_index }
}

///|
pub fn System::new(
  name : String,
  phase : SystemPhase,
  reads : Array[ComponentTypeId],
  writes : Array[ComponentTypeId],
  run : (World, SystemContext, CommandBuffer) -> Unit,
) -> System {
  if component_array_has_duplicates(reads) {
    abort("System::new: duplicate read component")
  }
  if component_array_has_duplicates(writes) {
    abort("System::new: duplicate write component")
  }
  {
    name,
    phase,
    reads: copy_component_array(reads),
    writes: copy_component_array(writes),
    run,
  }
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
/// Runs systems by phase order, preserving registration order within the same phase.
///
/// A fresh [`CommandBuffer`] is passed to each system and applied immediately after that system
/// returns, so later systems can observe earlier structural changes.
pub fn Schedule::run(
  self : Schedule,
  world : World,
  ctx : SystemContext,
) -> Bool {
  let mut ok = true
  for phase_rank = 0
      phase_rank < system_phase_count()
      phase_rank = phase_rank + 1 {
    for i = 0; i < self.systems.length(); i = i + 1 {
      let system = self.systems[i]
      if system_phase_rank(system.phase) == phase_rank {
        let commands = CommandBuffer::new()
        (system.run)(world, ctx, commands)
        if !commands.apply(world) {
          ok = false
        }
      }
    }
  }
  ok
}
