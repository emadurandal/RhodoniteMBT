# Rhodonite Core ECS System 設計

[`moon/rhodonite_core/src/ecs/`](../moon/rhodonite_core/src/ecs/) の ECS は、`World` がエンティティ、アーキタイプ SoA、GPU-visible flat store を所有し、`Schedule` / `System` / `CommandBuffer` が更新順序と遅延変更を扱います。

この文書は、かつての System 導入案ではなく、現行実装を正とした設計メモです。行イテレーションは高級 API の `Query` と低級 API の `RawQuery` に分かれ、アプリケーション側の更新処理は外付け `Schedule` に System を登録して実行できます。

## 結論

現行方針は **外付け `Schedule` + 関数型 `System` + deferred `CommandBuffer`** です。

- `World` は ECS データ所有と低レベル操作に留める。
- `Schedule` が phase 順、同一 phase 内は登録順で System を実行する。
- System は `reads` / `writes` / `structural_write` を宣言する。
- System 内の query callback 中に直接構造変更せず、必要な変更は `CommandBuffer` に積む。
- GPU-visible component を直接書いた場合は、`QueryRow::write` / `RawQueryRow::write_view` / `set_component_bytes` / builtin bulk path が dirty を記録する。bulk path では連続 dirty range を直接記録できる。

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
| `QueryRow::read` / `RawQueryRow::read_view` | `reads` または `writes` |
| `QueryRow::write` / `RawQueryRow::write_view` | `writes` |
| `set_component_bytes` / `clear_gpu_component` | `writes` |
| `drain_gpu_writes` | `writes` |
| `drain_gpu_write_views` | `writes` |
| `drain_global_transform_blob_write_views` | `writes` |
| `drain_global_transform_blob_resize_events` | `structural_write` |
| `gpu_component_active_indices` | `reads` または `writes` |
| `drain_resize_events` | `structural_write` |
| `add_component` / `add_component_bytes` / `remove_component` | `writes` + `structural_write` |
| `create_entity` / `destroy_entity` | `structural_write` |

`component_bytes` / `set_component_bytes` は CPU-only / GPU-visible の両方を registry kind に応じて扱います。CPU-only は archetype SoA row、GPU-visible は `EntityId.index` ベースの flat GPU row を読み書きします。`set_component_bytes` は既存 payload 更新だけを行い、archetype 構造を変えません。byte length が登録済み stride と一致しない場合は `false` を返します。

component 所有の追加は `add_component` または `add_component_bytes` を使います。どちらも registry kind に応じて CPU-only / GPU-visible の両方を扱います。`add_component` は CPU component なら zero bytes で SoA row を初期化し、GPU-visible component なら ownership marker を追加して GPU slot を zero clear します。`add_component_bytes` は CPU component なら SoA row、GPU-visible component なら flat GPU row を指定 bytes で初期化します。`remove_component` と各 add API は archetype 移動を起こすため、component `writes` だけでなく `structural_write` も要求します。`GpuVisible` component を `remove_component` で外す場合は、所有解除と同時に対象 entity の flat GPU slot を zero clear し、その row を dirty にします。

GPU-visible component に対する `component_bytes` / `set_component_bytes` / `clear_gpu_component` は、entity が対象 component を archetype signature 上で持っている場合だけ操作できます。GPU store の slot は `EntityId.index` で引けますが、component 所有の有無は archetype signature を正とします。`add_component*` は同時に packed active index set へ entity index を追加し、`remove_component` / `destroy_entity` は zero clear 後に active set から外します。`World::gpu_component_active_indices` はこの packed set のコピーを返す read API です。`remove_component` 後は ownership が消えるため `component_bytes` は `None` になり、GPU 側には zero clear された dirty row が残ります。

GPU store の capacity 拡張と `GpuResizeEvent` 発行は `World` 内部の共通経路に集約しています。`add_component`、`add_component_bytes`、`set_component_bytes`、`clear_gpu_component`、query の GPU row access は同じ resize event 生成規則に従います。JS / 非 JS とも capacity は幾何級数的に伸び、JS は `Uint8Array`、非 JS は MoonBit の byte array を使います。builtin `GlobalTransform` は例外で、GPU-visible store ではなく packed u32 blob 専用の resize/write event queue を使います。

