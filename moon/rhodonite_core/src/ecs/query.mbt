/// Copyright (c) 2026 emadurandal (Act and Wit, Inc.)
/// SPDX-License-Identifier: Apache-2.0

///|
/// Implements `component_array_index_of`.
fn component_array_index_of(
  components : Array[ComponentTypeId],
  component : ComponentTypeId,
) -> Int {
  for i = 0; i < components.length(); i = i + 1 {
    if components[i] == component {
      return i
    }
  }
  -1
}

///|
/// Returns true when two component arrays contain at least one shared id.
fn component_arrays_overlap(
  a : Array[ComponentTypeId],
  b : Array[ComponentTypeId],
) -> Bool {
  for i = 0; i < a.length(); i = i + 1 {
    if component_array_contains(b, a[i]) {
      return true
    }
  }
  false
}

///|
/// Validates required/excluded component sets before query construction.
fn assert_query_component_sets_valid(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
  operation : String,
) -> Unit {
  if component_array_has_duplicates(required) {
    abort(
      operation +
      ": duplicate required component. Hint: pass each ComponentTypeId at most once; use QueryRow::read or write with the component id instead of requesting the same row multiple times.",
    )
  }
  if component_array_has_duplicates(excluded) {
    abort(
      operation +
      ": duplicate excluded component. Hint: pass each excluded ComponentTypeId at most once.",
    )
  }
  if component_arrays_overlap(required, excluded) {
    abort(
      operation +
      ": required and excluded component sets overlap. Hint: a component cannot be both required and filtered out.",
    )
  }
}

///|
/// Builds a query descriptor and rejects duplicate component ids up front.
pub fn Query::new(required : Array[ComponentTypeId]) -> Query {
  Query::new_with_excluded(required, [])
}

///|
/// Builds a query descriptor with a `Without`-style excluded component filter.
pub fn Query::new_with_excluded(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
) -> Query {
  assert_query_component_sets_valid(
    required, excluded, "Query::new_with_excluded",
  )
  {
    required: copy_component_array(required),
    excluded: copy_component_array(excluded),
  }
}

///|
/// Builds a raw query descriptor and rejects duplicate component ids up front.
pub fn RawQuery::new(required : Array[ComponentTypeId]) -> RawQuery {
  RawQuery::new_with_excluded(required, [])
}

///|
/// Builds a raw query descriptor with a `Without`-style excluded component filter.
pub fn RawQuery::new_with_excluded(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
) -> RawQuery {
  assert_query_component_sets_valid(
    required, excluded, "RawQuery::new_with_excluded",
  )
  {
    required: copy_component_array(required),
    excluded: copy_component_array(excluded),
  }
}

///|
/// Builds a caller-owned row query cache for repeated iteration of the same required set.
pub fn QueryCache::new(required : Array[ComponentTypeId]) -> QueryCache {
  { query: Query::new(required), prepared: None }
}

///|
/// Builds a caller-owned row query cache with an excluded component filter.
pub fn QueryCache::new_with_excluded(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
) -> QueryCache {
  { query: Query::new_with_excluded(required, excluded), prepared: None }
}

///|
/// Builds a caller-owned raw query cache for repeated byte-view iteration of the same required set.
pub fn RawQueryCache::new(required : Array[ComponentTypeId]) -> RawQueryCache {
  { query: RawQuery::new(required), prepared: None }
}

///|
/// Builds a caller-owned raw query cache with an excluded component filter.
pub fn RawQueryCache::new_with_excluded(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
) -> RawQueryCache {
  { query: RawQuery::new_with_excluded(required, excluded), prepared: None }
}

///|
/// Returns a copy of the required component ids in callback payload order.
pub fn Query::required_components(self : Query) -> Array[ComponentTypeId] {
  copy_component_array(self.required)
}

///|
/// Returns a copy of the component ids filtered out by this query.
pub fn Query::excluded_components(self : Query) -> Array[ComponentTypeId] {
  copy_component_array(self.excluded)
}

///|
/// Returns the callback payload index for a required component.
pub fn Query::component_index(self : Query, component : ComponentTypeId) -> Int {
  query_component_index(self.required, component, "Query::component_index")
}

