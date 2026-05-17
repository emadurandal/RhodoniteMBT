///|
/// Runtime scene instance that binds one ECS world to one system runner.
pub struct Scene {
  priv name : String
  priv world : @ecs.World
  priv system_runner : @ecs.SystemRunner
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
    system_runner: @ecs.SystemRunner::new(),
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
/// Adds an already-built ECS system to this scene's system runner.
fn Scene::add_ecs_system(self : Scene, system : @ecs.System) -> Unit {
  self.system_runner.add_system(system)
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
/// Runs this scene's systems for one engine phase.
pub fn Scene::run_systems_for_phase(
  self : Scene,
  phase : PhaseKey,
  frame : FrameState,
) -> Bool {
  self.system_runner.run_phase(self.world, frame.system_context(), phase)
}

///|
/// Returns the scene main camera or aborts because a camera-bound engine handler requires one.
fn scene_main_camera_or_abort(scene : Scene, caller : String) -> @ecs.EntityId {
  match scene.main_camera() {
    Some(camera) => camera
    None => abort(caller + ": Scene.main_camera is not set")
  }
}