`drain_resize_events` は World が所有する resize event queue を消費します。Schedule 実行中に呼ぶ場合は、event queue に対する構造的 access として `structural_write` が必要です。Schedule 外では従来通り呼べます。

builtin convenience API も同じ access guard に従います。`get_transform` / `get_child_of` / `get_global_transform` は各 component の read を要求し、`set_transform` / `set_child_of` / `set_global_transform` は write を要求します。`compute_global_transform` は階層を扱う API として `Transform3D` と `ChildOf` の read を保守的に要求し、`update_global_transforms_from_transforms` は `Transform3D` / `ChildOf` read と `GlobalTransform` write を要求します。

`destroy_entity` は GPU slot の clear などを伴いますが、entity lifetime の構造操作として扱います。並列化では `structural_write` を持つ System が同 phase の他 System と衝突扱いになるため、個別 GPU component の `writes` までは要求しません。

## Schedule

`Schedule` は `World` の外側にあります。`World` に System list は持たせません。

```moonbit
pub struct Schedule {
  systems : Array[System]
}
```

`Schedule::run` は単一スレッドで phase 順に実行します。同一 phase 内では、登録順を保ちながら conflict しない System を greedy に batch 化します。各 System には新しい `CommandBuffer` が渡され、同一 batch 内の全 System が戻った後、登録順で commands が適用されます。そのため、同一 batch 内の System は互いの command 結果を観測せず、後続 batch の System は前 batch の command 結果を観測できます。

Schedule 実行中は component 登録がロックされます。`register_cpu_component` / `register_gpu_component` は schedule 実行中に呼ばれると `abort` します。Schedule 実行と実行の間では、新しい component type を登録できます。

## CommandBuffer

`Query::for_each` の callback 中に、構造変更 API を直接呼ぶことはできません。`query_depth` guard により `abort` します。これは走査中の archetype row view と entity location を守るためです。

System から遅延適用したい変更は `CommandBuffer` に積みます。

```moonbit
pub(all) enum WorldCommand {
  CreateEntity(EntityId)
  DestroyEntity(EntityId)
  AddComponent(EntityId, ComponentTypeId)
  AddComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  SetComponentBytes(EntityId, ComponentTypeId, FixedArray[Byte])
  RemoveComponent(EntityId, ComponentTypeId)
  ClearGpuComponent(EntityId, ComponentTypeId)
}
```

`CommandBuffer` は `Schedule::run` が System ごとに作り、System callback に渡します。ユーザーが直接作成・適用する API ではありません。batch 内の全 System が戻った後、Schedule が System 登録順かつ各 buffer の insertion order で commands を適用します。失敗した command があれば `Schedule::run` は `false` を返しますが、後続 command の適用は続き、最後に buffer は空になります。component 追加は `CommandBuffer::add_component` または `CommandBuffer::add_component_bytes` を使えます。

`Schedule::run` が System に渡す `CommandBuffer` は、その System の `writes` / `structural_write` 宣言を snapshot として持ちます。`add_component` / `remove_component` / `destroy_entity` などは queue 時点で必要権限を検査し、権限が足りない場合は `abort` します。適用時の `World` 側 access guard も引き続き有効です。

`CommandBuffer::create_entity` は queue 時点で `EntityId` を予約して返し、`CreateEntity` command を積みます。予約 entity は apply されるまで `is_alive == false` ですが、同じ command buffer の後続 `add_component` / `add_component_bytes` の対象にできます。entity 作成 command は `structural_write` を要求します。`Schedule::run` の戻り値が `false` になっても、既に適用された command は巻き戻しません。

## Query

公開の row iteration API は `Query` です。`Query` は `QueryRow::read(component, f)` / `write(component, f)` で closure の中だけ row view を貸し出し、component ごとの access guard を維持します。component identity は `ComponentTypeId` だけで、typed component handle や codec object は追加しません。

`required` に同じ `ComponentTypeId` を重複指定すると `abort` します。同じ component row を複数 payload として扱う意味が曖昧なためです。

