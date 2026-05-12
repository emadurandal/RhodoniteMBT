# Rhodonite Core ECS System 設計

[`moon/rhodonite_core/src/ecs/`](../moon/rhodonite_core/src/ecs/) の ECS は、`World` がエンティティ、アーキタイプ SoA、GPU-visible flat store を所有し、`Schedule` / `System` / `CommandBuffer` が更新順序と遅延変更を扱います。

この文書は、かつての System 導入案ではなく、現行実装を正とした設計メモです。行イテレーションは公開 API としては `Query` に一本化し、アプリケーション側の更新処理は外付け `Schedule` に System を登録して実行できます。

## 結論

現行方針は **外付け `Schedule` + 関数型 `System` + deferred `CommandBuffer`** です。

- `World` は ECS データ所有と低レベル操作に留める。
- `Schedule` が phase 順、同一 phase 内は登録順で System を実行する。
- System は `reads` / `writes` / `structural_write` を宣言する。
- System 内の query callback 中に直接構造変更せず、必要な変更は `CommandBuffer` に積む。
- GPU-visible component を直接書いた場合は、明示的に dirty を記録する。

## 主要な型

`SystemContext` は core ECS が知る最小限の実行時情報だけを持ちます。

```moonbit
pub(all) struct SystemContext {
  delta_seconds : Float
  frame_index : Int
}
```

System phase は固定 enum です。`Schedule::run` はこの順序で phase を処理します。

```moonbit
pub(all) enum SystemPhase {
  PreUpdate
  Update
  PostUpdate
  PreRender
  RenderExtract
}
```

`System` は名前、phase、component access 宣言、構造変更権限、実行関数を持ちます。

```moonbit
pub struct System {
  name : String
  phase : SystemPhase
  reads : Array[ComponentTypeId]
  writes : Array[ComponentTypeId]
  structural_write : Bool
  run : (World, SystemContext, CommandBuffer) -> Unit
}
```

`System::new` は `structural_write=false` の System を作ります。entity 作成・破棄や component 追加・削除のように World 構造を変える System は `System::new_with_structural_write` を使います。

## Access 宣言

`reads` は読み取り専用 access、`writes` は読み書き可能 access です。`writes` に含めた component は読むこともできます。

同じ component を `reads` と `writes` の両方に入れる必要はありません。現行実装では、`reads` 内、`writes` 内、または `reads` と `writes` 間に重複がある System は構築時に `abort` します。

Schedule 実行中、`World` は active system の access 宣言を guard として保持します。

| 操作 | 必要な宣言 |
|------|------------|
| `component_bytes` | `reads` または `writes` |
| `Query` required component | `reads` または `writes` |
| `QueryRow::read_view` | `reads` または `writes` |
| `QueryRow::write_view` | `writes` |
| `set_component_bytes` / `clear_gpu_component` | `writes` |
| `drain_gpu_writes` | `writes` |
| `drain_resize_events` | `structural_write` |
| `add_component` / `add_component_bytes` / `remove_component` | `writes` + `structural_write` |
| `create_entity` / `destroy_entity` | `structural_write` |

`component_bytes` / `set_component_bytes` は CPU-only / GPU-visible の両方を registry kind に応じて扱います。CPU-only は archetype SoA row、GPU-visible は `EntityId.index` ベースの flat GPU row を読み書きします。`set_component_bytes` は既存 payload 更新だけを行い、archetype 構造を変えません。byte length が登録済み stride と一致しない場合は `false` を返します。

component 所有の追加は `add_component` または `add_component_bytes` を使います。どちらも registry kind に応じて CPU-only / GPU-visible の両方を扱います。`add_component` は CPU component なら zero bytes で SoA row を初期化し、GPU-visible component なら ownership marker を追加して GPU slot を zero clear します。`add_component_bytes` は CPU component なら SoA row、GPU-visible component なら flat GPU row を指定 bytes で初期化します。`remove_component` と各 add API は archetype 移動を起こすため、component `writes` だけでなく `structural_write` も要求します。

GPU-visible component に対する `component_bytes` / `set_component_bytes` / `clear_gpu_component` は、entity が対象 component を archetype signature 上で持っている場合だけ操作できます。GPU store の slot は `EntityId.index` で引けますが、component 所有の有無は archetype signature を正とします。

GPU store の capacity 拡張と `GpuResizeEvent` 発行は `World` 内部の共通経路に集約しています。`add_component`、`add_component_bytes`、`set_component_bytes`、`clear_gpu_component`、query の GPU row access、builtin `set_global_transform` は同じ resize event 生成規則に従います。

`drain_resize_events` は World が所有する resize event queue を消費します。Schedule 実行中に呼ぶ場合は、event queue に対する構造的 access として `structural_write` が必要です。Schedule 外では従来通り呼べます。

`destroy_entity` は GPU slot の clear などを伴いますが、entity lifetime の構造操作として扱います。並列化では `structural_write` を持つ System が同 phase の他 System と衝突扱いになるため、個別 GPU component の `writes` までは要求しません。

## Schedule

`Schedule` は `World` の外側にあります。`World` に System list は持たせません。

```moonbit
pub struct Schedule {
  systems : Array[System]
}
```

`Schedule::run` は単一スレッドで phase 順、同一 phase 内は登録順に System を実行します。各 System には新しい `CommandBuffer` が渡され、System が戻った直後に commands が適用されます。そのため、前の System が行った変更を後続 System が観測できます。

Schedule 実行中は component 登録がロックされます。`register_cpu_component` / `register_gpu_component` は schedule 実行中に呼ばれると `abort` します。Schedule 実行と実行の間では、新しい component type を登録できます。

## CommandBuffer

