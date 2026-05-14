# Rhodonite Core ECS (`emadurandal/rhodonite_core/ecs`)

**Languages:** [日本語 (Japanese)](ecs_ja.md)

[`moon/rhodonite_core/src/ecs/`](../moon/rhodonite_core/src/ecs/) is an **archetype**-based ECS. On the CPU, components live in **SoA (Structure of Arrays)** tables for cache-friendly column iteration. For WebGPU, **`EntityId.index` is a stable logical subscript** into storage buffers: **GPU-visible** component payloads live in a **flat array separate from archetype rows**, while CPU-only data stays in archetype SoA columns.

External `System` / `Schedule` types are available, but `World` itself does not own systems. Row iteration is exposed through `Query`; built-in helpers are implemented on top of the same internal iterator.

For a machine-readable API listing, see [`pkg.generated.mbti`](../moon/rhodonite_core/src/ecs/pkg.generated.mbti).

---

## Core types

| Type | Role |
|------|------|
| `EntityId` | Dense `index` (GPU subscript / array slot) plus `generation`, bumped on destroy/reuse. Stale handles fail `is_alive`. |
| `ComponentTypeId` | Opaque id assigned monotonically by `ComponentRegistry`. |
| `EntityLocation` | Which archetype table and row a live entity occupies. |
| `ComponentKind` | `CpuOnly` (payload in SoA column) / `GpuVisible` (signature in archetype only; payload in flat `GpuComponentStore`). |
| `RegisteredComponent` | Name, `kind`, `cpu_stride`, optional `gpu_layout`. |
| `GpuWrite` | Owned GPU upload slice (`byte_offset` + `FixedArray[Byte]`), kept for APIs that need ownership. |
| `GpuWriteView` | Borrowed GPU upload slice (`byte_offset` + `ArrayView[Byte]`) for immediate zero-copy-style upload paths. |

---

## `World` internals

```mermaid
flowchart TB
  subgraph world [World]
    registry[ComponentRegistry]
    generations[generations]
    alive[alive]
    free_indices[free_indices]
    locations[locations]
    archetypes[archetypes]
    gpu_stores[gpu_stores]
    resize_events[resize_events]
    tf_ids[builtin ComponentTypeIds]
  end
  registry --> archetypes
  registry --> gpu_stores
  locations --> archetypes
  generations --> alive
  free_indices --> generations
  archetypes --> locations
  gpu_stores --> resize_events
```

- **`generations` / `alive` / `free_indices`**: Slot reuse and generation tracking.
- **`locations`**: `EntityId.index` → `EntityLocation?` (archetype index and row).
- **`archetypes`**: One SoA table per signature (CPU component payloads). Each column tracks a `row_capacity` watermark separately from the logical row count so appends can grow backing storage without leaking spare capacity to query column views.
- **`archetype_signature_cache` / `component_archetypes`**: Internal indexes for storage and query planning. Signature lookup avoids repeatedly scanning all archetypes for structural moves, and component-to-archetype lists let query planning start from the rarest required component instead of every archetype.
- **`gpu_stores`**: Parallel array to registry indices, `GpuComponentStore?` (`Some` only for GPU-visible types). Stores keep flat payload bytes, per-row dirty flags, batched dirty ranges, and a packed active-index set for owned GPU-visible rows.
- **`resize_events`**: Queue of notifications when flat stores grow (buffer recreation / full upload may be needed).

---

## Archetypes and SoA

- Each archetype’s **signature** is a **sorted ascending** list of `ComponentTypeId`; entities with the same set share one table.
- A new `World` starts with **archetype 0 = empty signature**; freshly spawned entities sit there until components are added ([`World::new` in `world.mbt`](../moon/rhodonite_core/src/ecs/world.mbt)).
- Each CPU column stores packed `bytes` with fixed `stride`; row `row` starts at offset `row * stride`.
- Column backing may have more capacity than live rows. Public `RawQueryArchetype::read_column` / `write_column` expose only `entities.length() * stride` logical bytes, not spare capacity.

