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
/// ECS component id for render participation data.
pub(all) struct RenderableComponent {
  priv id : @ecs.ComponentTypeId
}

///|
/// Implements `RenderableComponent::id`.
pub fn RenderableComponent::id(
  self : RenderableComponent,
) -> @ecs.ComponentTypeId {
  self.id
}

///|
/// Byte stride of the Renderable ECS component payload.
pub fn renderable_component_stride() -> Int {
  8
}

///|
/// Registers the CPU-only Renderable component in `world`.
pub fn register_renderable_component(world : @ecs.World) -> RenderableComponent {
  {
    id: world.register_cpu_component(
      "RhodoniteRenderable",
      renderable_component_stride(),
    ),
  }
}

///|
/// Builds the little-endian component payload for a mesh/material pair.
pub fn renderable_component_bytes(
  mesh : MeshHandle,
  material : MaterialHandle,
) -> FixedArray[Byte] {
  let bytes = FixedArray::make(renderable_component_stride(), (0 : Byte))
  @writes.put_u32_le(bytes, 0, mesh.index.reinterpret_as_uint())
  @writes.put_u32_le(bytes, 4, material.index.reinterpret_as_uint())
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
/// Adds or updates the Renderable component on an entity.
pub fn set_renderable(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : RenderableComponent,
  mesh : MeshHandle,
  material : MaterialHandle,
) -> Bool {
  let bytes = renderable_component_bytes(mesh, material)
  if world.has_component(entity, component.id) {
    world.set_component_bytes(entity, component.id, bytes)
  } else {
    world.add_component_bytes(entity, component.id, bytes)
  }
}

///|
/// Adds the Renderable component to an entity.
pub fn add_renderable(
  world : @ecs.World,
  entity : @ecs.EntityId,
  component : RenderableComponent,
  mesh : MeshHandle,
  material : MaterialHandle,
) -> Bool {
  world.add_component_bytes(
    entity,
    component.id,
    renderable_component_bytes(mesh, material),
  )
}
