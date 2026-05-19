# rhodonite-mbt

TypeScript wrapper package for RhodoniteMBT. It includes the existing math, ECS,
and browser app runtime wrappers plus the MoonBit JavaScript bridge code they
call.

```bash
npm install rhodonite-mbt
```

```ts
import { Vector3F } from "rhodonite-mbt/math";
import { World } from "rhodonite-mbt/ecs";

const v = Vector3F.new(1, 2, 3);
const world = World.new();
const entity = world.createEntity();
```

This package is ESM-only and is intended for modern TypeScript projects and
bundlers.
