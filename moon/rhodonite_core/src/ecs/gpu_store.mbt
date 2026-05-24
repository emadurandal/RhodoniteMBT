/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Registers a CPU SoA component and reserves its archetype index slot.
pub fn World::register_cpu_component(
  self : World,
  name : String,
  cpu_stride : Int,
) -> ComponentTypeId {
  self.assert_not_history_raw_mutation("World::register_cpu_component")
  self.assert_not_querying("World::register_cpu_component")
  self.assert_component_registration_open("World::register_cpu_component")
  let id = self.registry.register_cpu(name, cpu_stride)
  let archetypes : Array[Int] = []
  self.component_archetypes.push(archetypes)
  id
}