///|
/// Implements `RawQuery::required_components`.
pub fn RawQuery::required_components(self : RawQuery) -> Array[ComponentTypeId] {
  copy_component_array(self.required)
}

///|
/// Returns a copy of the component ids filtered out by this raw query.
pub fn RawQuery::excluded_components(self : RawQuery) -> Array[ComponentTypeId] {
  copy_component_array(self.excluded)
}

///|
/// Returns the raw callback payload index for a required component.
pub fn RawQuery::component_index(
  self : RawQuery,
  component : ComponentTypeId,
) -> Int {
  query_component_index(self.required, component, "RawQuery::component_index")
}

///|
/// Returns a copy of the cached row query's required component ids.
pub fn QueryCache::required_components(
  self : QueryCache,
) -> Array[ComponentTypeId] {
  self.query.required_components()
}

///|
/// Returns a copy of the cached row query's excluded component ids.
pub fn QueryCache::excluded_components(
  self : QueryCache,
) -> Array[ComponentTypeId] {
  self.query.excluded_components()
}

///|
/// Returns the cached row query payload index for a required component.
pub fn QueryCache::component_index(
  self : QueryCache,
  component : ComponentTypeId,
) -> Int {
  self.query.component_index(component)
}

///|
/// Returns a copy of the cached raw query's required component ids.
pub fn RawQueryCache::required_components(
  self : RawQueryCache,
) -> Array[ComponentTypeId] {
  self.query.required_components()
}

///|
/// Returns a copy of the cached raw query's excluded component ids.
pub fn RawQueryCache::excluded_components(
  self : RawQueryCache,
) -> Array[ComponentTypeId] {
  self.query.excluded_components()
}

///|
/// Returns the cached raw query payload index for a required component.
pub fn RawQueryCache::component_index(
  self : RawQueryCache,
  component : ComponentTypeId,
) -> Int {
  self.query.component_index(component)
}

///|
/// Returns the payload index for `component` or aborts with a setup error.
fn query_component_index(
  required : Array[ComponentTypeId],
  component : ComponentTypeId,
  operation : String,
) -> Int {
  let index = component_array_index_of(required, component)
  if index < 0 {
    abort(
      operation +
      ": " +
      component_id_text(component) +
      " is not part of this query required set.",
    )
  }
  index
}

///|
/// Implements `Query::assert_registered_components`.
fn Query::assert_registered_components(
  self : Query,
  world : World,
  operation : String,
) -> Unit {
  assert_query_components_registered(self.required, world, operation)
  assert_query_components_registered(self.excluded, world, operation)
}

///|
/// Implements `assert_query_components_registered`.
fn assert_query_components_registered(
  required : Array[ComponentTypeId],
  world : World,
  operation : String,
) -> Unit {
  for k = 0; k < required.length(); k = k + 1 {
    match world.registry.get(required[k]) {
      Some(_) => ()
      None =>
        abort(
          operation +
          ": unknown " +
          component_id_text(required[k]) +
          ". Hint: use ComponentTypeId values registered in this World, or builtin component accessors such as world.transform_component().",
        )
    }
  }
}

///|
/// Implements `query_archetype_accesses`.
fn query_archetype_accesses(
  required : Array[ComponentTypeId],
  world : World,
  archetype_index : Int,
  operation : String,
) -> Array[QueryArchetypeComponentAccess] {
  let arch = world.archetypes[archetype_index]
  let accesses : Array[QueryArchetypeComponentAccess] = []
  for k = 0; k < required.length(); k = k + 1 {
    let component = required[k]
    match world.registry.get(component) {
      Some(_) => {
        let ci = arch.column_index(component)
        if ci < 0 {
          abort(operation + ": matched archetype is missing CPU column")
        }
        accesses.push({
          component,
          column_index: ci,
          stride: arch.columns[ci].stride,
        })
      }
      None => abort(operation + ": unknown component")
    }
  }
  accesses
}

