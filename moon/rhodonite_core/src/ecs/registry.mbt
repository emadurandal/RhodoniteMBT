/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Creates an empty registry; call `register_*` before spawning entities that use those components.
fn ComponentRegistry::new() -> ComponentRegistry {
  let components : Array[RegisteredComponent] = []
  { components, }
}

///|
/// Registers a component: data lives in archetype SoA columns (`cpu_stride` bytes per row).
fn ComponentRegistry::register_cpu(
  self : ComponentRegistry,
  name : String,
  cpu_stride : Int,
) -> ComponentTypeId {
  self.register_cpu_with_identity(name, cpu_stride, None, None, None)
}

///|
/// Aborts if `stable_key` is empty or already used by another registered component.
fn ComponentRegistry::assert_unique_stable_key(
  self : ComponentRegistry,
  stable_key : String,
) -> Unit {
  if stable_key == "" {
    abort("component stable key must not be empty")
  }
  for i = 0; i < self.components.length(); i = i + 1 {
    match self.components[i].stable_key {
      Some(existing) =>
        if existing == stable_key {
          abort("duplicate component stable key: \{stable_key}")
        }
      None => ()
    }
  }
}

///|
/// Registers a CPU component with optional stable identity metadata.
fn ComponentRegistry::register_cpu_with_identity(
  self : ComponentRegistry,
  name : String,
  cpu_stride : Int,
  stable_key : String?,
  schema_version : String?,
  schema_hash : String?,
) -> ComponentTypeId {
  match stable_key {
    Some(key) => self.assert_unique_stable_key(key)
    None => ()
  }
  let id = ComponentTypeId::new(self.components.length())
  self.components.push({
    id,
    name,
    cpu_stride,
    stable_key,
    schema_version,
    schema_hash,
  })
  id
}

///|
/// Implements `ComponentRegistry::get`.
fn ComponentRegistry::get(
  self : ComponentRegistry,
  id : ComponentTypeId,
) -> RegisteredComponent? {
  if id.index < 0 || id.index >= self.components.length() {
    None
  } else {
    Some(self.components[id.index])
  }
}

///|
/// Resolves a component registered with the given stable key.
fn ComponentRegistry::component_by_stable_key(
  self : ComponentRegistry,
  stable_key : String,
) -> ComponentTypeId? {
  for i = 0; i < self.components.length(); i = i + 1 {
    match self.components[i].stable_key {
      Some(existing) =>
        if existing == stable_key {
          return Some(self.components[i].id)
        }
      None => ()
    }
  }
  None
}

///|
/// Returns true when an optional schema field matches, treating an expected `None` as wildcard.
fn optional_schema_field_matches(actual : String?, expected : String?) -> Bool {
  match expected {
    Some(value) => actual == Some(value)
    None => true
  }
}

///|
/// Checks whether a component matches stable identity metadata requested by an import path.
fn ComponentRegistry::component_matches_identity(
  self : ComponentRegistry,
  component : ComponentTypeId,
  stable_key : String,
  schema_version : String?,
  schema_hash : String?,
) -> Bool {
  match self.get(component) {
    Some(info) =>
      match info.stable_key {
        Some(existing) =>
          existing == stable_key &&
          optional_schema_field_matches(info.schema_version, schema_version) &&
          optional_schema_field_matches(info.schema_hash, schema_hash)
        None => false
      }
    None => false
  }
}

///|
/// Implements `ComponentRegistry::stride`.
fn ComponentRegistry::stride(
  self : ComponentRegistry,
  id : ComponentTypeId,
) -> Int {
  match self.get(id) {
    Some(component) => component.cpu_stride
    None => abort("unknown component type")
  }
}

///|
