# emadurandal/rhodonite_core

> **Stability:** This project is in **early development**. APIs and behavior may change without notice and are **not** production-ready yet. Prefer following the [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT) repository for the latest status.

Vector math (`math/*`), JS bridge helpers, and `binary/writes` — little-endian `u16` / `u32` / `f32` into `FixedArray[Byte]` (e.g. GPU staging buffers).

## Using from another MoonBit project

In the consuming project's `moon.mod.json`, add this module to `deps`. When
using the mooncakes registry package, specify the published version you want to
depend on.

```json
{
  "name": "your-org/your-module",
  "version": "0.1.0",
  "deps": {
    "emadurandal/rhodonite_core": "0.1.8"
  },
  "source": "src"
}
```

When using a local RhodoniteMBT checkout as a workspace or path dependency,
specify the local path in `moon.mod.json`.

```json
{
  "deps": {
    "emadurandal/rhodonite_core": {
      "path": "../RhodoniteMBT/moon/rhodonite_core"
    }
  }
}
```

Import the core packages you use from your package's `moon.pkg`. Math and
binary utility packages are platform-independent and do not require
`webgpu_objects` overrides.

```moonbit
import {
  "emadurandal/rhodonite_core/math/vector3" @v3,
  "emadurandal/rhodonite_core/math/vector4" @v4,
  "emadurandal/rhodonite_core/math/matrix33" @m33,
  "emadurandal/rhodonite_core/math/matrix44" @m44,
  "emadurandal/rhodonite_core/binary/writes" @writes,
}

supported_targets = "+js+native"
```

For ECS and input code, import the relevant packages directly.

```moonbit
import {
  "emadurandal/rhodonite_core/ecs" @ecs,
  "emadurandal/rhodonite_core/ecs/components" @components,
  "emadurandal/rhodonite_core/ecs/wgsl" @ecs_wgsl,
  "emadurandal/rhodonite_core/input" @input,
}
```

Available public package paths include:

- `emadurandal/rhodonite_core/binary/writes`
- `emadurandal/rhodonite_core/ecs`
- `emadurandal/rhodonite_core/ecs/components`
- `emadurandal/rhodonite_core/ecs/wgsl`
- `emadurandal/rhodonite_core/input`
- `emadurandal/rhodonite_core/math/matrix33`
- `emadurandal/rhodonite_core/math/matrix44`
- `emadurandal/rhodonite_core/math/matrix44ref`
- `emadurandal/rhodonite_core/math/vector3`
- `emadurandal/rhodonite_core/math/vector4`

The `math/js_bridge` and `ecs/js_bridge` packages are JS bridge entry packages
used by the repository's generated JavaScript and TypeScript wrappers. External
TypeScript projects should usually consume the npm package instead of importing
these MoonBit bridge packages directly.