```moonbit
let query = Query::new([tf, gt])
query.for_each(world, fn(row) {
  row.read(tf, fn(tf_row) {
    row.write(gt, fn(gt_row) {
      // ...
      ignore(tf_row)
      ignore(gt_row)
    })
  })
})
```

`QueryRow::read(component, f)` は、`CpuOnly` なら archetype SoA row、`GpuVisible` なら `EntityId.index` ベースの flat GPU row を `ArrayView[Byte]` として closure に渡します。Schedule 実行中は、component が active system の `reads ∪ writes` に含まれる必要があります。読み取り専用経路は GPU store の capacity 拡張や dirty 記録を行いません。

`QueryRow::write(component, f)` は同じ payload を `MutArrayView[Byte]` として closure に渡します。Schedule 実行中は、component が active system の `writes` に含まれる必要があります。`GpuVisible` component の mutable view を要求した場合、その entity row は直ちに dirty になります。

CPU-only の bulk loop では `RawQuery::for_each_archetype` を使えます。query plan は world の component-to-archetype index を使って無関係な archetype を飛ばし、マッチした archetype ごとに required component の column index / stride を cache します。そのため、`RawQueryArchetype::read_column` / `write_column` は論理 row 範囲だけを連続 view として返し、呼び出しごとに列探索しません。GPU-visible component は flat store 上にあるため、archetype column view は提供しません。

row callback の形を保ちたい場合は、`Query::prepare` で得た `PreparedQuery::for_each` を使えます。raw row/chunk が必要な hot loop は `RawQuery::prepare` で得た `RawPreparedQuery` を使い、`world.archetype_version` が変わった場合だけ plan を作り直します。非 prepared の `Query::for_each` / `RawQuery::for_each` も同じ plan builder を使います。

## GPU-visible component の dirty 管理

System が `QueryRow::write` または `RawQueryRow::write_view` で `GpuVisible` payload の mutable view を取得した場合、その row は自動で dirty になります。これは「実際に bytes が変わった row」ではなく、「mutable view を要求した row」を upload 対象にする設計です。読み取りだけなら `QueryRow::read` / `RawQueryRow::read_view` を使うことで余分な dirty を避けられます。

```moonbit
let query = Query::new([tf, gt])
query.for_each(world, fn(row) {
  // GlobalTransform は packed blob 参照を持つ CPU row。
  // matrix payload は World::set_global_transform か propagation API で更新する。
  let local = row.read_transform3d().local_matrix()
  ignore(world.set_global_transform(row.entity(), local))
})
```

`Schedule` が `writes` を見て自動 dirty 化する設計は採っていません。`writes` は「書く可能性がある」宣言であり、実際にどの entity が変わったかまでは表さないためです。

builtin transform propagation のように連続 entity index をまとめて更新できる bulk path は、個別 dirty index ではなく dirty range を積めます。`drain_gpu_writes` は dirty range と個別 dirty index を統合し、重複 upload を避けながら owned bytes の `GpuWrite` を返します。即時 upload では `drain_gpu_write_views` が同じ dirty queue を消費し、JS / native とも `GpuComponentStore` の backing を `ArrayView[Byte]` として借用します。

即時 upload する renderer path では `World::drain_gpu_write_views` を使えます。これは同じ dirty queue を消費しますが、payload を `FixedArray[Byte]` にコピーせず、`GpuWriteView` として `ArrayView[Byte]` を返します。JS では `GPUQueue::write_buffer_from_array_view` が underlying `Uint8Array` と source offset / size を `GPUQueue.writeBuffer` に渡します。native でも同 helper が `ArrayView[Byte]` の backing bytes と source offset を `wgpuQueueWriteBuffer` に渡すため、view を新しい `Bytes` に compact しません。借用 view は `GpuComponentStore` の backing storage を指すため、同じ GPU component store を次に resize / mutate する前に upload まで使い切る前提です。

## Builtin Transform System

`World::update_global_transforms_from_transforms` は低レベル API として残っています。System として使う場合は `transform_propagation_system(world)` factory を使います。

```moonbit
let schedule = Schedule::new()
schedule.add_system(transform_propagation_system(world))
let ok = schedule.run(world, SystemContext::new(0.016, frame_index))
```