///|
/// Implements `query_matches_archetype`.
fn query_matches_archetype(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
  world : World,
  archetype_index : Int,
) -> Bool {
  let sig = world.archetypes[archetype_index].components
  for i = 0; i < excluded.length(); i = i + 1 {
    if component_array_contains(sig, excluded[i]) {
      return false
    }
  }
  let required_len = required.length()
  if required_len == 0 {
    false
  } else if required_len == 1 {
    component_array_contains(sig, required[0])
  } else if required_len == 2 {
    component_array_contains(sig, required[0]) &&
    component_array_contains(sig, required[1])
  } else {
    component_array_contains_all(sig, required)
  }
}

///|
/// Implements `build_prepared_query_archetypes`.
fn build_prepared_query_archetypes(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
  world : World,
  operation : String,
) -> Array[PreparedQueryArchetype] {
  let prepared_archetypes : Array[PreparedQueryArchetype] = []
  if required.length() > 0 {
    let candidates = world.query_candidate_archetypes(required)
    for i = 0; i < candidates.length(); i = i + 1 {
      let ai = candidates[i]
      if query_matches_archetype(required, excluded, world, ai) {
        let accesses = query_archetype_accesses(required, world, ai, operation)
        prepared_archetypes.push({
          archetype_index: ai,
          accesses,
          row_accesses: query_row_accesses_from_archetype_accesses(accesses),
        })
      }
    }
  }
  prepared_archetypes
}

///|
/// Builds public matched-archetype entries from a prepared internal plan.
fn query_plan_archetypes(
  archetypes : Array[PreparedQueryArchetype],
  world : World,
) -> (Array[QueryPlanArchetype], Int) {
  let out : Array[QueryPlanArchetype] = []
  let mut matched_row_count = 0
  for i = 0; i < archetypes.length(); i = i + 1 {
    let ai = archetypes[i].archetype_index
    let row_count = world.archetypes[ai].entities.length()
    out.push({ archetype_index: ai, row_count })
    matched_row_count = matched_row_count + row_count
  }
  (out, matched_row_count)
}

///|
/// Counts the candidate archetypes for a registered required component set.
fn query_candidate_archetype_count(
  required : Array[ComponentTypeId],
  world : World,
) -> Int {
  if required.length() == 0 {
    0
  } else {
    world.query_candidate_archetypes(required).length()
  }
}

///|
/// Builds a public query plan snapshot from a prepared internal plan.
fn build_query_plan_from_prepared_archetypes(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
  world : World,
  archetypes : Array[PreparedQueryArchetype],
  stale : Bool,
) -> QueryPlan {
  let (plan_archetypes, matched_row_count) = query_plan_archetypes(
    archetypes, world,
  )
  {
    required: copy_component_array(required),
    excluded: copy_component_array(excluded),
    archetype_version: world.archetype_version,
    candidate_archetype_count: query_candidate_archetype_count(required, world),
    matched_archetype_count: plan_archetypes.length(),
    matched_row_count,
    stale,
    archetypes: plan_archetypes,
  }
}

///|
/// Builds a public query plan snapshot from the current world layout.
fn build_query_plan(
  required : Array[ComponentTypeId],
  excluded : Array[ComponentTypeId],
  world : World,
  operation : String,
  stale : Bool,
) -> QueryPlan {
  build_query_plan_from_prepared_archetypes(
    required,
    excluded,
    world,
    build_prepared_query_archetypes(required, excluded, world, operation),
    stale,
  )
}

///|
/// Precomputes matched archetypes and component access metadata for repeated chunk iteration.
pub fn Query::prepare(self : Query, world : World) -> PreparedQuery {
  world.assert_system_components_read(self.required, "Query::prepare")
  self.assert_registered_components(world, "Query::prepare")
  {
    required: copy_component_array(self.required),
    excluded: copy_component_array(self.excluded),
    archetype_version: world.archetype_version,
    archetypes: build_prepared_query_archetypes(
      self.required,
      self.excluded,
      world,
      "Query::prepare",
    ),
  }
}

///|
/// Returns a read-only diagnostic snapshot of the query plan for the current world layout.
pub fn Query::plan(self : Query, world : World) -> QueryPlan {
  world.assert_system_components_read(self.required, "Query::plan")
  self.assert_registered_components(world, "Query::plan")
  build_query_plan(self.required, self.excluded, world, "Query::plan", false)
}

