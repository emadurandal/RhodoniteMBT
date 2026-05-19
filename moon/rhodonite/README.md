# emadurandal/rhodonite

> **Stability:** This project is in **early development**. APIs and behavior may change without notice and are **not** production-ready yet. Prefer following the [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT) repository for the latest status.

Public **facade** module for [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT). It pulls in the workspace libraries as dependencies so `moon add emadurandal/rhodonite` can serve as a single entry point.

The module declares `preferred-target: "js"` because its browser app packages are JavaScript-targeted. This keeps mooncakes publish verification on the supported backend.

It also exposes early high-level runtime helpers:

- `emadurandal/rhodonite/app` — `Engine`, `Scene`, `FrameState`, and `TimeState`

For lower-level surface area, import packages from the underlying modules directly:

- `emadurandal/rhodonite_webgpu` — WebGPU (browser + native)
- `emadurandal/rhodonite_core` — vectors, related math, and little-endian buffer writes (`binary/writes`)

The `lib` package here exposes a small curated subset (see `src/lib`).

## Using from another MoonBit project

In the consuming project's `moon.mod.json`, add this facade module to `deps`.
When using the mooncakes registry package, specify the published version you
want to depend on.

```json
{
  "name": "your-org/your-module",
  "version": "0.1.0",
  "deps": {
    "emadurandal/rhodonite": "0.1.6"
  },
  "source": "src",
  "preferred-target": "js"
}
```

When using a local RhodoniteMBT checkout as a workspace or path dependency,
specify the local path in `moon.mod.json`.

```json
{
  "deps": {
    "emadurandal/rhodonite": {
      "path": "../RhodoniteMBT/moon/rhodonite"
    }
  }
}
```

Import the high-level runtime packages from your package's `moon.pkg`.
Platform-independent app/runtime code can import `emadurandal/rhodonite/app`.

```moonbit
import {
  "emadurandal/rhodonite/app" @app,
}

supported_targets = "+js+native"
```

Browser entry packages can import `emadurandal/rhodonite/app/browser` and must
select the JS implementation of `webgpu_objects` for runnable JS builds.

```moonbit
import {
  "emadurandal/rhodonite/app" @app,
  "emadurandal/rhodonite/app/browser" @app_browser,
}

supported_targets = "js"

options(
  "is-main": true,
  link: { "js": { "format": "esm" } },
  overrides: [ "emadurandal/rhodonite_webgpu/webgpu_objects/js" ],
)
```

SDL3 native entry packages should also depend on
`emadurandal/rhodonite_app_sdl3`. If the entry package imports
`moonbitlang/async` directly, add that dependency as well.

```json
{
  "deps": {
    "emadurandal/rhodonite": "0.1.6",
    "emadurandal/rhodonite_app_sdl3": "0.1.6",
    "moonbitlang/async": "0.18.1"
  },
  "preferred-target": "native"
}
```

For a local RhodoniteMBT checkout, use matching path dependencies for both
facade and SDL3 modules.

```json
{
  "deps": {
    "emadurandal/rhodonite": {
      "path": "../RhodoniteMBT/moon/rhodonite"
    },
    "emadurandal/rhodonite_app_sdl3": {
      "path": "../RhodoniteMBT/moon/rhodonite_app_sdl3"
    }
  }
}
```

The native entry package imports the facade app package and the SDL3 platform
package, selects the native WebGPU object implementation, and links SDL3.

```moonbit
import {
  "emadurandal/rhodonite/app" @app,
  "emadurandal/rhodonite_app_sdl3/sdl3" @sdl_app,
  "moonbitlang/async" @async,
}

supported_targets = "native"

options(
  "is-main": true,
  link: {
    "native": {
        "cc-flags": "-I/opt/homebrew/include -I/usr/local/include",
        "cc-link-flags": "-L/opt/homebrew/lib -L/usr/local/lib -lSDL3"
    },
  },
  overrides: [ "emadurandal/rhodonite_webgpu/webgpu_objects/native" ],
)
```

SDL3 development headers and libraries must be installed on the host system,
for example with `brew install sdl3` on macOS or `sudo apt install libsdl3-dev`
on Debian/Ubuntu.

The small curated facade package can be imported as `emadurandal/rhodonite/lib`.

```moonbit
import {
  "emadurandal/rhodonite/lib" @rhodonite,
}
```

If your MoonBit code directly imports lower-level packages such as
`emadurandal/rhodonite_core/ecs`,
`emadurandal/rhodonite_core/math/vector3`, or
`emadurandal/rhodonite_webgpu/webgpu`, add the corresponding modules
(`emadurandal/rhodonite_core` or `emadurandal/rhodonite_webgpu`) to the
consuming module's `moon.mod.json` `deps` as well.
