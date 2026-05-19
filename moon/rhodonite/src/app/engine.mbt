///|
/// Runtime that owns platform context, time state, and scenes.
pub struct Engine {
  priv gpu_context : @wgpu.GPUContext
  priv input_state : @input.InputState
  priv mut surface_state : SurfaceState
  priv mut surface_changed : Bool
  priv mut next_surface_id : Int
  priv surfaces : Array[EngineSurface]
  priv mut render_requested : Bool
  priv mut continuous_render_requested : Bool
  priv mut render_wakeup : (() -> Unit)?
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
  let (_device, _canvas_context, format, _queue) = gpu_context.get()
  let scenes : Array[Scene] = []
  let surfaces : Array[EngineSurface] = []
  let phase_handlers : Array[PhaseHandler] = []
  scenes.push(main_scene)
  {
    gpu_context,
    input_state: @input.InputState::new(),
    surface_state: SurfaceState::new_active(800, 600, format, 0),
    surface_changed: true,
    next_surface_id: 1,
    surfaces,
    render_requested: true,
    continuous_render_requested: false,
    render_wakeup: None,
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
/// Returns the latest engine surface state.
pub fn Engine::surface_state(self : Engine) -> SurfaceState {
  self.surface_state
}

///|
/// Reports whether the current surface can be rendered to.
pub fn Engine::surface_active(self : Engine) -> Bool {
  self.surface_state.active()
}

///|
/// Installs a platform wakeup callback used when render work is requested while idle.
pub fn Engine::set_render_wakeup(self : Engine, wakeup : (() -> Unit)?) -> Unit {
  self.render_wakeup = wakeup
}

///|
/// Marks the engine as needing one rendered frame.
pub fn Engine::request_render(self : Engine, _reason : String) -> Unit {
  self.render_requested = true
  match self.render_wakeup {
    Some(wakeup) => wakeup()
    None => ()
  }
}

///|
/// Returns whether a one-shot render has been requested.
pub fn Engine::render_requested(self : Engine) -> Bool {
  self.render_requested
}

///|
/// Consumes and clears the current one-shot render request flag.
pub fn Engine::consume_render_requested(self : Engine) -> Bool {
  let requested = self.render_requested
  self.render_requested = false
  requested
}

///|
/// Requests continuous frame rendering until explicitly stopped.
pub fn Engine::request_continuous_render(
  self : Engine,
  _reason : String,
) -> Unit {
  self.continuous_render_requested = true
  match self.render_wakeup {
    Some(wakeup) => wakeup()
    None => ()
  }
}

///|
/// Stops continuous frame rendering.
pub fn Engine::stop_continuous_render(self : Engine, _reason : String) -> Unit {
  self.continuous_render_requested = false
}

///|
/// Returns whether continuous rendering is currently requested.
pub fn Engine::continuous_render_requested(self : Engine) -> Bool {
  self.continuous_render_requested
}

///|
/// Marks the engine surface active with the latest drawable size and format.
pub fn Engine::set_surface_active(
  self : Engine,
  width : Int,
  height : Int,
  format : String,
) -> Unit {
  if width <= 0 || height <= 0 {
    self.set_surface_suspended()
    return
  }
  if self.surface_state.active() &&
    self.surface_state.width() == width &&
    self.surface_state.height() == height &&
    self.surface_state.format() == format {
    return
  }
  let generation = self.surface_state.generation() + 1
  self.surface_state = SurfaceState::new_active(
    width, height, format, generation,
  )
  self.surface_changed = true
  self.request_render("surface")
}

///|
/// Marks the engine surface suspended because it has no drawable pixel extent.
pub fn Engine::set_surface_suspended(self : Engine) -> Unit {
  if !self.surface_state.active() {
    return
  }
  let generation = self.surface_state.generation() + 1
  self.surface_state = SurfaceState::suspended(generation)
  self.surface_changed = true
  self.request_render("surface")
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
    fn(engine, frame) {
      let camera = scene_main_camera_or_abort(
        scene, "Engine::add_orbit_camera_controller_input_handler",
      )
      let input = match frame.input() {
        Some(input) => input
        None => engine.input()
      }
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
  match frame.surface_id() {
    Some(id) => {
      let scene = self.surface(id).scene()
      if self.scene_participates_in_phase(scene, phase) {
        ignore(scene.run_systems_for_phase(phase, frame))
      }
    }
    None =>
      for i = 0; i < self.scenes.length(); i = i + 1 {
        let scene = self.scenes[i]
        if self.scene_participates_in_phase(scene, phase) {
          ignore(scene.run_systems_for_phase(phase, frame))
        }
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
/// Runs render-frame phases, skipping surface-dependent phases while suspended.
fn Engine::run_render_frame_group_for_surface(
  self : Engine,
  frame : FrameState,
) -> Unit {
  let group_index = self.find_phase_group(
    "Engine::run_render_frame_group_for_surface",
    phase_group_render_frame(),
  )
  let phases = self.phase_groups[group_index].phases
  for i = 0; i < phases.length(); i = i + 1 {
    let phase = phases[i]
    if frame.surface_active() || !phase_is_render_path(phase) {
      self.run_phase(phase, frame)
    }
  }
}

///|
/// Runs each ready fixed-step frame after real elapsed time has accumulated.
fn Engine::run_ready_fixed_steps(
  self : Engine,
  elapsed_seconds : Float,
  surface : SurfaceState,
  surface_changed : Bool,
) -> Int {
  self.time_state.push_fixed_elapsed(elapsed_seconds)
  self.time_state.drain_ready_fixed_frames(fn(fixed_frame) {
    let frame = fixed_frame.with_surface(surface, surface_changed)
    self.run_phase_group(phase_group_fixed_step(), frame)
  })
}

///|
/// Advances one standard engine tick and runs frame-begin, fixed, and render phases.
pub fn Engine::run_frame(self : Engine, elapsed_seconds : Float) -> Int {
  self.ensure_initialized("Engine::run_frame")
  ignore(self.consume_render_requested())
  self.input_state.begin_frame()
  let surface = self.surface_state
  let surface_changed = self.surface_changed
  let frame = self.time_state
    .next_render_frame(elapsed_seconds)
    .with_surface(surface, surface_changed)
  self.run_phase_group(phase_group_frame_begin(), frame)
  let fixed_steps = self.run_ready_fixed_steps(
    elapsed_seconds, surface, surface_changed,
  )
  self.run_render_frame_group_for_surface(frame)
  self.surface_changed = false
  fixed_steps
}

///|
/// Advances one engine tick and renders every registered platform surface.
pub fn Engine::run_multi_surface_frame(
  self : Engine,
  elapsed_seconds : Float,
) -> Int {
  self.ensure_initialized("Engine::run_multi_surface_frame")
  if self.surfaces.length() == 0 {
    return self.run_frame(elapsed_seconds)
  }
  ignore(self.consume_render_requested())
  self.input_state.begin_frame()
  let base_frame = self.time_state.next_render_frame(elapsed_seconds)
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    let surface = self.surfaces[i]
    surface.sync_from_gpu_surface()
    surface.input().begin_frame()
    let changed = surface.changed
    let frame = base_frame.with_surface_view(
      surface.id(),
      surface.state(),
      changed,
      surface.input(),
    )
    self.run_phase_group(phase_group_frame_begin(), frame)
  }
  let fixed_steps = self.run_ready_fixed_steps(
    elapsed_seconds,
    self.surface_state,
    self.surface_changed,
  )
  let phases = self.phase_group_order(phase_group_render_frame())
  for i = 0; i < phases.length(); i = i + 1 {
    let phase = phases[i]
    if phase_is_render_path(phase) {
      for surface_index = 0
          surface_index < self.surfaces.length()
          surface_index = surface_index + 1 {
        let surface = self.surfaces[surface_index]
        if surface.state().active() {
          let frame = base_frame.with_surface_view(
            surface.id(),
            surface.state(),
            surface.changed,
            surface.input(),
          )
          self.run_phase(phase, frame)
        }
      }
    } else {
      self.run_phase(phase, base_frame)
    }
  }
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    ignore(self.surfaces[i].consume_changed())
  }
  self.surface_changed = false
  fixed_steps
}
