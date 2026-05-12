# Rhodonite Core ECS System 設計案

[`moon/rhodonite_core/src/ecs/`](../moon/rhodonite_core/src/ecs/) の現在の ECS は、`World` がエンティティ、アーキタイプ SoA、GPU-visible flat store を所有し、更新処理は `World::for_each_entity_with_components` とビルトインヘルパで行う構成です。

この設計に `System` を追加する場合は、`World` に System 管理を埋め込むよりも、`World` の外側に薄い `Schedule` 層を追加する方針が適しています。

## 結論

推奨する最初の形は **外付け `Schedule` + 関数型 `System` + deferred `CommandBuffer`** です。

- `World` はデータ所有者に留める。
- `Schedule` が System の順序実行を担当する。
- System 内の構造変更は `CommandBuffer` に積み、走査後に適用する。
- GPU-visible component の dirty 管理は、既存の `World::mark_gpu_component_dirty` を明示的に呼ぶ方針を維持する。

この形なら、既存 API を壊さず、現在の `World::update_global_transforms_from_transforms` もそのまま System 化できます。

## 現状の前提

現在の ECS では、主な責務が次のように分かれています。

| 領域 | 現在の実装 |
|------|------------|
| エンティティ管理 | `World` の `generations` / `alive` / `free_indices` |
| 位置管理 | `EntityId.index` から `EntityLocation?` |
| CPU component | アーキタイプごとの SoA column |
| GPU-visible component | `EntityId.index * stride` で引ける flat `GpuComponentStore` |
| クエリ | `World::for_each_entity_with_components`（query 中の構造変更は `query_depth` guard で abort） |
| GPU upload | `drain_gpu_writes` / `drain_resize_events` |
| Transform 更新 | `World::update_global_transforms_from_transforms` |

現行実装には、外付けの `Schedule`、関数型 `System`、`CommandBuffer`、薄い `Query` helper があります。アプリケーション側は `World` の低レベル API を直接使うことも、`Schedule` に system を登録して順序実行することもできます。

## 推奨する型

最小の `System` は、名前、phase、read/write component、実行関数を持つ構造体にします。

```moonbit
pub(all) struct SystemContext {
  delta_seconds : Float
  frame_index : Int
}

pub(all) enum SystemPhase {
  PreUpdate
  Update
  PostUpdate
  PreRender
  RenderExtract
}

pub(all) struct System {
  name : String
  phase : SystemPhase
  reads : Array[ComponentTypeId]
  writes : Array[ComponentTypeId]
  run : (World, SystemContext, CommandBuffer) -> Unit
}
```

`Schedule` はまず単純な phase 順、登録順の実行で十分です。

```moonbit
pub struct Schedule {
  systems : Array[System]
}

pub fn Schedule::run(
  self : Schedule,
  world : World,
  ctx : SystemContext,
) -> Unit {
  // phase 順、同一 phase 内は登録順で実行する。
}
```

最初から並列実行や依存グラフ解決を入れない方が安全です。現状の `World` は内部配列を可変に持ち、クエリは `MutArrayView[Byte]` を返すため、並列実行の安全性を型だけで担保しにくいためです。

## `World` に System を持たせない

`World` に `systems : Array[System]` を追加する設計は避けます。

`World` はすでに次を所有しています。

- Entity slot と generation
- `EntityId.index` から archetype row への location
- Archetype SoA tables
- GPU-visible flat stores
- GPU resize events
- Builtin component ids

ここに System 登録、phase、依存関係、renderer 連携まで持たせると、`World` がアプリケーションフレームワーク化します。

推奨する責務分離は次です。

| 型 | 責務 |
|----|------|
| `World` | ECS データ所有と低レベル操作 |
| `Schedule` | System の実行順序 |
| `CommandBuffer` | System 実行中の構造変更の遅延適用 |
| renderer 側 | GPU buffer 作成、resize event 処理、write upload |

## CommandBuffer

`for_each_entity_with_components` の callback 中に、`add_component_bytes`、`remove_component`、`destroy_entity` などを直接呼ぶ設計は避けるべきです。

