///|
/// Runtime that owns platform context, time state, and scenes.
pub struct Engine {
  priv gpu_context : @wgpu.GPUContext
  priv input_state : @input.InputState
  priv scenes : Array[Scene]
  priv main_scene_index : Int
  priv time_state : TimeState
  priv phase_groups : Array[PhaseGroup]
  priv phase_handlers : Array[PhaseHandler]
  priv mut phase_registration_locked : Bool
  priv mut initializing : Bool
  priv mut initialized : Bool
}

///|
/// Implements `Engine::new`.
pub fn Engine::new(gpu_context : @wgpu.GPUContext) -> Engine {
  Engine::new_with_main_scene(gpu_context, Scene::new("main"))
}

///|
/// Builds an engine with an explicitly configured main scene.
pub fn Engine::new_with_main_scene(
  gpu_context : @wgpu.GPUContext,
  main_scene : Scene,
) -> Engine {
  let scenes : Array[Scene] = []
  let phase_handlers : Array[PhaseHandler] = []
  scenes.push(main_scene)
  {
    gpu_context,
    input_state: @input.InputState::new(),
    scenes,
    main_scene_index: 0,
    time_state: TimeState::new(default_fixed_delta_seconds()),
    phase_groups: default_phase_groups(),
    phase_handlers,
    phase_registration_locked: false,
    initializing: false,
    initialized: false,
  }
}

///|
/// Implements `Engine::gpu_context`.
pub fn Engine::gpu_context(self : Engine) -> @wgpu.GPUContext {
  self.gpu_context
}

///|
/// Returns the engine-owned input state shared by platform adapters and systems.
pub fn Engine::input(self : Engine) -> @input.InputState {
  self.input_state
}

///|
/// Implements `Engine::main_scene`.
pub fn Engine::main_scene(self : Engine) -> Scene {
  self.scenes[self.main_scene_index]
}

///|
/// Ensures a phase handler can still be registered.
fn Engine::ensure_phase_handler_registration_open(
  self : Engine,
  caller : String,
) -> Unit {
  if self.phase_registration_locked {
    abort(
      caller +
      ": phase handlers cannot be registered after engine initialization",
    )
  }
}

///|
/// Appends a function to run in an engine phase slot.
pub fn Engine::add_phase_handler(
  self : Engine,
  phase : PhaseKey,
  handler : (Engine, FrameState) -> Unit,
  slot? : PhaseSlot = BeforeSystems,
) -> Unit {
  self.ensure_phase_handler_registration_open("Engine::add_phase_handler")
  self.phase_handlers.push({ phase, slot, run: handler })
}

///|
/// Appends the standard input handler for a scene main camera's orbit controller.
pub fn Engine::add_orbit_camera_controller_input_handler(
  self : Engine,
  scene : Scene,
  orbit_component : @ecs.ComponentTypeId,
  phase? : PhaseKey = phase_input(),
  slot? : PhaseSlot = BeforeSystems,
) -> Unit {
  self.add_phase_handler(
    phase,
    fn(engine, _frame) {
      let camera = scene_main_camera_or_abort(
        scene, "Engine::add_orbit_camera_controller_input_handler",
      )
      let input = engine.input()
      ignore(
        @ecs.update_orbit_camera_controller_from_mouse_frame(
          scene.world(),
          camera,
          orbit_component,
          input.mouse_down(Left),
          input.mouse_pressed(Left),
          input.mouse_down(Middle),
          input.mouse_pressed(Middle),
          input.pointer_delta_x(),
          input.pointer_delta_y(),
          input.wheel_delta_y(),
        ),
      )
    },
    slot~,
  )
}

///|
/// Adds standard engine handlers and scene systems shared by ECS samples.
pub fn Engine::add_common_handlers(
  self : Engine,
  scene : Scene,
  transform_propagation? : Bool = false,
  orbit_component? : @ecs.ComponentTypeId? = None,
  home_component? : @ecs.ComponentTypeId? = None,
  lens_component? : @ecs.ComponentTypeId? = None,
) -> Unit {
  scene.add_common_systems(
    transform_propagation~,
    orbit_component~,
    home_component~,
    lens_component~,
  )
  match orbit_component {
    Some(orbit) => self.add_orbit_camera_controller_input_handler(scene, orbit)
    None => ()
  }
}

///|
/// Prevents additional phase handler registration.
fn Engine::lock_phase_registration(self : Engine) -> Unit {
  self.phase_registration_locked = true
}

///|
/// Runs handlers registered for a phase slot.
fn Engine::run_phase_handlers(
  self : Engine,
  phase : PhaseKey,
  slot : PhaseSlot,
  frame : FrameState,
) -> Unit {
  for i = 0; i < self.phase_handlers.length(); i = i + 1 {
    let handler = self.phase_handlers[i]
    if handler.phase == phase && handler.slot == slot {
      (handler.run)(self, frame)
    }
  }
}