///|
/// Precomputes matched archetypes and component access metadata for repeated raw iteration.
pub fn RawQuery::prepare(self : RawQuery, world : World) -> RawPreparedQuery {
  world.assert_system_components_read(self.required, "RawQuery::prepare")
  assert_query_components_registered(self.required, world, "RawQuery::prepare")
  assert_query_components_registered(self.excluded, world, "RawQuery::prepare")
  {
    required: copy_component_array(self.required),
    excluded: copy_component_array(self.excluded),
    archetype_version: world.archetype_version,
    archetypes: build_prepared_query_archetypes(
      self.required,
      self.excluded,
      world,
      "RawQuery::prepare",
    ),
  }
}

///|
/// Returns a read-only diagnostic snapshot of the raw query plan for the current world layout.
pub fn RawQuery::plan(self : RawQuery, world : World) -> QueryPlan {
  world.assert_system_components_read(self.required, "RawQuery::plan")
  assert_query_components_registered(self.required, world, "RawQuery::plan")
  assert_query_components_registered(self.excluded, world, "RawQuery::plan")
  build_query_plan(self.required, self.excluded, world, "RawQuery::plan", false)
}

///|
/// Runs this query with component-id based row access instead of payload-index access.
pub fn Query::for_each(
  self : Query,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  self.prepare(world).for_each(world, f)
}

///|
/// Runs this raw query with component-id based byte-view row access.
pub fn RawQuery::for_each(
  self : RawQuery,
  world : World,
  f : (RawQueryRow) -> Unit,
) -> Unit {
  self.prepare(world).for_each(world, f)
}

///|
/// Runs this raw query archetype-by-archetype for hot column loops.
pub fn RawQuery::for_each_archetype(
  self : RawQuery,
  world : World,
  f : (RawQueryArchetype) -> Unit,
) -> Unit {
  self.prepare(world).for_each_archetype(world, f)
}

///|
/// Returns a diagnostic plan for this cache without updating the cached prepared plan.
pub fn QueryCache::plan(self : QueryCache, world : World) -> QueryPlan {
  match self.prepared {
    Some(prepared) => prepared.plan(world)
    None => self.query.plan(world)
  }
}

///|
/// Returns a diagnostic plan for this raw cache without updating the cached prepared plan.
pub fn RawQueryCache::plan(self : RawQueryCache, world : World) -> QueryPlan {
  match self.prepared {
    Some(prepared) => prepared.plan(world)
    None => self.query.plan(world)
  }
}

///|
/// Ensures this row query cache holds a prepared plan for the current world layout.
pub fn QueryCache::refresh(self : QueryCache, world : World) -> Unit {
  let prepared = match self.prepared {
    Some(existing) => existing.refresh(world)
    None => self.query.prepare(world)
  }
  self.prepared = Some(prepared)
}

///|
/// Ensures this raw query cache holds a prepared plan for the current world layout.
pub fn RawQueryCache::refresh(self : RawQueryCache, world : World) -> Unit {
  let prepared = match self.prepared {
    Some(existing) => existing.refresh(world)
    None => self.query.prepare(world)
  }
  self.prepared = Some(prepared)
}

///|
/// Runs this cached row query, preparing or refreshing only when needed.
pub fn QueryCache::for_each(
  self : QueryCache,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  self.refresh(world)
  match self.prepared {
    Some(prepared) => prepared.for_each(world, f)
    None => ()
  }
}

///|
/// Runs this cached raw row query, preparing or refreshing only when needed.
pub fn RawQueryCache::for_each(
  self : RawQueryCache,
  world : World,
  f : (RawQueryRow) -> Unit,
) -> Unit {
  self.refresh(world)
  match self.prepared {
    Some(prepared) => prepared.for_each(world, f)
    None => ()
  }
}

///|
/// Runs this cached raw query archetype-by-archetype, preparing or refreshing only when needed.
pub fn RawQueryCache::for_each_archetype(
  self : RawQueryCache,
  world : World,
  f : (RawQueryArchetype) -> Unit,
) -> Unit {
  self.refresh(world)
  match self.prepared {
    Some(prepared) => prepared.for_each_archetype(world, f)
    None => ()
  }
}