理由は、現在のアーキタイプ走査が `archetypes` と `entities` を直接走査しており、走査中の構造変更で次が起きるためです。

- Entity row の swap-remove
- moved entity の location 更新
- Entity の archetype 移行
- 新しい archetype の追加

現行実装では、query 実行中に構造変更系 API を呼ぶと `query_depth` guard により `abort` します。対象は `create_entity`、`destroy_entity`、`add_component_bytes`、`remove_component`、component 登録、`set_gpu_component_bytes`、`clear_gpu_component` です。

そのため、System 内の構造変更は `CommandBuffer` に積み、System 実行後に適用します。これは guard を回避するためではなく、System から構造変更を安全に表現するための API 層です。

```moonbit
pub struct CommandBuffer {
  commands : Array[WorldCommand]
}

pub(all) enum WorldCommand {
  DestroyEntity(EntityId)
  AddComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  RemoveComponent(EntityId, ComponentTypeId)
  SetGpuComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
}
```

`CreateEntity` は、生成された `EntityId` を同じ System 内ですぐ使いたい要求が出やすいため、query 走査外では `World::create_entity` を直接使えます。query 走査中に生成したい場合は、次のような callback 付き command が候補になります。

```moonbit
pub(all) enum WorldCommand {
  CreateEntity((EntityId) -> Unit)
  // ...
}
```

ただし、callback 付き command は設計が複雑になりやすいので、初期実装では次の方針が現実的です。

- Query 走査中の archetype 構造変更は禁止する。現行実装では `query_depth` guard 済み。
- System の外側、または Query 走査前後では `World::create_entity` を直接使ってよい。
- 必要になった段階で `CommandBuffer` の create API を拡張する。

Command の apply タイミングは、最初は **各 System の終了時** が扱いやすいです。前の System が作った変更を次の System が見られるため、挙動が直感的になります。

## Query helper

低レベル API として `World::for_each_entity_with_components` は残すべきです。これは CPU SoA と GPU-visible flat store の両方を `MutArrayView[Byte]` として扱える、現在の ECS の中核 API です。

現行実装では `required` に同じ `ComponentTypeId` を重複指定すると abort します。同じ mutable component view を複数 payload として渡す意味が曖昧なためです。

一方で System からは、薄い `Query` helper があると書きやすくなります。Query helper は重複 `required` を作れないようにするか、構築時に検査するのがよいです。

```moonbit
pub(all) struct Query {
  required : Array[ComponentTypeId]
}

pub fn Query::for_each(
  self : Query,
  world : World,
  f : (QueryRow) -> Unit,
) -> Unit {
  world.for_each_entity_with_components(self.required, fn(e, _sig, views) {
    f({ world, entity: e, components: self.required, payloads: views })
  })
}
```

現行実装では `Query::for_each` は `QueryRow` を渡し、`row.view(component)` で `CpuOnly` なら SoA row、`GpuVisible` なら GPU flat row の `MutArrayView[Byte]` を返します。`full_signature` が必要な System もあるため、`for_each_entity_with_components` を隠蔽しきらない方がよいです。

## GPU-visible component の dirty 管理

System が `GpuVisible` payload を直接変更する場合、現在と同じく `World::mark_gpu_component_dirty` を呼ぶ必要があります。

```moonbit
let query = Query::new([tf, gt])
query.for_each(world, fn(row) {
  // row.view(gt) は GlobalTransform の flat GPU row。
  // 書き換えた場合は dirty にする。
  let _ = row.mark_dirty(gt)
})
```

`Schedule` が `writes` を見て自動 dirty 化する案もありますが、これは推奨しません。System が対象 component を `writes` に宣言していても、実際には一部の entity だけ変更する場合があるためです。

自動 dirty 化すると、不要な GPU write 範囲が増えます。現在の `GpuComponentStore` は dirty entity index を集めて連続範囲に merge する設計なので、実際に変更した entity だけを明示的に dirty にする方が合っています。

必要なら、補助 API として次のような関数を追加できます。

```moonbit
pub fn World::for_each_entity_with_components_marking_gpu_dirty(
  self : World,
  required : Array[ComponentTypeId],
  dirty_gpu_components : Array[ComponentTypeId],
  f : (EntityId, Array[ComponentTypeId], Array[MutArrayView[Byte]]) -> Unit,
) -> Unit
```

