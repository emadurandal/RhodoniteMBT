/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Opaque renderer-owned mesh table handle stored by Renderable components.
pub(all) struct MeshHandle {
  priv index : Int
} derive(Eq)

///|
/// Implements `MeshHandle::index`.
pub fn MeshHandle::index(self : MeshHandle) -> Int {
  self.index
}

///|
/// Opaque renderer-owned material table handle stored by Renderable components.
pub(all) struct MaterialHandle {
  priv index : Int
} derive(Eq)

///|
/// Implements `MaterialHandle::index`.
pub fn MaterialHandle::index(self : MaterialHandle) -> Int {
  self.index
}

///|
/// Bitset controlling how a Renderable participates in renderer extraction.
pub(all) struct RenderableFlags {
  priv bits : UInt
} derive(Eq)

///|
/// Returns the raw bitset for storage and diagnostics.
pub fn RenderableFlags::bits(self : RenderableFlags) -> UInt {
  self.bits
}

///|
/// Reports whether all bits from `flag` are enabled.
pub fn RenderableFlags::contains(
  self : RenderableFlags,
  flag : RenderableFlags,
) -> Bool {
  (self.bits & flag.bits) == flag.bits
}

///|
/// Returns an empty renderable flag set.
pub fn renderable_flags_none() -> RenderableFlags {
  { bits: 0U }
}

///|
/// Returns the visible bit used by renderer extraction.
pub fn renderable_flags_visible() -> RenderableFlags {
  { bits: 1U }
}

///|
/// Returns the default renderable flags for newly visible objects.
pub fn renderable_flags_default() -> RenderableFlags {
  renderable_flags_visible()
}

///|
/// CPU-side renderable description stored in the Renderable ECS component.
pub(all) struct RenderableDesc {
  priv mesh : MeshHandle
  priv material : MaterialHandle
  priv flags : RenderableFlags
}

///|
/// Builds a renderable description for an entity.
pub fn RenderableDesc::new(
  mesh : MeshHandle,
  material : MaterialHandle,
  flags? : RenderableFlags = renderable_flags_default(),
) -> RenderableDesc {
  { mesh, material, flags }
}

///|
/// Returns the mesh handle referenced by this renderable.
pub fn RenderableDesc::mesh(self : RenderableDesc) -> MeshHandle {
  self.mesh
}

///|
/// Returns the material handle referenced by this renderable.
pub fn RenderableDesc::material(self : RenderableDesc) -> MaterialHandle {
  self.material
}

///|
/// Returns the extraction flags for this renderable.
pub fn RenderableDesc::flags(self : RenderableDesc) -> RenderableFlags {
  self.flags
}

///|
/// Byte stride of the Renderable ECS component payload.
pub fn renderable_component_stride() -> Int {
  16
}

///|
/// Registers the scene-owned CPU-only Renderable component in `world`.
fn register_scene_renderable_component(
  world : @ecs.World,
) -> @ecs.ComponentTypeId {
  world.register_component("RhodoniteRenderable", renderable_component_stride())
}

///|
/// Builds the little-endian component payload for a renderable description.
pub fn renderable_component_bytes(desc : RenderableDesc) -> FixedArray[Byte] {
  let bytes = FixedArray::make(renderable_component_stride(), (0 : Byte))
  @writes.put_u32_le(bytes, 0, desc.mesh.index.reinterpret_as_uint())
  @writes.put_u32_le(bytes, 4, desc.material.index.reinterpret_as_uint())
  @writes.put_u32_le(bytes, 8, desc.flags.bits)
  @writes.put_u32_le(bytes, 12, 0U)
  bytes
}

///|
/// Reads the mesh handle from a Renderable component row.
pub fn renderable_mesh_handle_from_view(bytes : ArrayView[Byte]) -> MeshHandle {
  { index: @writes.get_u32_le_byte_view(bytes, 0).reinterpret_as_int() }
}

///|
/// Reads the material handle from a Renderable component row.
pub fn renderable_material_handle_from_view(
  bytes : ArrayView[Byte],
) -> MaterialHandle {
  { index: @writes.get_u32_le_byte_view(bytes, 4).reinterpret_as_int() }
}

///|
/// Reads flags from a Renderable component row.
pub fn renderable_flags_from_view(bytes : ArrayView[Byte]) -> RenderableFlags {
  { bits: @writes.get_u32_le_byte_view(bytes, 8) }
}

///|
/// Adds or updates the Renderable component on an entity.
pub fn set_renderable(
  scene : Scene,
  entity : @ecs.EntityId,
  desc : RenderableDesc,
) -> Bool {
  let world = scene.world()
  let component = scene.renderable_component_id
  let bytes = renderable_component_bytes(desc)
  if world.has_component(entity, component) {
    world.set_component_bytes(entity, component, bytes)
  } else {
    world.add_component_bytes(entity, component, bytes)
  }
}

///|
/// Adds or updates Renderable through the history layer.
pub fn set_renderable_tracked(
  history : @ecs.WorldHistory,
  scene : Scene,
  entity : @ecs.EntityId,
  desc : RenderableDesc,
) -> Bool {
  let world = scene.world()
  let component = scene.renderable_component_id
  let bytes = renderable_component_bytes(desc)
  if world.has_component(entity, component) {
    history.set_component_bytes(world, entity, component, bytes)
  } else {
    history.add_component_bytes(world, entity, component, bytes)
  }
}

///|
/// Adds the Renderable component to an entity.
pub fn add_renderable(
  scene : Scene,
  entity : @ecs.EntityId,
  desc : RenderableDesc,
) -> Bool {
  let world = scene.world()
  world.add_component_bytes(
    entity,
    scene.renderable_component_id,
    renderable_component_bytes(desc),
  )
}

///|
/// Adds Renderable through the history layer.
pub fn add_renderable_tracked(
  history : @ecs.WorldHistory,
  scene : Scene,
  entity : @ecs.EntityId,
  desc : RenderableDesc,
) -> Bool {
  history.add_component_bytes(
    scene.world(),
    entity,
    scene.renderable_component_id,
    renderable_component_bytes(desc),
  )
}

///|
/// Removes Renderable through the history layer.
pub fn remove_renderable_tracked(
  history : @ecs.WorldHistory,
  scene : Scene,
  entity : @ecs.EntityId,
) -> Bool {
  history.remove_component(scene.world(), entity, scene.renderable_component_id)
}
