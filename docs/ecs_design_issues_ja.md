# ECS Design Notes

この文書は現行 ECS の設計上の注意点をまとめます。現在の ECS component storage は CPU-only の archetype SoA に統一されています。renderer upload 用の bytes は arbitrary component storage ではなく、builtin `GlobalTransform` / `Camera` の packed blob store が扱います。

## 残っている設計上の論点

### Query view の lifetime

`QueryRow::read` / `write` と `RawQueryRow::read_view` / `write_view` は closure-scoped view を返します。view を外へ逃がさない API 形状にしているため、将来の System 実行順や並列化に向けて最低限の境界は保っています。

ただし `RawQueryArchetype::write_column` は archetype column 全体を mutable view として貸し出す expert API です。callback 中の構造変更は `World::assert_not_querying` で拒否されますが、利用側は同じ component の別 mutable view を同時に作らないように query required set の duplicate check に依存します。

### SystemRunner access declaration

現行実装は single-thread 実行ですが、`System` は `reads` / `writes` / `structural_write` を宣言します。この宣言は system runner 実行中の API guard と conflict detection に使います。

- `writes` は同じ component の read も許可します。
- entity/archetype 構造を変える API は `structural_write` を要求します。
- `CommandBuffer` は queue 時点で component write と structural write を検証します。
- component 登録は system runner 実行中に lock されます。

### Builtin packed blob

`GlobalTransform` と `Camera` は CPU ref component と packed GPU blob の二層構造です。SoA row は renderer extraction 用の小さな ref だけを持ち、実 matrix payload は blob 側で resize/write event を管理します。

`GpuWriteView` は blob backing storage を借用するため、同じ blob を次に mutate / resize する前に upload する前提です。owned copy が必要な経路を増やす場合は、copy API を明示的な名前で追加してください。

### API cleanup status

汎用 GPU component storage は削除済みです。以下の責務は残していません。

- arbitrary component の GPU upload queue
- entity index 固定の component payload storage
- component kind 分岐
- component ごとの active index set

今後 GPU 向けデータを追加する場合は、まず builtin blob と同じ dedicated store にするか、CPU SoA から renderer extraction で明示的に pack する方針を検討してください。

## Test Focus

継続して確認するポイント:

- archetype move 時の CPU column copy
- query / raw query の row and column view
- system runner access guard と `CommandBuffer`
- `GlobalTransform` / `Camera` blob の allocation、resize event、write drain
- TypeScript wrapper の ByteView と builtin blob upload helper