```mermaid
flowchart LR
  empty["Archetype_0 empty signature"]
  a["Archetype_A TF"]
  ab["Archetype_AB TF+Mat"]
  empty -->|"add TF"| a
  a -->|"add Mat"| ab
```

For a visual of “columns = components, rows = entities”, see below.

![SoA sketch](assets/ecs-soa-sketch.svg)

---

## Where `CpuOnly` vs `GpuVisible` live

```mermaid
flowchart TB
  entity[Entity E with index i]
  subgraph arch_row [Archetype table row]
    sig[Signature includes type ids]
    soa[SoA columns for CpuOnly payloads]
  end
  subgraph flat [GpuComponentStore]
    slot["Byte range i times stride .. i plus 1 times stride"]
  end
  entity --> arch_row
  entity -->|"GpuVisible payload"| flat
```

- **CpuOnly**: Bytes live in the archetype SoA column. When an entity moves archetypes, its **row index** changes, but overlapping columns are copied with `copy_row_to`.
- **GpuVisible**: The archetype row only records the **type id** in the signature (`cpu_stride == 0`). Payload bytes always sit in the **flat store** at **`entity.index * stride`**. Archetype row motion does **not** change the GPU slot index.
- GPU-visible ownership is also mirrored in a packed active-index set (`World::gpu_component_active_indices`). `add_component*` activates the entity slot; `remove_component` and `destroy_entity` zero-clear and deactivate it.

---

## Entity lifecycle

```mermaid
sequenceDiagram
  participant W as World
  participant A0 as Archetype0
  participant GPU as GpuStores
  W->>W: create_entity
  alt free slot
    W->>W: pop free_indices reuse index
  else new slot
    W->>W: push generations alive locations
  end
  W->>A0: push_empty_row
  W->>W: locations index set
  W->>GPU: ensure_gpu_capacity
  W->>W: destroy_entity
  W->>A0: swap_remove_row update moved entity location
  W->>GPU: clear_gpu_slots index
  W->>W: bump generation push free_indices
```

### Bulk spawning built-in transforms

For large static batches that need the built-in `Transform3D` + `GlobalTransform` pair, use `World::spawn_transform_global_batch(count, write)`.

This API creates entities directly in the `[Transform3D, GlobalTransform]` archetype, avoiding the normal sequence of:

1. spawn into the empty archetype,
2. migrate when `Transform3D` is added,
3. migrate again when `GlobalTransform` ownership is added.

The callback receives direct row views:

```moonbit
let entities = world.spawn_transform_global_batch(count, fn(i, entity, tf_row, _gt_row) {
  @comp.Transform3D::write_trs_to_component_mut_view(
    tf_row,
    px,
    py,
    pz,
    0.0,
    0.0,
    0.0,
    1.0,
    sx,
    sy,
    sz,
  )
  ignore(i)
  ignore(entity)
})
```

The callback initializes the `Transform3D` row directly. `GlobalTransform` is now an 8-byte CPU row containing `{ format, word_offset }`; `spawn_transform_global_batch` allocates an identity slot in the packed transform blob for each entity, so the callback does not write matrix bytes itself.

For arbitrary component signatures, use `World::spawn_batch(components, count, write)`. It canonicalizes the signature, appends entities directly to the matching archetype, activates any `GpuVisible` slots, and marks those GPU rows dirty as one contiguous range when entity indices are dense.

```moonbit
let entities = world.spawn_batch([cpu_component, gpu_component], count, fn(i, entity, row) {
  row.write(cpu_component, fn(cpu) => cpu[0] = i.to_byte())
  row.write(gpu_component, fn(gpu) => gpu[0] = entity.gpu_index().to_byte())
})
```

The row callback runs while ECS views are borrowed, so structural mutation APIs are still rejected inside it. This keeps the direct append path from invalidating the row views it hands out.

---

## Adding/removing components and archetype migration

`add_component` / `add_component_bytes` / `remove_component` in short:

1. If the signature **already** contains the type, return `false`; existing CPU payloads are updated with `set_component_bytes`.
2. Otherwise **materialize** a new signature’s archetype via `ensure_archetype`.
3. Allocate a **new row** for the entity, `copy_row_to` overlapping columns.
4. Apply zero/default payload on `add_component`, or the supplied CPU/GPU payload on `add_component_bytes`.
5. **Remove** the old row with `swap_remove_row`. If the last row moved, **`update_moved_location`** fixes that entity’s `locations` entry.

```mermaid
flowchart TD
  start[add_component/add_component_bytes E C]
  alive{is_alive E}
  has{has_component E C}
  same[return false]
  migrate[ensure_archetype new signature]
  copy[copy_row_to new row set bytes]
  swap[swap_remove_row old row fix locations]
  start --> alive
  alive -->|no| fail[return false]
  alive -->|yes| has
  has -->|yes| same
  has -->|no| migrate
  migrate --> copy
  copy --> swap
```

---

## Query API (High-Level) and RawQuery API (Low-Level)

Component identity is always `ComponentTypeId`. There is no separate `Component<T>` handle or codec object.

High-level row iteration uses `Query::new(required)` and `query.for_each(world, f)`. `QueryRow::read(component, f)` / `write(component, f)` borrow `ArrayView[Byte]` / `MutArrayView[Byte]` only for the closure body. Callers do not need to branch on `CpuOnly` vs `GpuVisible`; writing a `GpuVisible` component marks the row dirty automatically.

- `required` becomes a named value that can be reused by a system.
- `Query::new` rejects duplicate component ids up front.
- The input array is copied, so later changes to the caller's array cannot change query payload order.
- During schedule execution, every required component must be declared in the active System's `reads` or `writes` set.
- If a GPU store grows during iteration, a `GpuResizeEvent` may be queued (`needs_full_upload`, etc.).

```moonbit
let query = Query::new([tf, gt])
query.for_each(world, fn(row) {
  row.read(tf, fn(tf_bytes) {
    row.write(gt, fn(gt_row) {
      let local = @comp.Transform3D::local_matrix_from_component_view(tf_bytes)
      @comp.matrix44f_write_affine3x4_to_gpu_row(local, gt_row)
    })
  })
})
```

Built-in components also have typed convenience helpers. These are intended for sparse edits, editor/debug code, and tests; engine hot paths continue to use raw or specialized bulk APIs.

```moonbit
query.for_each(world, fn(row) {
  let local = row.read_transform3d().local_matrix()
  row.write_global_transform(fn(gt) => gt.write_matrix(local))
})
```

Low-level iteration uses `RawQuery`. `RawQueryRow::read_view` / `write_view` and `RawQueryArchetype::read_column` / `write_column` return zero-copy views directly. They work for user-defined components too, but the caller owns layout, stride, view lifetime, and dirty/upload implications.

```moonbit
let raw = RawQuery::new([tf])
raw.for_each_archetype(world, fn(chunk) {
  let stride = chunk.component_stride(tf)
  let tf_column = chunk.write_column(tf)
  for row = 0; row < chunk.length(); row = row + 1 {
    let e = chunk.entity(row)
    let base = row * stride
    // update tf_column[base .. base + stride]
    ignore(e)
  }
})
```

`Query::prepare` / `RawQuery::prepare` use the world's component-to-archetype index to skip unrelated archetypes, then cache matched archetypes and access metadata while the world's archetype version is unchanged. Non-prepared `for_each` also goes through the same plan builder.

---

## CommandBuffer

World mutation APIs such as `create_entity`, `destroy_entity`, `add_component`, `add_component_bytes`, `remove_component`, `set_component_bytes`, and `clear_gpu_component` are guarded during active query iteration. Calling them from a query callback aborts because archetype rows and mutable payload views could be invalidated.

Use the `CommandBuffer` passed to a `System` when a query/system wants to request changes during iteration:

```moonbit
let system = System::new_with_structural_write(
  "replace-component",
  Update,
  [],
  [old_component, new_component],
  fn(world, _ctx, commands) {
    query.for_each(world, fn(row) {
      let spawned = commands.create_entity()
      commands.remove_component(row.entity(), old_component)
      commands.add_component_bytes(row.entity(), new_component, bytes)
      commands.add_component_bytes(spawned, new_component, spawn_bytes)
    })
  },
)
```

