# Rhodonite Core ECS 設計課題メモ

このメモは [`ecs_ja.md`](ecs_ja.md) と [`moon/rhodonite_core/src/ecs/`](../moon/rhodonite_core/src/ecs/) の現行実装を読んだ上で、設計上の問題点と今後の課題を整理したものです。

特に `World::for_each_entity_with_components` が内部 payload を `MutArrayView[Byte]` として返す設計について、利点、欠点、マルチスレッド化への影響を中心に扱います。

## 結論

現行 ECS は、単一スレッドで低レベルに高速な SoA / GPU flat storage を操作する実装としては筋が通っています。一方で、現在の公開 API は内部の可変バイト列を直接触らせるため、将来の System 化やマルチスレッド実行ではそのまま障害になります。

最も大きい課題は次の 4 点です。

- `MutArrayView[Byte]` が内部 storage の可変参照を直接公開しており、借用範囲や排他性を型としては表現できていない。
- `for_each_entity_with_components` の callback 中の構造変更は `query_depth` guard で実行時に禁止している。現行実装では最小の `CommandBuffer` を追加済みで、query / system 後に遅延適用できる。
- `GpuVisible` component を `MutArrayView[Byte]` 経由で変更しても dirty が自動記録されず、呼び忘れで GPU upload が欠落する。
- `World` 全体が `Array` ベースの可変所有物で、query borrow を型で表す境界はまだない。現行実装では、まず `System::reads` / `writes` と同一 phase 内の conflict 検査 API を追加済み。

したがって、`MutArrayView[Byte]` 自体は「低レベル backend API」として残せますが、将来の並列 System API の主インターフェースにするのは避けた方がよいです。

## 現行設計の良い点

### CPU SoA と GPU flat storage の分離

`CpuOnly` component は archetype ごとの SoA column に置かれ、`GpuVisible` component は `EntityId.index * stride` で引ける flat `GpuComponentStore` に置かれます。この分離は WebGPU 向けには有効です。

利点:

- archetype 移行で CPU row が swap-remove されても、GPU 側の論理 index が変わらない。
- shader / storage buffer 側で `EntityId.index` を配列添字として使える。
- CPU 走査と GPU upload の責務が分かれている。
- `drain_gpu_writes` が dirty entity index を連続 range にまとめられる。

この構造自体は維持する価値があります。

### `MutArrayView[Byte]` によるゼロコピー row access

`Archetype::component_byte_mut_view` は `ComponentColumn::bytes` の row 範囲を `MutArrayView[Byte]` として返します。`GpuVisible` の場合も `GpuComponentStore.bytes` の entity slot を直接 view にします。

利点:

- `FixedArray[Byte]` へのコピーなしで component row を読める、書ける。
- `Transform3D::from_component_mut_view` や `GlobalTransform::view_std140_gpu_row` のように、バイト列の上に typed view を被せられる。
- CPU SoA と GPU row を同じ callback payload として扱える。
- component 型ごとの generic / reflection が薄い MoonBit 環境でも、低レベル API を少ない型で表現できる。

現在の `update_global_transforms_from_transforms` はこの利点を活かして、`Transform3D` の SoA row を読み、`GlobalTransform` の GPU row へ直接書いています。

## `MutArrayView[Byte]` 公開の問題点

### 1. 型安全性が弱い

payload は `Array[MutArrayView[Byte]]` で、どの view がどの component かは `required` の順序に依存します。

問題:

- `payloads[0]` / `payloads[1]` の取り違えを型で防げない。
- stride や layout の意味を callback 側が知っている必要がある。
- `CpuOnly` と `GpuVisible` が同じ `MutArrayView[Byte]` で見えるため、dirty 必要性や storage の違いが型に出ない。
- `Transform3D` などの typed view がバイト列に別解釈を与えるだけなので、不正な component id との組み合わせを防ぎにくい。

低レベル API としては許容できますが、アプリケーション System が常用する API としては事故の余地が大きいです。