///|
/// Runs handlers registered before a phase's scene systems.
fn Engine::run_before_systems(
  self : Engine,
  phase : PhaseKey,
  frame : FrameState,
) -> Unit {
  self.run_phase_handlers(phase, BeforeSystems, frame)
}

///|
/// Runs handlers registered after a phase's scene systems.
fn Engine::run_after_systems(
  self : Engine,
  phase : PhaseKey,
  frame : FrameState,
) -> Unit {
  self.run_phase_handlers(phase, AfterSystems, frame)
}

///|
/// Returns a copy of one phase group's phase order.
pub fn Engine::phase_group_order(
  self : Engine,
  group_key : PhaseGroupKey,
) -> Array[PhaseKey] {
  let index = phase_group_array_index(self.phase_groups, group_key)
  if index < 0 {
    abort(
      "Engine::phase_group_order: phase group is not registered: " +
      group_key.name(),
    )
  }
  copy_phase_array(self.phase_groups[index].phases)
}

///|
/// Requires phase group edits to happen during startup.
fn Engine::ensure_phase_group_edit_window(
  self : Engine,
  caller : String,
) -> Unit {
  if !self.initializing {
    abort(
      caller + ": phase groups can only be edited during Engine::initialize",
    )
  }
}

///|
/// Validates a phase can be inserted into a phase group.
fn Engine::ensure_insertable_group_phase(
  _self : Engine,
  caller : String,
  phase_key : PhaseKey,
) -> Unit {
  if phase_is_one_shot(phase_key) {
    abort(caller + ": one-shot phases cannot be inserted into phase groups")
  }
}

///|
/// Finds a phase group or reports why it cannot be used.
fn Engine::find_phase_group(
  self : Engine,
  caller : String,
  group_key : PhaseGroupKey,
) -> Int {
  let group_index = phase_group_array_index(self.phase_groups, group_key)
  if group_index < 0 {
    abort(caller + ": phase group is not registered: " + group_key.name())
  }
  group_index
}

///|
/// Reports whether a phase is already registered in any phase group.
fn Engine::phase_registered_in_any_group(
  self : Engine,
  phase : PhaseKey,
) -> Bool {
  for i = 0; i < self.phase_groups.length(); i = i + 1 {
    if @ecs.phase_array_contains(self.phase_groups[i].phases, phase) {
      return true
    }
  }
  false
}

///|
/// Finds a phase group anchor or reports why it cannot be used.
fn Engine::find_group_phase_anchor(
  self : Engine,
  caller : String,
  group_key : PhaseGroupKey,
  anchor : PhaseKey,
) -> Int {
  if phase_is_one_shot(anchor) {
    abort(caller + ": one-shot phases cannot be used as phase group anchors")
  }
  let group_index = self.find_phase_group(caller, group_key)
  let index = phase_array_index(self.phase_groups[group_index].phases, anchor)
  if index < 0 {
    abort(
      caller +
      ": anchor phase is not registered in phase group " +
      group_key.name() +
      ": " +
      anchor.name(),
    )
  }
  index
}

///|
/// Registers an empty custom phase group.
pub fn Engine::add_phase_group(
  self : Engine,
  group_key : PhaseGroupKey,
) -> Unit {
  let caller = "Engine::add_phase_group"
  self.ensure_phase_group_edit_window(caller)
  if phase_group_array_contains(self.phase_groups, group_key) {
    abort(caller + ": phase group already exists: " + group_key.name())
  }
  self.phase_groups.push({ key: group_key, phases: [] })
}

///|
/// Appends a custom phase to a phase group.
pub fn Engine::append_phase_to_group(
  self : Engine,
  group_key : PhaseGroupKey,
  phase_key : PhaseKey,
) -> Unit {
  let caller = "Engine::append_phase_to_group"
  self.ensure_phase_group_edit_window(caller)
  self.ensure_insertable_group_phase(caller, phase_key)
  if self.phase_registered_in_any_group(phase_key) {
    abort(caller + ": phase already exists in a phase group")
  }
  let group_index = self.find_phase_group(caller, group_key)
  self.phase_groups[group_index].phases.push(phase_key)
}

///|
/// Inserts a custom phase before an existing phase in a group.
pub fn Engine::insert_phase_before_in_group(
  self : Engine,
  group_key : PhaseGroupKey,
  anchor : PhaseKey,
  phase_key : PhaseKey,
) -> Unit {
  let caller = "Engine::insert_phase_before_in_group"
  self.ensure_phase_group_edit_window(caller)
  self.ensure_insertable_group_phase(caller, phase_key)
  if self.phase_registered_in_any_group(phase_key) {
    abort(caller + ": phase already exists in a phase group")
  }
  let group_index = self.find_phase_group(caller, group_key)
  let index = self.find_group_phase_anchor(caller, group_key, anchor)
  phase_array_insert(self.phase_groups[group_index].phases, index, phase_key)
}