`Schedule::run` creates the command buffer for each system and validates queued commands against that system's `writes` / `structural_write` declaration. Within a phase, conflict-free systems are grouped into greedy batches. Commands are applied after every system in the batch returns, preserving system registration order and each buffer's insertion order. `commands.create_entity()` reserves an `EntityId` immediately; the reserved entity is not alive until apply, but later commands in the same buffer can add components to it.

---

## System and Schedule

`World` does not own systems. The first system layer is an external `Schedule` containing function-backed `System` values.

```moonbit
let schedule = Schedule::new()
schedule.add_system(System::new("Move", Update, [], [transform], fn(world, ctx, commands) {
  // query world, optionally enqueue structural changes into commands
}))
let _ = schedule.run(world, SystemContext::new(0.016, frame_index))
```

`Schedule::run` is single-threaded. It runs phases in this order: `PreUpdate`, `Update`, `PostUpdate`, `PreRender`, `RenderExtract`. Systems in the same phase keep registration order but are split into conflict-free greedy batches. Each system receives a fresh `CommandBuffer`; systems in the same batch cannot observe each other's queued changes, while later batches can observe commands applied by earlier batches.

`Schedule::run` temporarily closes component registration while systems are running, then reopens it before returning. Use `World::component_registration_locked()` to inspect that state.

`System::reads` and `System::writes` are metadata for scheduling and batching. They are validated for duplicates and copied on construction. `System::conflicts_with(other)` detects write/write, write/read, and read/write overlap, and `Schedule::has_parallel_access_conflicts()` reports whether systems in the same phase have access conflicts that force separate batches. `Schedule::run` remains single-threaded but uses the same conflict rules for batch splitting.

The built-in transform update can also be registered with `transform_propagation_system(world)`. That system runs the same work as `World::update_global_transforms_from_transforms` in the `PostUpdate` phase, declaring `Transform3D` / `ChildOf` as reads and `GlobalTransform` as a write.

`update_global_transforms_from_transforms` keeps archetypes without `ChildOf` on the direct fast path and sends only archetypes that include `ChildOf` through the hierarchy-aware path. A scene can therefore mix a large flat batch with a smaller parented set without forcing the flat batch through ancestor traversal.

---

## GPU upload and resize

- **`drain_gpu_writes(component)`**: Sorts dirty entity indices, merges contiguous runs, and also consumes already batched dirty ranges recorded by bulk paths. It returns `GpuWrite` slices (`byte_offset` + `bytes`) suitable for `write_buffer_from_fixed_array` (or similar).
- **`drain_gpu_write_views(component)`**: Same dirty consumption semantics, but returns borrowed `GpuWriteView` slices (`byte_offset` + `ArrayView[Byte]`). Use this when the caller can upload immediately before mutating the same GPU component store again. This avoids the extra `FixedArray[Byte]` payload copy in ECS drain paths.
- **`gpu_component_active_indices(component)`**: Returns a copy of the packed active `EntityId.index` values for a GPU-visible component. This is useful for renderer-side extraction or future packed update paths without scanning every possible entity slot.
- **`drain_resize_events`**: Drains notifications when backing arrays grow; callers may need to **recreate GPU buffers** and optionally **full-upload**. During `Schedule::run`, this consumes a world-owned event queue and requires `structural_write`; outside schedule execution it can be called directly.

`add_component`, `add_component_bytes`, `component_bytes`, and `set_component_bytes` handle both CPU-only and GPU-visible components. CPU-only payloads live in archetype SoA rows; GPU-visible payloads live in flat GPU rows keyed by `EntityId.index`. GPU store capacity growth and `GpuResizeEvent` creation go through one internal `World` path. Both JS and non-JS targets grow GPU stores geometrically; upload spans are exposed as borrowed `ArrayView[Byte]` values for immediate zero-copy upload.

For WebGPU uploads, `rhodonite_webgpu/webgpu` provides:

- `GPUQueue::write_buffer_from_fixed_array` for owned `GpuWrite` payloads.
- `GPUQueue::write_buffer_from_array_view` for borrowed `GpuWriteView` payloads. JS forwards the backing `Uint8Array` plus source offset/size to `GPUQueue.writeBuffer`; native forwards the `ArrayView[Byte]` backing bytes plus source offset to `wgpuQueueWriteBuffer` without compacting the view into a new `Bytes`.
- `GPUDevice::create_global_transform_words_buffer(world)` and `GPUQueue::upload_global_transform_writes(buffer, writes)` for the built-in packed `GlobalTransform` storage-buffer path. `GPUQueue::drain_and_upload_global_transform_writes(buffer, world)` combines the dirty-view drain with immediate upload.

Example: [`ecs-scene-graph` `render_frame`](../moon/rhodonite_examples/src/ecs-scene-graph/common/webgpu_renderer.mbt) and [`ecs-mass-cubes`](../moon/rhodonite_examples/src/ecs-mass-cubes/common/webgpu_renderer.mbt) now bind one storage buffer as `array<u32>`. Their instance buffers carry an 8-byte `GlobalTransform` ref (`format`, `word_offset`) plus color, and the WGSL helpers from `emadurandal/rhodonite_core/ecs/wgsl` (`global_transform_words_binding_default()`, `global_transform_helpers_default()`, or the custom-name variants) load either 12 f32 words or 6 packed-f16 words from the same blob in one draw. `rhodonite_webgpu/webgpu` also provides `global_transform_ref_instance_vertex_buffer_layout`, `GPUDevice::create_global_transform_words_buffer`, `GPUDevice::create_global_transform_words_bind_group`, and `GPUQueue::upload_global_transform_writes` for the matching vertex layout, storage buffer, bind group, and upload path. TypeScript renderers use the matching `globalTransformWordsBindingDefault()`, `globalTransformHelpersDefault()`, `globalTransformRefInstanceVertexBufferLayout()`, `createGlobalTransformWordsBuffer()`, `globalTransformWordsBindGroup()`, `uploadGlobalTransformWrites()`, and `writeGlobalTransformBlobRangeByRefs()` exports from `moon/rhodonite_core/src/ecs/ts`.

TypeScript bulk writers can use `GlobalTransformBlobWriter` to keep fp32/fp16 packing out of renderer code. The helper builds one reusable writer per upload callback, not one object per entity. Renderer loops call `writer.setAffine3x4At(index, ...)` for full rows or `writer.setElementAt(index, row, column, value)` for partial updates; the writer resolves each entity ref and writes either f32 words or packed f16 halves. For hot loops, `writer.elementSetter(row, column)` returns a reusable scalar setter selected once for dense f32, dense f16, or mixed refs. Mixed refs are scanned into contiguous same-format runs, so patterns such as first-half f32 / second-half f16 avoid a per-entity format lookup inside each run.

The MassCubes samples expose a source-level precision-mode constant near the top of their user source. The modes cover all-fp32, all-fp16, first-half fp32 / second-half fp16, and even-entity-id fp32 / odd-entity-id fp16. Mixed modes still use the same instance ref and one draw call; the renderer uploads only the active packed-word span needed by the selected refs.

`World::new()` uses fp32 as the default allocation format. `World::new_with_global_transform_format(Affine3x4F16)` changes only the default for newly allocated `GlobalTransform` slots; individual entities can later move between `Affine3x4F32` and `Affine3x4F16` with `set_global_transform_format(entity, format)`. The shader does not need separate draw calls for the two formats because the per-instance ref includes the format tag.

Packed GlobalTransform upload APIs:

- `global_transform_ref(entity)` returns the entity's `{ format, word_offset }`.
- `write_global_transform_refs_into(entities, dst, stride, offset)` writes refs into an instance buffer.
- `extract_global_transform_refs(entities)` returns a tightly packed ref blob for JS/TS callers.
- `global_transform_blob_word_capacity()` sizes the WebGPU storage buffer in `u32` words.
- `drain_global_transform_blob_write_views()` returns borrowed byte ranges for the packed blob.
- `write_global_transform_blob_range_views(first_word, word_count, write)` lends a mutable blob byte range for renderer-owned bulk writers, marks that word range dirty, and returns borrowed upload views. This is the hot path used by the MassCubes demos when their transform refs are dense.
- `drain_global_transform_blob_resize_events()` reports packed blob growth; renderers should recreate the storage buffer and full-upload when needed.

