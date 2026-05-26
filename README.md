# RhodoniteMBT

A monorepo of 3D graphics library RhodoniteMBT using MoonBit and WebGPU (browser and native). Multiple MoonBit **modules** are joined in a workspace via the root [`moon.work`](moon.work) ([Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)).

## Modules

| Module | Description |
|--------|-------------|
| `emadurandal/sdl3` | SDL3 MoonBit binding fork used by native runtime ([`moon/sdl3`](moon/sdl3)) |
| `emadurandal/rhodonite` | Public facade and high-level app/runtime helpers ([`moon/rhodonite`](moon/rhodonite)) |
| `emadurandal/rhodonite_app_sdl3` | SDL3 native app runtime helpers |
| `emadurandal/rhodonite_core` | Core (vectors, JS bridge, binary buffer writes, etc.) |
| `emadurandal/rhodonite_webgpu` | WebGPU abstraction |
| `emadurandal/rhodonite_examples` | Samples |

See [docs/en/module-boundaries.html](docs/en/module-boundaries.html) for boundaries and publishing notes.

## Development (workspace)

Example from the repository root (update deps and check everything):

```bash
moon update   # network may be required
moon check --target all
moon test --target all
moon fmt
moon info
```

The WebGPU object package is a virtual package with a default fallback stub so
workspace-wide checks/tests can build library packages directly; runnable JS and
native entry packages still override it with the real browser or wgpu backend.

### Node, pnpm, and workspace output

- The root [`package.json`](package.json) does **not** set `"type": "module"`. Setting it can break mooncake prebuilds (e.g. `Milky2018/wgpu_mbt`) that use CommonJS `require`, because Node then treats the package as ESM.
- JS artifacts built under [`moon.work`](moon.work) may be grouped under the **repository root `_build`**, not always next to each module (Vitest aliases and `samples/ts/main-*.ts` imports are written with that in mind).

### npm package

The TypeScript wrappers and the MoonBit JavaScript bridge they call are packaged
for npm as [`rhodonite-mbt`](packages/rhodonite-mbt/). The package is ESM-only
and exposes existing wrapper surfaces:

```ts
import { Vector3F } from "rhodonite-mbt/math";
import { World } from "rhodonite-mbt/ecs";
import { CubeMeshDesc, PlatformConfig, runPlatform } from "rhodonite-mbt/app";
```

The app entrypoint includes the v1 unlit renderer surface as well, including
`CubeMeshDesc`, `cubeMeshDesc`, and `Renderer.registerCubeMesh` for the
position-only cube primitive used by the examples.

Build and inspect the npm package from the repository root:

```bash
pnpm run build:npm
pnpm run pack:npm
```

## Build & Run

### JS (browser)

```bash
pnpm install
pnpm run dev:js:basic-triangle
pnpm run dev:js:ondemand-triangle
pnpm run dev:js:ecs-scene-graph
pnpm run dev:js:ecs-scene-graph-undo-redo
pnpm run dev:js:ecs-custom-component-color
pnpm run dev:js:multi-surface-independent-input
pnpm run dev:js:ecs-mass-cubes
```

The browser demos also include TypeScript-only WebGPU DemoState paths using the
ECS TypeScript wrapper, multi-surface runtime, and TypeScript-only on-demand
triangle:

```bash
pnpm run dev:js:ts-ecs-scene-graph
pnpm run dev:js:ts-ecs-scene-graph-undo-redo
pnpm run dev:js:ts-ecs-custom-component-color
pnpm run dev:js:ts-ecs-mass-cubes
pnpm run dev:js:ts-multi-surface-independent-input
pnpm run dev:js:ts-ondemand-triangle
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

> **Note:** SDL3 must be installed in advance for native builds. Linux uses SDL3
> window handles with the Vulkan backend. On Linux the runtime prefers the
> **Wayland** SDL driver and `wl_surface` when `WAYLAND_DISPLAY` is set
> (default on Ubuntu 24.04+). For an X11-only session, set `SDL_VIDEODRIVER=x11`.
> macOS uses SDL3 + Metal.

```bash
# macOS
$ brew install sdl3

# Linux (Debian/Ubuntu example)
$ sudo apt install libsdl3-dev
```

```bash
pnpm install
pnpm run dev:native:basic-triangle
pnpm run dev:native:ondemand-triangle
pnpm run dev:native:ecs-scene-graph
pnpm run dev:native:ecs-scene-graph-undo-redo
pnpm run dev:native:ecs-custom-component-color
pnpm run dev:native:multi-surface-independent-input
pnpm run dev:native:ecs-mass-cubes
```

The native demo scripts use `moon run --target native --release` from
[`moon/rhodonite_examples`](moon/rhodonite_examples), so no manual `_build`
executable path is needed.

Native SDL3 headers are compiled through the workspace `emadurandal/sdl3` fork,
which passes Homebrew include directories to its C stubs. The helper
[`scripts/setup-sdl3-env.sh`](scripts/setup-sdl3-env.sh) remains available only
for unusual local toolchain layouts.

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

### App TypeScript Runtime / Renderer

```bash
pnpm run test:app:ts
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
browser WebGPU, reads back RGBA8 pixels from offscreen targets or presented
browser canvases, and compares PNG golden files with exact or perceptual
comparison. See [docs/en/visual-regression-tests.html](docs/en/visual-regression-tests.html).

## Publish order (outline)

After `moon login`, publish Mooncakes from the repository root with
`pnpm run publish:moon`. The script publishes the library modules in dependency
order and excludes `emadurandal/rhodonite_examples`. Details:
[docs/en/module-boundaries.html](docs/en/module-boundaries.html) — Release units.

For npm, run `pnpm run publish:npm`; it rebuilds the release JS bridge and emits
the `packages/rhodonite-mbt/dist` package before invoking `npm publish`.

## License

Apache-2.0. See [LICENSE](LICENSE). The MoonBit modules declare the same SPDX
license in their `moon.mod.json` files, and the npm package includes its own
copy of the license for package tarballs.
