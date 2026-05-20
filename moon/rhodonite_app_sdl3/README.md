# rhodonite_app_sdl3

SDL3 native app runtime helpers for RhodoniteMBT.

This module owns SDL3 window/event polling and native WebGPU surfaces (macOS
Metal, Linux Wayland/X11 Vulkan)
bootstrap used by native examples. The main public package is
`emadurandal/rhodonite_app_sdl3/sdl3`. It uses `emadurandal/sdl3`, a
Rhodonite-maintained fork of the SDL3 MoonBit binding whose C stub package owns
the SDL3 include flags required on Homebrew-based macOS installations.

The SDL3 session type is opaque. Callers use accessors such as `gpu_context()`,
`surface_active()`, `surface_width()`, `surface_height()`, and
`surface_format()` instead of reading runtime fields directly.

Initialization, device creation, window-size queries, and resize handling report
structured `Sdl3AppError` values. The runtime handles SDL window resize events
and reconfigures the native WebGPU surface when the drawable pixel size changes.
Runtime 0x0/minimized surfaces are propagated to `Engine` as suspended rather
than as fatal errors.

The Wayland/X11 native surface C helper is active only on Linux. Other native
hosts export no-op/null ABI stubs so the macOS Metal path does not require SDL3
headers while compiling Linux-only helper code.

## Using from another MoonBit project

In the consuming project's `moon.mod.json`, add this module to `deps`. When
using the mooncakes registry package, specify the published version you want to
depend on.

```json
{
  "name": "your-org/your-module",
  "version": "0.1.0",
  "deps": {
    "emadurandal/rhodonite_app_sdl3": "0.1.8"
  },
  "source": "src",
  "preferred-target": "native"
}
```

When using a local RhodoniteMBT checkout as a workspace or path dependency,
specify the local path in `moon.mod.json`.

```json
{
  "deps": {
    "emadurandal/rhodonite_app_sdl3": {
      "path": "../RhodoniteMBT/moon/rhodonite_app_sdl3"
    }
  }
}
```

Native SDL3 entry packages usually import the high-level app facade, this SDL3
platform package, and `moonbitlang/async`. If your code imports those packages
directly, add them to the consuming module's `moon.mod.json` `deps` as well.

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

The `overrides` entry selects the native implementation of
`emadurandal/rhodonite_webgpu/webgpu_objects`, which is required for runnable
native entry packages. The SDL3 development package must also be installed on
the host system, for example `brew install sdl3` on macOS or `sudo apt install
libsdl3-dev` on Debian/Ubuntu. Consumers do not need to pass SDL3
`stub-cc-flags` from their main package; dependency stubs do not inherit those
flags, so `emadurandal/sdl3` sets them in the package that owns the SDL3 C
stubs.