この System は `Transform3D` と `ChildOf` を読み、`GlobalTransform` を書きます。`GlobalTransform` は GPU-visible component なので、内部で dirty 記録も行います。

`World::update_transform3d_positions` は `Transform3D.position` 専用の bulk API です。JS では `RawQuery::for_each_archetype` による column path、非 JS では direct archetype sweep を使い、entity ごとの `QueryRow` 構築を避けます。

`World::update_global_transforms_from_transforms` は、`ChildOf` を持たない `[Transform3D, GlobalTransform]` archetype を fast path のまま処理し、`ChildOf` を含む archetype だけを階層対応 path に回します。これにより、scene の一部に親子関係がある場合でも、flat な大量 entity が階層 path へ巻き込まれません。階層 path の親 lookup は `ChildOf` column から直接読み、`get_child_of` 経由の component bytes copy を避けます。

大量生成では `World::spawn_transform_global_batch` を使うと、entity を最初から builtin `[Transform3D, GlobalTransform]` archetype に連続 append できます。callback には `Transform3D` の CPU row と `GlobalTransform` の 8 byte ref row が `MutArrayView[Byte]` として渡されます。`Transform3D` は `Transform3D::write_trs_to_component_mut_view` で直接初期化し、`GlobalTransform` の matrix payload は `World` が packed u32 blob に identity slot として確保します。この path は archetype migration と component-by-component add を避ける、builtin transform 専用の direct write API です。

任意の component signature には `World::spawn_batch(components, count, write)` を使えます。指定 signature の archetype に直接 append し、`SpawnBatchRow::write(component, f)` から CPU row / GPU row を初期化します。expert path には `write_view` もあります。`GpuVisible` component は entity index slot を active 化し、連続 index なら dirty range としてまとめて記録します。callback 中は row view を貸し出しているため、通常 query と同じく構造変更 API は拒否されます。

`GlobalTransform` の matrix payload は entity index dense row ではなく、world 所有の packed u32 blob に置きます。`GlobalTransform` component row は `{ format: u32, word_offset: u32 }` だけを持ち、renderer はこの 8 byte ref を instance buffer に複製します。payload は `Affine3x4F32` なら 12 words、`Affine3x4F16` なら 6 words です。shader は format tag で f32 load / `unpack2x16float` を分岐するため、精度差は draw 分割を要求しません。

更新 path は `set_global_transform`、`set_global_transform_format`、`update_global_transforms_from_transforms` が packed blob を dirty word range として記録し、即時 upload では `drain_global_transform_blob_write_views` + `GPUQueue::write_buffer_from_array_view` を使います。renderer が transform 計算を所有する hot path では `write_global_transform_blob_range_views(first_word, word_count, write)` が mutable blob range を貸し、callback 後に同じ range を dirty として返します。buffer capacity は `global_transform_blob_word_capacity() * 4` で確保し、`drain_global_transform_blob_resize_events` が growth を通知します。`World::new_with_global_transform_format(Affine3x4F16)` は world 全体の固定 layout ではなく、新規 slot の default format だけを指定します。

## Conflict 検査

`System::conflicts_with` と `Schedule::has_parallel_access_conflicts` は、batching 用の境界です。`Schedule::run` 自体はまだ単一スレッドですが、同一 phase 内ではこの conflict 判定に基づいて greedy batch を作ります。

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

- ユーザー定義 component 向けの typed row wrapper pattern。標準 component には `Transform3DRow` / `Transform3DMutRow` / `ChildOf` 系 wrapper と packed `GlobalTransform` API があるため、残る課題は custom component でも同じ書き味を作りやすくすること。
- 既存の conflict-free batch 分割を使った、実際の並列 System 実行。
- GPU dirty tracking の thread-local 化と merge。
- component-to-archetype index と signature cache は導入済み。残る課題は、query pattern ごとの長寿命 cache や、並列 chunk 分割と一体化した plan cache。
- native backend の汎用 `write_buffer_from_array_view` は `ArrayView[Byte]` を直接 lower-level queue binding に渡すため、任意の borrowed byte view upload でも `Bytes::from_array` の compact copy は発生しません。
- `moon/rhodonite_core/src/ecs_bench` と `pnpm run bench:ecs:*` による target 別回帰測定。

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
