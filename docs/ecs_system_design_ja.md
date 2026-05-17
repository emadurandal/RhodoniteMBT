# ECS System Design

[`moon/rhodonite_core/src/ecs/`](../moon/rhodonite_core/src/ecs/) の ECS は、`World` が entity、archetype SoA、builtin packed GPU blob を所有し、`Schedule` / `System` / `CommandBuffer` が更新順序と遅延変更を扱います。

## Storage

ECS component storage は CPU-only です。user 登録 component は `RegisteredComponent { id, name, cpu_stride }` として登録され、payload は archetype ごとの `ComponentColumn` に `row * stride` で packed されます。`ComponentColumn` は固定長の byte buffer を backing storage とし、capacity 拡張時は buffer を一括確保して既存 payload をコピーします。JS backend でも byte 単位の `Array.push` では拡張しません。

`GlobalTransform` と `Camera` は例外的に renderer upload 用の dedicated blob を持ちます。ECS component row には `{ format, word_offset }` などの CPU ref だけを保持し、matrix bytes は `GlobalTransformBlobStore` / `CameraBlobStore` が管理します。

## Mutation API

`component_bytes` / `set_component_bytes` は entity が対象 component を所有している場合だけ SoA row を読み書きします。byte length が登録済み `cpu_stride` と一致しない場合は `false` / `None` になります。

component 所有の追加は `add_component` または `add_component_bytes` を使います。`add_component` は通常 component を zero bytes で初期化し、builtin `GlobalTransform` / `Camera` の場合は blob slot を確保して CPU ref bytes を書きます。`remove_component` は archetype 移動を起こし、builtin ref component の場合は対応する blob allocation を解放します。

`reserve_batch_capacity(components, additional_rows)` は任意の CPU component signature の archetype に対して、今後 append する row 数を事前確保します。大量 entity を作る sample やアプリでは、既知の batch spawn 前に呼ぶことで spawn/write hot path 中の capacity 拡張と既存 payload コピーを避けます。`spawn_batch(components, count, write)` は同じ signature の archetype に直接 append します。callback 中は row view を貸し出しているため、通常 query callback と同じく構造変更 API は拒否されます。

## Schedule Access Rules

`Schedule` は固定の update/render lifecycle を持ちません。`PhaseKey` は外部から渡される文字列名付き id で、phase の意味と実行順序は `Schedule::run(world, ctx, phases)` または `Schedule::run_phase(world, ctx, phase)` の呼び出し側が決めます。facade runtime では標準 phase を `phase_update()` / `phase_render_extract()` / `phase_render()` などの関数で提供し、`Engine::run_phase_group` が `PhaseGroupKey` ごとの順序で `PhaseSlot::BeforeSchedule`、scene schedule、`PhaseSlot::AfterSchedule` の順に処理します。

このため、ここでの `Schedule` は lifecycle owner ではなく、1 つの `World` に対する system set / runner として扱います。どの phase をどの順で走らせるかは caller / runtime が所有し、`Schedule` は渡された phase に属する system を access declaration に従って実行します。

| API | Required access |
|-----|-----------------|
| `has_component`, `component_bytes`, query prepare/iteration | `reads` または `writes` |
| `set_component_bytes`, `QueryRow::write`, `RawQueryRow::write_view`, column writes | `writes` |
| `create_entity`, `destroy_entity`, `add_component*`, `remove_component`, `reserve_batch_capacity`, `spawn_batch` | `structural_write` と対象 component の `writes` |
| `register_cpu_component` | schedule execution 外 |
| builtin blob resize event drain | `structural_write` |

`Schedule::run` / `Schedule::run_phase` 中は component 登録が lock されます。新しい component type は schedule 実行前、または実行と実行の間で登録します。

## Query Model

`QueryRow::read(component, f)` / `write(component, f)` は CPU SoA row を closure-scoped view として渡します。`RawQuery::for_each_archetype` は hot loop 向けに archetype column view を返します。query plan は component-to-archetype index を使って候補 archetype を絞ります。

query callback 中に `create_entity`、`destroy_entity`、`add_component*`、`remove_component`、`set_component_bytes`、component 登録を直接呼ぶと abort します。構造変更は `CommandBuffer` に積み、system callback 後に適用します。

## Builtin Blob Upload

Renderer upload は builtin blob API を使います。

- `drain_global_transform_blob_write_views`
- `drain_global_transform_blob_resize_events`
- `drain_camera_blob_write_views`
- `drain_camera_blob_resize_events`
- `write_global_transform_blob_range_views`
- `write_global_transform_blob_range_by_refs`

`GpuWriteView` は blob backing bytes の借用 view です。同じ blob を resize / mutate する前に upload まで終える必要があります。

## Tests

主要な期待値は `ecs_test.mbt` と TypeScript wrapper の `world.test.ts` にあります。変更後は `moon check --target all`、`pnpm run test:core:mbt`、`pnpm run test:core:js` を通します。rendering に影響する変更では visual regression も確認します。
