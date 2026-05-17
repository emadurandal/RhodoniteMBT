///|
/// Per-frame state passed through the engine lifecycle.
pub(all) struct FrameState {
  delta_seconds : Float
  frame_index : Int
  elapsed_seconds : Double
}

///|
/// Open lifecycle phase identifier shared by engine tasks, engine handlers, and scene schedules.
pub type PhaseKey = @ecs.PhaseKey

///|
/// Open phase group identifier used by external drivers to choose a clock domain.
pub(all) struct PhaseGroupKey {
  name : String
} derive(Eq)

///|
/// Execution slot inside an engine phase.
pub(all) enum PhaseSlot {
  BeforeSchedule
  AfterSchedule
} derive(Eq)

///|
/// Function registered by the engine to run inside a phase slot.
priv struct PhaseHandler {
  phase : PhaseKey
  slot : PhaseSlot
  run : (Engine, FrameState) -> Unit
}

///|
/// Ordered phase list for one externally driven clock domain.
priv struct PhaseGroup {
  key : PhaseGroupKey
  phases : Array[PhaseKey]
}

///|
/// Registration key for the builtin transform propagation system.
priv struct TransformPropagationRegistration {
  phase : PhaseKey
}

///|
/// Registration key for the builtin Camera blob sync system.
priv struct CameraBlobSyncRegistration {
  phase : PhaseKey
  lens_component : @ecs.ComponentTypeId
}

///|
/// Registration key for the builtin orbit camera transform system.
priv struct OrbitCameraTransformRegistration {
  phase : PhaseKey
  orbit_component : @ecs.ComponentTypeId
  home_component : @ecs.ComponentTypeId
}

///|
/// Registration key for the builtin orbit camera Camera blob sync system.
priv struct OrbitCameraBlobSyncRegistration {
  phase : PhaseKey
  orbit_component : @ecs.ComponentTypeId
  lens_component : @ecs.ComponentTypeId
}

///|
/// Mutable fixed-step clock used by the engine runner.
pub struct TimeState {
  priv mut frame_index : Int
  priv mut elapsed_seconds : Double
  priv fixed_delta_seconds : Float
}

///|
/// Runtime scene instance that binds one ECS world to one schedule.
pub struct Scene {
  priv name : String
  priv world : @ecs.World
  priv schedule : @ecs.Schedule
  priv mut main_camera : @ecs.EntityId?
  priv mut enabled : Bool
  priv mut visible : Bool
  priv transform_propagation_registrations : Array[
    TransformPropagationRegistration,
  ]
  priv camera_blob_sync_registrations : Array[CameraBlobSyncRegistration]
  priv orbit_camera_transform_registrations : Array[
    OrbitCameraTransformRegistration,
  ]
  priv orbit_camera_blob_sync_registrations : Array[
    OrbitCameraBlobSyncRegistration,
  ]
}

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
/// Implements `FrameState::new`.
pub fn FrameState::new(
  delta_seconds : Float,
  frame_index : Int,
  elapsed_seconds : Double,
) -> FrameState {
  { delta_seconds, frame_index, elapsed_seconds }
}

///|
/// Implements `FrameState::delta_seconds`.
pub fn FrameState::delta_seconds(self : FrameState) -> Float {
  self.delta_seconds
}

///|
/// Implements `FrameState::frame_index`.
pub fn FrameState::frame_index(self : FrameState) -> Int {
  self.frame_index
}

///|
/// Implements `FrameState::elapsed_seconds`.
pub fn FrameState::elapsed_seconds(self : FrameState) -> Double {
  self.elapsed_seconds
}

///|
/// Converts the engine frame state to an ECS system context.
pub fn FrameState::system_context(self : FrameState) -> @ecs.SystemContext {
  @ecs.SystemContext::new(self.delta_seconds, self.frame_index)
}

///|
/// Builds a custom phase key. Use namespaced strings such as `user/my_phase` to avoid collisions.
pub fn phase(name : String) -> PhaseKey {
  @ecs.PhaseKey::new(name)
}

///|
/// Builds a custom phase group key. Use namespaced strings such as `user/fixed` to avoid collisions.
pub fn phase_group(name : String) -> PhaseGroupKey {
  { name, }
}