///|
/// Implements `query_row_accesses_from_archetype_accesses`.
fn query_row_accesses_from_archetype_accesses(
  accesses : Array[QueryArchetypeComponentAccess],
) -> Array[QueryRowComponentAccess] {
  let out : Array[QueryRowComponentAccess] = []
  for i = 0; i < accesses.length(); i = i + 1 {
    let access = accesses[i]
    out.push({ column_index: access.column_index, stride: access.stride })
  }
  out
}

///|
/// Runs a prepared query with row callbacks. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn PreparedQuery::for_each(
  self : PreparedQuery,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  world.assert_system_components_read(self.required, "PreparedQuery::for_each")
  assert_query_components_registered(
    self.excluded,
    world,
    "PreparedQuery::for_each",
  )
  let plan = if self.archetype_version == world.archetype_version {
    self
  } else {
    Query::new_with_excluded(self.required, self.excluded).prepare(world)
  }
  if plan.required.length() == 0 {
    return
  }
  world.query_depth = world.query_depth + 1
  for i = 0; i < plan.archetypes.length(); i = i + 1 {
    let chunk = plan.archetypes[i]
    let arch = world.archetypes[chunk.archetype_index]
    let ents = arch.entities
    for row = 0; row < ents.length(); row = row + 1 {
      f({
        world,
        entity: ents[row],
        components: plan.required,
        accesses: chunk.row_accesses,
        archetype_index: chunk.archetype_index,
        row,
      })
    }
  }
  world.query_depth = world.query_depth - 1
}

///|
/// Returns a read-only diagnostic snapshot of this prepared query against `world`.
pub fn PreparedQuery::plan(self : PreparedQuery, world : World) -> QueryPlan {
  world.assert_system_components_read(self.required, "PreparedQuery::plan")
  assert_query_components_registered(
    self.required,
    world,
    "PreparedQuery::plan",
  )
  assert_query_components_registered(
    self.excluded,
    world,
    "PreparedQuery::plan",
  )
  let stale = self.archetype_version != world.archetype_version
  if stale {
    build_query_plan(
      self.required,
      self.excluded,
      world,
      "PreparedQuery::plan",
      true,
    )
  } else {
    build_query_plan_from_prepared_archetypes(
      self.required,
      self.excluded,
      world,
      self.archetypes,
      false,
    )
  }
}

///|
/// Returns true when this prepared query was built for an older archetype layout.
pub fn PreparedQuery::is_stale(self : PreparedQuery, world : World) -> Bool {
  self.archetype_version != world.archetype_version
}

///|
/// Returns a current prepared query for `world`, rebuilding only when the cached plan is stale.
pub fn PreparedQuery::refresh(
  self : PreparedQuery,
  world : World,
) -> PreparedQuery {
  world.assert_system_components_read(self.required, "PreparedQuery::refresh")
  assert_query_components_registered(
    self.required,
    world,
    "PreparedQuery::refresh",
  )
  assert_query_components_registered(
    self.excluded,
    world,
    "PreparedQuery::refresh",
  )
  if self.is_stale(world) {
    Query::new_with_excluded(self.required, self.excluded).prepare(world)
  } else {
    self
  }
}

///|
/// Runs a prepared raw query with row callbacks. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn RawPreparedQuery::for_each(
  self : RawPreparedQuery,
  world : World,
  f : (RawQueryRow) -> Unit,
) -> Unit {
  let plan = if self.archetype_version == world.archetype_version {
    self
  } else {
    RawQuery::new_with_excluded(self.required, self.excluded).prepare(world)
  }
  if plan.required.length() == 0 {
    return
  }
  world.assert_system_components_read(
    plan.required,
    "RawPreparedQuery::for_each",
  )
  assert_query_components_registered(
    plan.excluded,
    world,
    "RawPreparedQuery::for_each",
  )
  world.query_depth = world.query_depth + 1
  for i = 0; i < plan.archetypes.length(); i = i + 1 {
    let chunk = plan.archetypes[i]
    let arch = world.archetypes[chunk.archetype_index]
    let ents = arch.entities
    for row = 0; row < ents.length(); row = row + 1 {
      f({
        world,
        entity: ents[row],
        components: plan.required,
        accesses: chunk.row_accesses,
        archetype_index: chunk.archetype_index,
        row,
      })
    }
  }
  world.query_depth = world.query_depth - 1
}