### 2. 内部 storage の可変参照が callback 外へ逃げる可能性

`for_each_entity_with_components` は view を作って callback に渡しますが、API 上は callback が view を保存しない保証を表現していません。

`MutArrayView` が実際にどこまでコンパイラに制約されるかに依存しますが、設計上は少なくとも次の前提を利用者に要求しています。

- callback 中だけ使う。
- `World` の構造変更後に古い view を使わない。
- 同じ storage に対する別 view と同時に競合書き込みしない。

このようなライフタイム制約は、ドキュメントだけでは将来の大規模利用時に破れやすいです。

### 3. Query 中の構造変更は guard 済みで、最小の遅延変更 API も追加済み

`for_each_entity_with_components` は `self.archetypes` と `arch.entities` を直接走査します。以前は callback に `World` を閉じ込めることで、callback 内から次のような操作を呼べました。

- `add_component_bytes`
- `remove_component`
- `destroy_entity`
- `create_entity`
- `register_cpu_component` / `register_gpu_component`
- `set_gpu_component_bytes` / `clear_gpu_component`

これらは archetype の追加、row の追加、swap-remove、location 更新、GPU store resize を起こします。走査中に同じ archetype を変更すると、次の問題が起こりえます。

- 現在の row view が指す byte range と entity location がずれる。
- swap-remove により未走査 entity が移動し、スキップまたは重複処理される。
- `arch.entities.length()` が走査中に変わる。
- 新 archetype が追加され、同じ query 実行中に対象集合が変わる。
- view 作成後に backing array が伸び、view の妥当性が不明になる。

現行実装では、`World` に `query_depth` を持たせ、query 実行中に構造変更系 API が呼ばれた場合は `abort` します。これにより、低レベル query API のままでも row view と entity location の破壊は実行時に防げます。

ただし、これは「禁止」の仕組みであり、System から構造変更を安全に要求する仕組みではありませんでした。現行実装では `CommandBuffer` を追加済みで、`destroy`、`add/remove component`、`set/clear GPU component` を query / system 後に適用できます。`CreateEntity` command はまだ含めず、query 走査外では `World::create_entity` を直接使う方針です。

### 4. GPU dirty 管理が手動で漏れやすい

`GpuComponentStore::set_bytes` や `mut_entity_row` は `mark_dirty` します。一方で `for_each_entity_with_components` が返す `GpuVisible` の `MutArrayView[Byte]` を直接書き換えた場合は、自動 dirty になりません。

現行実装では `update_global_transforms_from_transforms` が `GlobalTransform` row を書いた後に `World::mark_gpu_component_dirty` を明示的に呼んでいます。この呼び忘れはコンパイル時にも実行時にも検出されません。

影響:

- CPU 側の bytes は更新済みなのに、`drain_gpu_writes` が空になる。
- GPU buffer だけ古い値のままになる。
- dirty 漏れは見た目の描画バグとして現れ、原因追跡が難しい。

対策候補:

- 低レベル API は残しつつ、通常利用向けに `for_each_*_marking_gpu_dirty` のような helper を追加する。
- `GpuVisible` payload だけ `GpuRowMut` のような wrapper にし、`write` API 経由で dirty を立てる。
- System API では `writes` に宣言した GPU component を callback 後に dirty 化する option を提供する。

ただし、自動 dirty は「実際には変更していない entity」まで upload 対象にしやすいため、低レベル最適化 APIと安全 APIを分けるのがよいです。

## マルチスレッド化への影響

### 現状のままでは並列 System 実行は難しい

現在の `World` は内部に複数の可変 `Array` を持つ単一の mutable object です。`for_each_entity_with_components` も `self : World` を受け取り、内部 storage の `MutArrayView[Byte]` を callback に渡します。

この形では、複数 System を別スレッドで同時に走らせると次の競合が起こります。

- 同じ component column への同時書き込み。
- 片方が query 走査中に、もう片方が entity / archetype を構造変更する。
- GPU store bytes / dirty_flags / dirty_indices への同時書き込み。
- `resize_events` への同時 push。
- `generations` / `alive` / `locations` / `free_indices` の同時更新。

