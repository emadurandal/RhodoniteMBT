# RhodoniteMBT — エージェント向けガイド

[RhodoniteMBT](README.md) は [MoonBit](https://docs.moonbitlang.com) と WebGPU（ブラウザ・ネイティブ SDL3）を扱う **モノレポ** です。ルートの [`moon.work`](moon.work) で複数モジュールがワークスペース化されています（[Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)）。

MoonBit 共通のスキルは <https://github.com/moonbitlang/skills> を参照できます。

## モジュール構成

| モジュール名（`moon.mod.json`） | ディレクトリ | 役割 |
|--------------------------------|--------------|------|
| `emadurandal/rhodonite` | `moon/rhodonite/` | 公開用 facade |
| `emadurandal/rhodonite_binary` | `moon/rhodonite_binary/` | バイナリ書き込みヘルパー |
| `emadurandal/rhodonite_core` | `moon/rhodonite_core/` | コア（ベクトル・JS bridge など） |
| `emadurandal/rhodonite_webgpu` | `moon/rhodonite_webgpu/` | WebGPU 抽象化 |
| `emadurandal/rhodonite_examples` | `moon/rhodonite_examples/` | サンプル・デモ |

モジュール間の依存境界・publish 順序は [`docs/module_boundaries.md`](docs/module_boundaries.md) を正とする。

## ワークスペースでの開発

リポジトリルートで:

```bash
moon update          # 必要に応じて（ネットワーク利用）
moon check --target all
moon fmt
moon info
```

[`justfile`](justfile) の `just check-ws` は `moon check --target all` を呼ぶ。

## Node / pnpm の注意

- ルート [`package.json`](package.json) に **`"type": "module"` は付けない**。付けると依存 mooncake（例: `Milky2018/wgpu_mbt`）の prebuild が CommonJS の `require` と衝突して失敗することがある。
- ワークスペースビルドの JS 成果物は、モジュール直下ではなく **リポジトリルートの `_build`** にまとまることがある（Vitest のエイリアスや `src/main-*.ts` の import はその前提）。

## ビルド・実行・テスト（pnpm）

```bash
pnpm install
```

| 目的 | コマンド |
|------|----------|
| Web デモ（例: basic-triangle） | `pnpm run dev:basic-triangle`（他に `dev:triangle-with-buffer`, `dev:depth-test`） |
| ネイティブ（SDL3 / wgpu） | `pnpm run run:wgpu:basic-triangle` など（[`scripts/run-wgpu-sdl3.sh`](scripts/run-wgpu-sdl3.sh)） |
| Core の JS bridge（Vitest） | `pnpm run test:core:js` |
| Core の MoonBit テスト | `pnpm run test:core:mbt` |

ネイティブ実行ファイルは、`moon/rhodonite_examples/_build` ではなく **ルート** `_build/native/debug/build/emadurandal/rhodonite_examples/<サンプル>/wgpu/main/main.exe` に出力される（[`scripts/run-wgpu-sdl3.sh`](scripts/run-wgpu-sdl3.sh) が参照）。

ルートに `moon.work` があると `moon/rhodonite_core` だけで `moon test` すると `rhodonite_webgpu` などが計画に含まれ、`webgpu_objects` の解決で失敗することがある。そのため Core の MoonBit テストは [`scripts/test-rhodonite-core-mbt.sh`](scripts/test-rhodonite-core-mbt.sh) 経由で、`rhodonite_core/src` 以下に `*_test.mbt` があるパッケージだけを指定する。

## MoonBit プロジェクト構造（各モジュール内）

- パッケージはディレクトリ単位。各ディレクトリに `moon.pkg`（依存関係）。
- ファイル名: 通常の実装、ブラックボックステスト `*_test.mbt`、ホワイトボックステスト `*_wbtest.mbt`。
- モジュール直下に `moon.mod.json`（モジュールメタデータ）。

## コーディング規約（MoonBit）

- コードはブロックスタイル。ブロックは `///|` で区切り、順序は任意。リファクタ時はブロック単位で扱える。
- 非推奨コードは各ディレクトリの `deprecated.mbt` に寄せるとよい。

## ツールチェーン

- `moon fmt` — 整形。
- `moon ide` — peek-def / outline / find-references など（詳細は `$moonbit-agent-guide`）。
- `moon info` — パッケージの `.mbti`（公開インターフェース）を更新。差分がなければ外部から見た変更は通常ない（安全なリファクタの目安）。
- 変更の最後は `moon info && moon fmt` を推奨。`.mbti` の差分が意図どおりか確認する。
- `moon test` — テスト。スナップショットは `moon test --update` で更新。
- アサーションは結果が安定しているなら `assert_eq` や `assert_true(pattern is Pattern(...))`。振る舞いの記録にはスナップショット。数値計算など明確な結果にはアサーション優先。
- `moon coverage analyze > uncovered.log` でカバレッジの穴を確認できる。
