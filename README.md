# RhodoniteMBT

A monorepo of 3D graphics library RhodoniteMBT using MoonBit and WebGPU (browser and native). Multiple MoonBit **modules** are joined in a workspace via the root [`moon.work`](moon.work) ([Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)).

## Modules

| Module | Description |
|--------|-------------|
| `emadurandal/rhodonite` | Public facade and high-level app/runtime helpers ([`moon/rhodonite`](moon/rhodonite)) |
| `emadurandal/rhodonite_app_sdl3` | SDL3 native app runtime helpers |
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

### JS (browser)

```bash
pnpm install
pnpm run dev:js:basic-triangle
```

The browser demos also include a TypeScript-only WebGPU DemoState using the ECS
TypeScript wrapper:

```bash
pnpm run dev:js:ts-ecs-mass-cubes
```

The ECS mass-cubes sample also has MoonBit `wasm` and `wasm-gc` browser
variants. The mass-cubes demos use the same packed transform ref path as the
TypeScript demo, and a source-level precision-mode constant can switch all
entities to fp32, all to fp16, or mix fp32/fp16 by entity range or entity id.
The dev scripts build release WASM artifacts for these high-load demos:

```bash
pnpm run dev:wasm:ecs-mass-cubes
pnpm run dev:wasm-gc:ecs-mass-cubes
```

### Native

> **Note:** SDL3 must be installed in advance for native builds.

```bash
# macOS
$ brew install sdl3
```

```bash
pnpm install
pnpm run dev:native:basic-triangle
```

The native demo scripts use `moon run --target native --release` from
[`moon/rhodonite_examples`](moon/rhodonite_examples), so no manual `_build`
executable path is needed.

If the native build cannot find SDL3 headers, source
[`scripts/setup-sdl3-env.sh`](scripts/setup-sdl3-env.sh) in the shell before
running native commands:

```bash
source scripts/setup-sdl3-env.sh
pnpm run dev:native:basic-triangle
```

For a debug native build while iterating, run the package directly without
`--release`, for example:

```bash
cd moon/rhodonite_examples
moon run --target native src/basic-triangle/wgpu/main
```

### Core (JS bridge / Vitest)

```bash
pnpm run test:core:js
```

### Core (MoonBit tests)

```bash
pnpm run test:core:mbt
```

With a root [`moon.work`](moon.work), running plain `moon test` from `moon/rhodonite_core` can include `rhodonite_webgpu` in the workspace plan and fail while `webgpu_objects` stays unresolved. [`scripts/test-rhodonite-core-mbt.sh`](scripts/test-rhodonite-core-mbt.sh) therefore runs from the repo root and passes only packages under `moon/rhodonite_core/src` that contain `*_test.mbt` (no need to edit `package.json` when adding packages).

### Example visual snapshots

```bash
pnpm run test:examples:visual
pnpm run test:examples:visual:update
```

The visual regression setup renders existing examples through native WebGPU and
browser WebGPU, reads back offscreen RGBA8 textures, and compares PNG golden
files with exact or perceptual comparison. See [docs/image_regression_tests.md](docs/image_regression_tests.md).

## Publish order (outline)

When publishing to the registry, run `moon publish` **per module** from shallow dependencies outward (each subdirectory). Details: [docs/module_boundaries.md](docs/module_boundaries.md) — Release units.