///|
/// Implements `PhaseGroupKey::name`.
pub fn PhaseGroupKey::name(self : PhaseGroupKey) -> String {
  self.name
}

///|
/// Standard render-frame group driven by display frame callbacks.
pub fn phase_group_render_frame() -> PhaseGroupKey {
  phase_group("rhodonite/render_frame")
}

///|
/// Standard fixed-step group driven by caller-owned fixed cadence.
pub fn phase_group_fixed_step() -> PhaseGroupKey {
  phase_group("rhodonite/fixed_step")
}

///|
/// Standard startup phase.
pub fn phase_startup() -> PhaseKey {
  phase("rhodonite/startup")
}

///|
/// Standard input phase. Platform adapters finalize queued input before this phase.
pub fn phase_input() -> PhaseKey {
  phase("rhodonite/input")
}

///|
/// Standard gameplay update phase.
pub fn phase_update() -> PhaseKey {
  phase("rhodonite/update")
}

///|
/// Standard post-update phase.
pub fn phase_post_update() -> PhaseKey {
  phase("rhodonite/post_update")
}

///|
/// Standard renderer extraction phase.
pub fn phase_render_extract() -> PhaseKey {
  phase("rhodonite/render_extract")
}

///|
/// Standard renderer preparation phase.
pub fn phase_render_prepare() -> PhaseKey {
  phase("rhodonite/render_prepare")
}

///|
/// Standard draw phase.
pub fn phase_render() -> PhaseKey {
  phase("rhodonite/render")
}

///|
/// Standard present/finalization phase.
pub fn phase_present() -> PhaseKey {
  phase("rhodonite/present")
}

///|
/// Standard shutdown phase.
pub fn phase_shutdown() -> PhaseKey {
  phase("rhodonite/shutdown")
}

///|
/// Returns the default render-frame phases in engine execution order.
pub fn default_render_frame_phases() -> Array[PhaseKey] {
  [
    phase_input(),
    phase_update(),
    phase_post_update(),
    phase_render_extract(),
    phase_render_prepare(),
    phase_render(),
    phase_present(),
  ]
}

///|
/// Returns the default engine phase groups.
fn default_phase_groups() -> Array[PhaseGroup] {
  let groups : Array[PhaseGroup] = []
  groups.push({
    key: phase_group_render_frame(),
    phases: default_render_frame_phases(),
  })
  groups.push({ key: phase_group_fixed_step(), phases: [] })
  groups
}

///|
/// Builds a frame state for one-shot phases that do not advance time.
fn zero_frame_state() -> FrameState {
  FrameState::new((0.0 : Float), 0, 0.0)
}

///|
/// Reports whether a phase is part of the standard rendering path.
fn phase_is_render_path(phase_key : PhaseKey) -> Bool {
  phase_key == phase_render_extract() ||
  phase_key == phase_render_prepare() ||
  phase_key == phase_render() ||
  phase_key == phase_present()
}

///|
/// Copies a phase key array.
fn copy_phase_array(src : Array[PhaseKey]) -> Array[PhaseKey] {
  let out : Array[PhaseKey] = []
  for i = 0; i < src.length(); i = i + 1 {
    out.push(src[i])
  }
  out
}