`Query::for_each` の callback 中に、構造変更 API を直接呼ぶことはできません。`query_depth` guard により `abort` します。これは走査中の archetype row view と entity location を守るためです。

System から遅延適用したい変更は `CommandBuffer` に積みます。

```moonbit
pub(all) enum WorldCommand {
  DestroyEntity(EntityId)
  AddComponent(EntityId, ComponentTypeId)
  AddComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  SetComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  RemoveComponent(EntityId, ComponentTypeId)
  ClearGpuComponent(EntityId, ComponentTypeId)
}
```

`CommandBuffer::apply` は insertion order で commands を適用し、失敗した command があれば `false` を返します。失敗後も後続 command は実行され、最後に buffer は空になります。component 追加は `CommandBuffer::add_component` または `CommandBuffer::add_component_bytes` を使えます。

`CreateEntity` command はまだありません。System 内で entity を作る場合は、query callback の外で `World::create_entity` を直接呼びます。この場合は `structural_write` が必要です。query callback 内で entity 作成を予約したい場合は、将来的に予約 ID 付き create command を設計する必要があります。

## Query

公開の row iteration API は `Query` です。`Query` は内部 row iterator を使いますが、外へは `QueryRow::read_view` / `QueryRow::write_view` として公開し、component ごとの access guard を維持します。

`required` に同じ `ComponentTypeId` を重複指定すると `abort` します。同じ component row を複数 payload として扱う意味が曖昧なためです。

```moonbit
let query = Query::new([tf, gt])
query.for_each(world, fn(row) {
  let tf_row = row.read_view(tf)
  let gt_row = row.write_view(gt)
  // ...
})
```

`QueryRow::read_view(component)` は、`CpuOnly` なら archetype SoA row、`GpuVisible` なら `EntityId.index` ベースの flat GPU row を `ArrayView[Byte]` として返します。Schedule 実行中は、component が active system の `reads ∪ writes` に含まれる必要があります。

`QueryRow::write_view(component)` は同じ payload を `MutArrayView[Byte]` として返します。Schedule 実行中は、component が active system の `writes` に含まれる必要があります。`GpuVisible` component の mutable view を要求した場合、その entity row は直ちに dirty になります。

## GPU-visible component の dirty 管理

System が `QueryRow::write_view` で `GpuVisible` payload の mutable view を取得した場合、その row は自動で dirty になります。これは「実際に bytes が変わった row」ではなく、「mutable view を要求した row」を upload 対象にする設計です。読み取りだけなら `read_view` を使うことで余分な dirty を避けられます。

```moonbit
let query = Query::new([tf, gt])
query.for_each(world, fn(row) {
  // row.write_view(gt) は GlobalTransform の flat GPU row。
  // GpuVisible の mutable view を取得した時点で dirty になる。
  let gt_row = row.write_view(gt)
  ignore(gt_row)
})
```

`Schedule` が `writes` を見て自動 dirty 化する設計は採っていません。`writes` は「書く可能性がある」宣言であり、実際にどの entity が変わったかまでは表さないためです。

## Builtin Transform System

`World::update_global_transforms_from_transforms` は低レベル API として残っています。System として使う場合は `transform_propagation_system(world)` factory を使います。

```moonbit
let schedule = Schedule::new()
schedule.add_system(transform_propagation_system(world))
let ok = schedule.run(world, SystemContext::new(0.016, frame_index))
```

この System は `Transform3D` と `ChildOf` を読み、`GlobalTransform` を書きます。`GlobalTransform` は GPU-visible component なので、内部で dirty 記録も行います。

## Conflict 検査

`System::conflicts_with` と `Schedule::has_parallel_access_conflicts` は、将来の並列 batching 用の境界です。`Schedule::run` 自体はまだ単一スレッドで登録順に実行します。

同一 phase 内では、次の関係を conflict とみなします。

- write / write
- write / read
- read / write
- どちらかの System が `structural_write=true`

`structural_write` は entity/archetype の集合や配置を変える可能性があるため、同一 phase の他 System とは保守的に衝突扱いにします。

## Resource / Context

core ECS では、汎用 heterogeneous `Resources` map は持ちません。時間や frame index は `SystemContext` に限定しています。

WebGPU buffer や renderer object は `rhodonite_core/ecs` ではなく、`rhodonite_examples` や renderer 側に置く方がモジュール境界に合います。

アプリケーション層では、必要なら次のような所有構造にできます。

```moonbit
pub struct App {
  world : World
  schedule : Schedule
  // renderer や入力状態は core ECS の外側で持つ。
}
```

## まだ残る課題

- typed component wrapper や GPU row wrapper による、component kind / dirty 操作の型上の明確化。
- `CreateEntity` command、または予約 `EntityId` を返す spawn API。
- read/write/structural access に基づく実際の System batch 分割と並列実行。
- GPU dirty tracking の thread-local 化と merge。
- query plan cache、archetype index cache、required component column index cache。

## 避ける方針

- `World` に System list を持たせない。
- Query callback 中に archetype 構造変更を直接許可しない。
- read/write 宣言だけで GPU-visible component を自動 dirty にしない。
- 最初から並列 System 実行を実装しない。
- 汎用 ResourceMap を core ECS に入れない。
- renderer や GPU buffer handle を `rhodonite_core/ecs` に持ち込まない。

## まとめ

この ECS の強みは、CPU 側の archetype SoA と、GPU 側の `EntityId.index` ベース flat storage が明確に分離されている点です。

`System` はこの構造を置き換えるものではなく、既存の `World` 操作をフレーム順に整理する層です。現行実装では、外付け `Schedule`、関数型 `System`、`CommandBuffer`、access guard により、低レベル API を保ちながら System ベースの更新順序を扱えるようにしています。
