# Image Regression Tests

`moon/rhodonite_examples/src/visual_regression` is the visual regression layer
for existing examples. It renders the real native WebGPU sample renderer into
an offscreen `rgba8unorm` texture, copies that texture into a readback buffer,
unpacks the padded RGBA rows, and compares the resulting image with PNG golden
files.

This is intentionally **not** a CPU-side canvas reference. A test only validates
pixels produced by the WebGPU backend and the sample renderer path.

## Commands

From the repository root:

```bash
pnpm run test:examples:visual
pnpm run test:examples:visual:update
```

Equivalent `just` recipes are available:

```bash
just test-visual
just update-visual-snapshots
```

`test:examples:visual:update` sets `RHODONITE_UPDATE_VISUAL_SNAPSHOTS=1` and
rewrites PNG golden files from the current WebGPU readback output. Use it only
after inspecting the rendered change.

Native WebGPU adapter creation can fail on headless machines or machines
without a supported backend. In that case the tests print a skip message and
pass without comparing pixels. Run the update command on a native WebGPU-capable
machine to create or refresh golden PNGs.

## Golden Files

PNG golden files live under:

```text
moon/rhodonite_examples/src/visual_regression/__image_snapshots__/
```

The current test set covers:

| Sample | Golden file |
|--------|-------------|
| `basic-triangle` | `basic_triangle_sample.png` |
| `triangle-with-buffer` | `triangle_with_buffer_sample.png` |
| `depth-test` | `depth_test_sample.png` |
| `ecs-scene-graph` | `ecs_scene_graph_sample.png` |
| `ecs-mass-cubes` | `ecs_mass_cubes_sample.png` |

If a PNG is missing, a WebGPU-capable normal test run fails with a message that
points at the update command. On machines where adapter creation fails, the
test is skipped before snapshot IO.

## Comparison

The helper decodes PNGs with `mizchi/image` and uses `mizchi/pixelmatch` for
perceptual comparison:

```moonbit
match_or_update_rgba_png_snapshot_perceptual(
  image,
  filename="basic_triangle_sample.png",
  max_mismatch_rate=0.0005,
  perceptual_threshold=0.1,
)
```

`max_mismatch_rate` is the allowed ratio of differing pixels. The current sample
tests use `0.0005`, which allows a tiny amount of backend or driver variance
while still catching visible regressions. `perceptual_threshold` follows
pixelmatch semantics: lower values are more sensitive, higher values tolerate
larger perceptual color differences.

Exact RGBA comparison is also available through
`match_or_update_rgba_png_snapshot` with `channel_tolerance`.

## Implementation Notes

- The visual package is `supported_targets = "native"`.
- It overrides `emadurandal/rhodonite_webgpu/webgpu_objects/native`.
- `rhodonite_webgpu` exposes offscreen RGBA texture creation, texture-to-buffer
  copy, padded-row sizing helpers, and native buffer readback.
- Sample renderers expose `create_renderer_for_device` and
  `render_frame_to_view`, so the same renderer state and draw code can target a
  swapchain view or an offscreen test texture.
- The readback texture size is currently `800x600`, matching the native/demo
  sample canvas size.