///|
/// Finds a phase key index or returns -1.
fn phase_array_index(phases : Array[PhaseKey], phase_key : PhaseKey) -> Int {
  for i = 0; i < phases.length(); i = i + 1 {
    if phases[i] == phase_key {
      return i
    }
  }
  -1
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

///|
/// Inserts a phase at an index, preserving existing order.
fn phase_array_insert(
  phases : Array[PhaseKey],
  index : Int,
  phase_key : PhaseKey,
) -> Unit {
  if index < 0 || index > phases.length() {
    abort("phase_array_insert: index out of bounds")
  }
  phases.push(phase_key)
  let mut i = phases.length() - 1
  while i > index {
    phases[i] = phases[i - 1]
    i = i - 1
  }
  phases[index] = phase_key
}

///|
/// Reports whether a phase is an engine one-shot phase.
fn phase_is_one_shot(phase_key : PhaseKey) -> Bool {
  phase_key == phase_startup() || phase_key == phase_shutdown()
}

///|
/// Implements `TimeState::new`.
pub fn TimeState::new(fixed_delta_seconds : Float) -> TimeState {
  { frame_index: 0, elapsed_seconds: 0.0, fixed_delta_seconds }
}

///|
/// Advances the fixed-step clock and returns the next frame state.
pub fn TimeState::next_frame(self : TimeState) -> FrameState {
  self.frame_index = self.frame_index + 1
  self.elapsed_seconds = self.elapsed_seconds +
    self.fixed_delta_seconds.to_double()
  FrameState::new(
    self.fixed_delta_seconds,
    self.frame_index,
    self.elapsed_seconds,
  )
}

///|
/// Implements `Scene::new`.
pub fn Scene::new(name : String) -> Scene {
  Scene::new_with_world(name, @ecs.World::new())
}

///|
/// Builds a scene around an already configured ECS world.
pub fn Scene::new_with_world(name : String, world : @ecs.World) -> Scene {
  {
    name,
    world,
    schedule: @ecs.Schedule::new(),
    main_camera: None,
    enabled: true,
    visible: true,
    transform_propagation_registrations: [],
    camera_blob_sync_registrations: [],
    orbit_camera_transform_registrations: [],
    orbit_camera_blob_sync_registrations: [],
  }
}

///|
/// Implements `Scene::name`.
pub fn Scene::name(self : Scene) -> String {
  self.name
}

///|
/// Implements `Scene::world`.
pub fn Scene::world(self : Scene) -> @ecs.World {
  self.world
}

///|
/// Adds an already-built ECS system to this scene's schedule.
fn Scene::add_ecs_system(self : Scene, system : @ecs.System) -> Unit {
  self.schedule.add_system(system)
}

///|
/// Builds and adds a non-structural ECS system for one engine phase.
pub fn Scene::add_system(
  self : Scene,
  phase : PhaseKey,
  name : String,
  reads : Array[@ecs.ComponentTypeId],
  writes : Array[@ecs.ComponentTypeId],
  run : (@ecs.World, @ecs.SystemContext, @ecs.CommandBuffer) -> Unit,
) -> Unit {
  self.add_ecs_system(@ecs.System::new(name, phase, reads, writes, run))
}

///|
/// Builds and adds a structural-write ECS system for one engine phase.
pub fn Scene::add_structural_system(
  self : Scene,
  phase : PhaseKey,
  name : String,
  reads : Array[@ecs.ComponentTypeId],
  writes : Array[@ecs.ComponentTypeId],
  run : (@ecs.World, @ecs.SystemContext, @ecs.CommandBuffer) -> Unit,
) -> Unit {
  self.add_ecs_system(
    @ecs.System::new_with_structural_write(name, phase, reads, writes, run),
  )
}

///|
/// Reports whether transform propagation has already been registered for a phase.
fn Scene::has_transform_propagation_registration(
  self : Scene,
  phase : PhaseKey,
) -> Bool {
  for i = 0; i < self.transform_propagation_registrations.length(); i = i + 1 {
    if self.transform_propagation_registrations[i].phase == phase {
      return true
    }
  }
  false
}

///|
/// Adds the builtin transform propagation system for one engine phase.
pub fn Scene::add_transform_propagation_system(
  self : Scene,
  phase : PhaseKey,
) -> Unit {
  if self.has_transform_propagation_registration(phase) {
    return
  }
  self.transform_propagation_registrations.push({ phase, })
  self.add_ecs_system(@ecs.transform_propagation_system(self.world, phase))
}

///|
/// Reports whether orbit camera transform has already been registered.
fn Scene::has_orbit_camera_transform_registration(
  self : Scene,
  phase : PhaseKey,
  orbit_component : @ecs.ComponentTypeId,
  home_component : @ecs.ComponentTypeId,
) -> Bool {
  for i = 0; i < self.orbit_camera_transform_registrations.length(); i = i + 1 {
    let reg = self.orbit_camera_transform_registrations[i]
    if reg.phase == phase &&
      reg.orbit_component == orbit_component &&
      reg.home_component == home_component {
      return true
    }
  }
  false
}

///|
/// Adds the orbit camera transform system for one engine phase.
pub fn Scene::add_orbit_camera_transform_system(
  self : Scene,
  phase : PhaseKey,
  orbit_component : @ecs.ComponentTypeId,
  home_component : @ecs.ComponentTypeId,
) -> Unit {
  if self.has_orbit_camera_transform_registration(
      phase, orbit_component, home_component,
    ) {
    return
  }
  self.orbit_camera_transform_registrations.push({
    phase,
    orbit_component,
    home_component,
  })
  self.add_ecs_system(
    @ecs.orbit_camera_transform_system(
      self.world,
      phase,
      orbit_component,
      home_component,
    ),
  )
}

///|
/// Reports whether orbit camera Camera blob sync has already been registered.
fn Scene::has_orbit_camera_blob_sync_registration(
  self : Scene,
  phase : PhaseKey,
  orbit_component : @ecs.ComponentTypeId,
  lens_component : @ecs.ComponentTypeId,
) -> Bool {
  for i = 0; i < self.orbit_camera_blob_sync_registrations.length(); i = i + 1 {
    let reg = self.orbit_camera_blob_sync_registrations[i]
    if reg.phase == phase &&
      reg.orbit_component == orbit_component &&
      reg.lens_component == lens_component {
      return true
    }
  }
  false
}

///|
/// Reports whether Camera blob sync has already been registered.
fn Scene::has_camera_blob_sync_registration(
  self : Scene,
  phase : PhaseKey,
  lens_component : @ecs.ComponentTypeId,
) -> Bool {
  for i = 0; i < self.camera_blob_sync_registrations.length(); i = i + 1 {
    let reg = self.camera_blob_sync_registrations[i]
    if reg.phase == phase && reg.lens_component == lens_component {
      return true
    }
  }
  false
}

///|
/// Adds the Camera blob synchronization system for one engine phase.
pub fn Scene::add_camera_blob_sync_system(
  self : Scene,
  phase : PhaseKey,
  lens_component : @ecs.ComponentTypeId,
) -> Unit {
  if self.has_camera_blob_sync_registration(phase, lens_component) {
    return
  }
  self.camera_blob_sync_registrations.push({ phase, lens_component })
  self.add_ecs_system(
    @ecs.camera_blob_sync_system(self.world, phase, lens_component),
  )
}

///|
/// Adds the Camera blob sync system that applies orbit camera dolly to orthographic lenses.
pub fn Scene::add_orbit_camera_blob_sync_system(
  self : Scene,
  phase : PhaseKey,
  orbit_component : @ecs.ComponentTypeId,
  lens_component : @ecs.ComponentTypeId,
) -> Unit {
  if self.has_orbit_camera_blob_sync_registration(
      phase, orbit_component, lens_component,
    ) {
    return
  }
  self.orbit_camera_blob_sync_registrations.push({
    phase,
    orbit_component,
    lens_component,
  })
  self.add_ecs_system(
    @ecs.orbit_camera_blob_sync_system(
      self.world,
      phase,
      orbit_component,
      lens_component,
    ),
  )
}

///|
/// Adds the standard orbit-camera transform and Camera blob sync systems.
pub fn Scene::add_orbit_camera_systems(
  self : Scene,
  orbit_component : @ecs.ComponentTypeId,
  home_component : @ecs.ComponentTypeId,
  lens_component : @ecs.ComponentTypeId,
) -> Unit {
  self.add_orbit_camera_transform_system(
    phase_post_update(),
    orbit_component,
    home_component,
  )
  self.add_orbit_camera_blob_sync_system(
    phase_render_extract(),
    orbit_component,
    lens_component,
  )
}

///|
/// Adds standard scene systems shared by ECS samples.
///
/// Builtin scene systems are deduplicated by phase and component ids, so this
/// may be called both during scene setup and engine handler setup.
pub fn Scene::add_common_systems(
  self : Scene,
  transform_propagation? : Bool = false,
  orbit_component? : @ecs.ComponentTypeId? = None,
  home_component? : @ecs.ComponentTypeId? = None,
  lens_component? : @ecs.ComponentTypeId? = None,
) -> Unit {
  if transform_propagation {
    self.add_transform_propagation_system(phase_update())
  }
  match orbit_component {
    Some(orbit) => {
      match home_component {
        Some(home) =>
          self.add_orbit_camera_transform_system(
            phase_post_update(),
            orbit,
            home,
          )
        None => ()
      }
      match lens_component {
        Some(lens) =>
          self.add_orbit_camera_blob_sync_system(
            phase_render_extract(),
            orbit,
            lens,
          )
        None => ()
      }
    }
    None => {
      match home_component {
        Some(_) =>
          abort(
            "Scene::add_common_systems: home_component requires orbit_component",
          )
        None => ()
      }
      match lens_component {
        Some(_) =>
          abort(
            "Scene::add_common_systems: lens_component requires orbit_component",
          )
        None => ()
      }
    }
  }
}

///|
/// Implements `Scene::set_main_camera`.
pub fn Scene::set_main_camera(self : Scene, camera : @ecs.EntityId?) -> Unit {
  self.main_camera = camera
}

///|
/// Implements `Scene::main_camera`.
pub fn Scene::main_camera(self : Scene) -> @ecs.EntityId? {
  self.main_camera
}

///|
/// Implements `Scene::set_enabled`.
pub fn Scene::set_enabled(self : Scene, enabled : Bool) -> Unit {
  self.enabled = enabled
}

///|
/// Implements `Scene::enabled`.
pub fn Scene::enabled(self : Scene) -> Bool {
  self.enabled
}

///|
/// Implements `Scene::set_visible`.
pub fn Scene::set_visible(self : Scene, visible : Bool) -> Unit {
  self.visible = visible
}

///|
/// Implements `Scene::visible`.
pub fn Scene::visible(self : Scene) -> Bool {
  self.visible
}

///|
/// Runs this scene's schedule for one engine phase.
pub fn Scene::run_schedule_phase(
  self : Scene,
  phase : PhaseKey,
  frame : FrameState,
) -> Bool {
  self.schedule.run_phase(self.world, frame.system_context(), phase)
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
    time_state: TimeState::new((0.022 : Float)),
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
/// Returns the scene main camera or aborts because a camera-bound engine handler requires one.
fn scene_main_camera_or_abort(scene : Scene, caller : String) -> @ecs.EntityId {
  match scene.main_camera() {
    Some(camera) => camera
    None => abort(caller + ": Scene.main_camera is not set")
  }
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
pub fn Engine::add_handler_on_phase(
  self : Engine,
  phase : PhaseKey,
  handler : (Engine, FrameState) -> Unit,
  slot? : PhaseSlot = BeforeSchedule,
) -> Unit {
  self.ensure_phase_handler_registration_open("Engine::add_handler_on_phase")
  self.phase_handlers.push({ phase, slot, run: handler })
}

///|
/// Appends the standard input handler for a scene main camera's orbit controller.
pub fn Engine::add_orbit_camera_controller_input_handler(
  self : Engine,
  scene : Scene,
  orbit_component : @ecs.ComponentTypeId,
  phase? : PhaseKey = phase_input(),
  slot? : PhaseSlot = BeforeSchedule,
) -> Unit {
  self.add_handler_on_phase(
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
/// Runs handlers registered before a phase's scene schedules.
fn Engine::run_before_schedule(
  self : Engine,
  phase : PhaseKey,
  frame : FrameState,
) -> Unit {
  self.run_phase_handlers(phase, BeforeSchedule, frame)
}

///|
/// Runs handlers registered after a phase's scene schedules.
fn Engine::run_after_schedule(
  self : Engine,
  phase : PhaseKey,
  frame : FrameState,
) -> Unit {
  self.run_phase_handlers(phase, AfterSchedule, frame)
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
  self.run_before_schedule(phase, frame)
  for i = 0; i < self.scenes.length(); i = i + 1 {
    let scene = self.scenes[i]
    if self.scene_participates_in_phase(scene, phase) {
      ignore(scene.run_schedule_phase(phase, frame))
    }
  }
  self.run_after_schedule(phase, frame)
}

///|
/// Runs one engine phase, including handlers and matching scene schedules.
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
/// Reports whether a scene should run schedule systems for a phase.
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
/// Advances the render-frame clock and runs the standard render-frame phase group.
pub fn Engine::run_render_frame(self : Engine) -> Unit {
  self.ensure_initialized("Engine::run_render_frame")
  self.input_state.begin_frame()
  let frame = self.time_state.next_frame()
  self.run_phase_group(phase_group_render_frame(), frame)
}
