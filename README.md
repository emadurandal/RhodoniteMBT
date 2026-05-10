# RhodoniteMBT

A monorepo of graphics-related code using MoonBit and WebGPU (browser and native). Multiple MoonBit **modules** are joined in a workspace via the root [`moon.work`](moon.work) ([Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)).

## Modules

| Module | Description |
|--------|-------------|
| `emadurandal/rhodonite` | Thin public facade ([`moon/rhodonite`](moon/rhodonite)) |
| `emadurandal/rhodonite_core` | Core (vectors, JS bridge, binary buffer writes, etc.) |
| `emadurandal/rhodonite_webgpu` | WebGPU abstraction |
| `emadurandal/rhodonite_examples` | Samples |

See [docs/module_boundaries.md](docs/module_boundaries.md) for boundaries and publishing notes.

## Development (workspace)

Example from the repository root (update deps and check everything):

```bash
moon update   # network may be required
moon check --target all
moon fmt
moon info
```

From [`justfile`](justfile), `just check-ws` runs `moon check --target all`.

### Node, pnpm, and workspace output

- The root [`package.json`](package.json) does **not** set `"type": "module"`. Setting it can break mooncake prebuilds (e.g. `Milky2018/wgpu_mbt`) that use CommonJS `require`, because Node then treats the package as ESM.
- JS artifacts built under [`moon.work`](moon.work) may be grouped under the **repository root `_build`**, not always next to each module (Vitest aliases and `src/main-*.ts` imports are written with that in mind).

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

[`scripts/run-wgpu-sdl3.sh`](scripts/run-wgpu-sdl3.sh) runs the native binary; under workspace builds it lives at `_build/native/debug/build/emadurandal/rhodonite_examples/<sample>/wgpu/main/main.exe`, **not** under `moon/rhodonite_examples/_build`.

### Core (JS bridge / Vitest)

```bash
pnpm run test:core:js
```

### Core (MoonBit tests)

```bash
pnpm run test:core:mbt
```

With a root [`moon.work`](moon.work), running plain `moon test` from `moon/rhodonite_core` can include `rhodonite_webgpu` in the workspace plan and fail while `webgpu_objects` stays unresolved. [`scripts/test-rhodonite-core-mbt.sh`](scripts/test-rhodonite-core-mbt.sh) therefore runs from the repo root and passes only packages under `moon/rhodonite_core/src` that contain `*_test.mbt` (no need to edit `package.json` when adding packages).

## Publish order (outline)

When publishing to the registry, run `moon publish` **per module** from shallow dependencies outward (each subdirectory). Details: [docs/module_boundaries.md](docs/module_boundaries.md) — Release units.
