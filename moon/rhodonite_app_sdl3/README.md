# rhodonite_app_sdl3

SDL3 native app runtime helpers for RhodoniteMBT.

This module owns SDL3 window/event polling and native WebGPU surfaces (macOS
Metal, Linux Wayland/X11 Vulkan)
bootstrap used by native examples. The main public package is
`emadurandal/rhodonite_app_sdl3/sdl3`.

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
