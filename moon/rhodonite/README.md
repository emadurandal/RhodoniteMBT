# emadurandal/rhodonite

> **Stability:** This project is in **early development**. APIs and behavior may change without notice and are **not** production-ready yet. Prefer following the [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT) repository for the latest status.

Public **facade** module for [RhodoniteMBT](https://github.com/emadurandal/RhodoniteMBT). It pulls in the workspace libraries as dependencies so `moon add emadurandal/rhodonite` can serve as a single entry point.

It also exposes early high-level runtime helpers:

- `emadurandal/rhodonite/app` — `Engine`, `Scene`, `FrameState`, and `TimeState`

For lower-level surface area, import packages from the underlying modules directly:

- `emadurandal/rhodonite_webgpu` — WebGPU (browser + native)
- `emadurandal/rhodonite_core` — vectors, related math, and little-endian buffer writes (`binary/writes`)

The `lib` package here exposes a small curated subset (see `src/lib`).
