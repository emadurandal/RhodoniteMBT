# RhodoniteMBT

MoonBit と WebGPU（ブラウザ・ネイティブ）を使ったグラフィクス関連コードのモノレポです。複数の MoonBit **モジュール**はルートの [`moon.work`](moon.work) でワークスペース化されています（[Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)）。

## モジュール構成

| モジュール | 説明 |
|------------|------|
| `emadurandal/rhodonite` | 公開用の薄い facade（[`moon/rhodonite`](moon/rhodonite)） |
| `emadurandal/rhodonite_binary` | バイナリ書き込みヘルパー |
| `emadurandal/rhodonite_math` | ベクトル・JS bridge |
| `emadurandal/rhodonite_webgpu` | WebGPU 抽象化 |
| `emadurandal/rhodonite_examples` | サンプル |

境界と publish の注意は [docs/module_boundaries.md](docs/module_boundaries.md) を参照。

## 開発（ワークスペース）

リポジトリルートで依存を更新し、全体をチェックする例:

```bash
moon update   # ネットワークが必要な場合があります
moon check --target all
moon fmt
moon info
```

[`justfile`](justfile) から `just check-ws` で `moon check --target all` を実行できます。

### Node・pnpm とワークスペースの出力

- ルート [`package.json`](package.json) に **`"type": "module"` を付けていません**。付けると、依存 mooncake（例: `Milky2018/wgpu_mbt`）の prebuild が CommonJS の `require` を使うため、Node が ES モジュール扱いにして失敗することがあります。
- [`moon.work`](moon.work) 配下でビルドした JS の成果物は、モジュール直下ではなく **リポジトリルートの `_build`** にまとまることがあります（Vitest のエイリアスや `src/main-*.ts` の import はその前提で書いています）。

## Build & Run

### Web

```bash
pnpm install
pnpm run dev:basic-triangle
```

### Native

```bash
pnpm install
pnpm run run:wgpu:basic-triangle
```

`scripts/run-wgpu-sdl3.sh` が参照する実行ファイルは、ワークスペースビルドでは **`moon/rhodonite_examples/_build` ではなく**、ルートの `_build/native/debug/build/emadurandal/rhodonite_examples/<サンプル>/wgpu/main/main.exe` に出力されます。

### Math（JS bridge の Vitest）

```bash
pnpm run test:math:js
```

### Math（MoonBit のテスト）

```bash
pnpm run test:math:mbt
```

ルートに [`moon.work`](moon.work) があると、`moon/rhodonite_math` に移動して単に `moon test` するとワークスペース全体のビルド計画に `rhodonite_webgpu` が含まれ、`webgpu_objects` が仮想パッケージのまま解決できずエラーになることがあります。そのため [`scripts/test-rhodonite-math-mbt.sh`](scripts/test-rhodonite-math-mbt.sh) がリポジトリルートから実行し、`moon/rhodonite_math/src` 以下の `*_test.mbt` があるパッケージだけを `moon test` に渡します（新しいパッケージを追加しても `package.json` を編集する必要はありません）。

## Publish の順序（目安）

registry に出すときは、依存の浅い順に **モジュール単位**で `moon publish` します（各サブディレクトリで実行）。詳細は [docs/module_boundaries.md](docs/module_boundaries.md) の Release units を参照。
