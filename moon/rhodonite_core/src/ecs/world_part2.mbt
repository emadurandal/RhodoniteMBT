/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Adds one component id to an entity archetype signature and initializes its CPU SoA bytes.
fn World::add_component_signature(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  if !self.is_alive(entity) {
    return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  if self.has_component(entity, component) {
    return false
  }
  let old_arch = self.archetypes[loc.archetype_index]
  let new_components = sorted_with_added(old_arch.components, component)
  let new_arch_index = self.ensure_archetype(new_components)
  let new_arch = self.archetypes[new_arch_index]
  let new_row = new_arch.push_empty_row(entity)
  old_arch.copy_row_to(loc.row, new_arch)
  new_arch.set_component_bytes(new_row, component, bytes)
  self.locations[entity.index] = Some({
    archetype_index: new_arch_index,
    row: new_row,
  })
  let moved = old_arch.swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  true
}

///|
/// Implements `component_accepts_add_bytes`.
fn component_accepts_add_bytes(
  component : RegisteredComponent,
  bytes : FixedArray[Byte],
) -> Bool {
  bytes.length() == component.cpu_stride
}

///|
/// Adds a component with a zero/default payload.
pub fn World::add_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  self.assert_not_history_raw_mutation("World::add_component")
  self.assert_not_querying("World::add_component")
  self.assert_system_structural_write("World::add_component")
  self.assert_system_component_write(component, "World::add_component")
  if !self.is_alive(entity) {
    return false
  }
  match self.registry.get(component) {
    Some(rc) => {
      let bytes = if component == self.global_transform_component_id {
        let gt_ref = self.alloc_global_transform_ref(
          self.global_transform_default_format,
          @m44.Matrix44F::identity(),
        )
        @comp.global_transform_ref_bytes(gt_ref.format, gt_ref.word_offset)
      } else if component == self.camera_component_id {
        let camera_ref = self.alloc_camera_ref(
          @m44.Matrix44F::identity(),
          @m44.Matrix44F::identity(),
          (0.1 : Float),
          (1000.0 : Float),
          (1.0 : Float),
          (0.0 : Float),
          (0.0 : Float),
        )
        @comp.camera_ref_bytes(camera_ref.word_offset)
      } else {
        FixedArray::make(rc.cpu_stride, (0 : Byte))
      }
      self.add_component_signature(entity, component, bytes)
    }
    None => false
  }
}

///|
/// Adds a component and initializes its payload bytes.
///
/// Bytes initialize the archetype SoA row.
pub fn World::add_component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
  bytes : FixedArray[Byte],
) -> Bool {
  self.assert_not_history_raw_mutation("World::add_component_bytes")
  self.assert_not_querying("World::add_component_bytes")
  self.assert_system_structural_write("World::add_component_bytes")
  self.assert_system_component_write(component, "World::add_component_bytes")
  if !self.is_alive(entity) {
    return false
  }
  match self.registry.get(component) {
    Some(rc) => {
      if !component_accepts_add_bytes(rc, bytes) {
        return false
      }
      self.add_component_signature(entity, component, bytes)
    }
    None => false
  }
}

///|
/// Removes a component: migrates to a smaller archetype (signature loses one id).
pub fn World::remove_component(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> Bool {
  self.assert_not_history_raw_mutation("World::remove_component")
  self.assert_not_querying("World::remove_component")
  self.assert_system_structural_write("World::remove_component")
  self.assert_system_component_write(component, "World::remove_component")
  if !self.is_alive(entity) || !self.has_component(entity, component) {
    return false
  }
  match self.registry.get(component) {
    Some(_) => ()
    None => return false
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return false
  }
  if component == self.global_transform_component_id {
    self.release_global_transform_ref(entity)
  } else if component == self.camera_component_id {
    self.release_camera_ref(entity)
  }
  let old_arch = self.archetypes[loc.archetype_index]
  let new_components = sorted_with_removed(old_arch.components, component)
  let new_arch_index = self.ensure_archetype(new_components)
  let new_arch = self.archetypes[new_arch_index]
  let new_row = new_arch.push_empty_row(entity)
  old_arch.copy_row_to(loc.row, new_arch)
  self.locations[entity.index] = Some({
    archetype_index: new_arch_index,
    row: new_row,
  })
  let moved = old_arch.swap_remove_row(loc.row)
  self.update_moved_location(moved, loc.archetype_index, loc.row)
  true
}

///|
/// Looks up component bytes for a living entity that owns `component`.
pub fn World::component_bytes(
  self : World,
  entity : EntityId,
  component : ComponentTypeId,
) -> FixedArray[Byte]? {
  self.assert_system_component_read(component, "World::component_bytes")
  if !self.is_alive(entity) {
    return None
  }
  let loc = match self.locations[entity.index] {
    Some(loc) => loc
    None => return None
  }
  if !component_array_contains(
      self.archetypes[loc.archetype_index].components,
      component,
    ) {
    return None
  }
  match self.registry.get(component) {
    Some(_) =>
      self.archetypes[loc.archetype_index].component_bytes(loc.row, component)
    None => None
  }
}

///|
/// Implements `World::transform_component`.
pub fn World::transform_component(self : World) -> ComponentTypeId {
  self.transform_component_id
}

///|
/// Implements `World::global_transform_component`.
pub fn World::global_transform_component(self : World) -> ComponentTypeId {
  self.global_transform_component_id
}

///|
/// Implements `World::child_of_component`.
pub fn World::child_of_component(self : World) -> ComponentTypeId {
  self.child_of_component_id
}

///|
/// Implements `World::camera_component`.
pub fn World::camera_component(self : World) -> ComponentTypeId {
  self.camera_component_id
}

///|
/// Implements `World::orbit_camera_controller_component`.
pub fn World::orbit_camera_controller_component(
  self : World,
) -> ComponentTypeId {
  self.orbit_camera_controller_component_id
}

///|
/// Implements `World::camera_home_transform_component`.
pub fn World::camera_home_transform_component(self : World) -> ComponentTypeId {
  self.camera_home_transform_component_id
}

///|
/// Implements `World::camera_lens_component`.
pub fn World::camera_lens_component(self : World) -> ComponentTypeId {
  self.camera_lens_component_id
}