---

## TypeScript wrapper

The JS target also exposes an ECS bridge and TypeScript wrappers under [`moon/rhodonite_core/src/ecs/ts/`](../moon/rhodonite_core/src/ecs/ts/). The wrapper currently covers the `World` + `Query` / `RawQuery` surface: entity lifecycle, component registration, built-in component ids, closure-scoped query access, raw row/chunk views, GPU write-view drains, resize events, and built-in transform upload helpers. `Schedule`, `System`, and `CommandBuffer` are intentionally not wrapped yet.

The wrapper separates high-level and raw access:

- `QueryRow.read(component, f)` / `write(component, f)` pass `ByteView` only inside the callback.
- `RawQueryRow.readView` / `writeView`, `RawQueryArchetype.readColumn` / `writeColumn`, and `GpuWriteView.bytes` expose `ByteView` directly for expert paths.
- `ByteView` stores the original MoonBit `{ buf, start, end }` view and reads/writes through that backing storage directly.
- `ByteView.asUint8Array()` returns a zero-copy `Uint8Array.subarray(...)` only when the backing storage is already typed, which is the normal GPU-store upload path.
- CPU SoA columns may be backed by a JS number array. Those are still zero-copy through `ByteView.get`, `set`, `getF32`, and `setF32`; converting them to a `Uint8Array` requires the explicitly named `toUint8ArrayCopy()`.
- Copying APIs are named accordingly in TS, for example `componentBytesCopy` and `drainGpuWritesCopy`. Prefer `drainGpuWriteViews` for immediate WebGPU uploads.

```ts
import { GpuLayout, Query, World } from "./moon/rhodonite_core/src/ecs/ts/index.ts";

const world = World.new();
const material = world.registerGpuComponent("Material", GpuLayout.empty(16));
const entity = world.createEntity();
world.addComponent(entity, material);

Query.new([material]).forEach(world, (row) => {
  row.write(material, (bytes) => {
    bytes.setF32(0, 1.0);
  });
});

for (const write of world.drainGpuWriteViews(material)) {
  const bytes = write.bytes().asUint8Array();
  if (bytes === null) throw new Error("GPU write view must be typed");
  // queue.writeBuffer(buffer, write.byteOffset(), bytes);
}
```

---

## Built-in components (three)

Registered in `World::new` in this order (`ComponentTypeId.index` 0, 1, 2):

| Order | Name | Kind | Role |
|-------|------|------|------|
| 0 | `Transform3D` | CpuOnly | Local TRS, etc., in SoA. `set_transform` / `get_transform`. |
| 1 | `GlobalTransform` | GpuVisible | World affine matrix in flat GPU store. Default is three `vec4<f32>` rows (48-byte stride); fp16 worlds use three `vec4<f16>` rows (24-byte stride). `set_global_transform` / `get_global_transform`. |
| 2 | `ChildOf` | CpuOnly | Parent `EntityId` index/generation. `set_child_of` / `get_child_of`. |

Hierarchy and world matrix:

```mermaid
flowchart BT
  root[Root entity TF only]
  child[Child TF plus ChildOf]
  root -->|"ChildOf parent"| child
  child -->|"compute_global_transform chain"| worldM[World matrix]
  worldM -->|"update_global_transforms_from_transforms"| gtBlob[GlobalTransform packed blob slot]
```

