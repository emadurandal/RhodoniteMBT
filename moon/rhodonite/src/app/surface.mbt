///|
/// Surface-specific rendering view owned by an engine.
pub(all) struct EngineSurface {
  id : SurfaceId
  gpu_surface : @wgpu.GPUSurface
  mut scene : Scene
  input_state : @input.InputState
  mut state : SurfaceState
  mut changed : Bool
}

///|
/// Builds an engine surface from a platform GPU surface and scene.
fn EngineSurface::new(
  id : SurfaceId,
  gpu_surface : @wgpu.GPUSurface,
  scene : Scene,
) -> EngineSurface {
  {
    id,
    gpu_surface,
    scene,
    input_state: @input.InputState::new(),
    state: surface_state_from_gpu_surface(gpu_surface),
    changed: true,
  }
}

///|
/// Returns the stable surface id.
pub fn EngineSurface::id(self : EngineSurface) -> SurfaceId {
  self.id
}

///|
/// Returns the GPU presentation surface.
pub fn EngineSurface::gpu_surface(self : EngineSurface) -> @wgpu.GPUSurface {
  self.gpu_surface
}

///|
/// Returns the scene rendered by this surface view.
pub fn EngineSurface::scene(self : EngineSurface) -> Scene {
  self.scene
}

///|
/// Returns the surface-local input state.
pub fn EngineSurface::input(self : EngineSurface) -> @input.InputState {
  self.input_state
}

///|
/// Returns the latest surface state snapshot.
pub fn EngineSurface::state(self : EngineSurface) -> SurfaceState {
  self.state
}

///|
/// Replaces the scene rendered by this surface view.
pub fn EngineSurface::set_scene(self : EngineSurface, scene : Scene) -> Unit {
  self.scene = scene
}

///|
/// Synchronizes the engine surface state from its GPU surface.
fn EngineSurface::sync_from_gpu_surface(self : EngineSurface) -> Unit {
  let next = surface_state_from_gpu_surface(self.gpu_surface)
  if self.state != next {
    self.state = next
    self.changed = true
  }
}

///|
/// Consumes the changed flag after a surface frame has observed it.
fn EngineSurface::consume_changed(self : EngineSurface) -> Bool {
  let changed = self.changed
  self.changed = false
  changed
}

///|
/// Converts a GPU surface snapshot into the app-level surface state.
fn surface_state_from_gpu_surface(surface : @wgpu.GPUSurface) -> SurfaceState {
  if surface.active() {
    SurfaceState::new_active(
      surface.width(),
      surface.height(),
      surface.format(),
      surface.generation(),
    )
  } else {
    SurfaceState::suspended(surface.generation())
  }
}

///|
/// Adds a GPU presentation surface using the engine main scene as its view.
pub fn Engine::add_surface(
  self : Engine,
  surface : @wgpu.GPUSurface,
) -> SurfaceId {
  self.add_surface_for_scene(surface, self.main_scene())
}

///|
/// Adds a GPU presentation surface that renders the given scene.
pub fn Engine::add_surface_for_scene(
  self : Engine,
  surface : @wgpu.GPUSurface,
  scene : Scene,
) -> SurfaceId {
  let id = SurfaceId::new(self.next_surface_id)
  self.next_surface_id = self.next_surface_id + 1
  self.surfaces.push(EngineSurface::new(id, surface, scene))
  self.request_render("surface")
  id
}

///|
/// Returns the number of surfaces registered on this engine.
pub fn Engine::surface_count(self : Engine) -> Int {
  self.surfaces.length()
}

///|
/// Returns the surface id at a zero-based index or aborts when out of range.
pub fn Engine::surface_id_at(self : Engine, index : Int) -> SurfaceId {
  if index < 0 || index >= self.surfaces.length() {
    abort("Engine::surface_id_at: index out of range")
  }
  self.surfaces[index].id()
}

///|
/// Returns a registered engine surface by id or aborts when missing.
pub fn Engine::surface(self : Engine, id : SurfaceId) -> EngineSurface {
  match self.find_surface_index(id) {
    Some(index) => self.surfaces[index]
    None => abort("Engine::surface: unknown surface id")
  }
}

///|
/// Returns the surface-local input state for a registered surface.
pub fn Engine::surface_input(
  self : Engine,
  id : SurfaceId,
) -> @input.InputState {
  self.surface(id).input()
}

///|
/// Changes the scene rendered by a registered surface.
pub fn Engine::set_surface_scene(
  self : Engine,
  id : SurfaceId,
  scene : Scene,
) -> Unit {
  self.surface(id).set_scene(scene)
  self.request_render("surface-scene")
}

///|
/// Removes a registered surface by id.
pub fn Engine::remove_surface(self : Engine, id : SurfaceId) -> Unit {
  match self.find_surface_index(id) {
    Some(index) => {
      ignore(self.surfaces.remove(index))
      self.request_render("surface")
    }
    None => ()
  }
}

///|
/// Finds a registered surface index by id.
fn Engine::find_surface_index(self : Engine, id : SurfaceId) -> Int? {
  for i = 0; i < self.surfaces.length(); i = i + 1 {
    if self.surfaces[i].id() == id {
      return Some(i)
    }
  }
  None
}