`MutArrayView[Byte]` は「ここを書ける」という能力を直接渡すため、スケジューラが排他制御を行う前提がないと data race を防げません。

### 障害になるのは `MutArrayView` そのものより、借用境界がないこと

`MutArrayView[Byte]` は、単一 archetype の disjoint row range を worker に分けるような用途では有効です。例えば同じ component column でも、row 0..999 と row 1000..1999 のように非重複 range に分割できれば、並列処理の実装材料にはなります。

問題は、現行 API がその分割と排他性を表現していないことです。

必要な境界:

- Query 実行中は構造変更しない。現行実装では `query_depth` guard で単一スレッド内の誤用を検出する。
- System ごとに read component / write component を宣言する。現行実装では `System::reads` / `writes` を追加済み。
- 同じ component への write が重なる System は同時実行しない。現行実装では `System::conflicts_with` と `Schedule::has_parallel_access_conflicts` で、同一 phase 内の write/write、write/read、read/write 衝突を検査できる。
- `GpuVisible` dirty tracking は thread-local に集めて後で merge する。
- archetype ごと、または row chunk ごとに disjoint な mutable slice を切って worker に渡す。

これらを導入すれば、内部実装で `MutArrayView[Byte]` を使うこと自体は可能です。ただし公開 System API で生の `MutArrayView[Byte]` を広く露出すると、スケジューラの保証を利用者コードが簡単に破れてしまいます。

### 推奨する並列化の段階

1. まず単一スレッドの `Schedule` と `CommandBuffer` を導入する。
2. System に `reads` / `writes` component set を持たせる。現行実装では追加済み。
3. Query callback 中の構造変更禁止は現行の `query_depth` guard を前提にし、System では `CommandBuffer` 経由に寄せる。
4. `for_each_entity_with_components` を低レベル API と位置付け、System 用の wrapper を追加する。
5. `query_depth` guard では表現できない read/write 排他性を System 側の宣言で検査する。現行実装では同一 phase 内の conflict helper を追加済み。
6. dirty tracking を per-thread buffer に分離し、System 終了時に `GpuComponentStore` へ merge する。
7. 最後に read/write set が衝突しない System だけ並列実行する。

この順序なら、現行設計を壊しすぎずに安全性を足せます。

## その他の設計課題

### Component 登録後の既存 archetype 対応

`register_cpu_component` / `register_gpu_component` は registry と `gpu_stores` に slot を追加します。既存 archetype は新 component を含まないため即時問題にはなりませんが、実行中に登録できる設計は System スケジューリングと相性が悪いです。

現行実装では `World::component_registration_locked` を追加済みです。`Schedule::run` は system 実行中だけ world の component 登録を内部的にロックし、その間の `register_cpu_component` / `register_gpu_component` は abort します。run が戻る前に登録ロックは解除されるため、schedule 実行と実行の間では新しい component type を登録できます。

残る推奨:

- component 登録は active な schedule 実行の外で行う。
- 既存 system が新 component を読む/書く必要がある場合は、その component 登録後に該当 system を追加または作り直す。

### Archetype 検索と component 検索が線形

`find_archetype` は全 archetype を線形探索し、`component_array_contains_all` や `column_index` も線形探索です。小規模なら問題ありませんが、component 種類や archetype 数が増えると query overhead が増えます。

将来候補:

- signature key から archetype index への map。
- component id の sorted list に対する二分探索。
- query plan cache。
- archetype ごとの required component column index cache。

ただし、現時点では安全性・構造変更ルールの整理の方が優先度は高いです。

### `required` の重複・順序の扱い

`required` は `Array[ComponentTypeId]` のため、未ソートを許します。未ソートは payload 順序として意味があります。

重複 component については、現行実装の `for_each_entity_with_components` が duplicate required を検出して `abort` します。同じ component view を同一 callback に複数渡す意味が曖昧で、mutable view の排他性も弱くなるためです。

