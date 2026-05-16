///|
/// Per-frame application state passed through the app lifecycle.
pub(all) struct FrameState {
  delta_seconds : Float
  frame_index : Int
  elapsed_seconds : Double
}

///|
/// Engine-level lifecycle phase supplied to scene schedules and app handlers.
pub(all) enum AppPhase {
  Startup
  Update
  Extract
  Render
  Shutdown
} derive(Eq)

///|
/// Execution slot inside an app phase.
pub(all) enum PhaseSlot {
  BeforeSchedule
  AfterSchedule
} derive(Eq)

///|
/// Function registered by an app to run inside a phase slot.
priv struct PhaseHandler {
  phase : AppPhase
  slot : PhaseSlot
  run : (Engine, FrameState) -> Unit
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
}

///|
/// Application phase handler registry.
pub struct App {
  priv phase_handlers : Array[PhaseHandler]
}

///|
/// Runtime that owns platform context, time state, and scenes.
pub struct Engine {
  priv gpu_context : @wgpu.GPUContext
  priv scenes : Array[Scene]
  priv main_scene_index : Int
  priv time_state : TimeState
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
/// Converts the app frame state to an ECS system context.
pub fn FrameState::system_context(self : FrameState) -> @ecs.SystemContext {
  @ecs.SystemContext::new(self.delta_seconds, self.frame_index)
}

///|
/// Converts this app phase to the ECS schedule phase used by scenes.
pub fn AppPhase::system_phase(self : AppPhase) -> @ecs.SystemPhase {
  match self {
    Startup => @ecs.SystemPhase::new(0)
    Update => @ecs.SystemPhase::new(1)
    Extract => @ecs.SystemPhase::new(2)
    Render => @ecs.SystemPhase::new(3)
    Shutdown => @ecs.SystemPhase::new(4)
  }
}

///|
/// Returns the default per-frame app phases in engine execution order.
pub fn app_frame_phases() -> Array[AppPhase] {
  [Update, Extract, Render]
}

///|
/// Builds a frame state for lifecycle phases that do not advance time.
fn zero_frame_state() -> FrameState {
  FrameState::new((0.0 : Float), 0, 0.0)
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
/// Implements `Scene::schedule`.
pub fn Scene::schedule(self : Scene) -> @ecs.Schedule {
  self.schedule
}

///|
/// Adds a system to this scene's schedule.
pub fn Scene::add_system(self : Scene, system : @ecs.System) -> Unit {
  self.schedule.add_system(system)
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
/// Runs this scene's schedule for one app phase.
pub fn Scene::run_schedule_phase(
  self : Scene,
  phase : AppPhase,
  frame : FrameState,
) -> Bool {
  self.schedule.run_phase(
    self.world,
    frame.system_context(),
    phase.system_phase(),
  )
}

///|
/// Runs this scene's schedule for one explicit ECS system phase.
pub fn Scene::run_schedule_system_phase(
  self : Scene,
  phase : @ecs.SystemPhase,
  ctx : @ecs.SystemContext,
) -> Bool {
  self.schedule.run_phase(self.world, ctx, phase)
}

///|
/// Implements `App::new`.
pub fn App::new() -> App {
  let phase_handlers : Array[PhaseHandler] = []
  { phase_handlers, }
}

///|
/// Registers a function to run in an app phase slot.
pub fn App::on_phase(
  self : App,
  phase : AppPhase,
  handler : (Engine, FrameState) -> Unit,
  slot? : PhaseSlot = BeforeSchedule,
) -> Unit {
  self.phase_handlers.push({ phase, slot, run: handler })
}

///|
/// Runs handlers registered for a phase slot.
pub fn App::run_phase_handlers(
  self : App,
  phase : AppPhase,
  slot : PhaseSlot,
  engine : Engine,
  frame : FrameState,
) -> Unit {
  for i = 0; i < self.phase_handlers.length(); i = i + 1 {
    let handler = self.phase_handlers[i]
    if handler.phase == phase && handler.slot == slot {
      (handler.run)(engine, frame)
    }
  }
}

///|
/// Runs handlers registered before a phase's scene schedules.
pub fn App::run_before_schedule(
  self : App,
  phase : AppPhase,
  engine : Engine,
  frame : FrameState,
) -> Unit {
  self.run_phase_handlers(phase, BeforeSchedule, engine, frame)
}

///|
/// Runs handlers registered after a phase's scene schedules.
pub fn App::run_after_schedule(
  self : App,
  phase : AppPhase,
  engine : Engine,
  frame : FrameState,
) -> Unit {
  self.run_phase_handlers(phase, AfterSchedule, engine, frame)
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
  scenes.push(main_scene)
  {
    gpu_context,
    scenes,
    main_scene_index: 0,
    time_state: TimeState::new((0.022 : Float)),
  }
}

///|
/// Implements `Engine::gpu_context`.
pub fn Engine::gpu_context(self : Engine) -> @wgpu.GPUContext {
  self.gpu_context
}

///|
/// Implements `Engine::main_scene`.
pub fn Engine::main_scene(self : Engine) -> Scene {
  self.scenes[self.main_scene_index]
}

///|
/// Implements `Engine::shutdown_app`.
pub fn Engine::shutdown_app(self : Engine, app : App) -> Unit {
  self.run_phase(app, Shutdown, zero_frame_state())
}

///|
/// Runs one app phase, including app handlers and matching scene schedules.
pub fn Engine::run_phase(
  self : Engine,
  app : App,
  phase : AppPhase,
  frame : FrameState,
) -> Unit {
  app.run_before_schedule(phase, self, frame)
  for i = 0; i < self.scenes.length(); i = i + 1 {
    let scene = self.scenes[i]
    if self.scene_participates_in_phase(scene, phase) {
      ignore(scene.run_schedule_phase(phase, frame))
    }
  }
  app.run_after_schedule(phase, self, frame)
}

///|
/// Reports whether a scene should run schedule systems for a phase.
fn Engine::scene_participates_in_phase(
  _self : Engine,
  scene : Scene,
  phase : AppPhase,
) -> Bool {
  match phase {
    Render => scene.visible()
    _ => scene.enabled()
  }
}

///|
/// Implements `Engine::initialize_app`.
pub fn Engine::initialize_app(self : Engine, app : App) -> Unit {
  self.run_phase(app, Startup, zero_frame_state())
}

///|
/// Advances the engine one frame and runs the default frame phases.
pub fn Engine::tick(self : Engine, app : App) -> Unit {
  let frame = self.time_state.next_frame()
  let phases = app_frame_phases()
  for i = 0; i < phases.length(); i = i + 1 {
    self.run_phase(app, phases[i], frame)
  }
}
