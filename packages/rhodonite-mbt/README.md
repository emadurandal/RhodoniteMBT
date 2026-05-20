# rhodonite-mbt

TypeScript wrapper package for RhodoniteMBT. It includes the existing math, ECS,
and browser app runtime wrappers plus the MoonBit JavaScript bridge code they
call.

## Installation

Install from npm with your package manager:

```bash
npm install rhodonite-mbt
```

```bash
pnpm add rhodonite-mbt
```

```bash
yarn add rhodonite-mbt
```

This package is ESM-only and is intended for modern TypeScript projects and
bundlers. Use it from browser-capable ESM environments. The package depends on
`@webgpu/types` for WebGPU TypeScript declarations.

## Import paths

The package exposes these entrypoints:

- `rhodonite-mbt` — combined export surface
- `rhodonite-mbt/math` — vector and matrix wrappers
- `rhodonite-mbt/ecs` — ECS wrappers and GPU write helpers
- `rhodonite-mbt/app` — browser WebGPU app/runtime helpers

## Basic math usage

```ts
import { Vector3F } from "rhodonite-mbt/math";

const v = Vector3F.new(1, 2, 3);
const doubled = v.scale(2);

console.log(doubled.toString());
```

## ECS usage

```ts
import { World } from "rhodonite-mbt/ecs";

const world = World.new();
const entity = world.createEntity();

world.addComponent(entity, world.transformComponent());
```

## Browser app runtime usage

The app runtime helpers are browser-only and expect WebGPU support.

```ts
import {
  Engine,
  PlatformApp,
  PlatformOptions,
  runSingleCanvasPlatform,
} from "rhodonite-mbt/app";

const canvas = document.querySelector<HTMLCanvasElement>("#canvas");

if (canvas) {
  await runSingleCanvasPlatform(
    canvas,
    PlatformApp.defaultEngine((engine: Engine) => {
      engine.addPhaseHandler("rhodonite/render", (_engine, frame) => {
        if (!frame.surface.active) {
          return;
        }

        const encoder = engine.device.createCommandEncoder();
        const pass = encoder.beginRenderPass({
          colorAttachments: [
            {
              view: engine.context.getCurrentTexture().createView(),
              clearValue: { r: 0.04, g: 0.04, b: 0.05, a: 1 },
              loadOp: "clear",
              storeOp: "store",
            },
          ],
        });

        pass.end();
        engine.queue.submit([encoder.finish()]);
      });
    }),
    PlatformOptions.interactive(),
  );
}
```

If you only need input normalization or frame-loop helpers, import them from
`rhodonite-mbt/app` directly, for example `installBrowserInputState`,
`startBrowserFrameLoop`, or `startBrowserOnDemandFrameLoop`.

## Local package testing

From the RhodoniteMBT repository root, build and pack the npm package with:

```bash
pnpm run build:npm
pnpm run pack:npm
```

Then install the generated tarball into another project with your package
manager, for example:

```bash
pnpm add /path/to/RhodoniteMBT/packages/rhodonite-mbt/rhodonite-mbt-0.1.8.tgz
```

## License

Apache-2.0. See [LICENSE](LICENSE).
