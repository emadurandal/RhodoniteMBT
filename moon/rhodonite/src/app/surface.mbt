/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Surface-specific rendering view owned by an engine.
pub struct EngineSurface {
  priv id : SurfaceId
  priv gpu_surface : @wgpu.GPUSurface
  priv mut scene : Scene
  priv input_state : @input.InputState
  priv render_target_resources : RenderTargetResources
  priv mut state : SurfaceState
  priv mut changed : Bool
}

///|
/// Builds an engine surface from a platform GPU surface and scene.
fn EngineSurface::new(
  id : SurfaceId,
  gpu_surface : @wgpu.GPUSurface,
  device : @wgpu.GPUDevice,
  scene : Scene,
) -> EngineSurface {
  let state = surface_state_from_gpu_surface(gpu_surface)
  let render_target_resources = if state.active() {
    RenderTargetResources::new(
      device,
      state.width(),
      state.height(),
      state.format(),
    )
  } else {
    RenderTargetResources::new(device, 0, 0, "")
  }
  {
    id,
    gpu_surface,
    scene,
    input_state: @input.InputState::new(),
    render_target_resources,
    state,
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
/// Returns surface-local render target resources.
pub fn EngineSurface::render_target_resources(
  self : EngineSurface,
) -> RenderTargetResources {
  self.render_target_resources
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
    if next.active() {
      self.render_target_resources.resize(
        next.width(),
        next.height(),
        next.format(),
      )
    } else {
      self.render_target_resources.resize(0, 0, "")
    }
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
/// Releases surface-local render target resources.
fn EngineSurface::release(self : EngineSurface) -> Unit {
  self.render_target_resources.release()
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
  let (device, _canvas_context, _format, _queue) = self.gpu_context().get()
  self.surfaces.push(EngineSurface::new(id, surface, device, scene))
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
  self.try_install_declared_common_runtime(scene)
  self.request_render("surface-scene")
}

///|
/// Removes a registered surface by id.
pub fn Engine::remove_surface(self : Engine, id : SurfaceId) -> Unit {
  match self.find_surface_index(id) {
    Some(index) => {
      self.surfaces[index].release()
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
