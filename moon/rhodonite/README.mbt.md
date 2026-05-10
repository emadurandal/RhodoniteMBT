# emadurandal/rhodonite

Public **facade** module for [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT). It pulls in the workspace libraries as dependencies so `moon add emadurandal/rhodonite` can serve as a single entry point.

For full surface area, import packages from the underlying modules directly:

- `emadurandal/rhodonite_webgpu` — WebGPU (browser + native)
- `emadurandal/rhodonite_core` — vectors, related math, and little-endian buffer writes (`binary/writes`)

The `lib` package here exposes a small curated subset (see `src/lib`).