残る推奨:

- System 用 Query builder では重複を作れないようにする。

### `GpuVisible` component の archetype 上の存在表現

`GpuVisible` は archetype signature には含まれますが、archetype column stride は `0` です。このため、「component を持つかどうか」と「payload はどこにあるか」が分離しています。

これは GPU index 安定性のためには良い設計ですが、利用者には分かりにくいです。`component_bytes` は CPU column だけを読む API なので、`GpuVisible` には `gpu_component_bytes` を使う必要があります。

推奨:

- API 名で CPU / GPU をより明確に分ける。
- Query payload wrapper に `CpuRow` / `GpuRow` の区別を持たせる。

### EntityId.index の安定利用と世代再利用

`EntityId.index` を GPU index として使うため、destroy 時に GPU slot を zero clear して dirty にしています。この方針は妥当ですが、index 再利用により外部システムが古い index だけを保持していると別 entity を参照します。

推奨:

- 外部 API では `EntityId` 全体を保持し、index 単体の保持を避ける。
- shader 側に index だけを渡す場合は、CPU 側で alive / generation を検証済みの draw list を作る。

## 推奨方針

### 短期

- `for_each_entity_with_components` を「低レベル、単一スレッド、構造変更禁止」の API と明記する。現行実装ではコメントと `query_depth` guard で対応済み。
- Query callback 中の `add/remove/destroy/register` などを禁止事項として docs に追記する。現行実装では `create_entity`、`destroy_entity`、`add_component_bytes`、`remove_component`、component 登録、`set_gpu_component_bytes`、`clear_gpu_component` を guard 済み。
- `GpuVisible` view を書いたら `mark_gpu_component_dirty` が必要なことを、API 名や helper で目立たせる。
  - 現行実装では `World::for_each_entity_with_components_marking_gpu_dirty` を追加済み。callback が呼ばれた entity について、指定した GPU-visible component を callback 後に dirty 化する。
- `required` の重複検査を追加する。現行実装では duplicate required を `abort` 済み。

### 中期

- `Schedule` / `System` / `CommandBuffer` を導入する。現行実装では、単一スレッドで phase 順に実行する最小の `Schedule` / `System` を追加済み。
- 現行実装では、まず最小の `CommandBuffer` を追加済み。query 中に積んだ `destroy`、`add/remove component`、`set/clear GPU component` を query 後に適用できる。
- System は read/write component set を宣言する。
- Schedule 実行中だけ component 登録をロックする。現行実装では `Schedule::run` が内部ロックを開始・解除する。
- System 用 Query wrapper を作り、通常は typed wrapper または role 付き payload を使う。現行実装では、まず薄い `Query` helper を追加済み。
- `query_depth` guard を前提に、構造変更を `CommandBuffer` へ集約する。

### 長期

- read/write set に基づく System conflict 検査は、同一 phase 内の並列実行可否を判定する helper として追加済み。次の課題は、この結果を使った実際の batch 分割や並列実行。
- archetype / row chunk 単位の並列 query を設計する。
- GPU dirty tracking を thread-local に分けて merge する。
- query plan cache と archetype index cache を追加する。

## まとめ

`for_each_entity_with_components` が `MutArrayView[Byte]` を返す設計は、現行の ECS が目指す低レベル・ゼロコピー・WebGPU 連携には合っています。特に `Transform3D` から `GlobalTransform` を更新するような内部処理では、余計なコピーや型階層なしに効率よく動きます。

一方で、この API は内部可変 storage への直接アクセスを公開するため、System の安全な実行順序、構造変更の遅延、GPU dirty 管理、並列実行の排他制御をすべて利用者側の規律に依存します。

将来マルチスレッド対応を考えるなら、`MutArrayView[Byte]` を廃止する必要はありません。ただし、公開の高レベル System API では生の view を直接渡す範囲を狭め、`Schedule`、`CommandBuffer`、read/write 宣言、query guard、dirty merge のような実行境界を先に設計する必要があります。