///|
/// Inserts a custom phase after an existing phase in a group.
pub fn Engine::insert_phase_after_in_group(
  self : Engine,
  group_key : PhaseGroupKey,
  anchor : PhaseKey,
  phase_key : PhaseKey,
) -> Unit {
  let caller = "Engine::insert_phase_after_in_group"
  self.ensure_phase_group_edit_window(caller)
  self.ensure_insertable_group_phase(caller, phase_key)
  if self.phase_registered_in_any_group(phase_key) {
    abort(caller + ": phase already exists in a phase group")
  }
  let group_index = self.find_phase_group(caller, group_key)
  let index = self.find_group_phase_anchor(caller, group_key, anchor)
  phase_array_insert(
    self.phase_groups[group_index].phases,
    index + 1,
    phase_key,
  )
}

///|
/// Reports whether a phase is valid for this engine's lifecycle.
fn Engine::can_run_phase(self : Engine, phase : PhaseKey) -> Bool {
  phase == phase_startup() ||
  phase == phase_shutdown() ||
  self.phase_registered_in_any_group(phase)
}

///|
/// Verifies that all phase handlers target phases owned by this engine.
fn Engine::validate_phase_handlers(self : Engine) -> Unit {
  for i = 0; i < self.phase_handlers.length(); i = i + 1 {
    let handler = self.phase_handlers[i]
    if !self.can_run_phase(handler.phase) {
      abort(
        "Engine::initialize: phase handler target is not registered in this engine: " +
        handler.phase.name(),
      )
    }
  }
}

///|
/// Requires the engine lifecycle to have been initialized.
fn Engine::ensure_initialized(self : Engine, caller : String) -> Unit {
  if !self.initialized {
    abort(
      caller +
      ": engine must be initialized with Engine::initialize before execution",
    )
  }
}

///|
/// Implements `Engine::shutdown`.
pub fn Engine::shutdown(self : Engine) -> Unit {
  self.ensure_initialized("Engine::shutdown")
  self.run_phase(phase_shutdown(), zero_frame_state())
}

///|
/// Runs one engine phase without lifecycle initialization checks.
fn Engine::run_phase_unchecked(
  self : Engine,
  phase : PhaseKey,
  frame : FrameState,
) -> Unit {
  self.run_before_systems(phase, frame)
  for i = 0; i < self.scenes.length(); i = i + 1 {
    let scene = self.scenes[i]
    if self.scene_participates_in_phase(scene, phase) {
      ignore(scene.run_systems_for_phase(phase, frame))
    }
  }
  self.run_after_systems(phase, frame)
}

///|
/// Runs one engine phase, including handlers and matching scene systems.
pub fn Engine::run_phase(
  self : Engine,
  phase : PhaseKey,
  frame : FrameState,
) -> Unit {
  self.ensure_initialized("Engine::run_phase")
  if !self.can_run_phase(phase) {
    abort(
      "Engine::run_phase: phase is not registered in this engine: " +
      phase.name(),
    )
  }
  self.run_phase_unchecked(phase, frame)
}

///|
/// Reports whether a scene should run systems for a phase.
fn Engine::scene_participates_in_phase(
  _self : Engine,
  scene : Scene,
  phase : PhaseKey,
) -> Bool {
  if phase_is_render_path(phase) {
    scene.visible()
  } else {
    scene.enabled()
  }
}

///|
/// Implements `Engine::initialize`.
pub fn Engine::initialize(self : Engine) -> Unit {
  if self.initializing || self.initialized {
    abort("Engine::initialize: engine is already initialized")
  }
  self.lock_phase_registration()
  self.initializing = true
  self.run_phase_unchecked(phase_startup(), zero_frame_state())
  self.initializing = false
  self.validate_phase_handlers()
  self.initialized = true
}

///|
/// Runs all phases in one phase group using a caller-supplied frame state.
pub fn Engine::run_phase_group(
  self : Engine,
  group_key : PhaseGroupKey,
  frame : FrameState,
) -> Unit {
  self.ensure_initialized("Engine::run_phase_group")
  let group_index = self.find_phase_group("Engine::run_phase_group", group_key)
  let phases = self.phase_groups[group_index].phases
  for i = 0; i < phases.length(); i = i + 1 {
    self.run_phase(phases[i], frame)
  }
}

///|
/// Advances the render-frame clock with real elapsed time and runs its phase group.
pub fn Engine::run_render_frame(self : Engine, delta_seconds : Float) -> Unit {
  self.ensure_initialized("Engine::run_render_frame")
  self.input_state.begin_frame()
  let frame = self.time_state.next_render_frame(delta_seconds)
  self.run_phase_group(phase_group_render_frame(), frame)
}

///|
/// Advances the fixed-step accumulator and runs each ready fixed-step frame.
pub fn Engine::run_fixed_steps(self : Engine, elapsed_seconds : Float) -> Int {
  self.ensure_initialized("Engine::run_fixed_steps")
  self.time_state.push_fixed_elapsed(elapsed_seconds)
  let mut count = 0
  while self.time_state.can_step_fixed() {
    let frame = self.time_state.next_fixed_frame()
    self.run_phase_group(phase_group_fixed_step(), frame)
    count = count + 1
  }
  count
}
