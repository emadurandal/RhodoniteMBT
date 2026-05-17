///|
/// Ordered phase list for one externally driven clock domain.
priv struct PhaseGroup {
  key : PhaseGroupKey
  phases : Array[PhaseKey]
}

///|
/// Returns the default engine phase groups.
fn default_phase_groups() -> Array[PhaseGroup] {
  let groups : Array[PhaseGroup] = []
  groups.push({
    key: phase_group_frame_begin(),
    phases: default_frame_begin_phases(),
  })
  groups.push({
    key: phase_group_fixed_step(),
    phases: default_fixed_step_phases(),
  })
  groups.push({
    key: phase_group_render_frame(),
    phases: default_render_frame_phases(),
  })
  groups
}

///|
/// Reports whether a phase group array contains a group.
fn phase_group_array_contains(
  groups : Array[PhaseGroup],
  group_key : PhaseGroupKey,
) -> Bool {
  for i = 0; i < groups.length(); i = i + 1 {
    if groups[i].key == group_key {
      return true
    }
  }
  false
}

///|
/// Finds a phase group index or returns -1.
fn phase_group_array_index(
  groups : Array[PhaseGroup],
  group_key : PhaseGroupKey,
) -> Int {
  for i = 0; i < groups.length(); i = i + 1 {
    if groups[i].key == group_key {
      return i
    }
  }
  -1
}
