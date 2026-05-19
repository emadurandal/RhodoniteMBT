# emadurandal/rhodonite_webgpu

> **Stability:** This project is in **early development**. APIs and behavior may change without notice and are **not** production-ready yet. Prefer following the [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT) repository for the latest status.

WebGPU abstraction for RhodoniteMBT (browser and native targets). Depends on registry packages such as `Milky2018/wgpu_mbt`; see `moon.mod.json` for versions. Native SDL windowing uses `Kaida-Amethyst/sdl3` from the consuming project (for example `emadurandal/rhodonite_examples`).

## Using from another MoonBit project

In the consuming project's `moon.mod.json`, add this module to `deps`. When using the mooncakes registry package, specify the published version you want to depend on.

```json
{
  "name": "your-org/your-module",
  "version": "0.1.0",
  "deps": {
    "emadurandal/rhodonite_webgpu": "0.1.6"
  },
  "source": "src"
}
```

When using a local RhodoniteMBT checkout as a workspace or path dependency, specify the local path in `moon.mod.json`.

```json
{
  "deps": {
    "emadurandal/rhodonite_webgpu": {
      "path": "../RhodoniteMBT/moon/rhodonite_webgpu"
    }
  }
}
```

In a package that imports `emadurandal/rhodonite_webgpu/webgpu`, write `moon.pkg` like this. `webgpu_objects` is a virtual package that switches between browser and native implementations, so the final entry package you build must also set `overrides`.

```moonbit
import {
  "emadurandal/rhodonite_webgpu/webgpu" @wgpu,
}

supported_targets = "+js+native"
```

For a browser / JS entry package, select the JS implementation.

```moonbit
import {
  "emadurandal/rhodonite_webgpu/webgpu" @wgpu,
}

supported_targets = "js"

options(
  "is-main": true,
  link: { "js": { "format": "esm" } },
  overrides: [ "emadurandal/rhodonite_webgpu/webgpu_objects/js" ],
)
```

For a native / wgpu entry package, select the native implementation. If you use SDL3 windowing, add `Kaida-Amethyst/sdl3` to the consuming module and provide the required link flags.

```moonbit
import {
  "emadurandal/rhodonite_webgpu/webgpu" @wgpu,
}

supported_targets = "native"

options(
  "is-main": true,
  overrides: [ "emadurandal/rhodonite_webgpu/webgpu_objects/native" ],
  link: {
    "native": {
        "cc-flags": "-I/opt/homebrew/include -I/usr/local/include",
        "cc-link-flags": "-L/opt/homebrew/lib -L/usr/local/lib -lSDL3"
    },
  },
)
```

If your MoonBit code directly imports packages such as `moonbitlang/async`, `Milky2018/wgpu_mbt`, or `Kaida-Amethyst/sdl3`, add those packages to the consuming module's `moon.mod.json` `deps` as well. For packages that only import `rhodonite_webgpu`, the `emadurandal/rhodonite_webgpu` dependency is usually enough.