ただし、この API も「callback が呼ばれた entity は必ず dirty」とするため、変更の有無を System 側が判断したい場合には過剰です。

## Builtin Transform System

現在の `World::update_global_transforms_from_transforms` は、最初に System 化する対象として適しています。

現行実装では既存 API は残したまま、`transform_propagation_system(world)` factory を追加済みです。

```moonbit
let schedule = Schedule::new()
schedule.add_system(transform_propagation_system(world))
let _ = schedule.run(world, SystemContext::new(0.016, frame_index))
```

現行実装では、`reads` / `writes` は構築時に重複検査され、`System::conflicts_with` と `Schedule::has_parallel_access_conflicts` で同一 phase 内の read/write 衝突を検査できます。これは将来の並列 batching 用の境界であり、`Schedule::run` はまだ単一スレッドで登録順に実行します。

`Schedule::run` は system 実行中だけ component 登録を閉じ、return 前に再び開きます。これにより、system 実行中に registry と system の read/write 宣言がずれることを防ぎつつ、schedule 実行と実行の間では新しい component type を登録できます。

## Resource / Context

System を導入すると、時間、入力、レンダラ、GPU buffer handle などをどこに置くかが問題になります。

core ECS では、最初から汎用の heterogeneous `Resources` map を作るより、用途を限定した context を推奨します。

```moonbit
pub(all) struct SystemContext {
  delta_seconds : Float
  frame_index : Int
}
```

WebGPU buffer や renderer object は `rhodonite_core/ecs` ではなく、`rhodonite_examples` や renderer 側に置く方がモジュール境界に合います。

アプリケーション層では、必要なら次のような所有構造にできます。

```moonbit
pub struct App {
  world : World
  schedule : Schedule
  // renderer や入力状態は core ECS の外側で持つ。
}
```

## 段階的な導入案

1. `SystemContext`、`SystemPhase`、`System`、`Schedule` を定義する。現行実装では `schedule.mbt` / `types.mbt` に追加済み。
2. `Schedule::add_system` と `Schedule::run` を実装する。現行実装では単一スレッド・phase 順・登録順で実行済み。
3. `World::update_global_transforms_from_transforms` は残したまま、同等の builtin System factory を追加する。現行実装では `transform_propagation_system(world)` を追加済み。
4. `CommandBuffer` を追加し、System 内、特に query callback 内の構造変更要求は command 経由にする。現行実装では `destroy`、`add/remove component`、`set/clear GPU component` を追加済み。
5. 必要に応じて `Query` helper を追加する。現行実装では `Query::new`、`for_each`、`for_each_marking_gpu_dirty` を追加済み。
6. `reads` / `writes` の conflict 検査を追加する。現行実装では `System::conflicts_with` と `Schedule::has_parallel_access_conflicts` を追加済み。
7. Schedule 実行中だけ component 登録をロックする。現行実装では `Schedule::run` が内部ロックを開始・解除する。
8. 並列実行、before/after 依存関係、System batch 分割は最後に検討する。

## 避けたい初期実装

初期段階では、次の機能は入れない方がよいです。

- `World` に System list を持たせる。
- Query callback 中に archetype 構造変更を直接許可する。現行の `query_depth` guard は維持する。
- read/write 宣言だけで GPU-visible component を自動 dirty にする。
- 最初から並列 System 実行を実装する。
- 汎用 ResourceMap を core ECS に入れる。
- renderer や GPU buffer handle を `rhodonite_core/ecs` に持ち込む。

## まとめ

この ECS の強みは、CPU 側のアーキタイプ SoA と、GPU 側の `EntityId.index` ベース flat storage が明確に分離されている点です。

`System` はこの構造を置き換えるものではなく、既存の `World` 操作をフレーム順に整理する層として追加するのが良いです。

最初の実装は、外付け `Schedule`、関数型 `System`、deferred `CommandBuffer` に留めるのが最も安全です。これにより、既存の低レベル API を保ちながら、アプリケーション側では System ベースの更新順序を扱えるようになります。