///|
/// Returns a read-only diagnostic snapshot of this prepared raw query against `world`.
pub fn RawPreparedQuery::plan(
  self : RawPreparedQuery,
  world : World,
) -> QueryPlan {
  world.assert_system_components_read(self.required, "RawPreparedQuery::plan")
  assert_query_components_registered(
    self.required,
    world,
    "RawPreparedQuery::plan",
  )
  assert_query_components_registered(
    self.excluded,
    world,
    "RawPreparedQuery::plan",
  )
  let stale = self.archetype_version != world.archetype_version
  if stale {
    build_query_plan(
      self.required,
      self.excluded,
      world,
      "RawPreparedQuery::plan",
      true,
    )
  } else {
    build_query_plan_from_prepared_archetypes(
      self.required,
      self.excluded,
      world,
      self.archetypes,
      false,
    )
  }
}

///|
/// Returns true when this prepared raw query was built for an older archetype layout.
pub fn RawPreparedQuery::is_stale(
  self : RawPreparedQuery,
  world : World,
) -> Bool {
  self.archetype_version != world.archetype_version
}

///|
/// Returns a current prepared raw query for `world`, rebuilding only when the cached plan is stale.
pub fn RawPreparedQuery::refresh(
  self : RawPreparedQuery,
  world : World,
) -> RawPreparedQuery {
  world.assert_system_components_read(
    self.required,
    "RawPreparedQuery::refresh",
  )
  assert_query_components_registered(
    self.required,
    world,
    "RawPreparedQuery::refresh",
  )
  assert_query_components_registered(
    self.excluded,
    world,
    "RawPreparedQuery::refresh",
  )
  if self.is_stale(world) {
    RawQuery::new_with_excluded(self.required, self.excluded).prepare(world)
  } else {
    self
  }
}

///|
/// Runs a prepared raw query archetype-by-archetype. If structural changes made the plan stale,
/// it rebuilds once before iteration.
pub fn RawPreparedQuery::for_each_archetype(
  self : RawPreparedQuery,
  world : World,
  f : (RawQueryArchetype) -> Unit,
) -> Unit {
  world.assert_system_components_read(
    self.required,
    "RawPreparedQuery::for_each_archetype",
  )
  assert_query_components_registered(
    self.excluded,
    world,
    "RawPreparedQuery::for_each_archetype",
  )
  let plan = if self.archetype_version == world.archetype_version {
    self
  } else {
    RawQuery::new_with_excluded(self.required, self.excluded).prepare(world)
  }
  if plan.required.length() == 0 {
    return
  }
  world.query_depth = world.query_depth + 1
  for i = 0; i < plan.archetypes.length(); i = i + 1 {
    let chunk = plan.archetypes[i]
    f({
      world,
      accesses: chunk.accesses,
      archetype_index: chunk.archetype_index,
    })
  }
  world.query_depth = world.query_depth - 1
}

///|
/// Returns the entity for this query row.
pub fn QueryRow::entity(self : QueryRow) -> EntityId {
  self.entity
}

///|
/// Returns true if this row was queried with `component`.
pub fn QueryRow::has(self : QueryRow, component : ComponentTypeId) -> Bool {
  component_array_index_of(self.components, component) >= 0
}

///|
/// Returns true after validating that `index` is a valid query payload slot.
pub fn QueryRow::has_at(self : QueryRow, index : Int) -> Bool {
  ignore(self.component_at_index(index, "QueryRow::has_at"))
  true
}

///|
/// Implements `RawQueryRow::entity`.
pub fn RawQueryRow::entity(self : RawQueryRow) -> EntityId {
  self.entity
}

///|
/// Implements `RawQueryRow::has`.
pub fn RawQueryRow::has(
  self : RawQueryRow,
  component : ComponentTypeId,
) -> Bool {
  component_array_index_of(self.components, component) >= 0
}
