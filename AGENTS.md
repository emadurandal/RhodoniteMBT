# RhodoniteMBT — Agent guide

[RhodoniteMBT](README.md) is a **monorepo** for graphics-related code using [MoonBit](https://docs.moonbitlang.com) and WebGPU (browser and native SDL3). Multiple modules are wired as a workspace via the root [`moon.work`](moon.work) ([Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)).

Community MoonBit skills are listed at <https://github.com/moonbitlang/skills>.

## Modules

| Module (`moon.mod.json` name) | Directory | Role |
|-------------------------------|-----------|------|
| `emadurandal/rhodonite` | `moon/rhodonite/` | Public facade |
| `emadurandal/rhodonite_core` | `moon/rhodonite_core/` | Core (vectors, JS bridge, binary buffer writes, etc.) |
| `emadurandal/rhodonite_webgpu` | `moon/rhodonite_webgpu/` | WebGPU abstraction |
| `emadurandal/rhodonite_examples` | `moon/rhodonite_examples/` | Samples and demos |

See [`docs/module_boundaries.md`](docs/module_boundaries.md) for dependency boundaries and publish order.

## Documentation (`docs/`)

Keep **source code and everything under [`docs/`](docs/) in sync at all times**. When behavior, APIs, module layout, build or publish steps, or project conventions change in the repo, update the relevant `docs/*.md` in the same change; when documentation is revised to reflect the current system, ensure the code and scripts match. Do not leave `docs/` describing outdated paths, commands, or architecture.

## Publish (mooncakes)

After `moon login`, from the repository root: `just publish-mooncakes` or `pnpm run publish:moon`. This publishes `emadurandal/rhodonite_core`, `emadurandal/rhodonite_webgpu`, and `emadurandal/rhodonite` only ([`scripts/publish-rhodonite-mooncakes.sh`](scripts/publish-rhodonite-mooncakes.sh)); `rhodonite_examples` is excluded. The script runs `moon update` and a short wait (8s, overridable with `MOON_PUBLISH_INDEX_WAIT_SECONDS`) so the facade’s publish-time `moon check` can resolve freshly published deps. If core/webgpu are already on the registry and only the facade step must be retried, use `PUBLISH_MOON_FACADE_ONLY=1 pnpm run publish:moon`.

## Workspace development

From the repository root:

```bash
moon update          # when needed (may require network)
moon check --target all
moon fmt
moon info
```

[`justfile`](justfile) `just check-ws` runs `moon check --target all`.

## Node / pnpm notes

- Do **not** add `"type": "module"` to the root [`package.json`](package.json). Doing so can break mooncake prebuilds (e.g. `Milky2018/wgpu_mbt`) that rely on CommonJS `require`.
- Workspace JS build artifacts may land under the **repository root `_build`**, not necessarily next to each module (Vitest aliases and `src/main-*.ts` imports assume this).

## Build, run, and test (pnpm)

```bash
pnpm install
```

| Goal | Command |
|------|---------|
| JS demo (browser) | `pnpm run dev:js:basic-triangle` (also `dev:js:triangle-with-buffer`, `dev:js:depth-test`) |
| Native (SDL3 / wgpu) | `pnpm run dev:native:basic-triangle`, etc. ([`scripts/run-wgpu-sdl3.sh`](scripts/run-wgpu-sdl3.sh)) |
| Core JS bridge (Vitest) | `pnpm run test:core:js` |
| Core MoonBit tests | `pnpm run test:core:mbt` |

Native executables are emitted under the **root** `_build/native/debug/build/emadurandal/rhodonite_examples/<sample>/wgpu/main/main.exe`, not under `moon/rhodonite_examples/_build` ([`scripts/run-wgpu-sdl3.sh`](scripts/run-wgpu-sdl3.sh) expects this).

With a root `moon.work`, running `moon test` only inside `moon/rhodonite_core` can pull `rhodonite_webgpu` into the plan and fail resolving `webgpu_objects`. Use [`scripts/test-rhodonite-core-mbt.sh`](scripts/test-rhodonite-core-mbt.sh) from the repo root to pass only packages under `moon/rhodonite_core/src` that contain `*_test.mbt`.

## MoonBit layout (inside each module)

- Packages are directories; each has `moon.pkg` (dependencies).
- Files: implementation, black-box tests `*_test.mbt`, white-box tests `*_wbtest.mbt`.
- Module metadata lives in `moon.mod.json` at the module root.

## Coding conventions (MoonBit)

- Block-oriented style; blocks are separated by `///|` and order does not matter; refactor block-by-block when useful.
- Prefer moving deprecated code into `deprecated.mbt` per directory.

## JS bridge and TypeScript wrappers

When MoonBit code has a corresponding **`js_bridge`** and/or **TypeScript wrapper** (facades, `src/main-*.ts`, Vitest glue, etc.), keep **their contracts in sync** with the MoonBit side (exports, calling conventions, data layout, and error paths). Land coordinated updates in the same change when possible. Before finishing, **confirm the workspace still builds and tests cleanly** for the affected targets—for example `moon check --target all` plus the relevant `pnpm` scripts (JS demos, `pnpm run test:core:js`, etc.).

## Tooling

- `moon fmt` — formatting.
- `moon ide` — peek-def, outline, find-references (see `$moonbit-agent-guide`).
- `moon info` — refresh `.mbti` public interfaces; no diff usually means no externally visible change (safe refactor signal).
- Finish changes with `moon info && moon fmt` when appropriate; review `.mbti` diffs.
- `moon test` — run tests; refresh snapshots with `moon test --update`.
- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for stable results; use snapshots to capture behavior; prefer assertions for well-defined numeric output.
- `moon coverage analyze > uncovered.log` — inspect coverage gaps.