- **`compute_global_transform`**: Walks `ChildOf` toward the root (fails on cycles or dead parents), multiplies `Transform3D` matrices into a world matrix.
- **`update_transform3d_positions`**: Bulk-updates only the position field of built-in `Transform3D` without constructing a `QueryRow` per entity. JS uses the public archetype-column path; non-JS uses a direct archetype sweep with fixed-offset f32 writes.
- **`update_global_transforms_from_transforms`**: Bulk-updates every entity that has **both** built-in transforms. Archetypes without `ChildOf` stay on the direct fast path; archetypes with `ChildOf` use the hierarchy-aware path and read parent links directly from the `ChildOf` column. The result is written to each entity's packed blob slot and marked dirty as a word range. `Affine3x4F32` slots use 12 `u32` words; `Affine3x4F16` slots use 6 packed-half words. Both preserve shear from non-uniform scale combined with parent rotation while avoiding the implicit `[0,0,0,1]` row upload.

---

## Registering custom components

- **`World::register_cpu_component(name, cpu_stride)`**: Stride for SoA storage; appends `None` to `gpu_stores`.
- **`World::register_gpu_component(name, gpu_layout)`**: Requires `GpuLayout::is_valid`; appends `Some(GpuComponentStore::new(...))`.

Register components outside active schedule execution. `Schedule::run` temporarily closes registration while systems run, then reopens it before returning; registering new component types between schedule runs is allowed.

Layout helpers: [`gpu_layout.mbt`](../moon/rhodonite_core/src/ecs/components/gpu_layout.mbt) (`GpuLayout::std140`, `GpuLayout::empty`, etc.).

---

## Minimal API cookbook

Sketch only—**imports and package aliases omitted**. In a real package, add `@ecs`, `@matrix44`, etc. in `moon.pkg`.

```moonbit
// World and entity
let world = World::new()
let e = world.create_entity()

// Built-ins
ignore(world.set_transform_trs(e, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0))
ignore(world.set_global_transform(e, Matrix44F::identity()))

// Custom CPU component
let tag = world.register_cpu_component("Tag", 4)
ignore(world.add_component_bytes(e, tag, tag_bytes))

// Query (e.g. TF + GT together)
let required = [world.transform_component(), world.global_transform_component()]
let query = Query::new(required)
query.for_each(world, fn(row) {
  let local = row.read_transform3d().local_matrix()
  ignore(world.set_global_transform(row.entity(), local))
  ...
})

// End of frame: partial GPU upload
let gt = world.global_transform_component()
let writes = world.drain_gpu_writes(gt)
// queue.write_buffer_from_fixed_array(buffer, w.byte_offset, w.bytes)

// Immediate borrowed upload path
let views = world.drain_global_transform_blob_write_views()
// queue.write_buffer_from_array_view(buffer, v.byte_offset, v.bytes)
```

---

## Tests and source map

Behavior is pinned in [`ecs_test.mbt`](../moon/rhodonite_core/src/ecs/ecs_test.mbt) (archetype moves, generation reuse, logical column length after capacity growth, packed GPU active indices, merged `drain_gpu_writes` / `drain_gpu_write_views` ranges, bulk transform spawn, std140 padding, etc.).

The ECS microbench package lives at [`moon/rhodonite_core/src/ecs_bench/`](../moon/rhodonite_core/src/ecs_bench/). From the repository root:

```bash
pnpm run bench:ecs        # JS target
pnpm run bench:ecs:js
pnpm run bench:ecs:native
pnpm run bench:ecs:wasm   # wasm-gc build only
pnpm run bench:ecs:wasm-gc
```

Core implementation files:

- [`types.mbt`](../moon/rhodonite_core/src/ecs/types.mbt) — data structures
- [`world.mbt`](../moon/rhodonite_core/src/ecs/world.mbt) — entities, archetypes, queries
- [`archetype.mbt`](../moon/rhodonite_core/src/ecs/archetype.mbt) — SoA / swap-remove
- [`registry.mbt`](../moon/rhodonite_core/src/ecs/registry.mbt) — registration
- [`gpu_store.mbt`](../moon/rhodonite_core/src/ecs/gpu_store.mbt) — flat stores and dirty queues
- [`world_transform3d.mbt`](../moon/rhodonite_core/src/ecs/world_transform3d.mbt) / [`world_global_transform.mbt`](../moon/rhodonite_core/src/ecs/world_global_transform.mbt) / [`world_child_of.mbt`](../moon/rhodonite_core/src/ecs/world_child_of.mbt) — built-in APIs
