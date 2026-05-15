///|
/// Per-frame application state passed through the prototype app lifecycle.
pub(all) struct FrameState {
  delta_seconds : Float
  frame_index : Int
  elapsed_seconds : Double
}

///|
/// Mutable fixed-step clock used by the prototype engine runner.
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
/// Callback-backed prototype application lifecycle.
pub struct App {
  priv on_init : (Engine) -> Unit
  priv on_update : (Engine, FrameState) -> Unit
  priv on_render : (Engine, FrameState) -> Unit
  priv on_shutdown : (Engine) -> Unit
}

///|
/// Prototype engine runtime that owns platform context, time state, and scenes.
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
  {
    name,
    world: @ecs.World::new(),
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
/// Runs this scene's schedule against this scene's world.
pub fn Scene::run_schedule(self : Scene, frame : FrameState) -> Bool {
  self.schedule.run(self.world, frame.system_context())
}

///|
/// Runs this scene's schedule with an explicit ECS system context.
pub fn Scene::run_schedule_with_context(
  self : Scene,
  ctx : @ecs.SystemContext,
) -> Bool {
  self.schedule.run(self.world, ctx)
}

///|
/// Implements `App::new`.
pub fn App::new(
  on_init : (Engine) -> Unit,
  on_update : (Engine, FrameState) -> Unit,
  on_render : (Engine, FrameState) -> Unit,
  on_shutdown : (Engine) -> Unit,
) -> App {
  { on_init, on_update, on_render, on_shutdown }
}

///|
/// Calls the app initialization callback.
pub fn App::init(self : App, engine : Engine) -> Unit {
  (self.on_init)(engine)
}

///|
/// Calls the app update callback.
pub fn App::update(self : App, engine : Engine, frame : FrameState) -> Unit {
  (self.on_update)(engine, frame)
}

///|
/// Calls the app render callback.
pub fn App::render(self : App, engine : Engine, frame : FrameState) -> Unit {
  (self.on_render)(engine, frame)
}

///|
/// Calls the app shutdown callback.
pub fn App::shutdown(self : App, engine : Engine) -> Unit {
  (self.on_shutdown)(engine)
}

///|
/// Implements `Engine::new`.
pub fn Engine::new(gpu_context : @wgpu.GPUContext) -> Engine {
  let scenes : Array[Scene] = []
  scenes.push(Scene::new("main"))
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
/// Implements `Engine::initialize_app`.
pub fn Engine::initialize_app(self : Engine, app : App) -> Unit {
  app.init(self)
}

///|
/// Implements `Engine::shutdown_app`.
pub fn Engine::shutdown_app(self : Engine, app : App) -> Unit {
  app.shutdown(self)
}

///|
/// Advances the engine one frame and runs update, scene schedules, and render.
pub fn Engine::tick(self : Engine, app : App) -> Unit {
  let frame = self.time_state.next_frame()
  app.update(self, frame)
  for i = 0; i < self.scenes.length(); i = i + 1 {
    let scene = self.scenes[i]
    if scene.enabled() {
      ignore(scene.run_schedule(frame))
    }
  }
  app.render(self, frame)
}
