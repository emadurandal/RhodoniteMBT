# Image Regression Tests

`moon/rhodonite_examples/src/visual_regression` and
`moon/rhodonite_examples/src/visual_regression_browser/js/main` are the visual
regression layers for existing examples. They render the real sample renderer
into an offscreen `rgba8unorm` texture, copy that texture into a readback
buffer, unpack the padded RGBA rows, and compare the resulting image with PNG
golden files.

This is intentionally **not** a CPU-side canvas reference. A test only validates
pixels produced by the WebGPU backend and the sample renderer path. The native
path uses the SDL/wgpu backend; the browser path runs the MoonBit JS target in a
headless Chrome/Chromium WebGPU page.

## Commands

From the repository root:

```bash
pnpm run test:examples:visual
pnpm run test:examples:visual:update
```

The combined commands run both native and browser visual checks. The individual
targets are also available:

```bash
pnpm run test:examples:visual:native
pnpm run test:examples:visual:browser
pnpm run test:examples:visual:update:native
pnpm run test:examples:visual:update:browser
```

Equivalent `just` recipes are available:

```bash
just test-visual
just test-visual-native
just test-visual-browser
just update-visual-snapshots
just update-visual-snapshots-native
just update-visual-snapshots-browser
```

`test:examples:visual:update` sets `RHODONITE_UPDATE_VISUAL_SNAPSHOTS=1` and
rewrites PNG golden files from the current WebGPU readback output. Use it only
after inspecting the rendered change.

Native WebGPU adapter creation or browser WebGPU startup can fail on headless
machines, machines without a supported backend, or machines without
Chrome/Chromium installed. In that case the relevant test prints a skip message
and passes without comparing pixels. Run the update command on a WebGPU-capable
native/browser machine to create or refresh golden PNGs.

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
| `basic-triangle` browser | `basic_triangle_browser_sample.png` |
| `triangle-with-buffer` browser | `triangle_with_buffer_browser_sample.png` |
| `depth-test` browser | `depth_test_browser_sample.png` |
| `ecs-scene-graph` browser | `ecs_scene_graph_browser_sample.png` |
| `ecs-mass-cubes` browser | `ecs_mass_cubes_browser_sample.png` |

If a PNG is missing, a WebGPU-capable normal test run fails with a message that
points at the update command. On machines where adapter creation fails, the
test is skipped before snapshot IO.

## Comparison

The native helper decodes PNGs with `mizchi/image` and uses `mizchi/pixelmatch`
for perceptual comparison:

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

The browser harness uses the same `max_mismatch_rate=0.0005` and a YIQ-based
perceptual threshold equivalent to pixelmatch's threshold scale. It decodes and
encodes PNGs inside the browser using `createImageBitmap` and `OffscreenCanvas`,
then sends comparison results or updated PNG bytes back to the Node runner.

## Implementation Notes

- The native visual package is `supported_targets = "native"`.
- The browser visual package is `supported_targets = "js"`.
- Native overrides `emadurandal/rhodonite_webgpu/webgpu_objects/native`;
  browser overrides `emadurandal/rhodonite_webgpu/webgpu_objects/js`.
- `rhodonite_webgpu` exposes offscreen RGBA texture creation, texture-to-buffer
  copy, padded-row sizing helpers, native buffer readback, and JS async buffer
  readback.
- Sample renderers expose `create_renderer_for_device` and
  `render_frame_to_view`, so the same renderer state and draw code can target a
  swapchain view or an offscreen test texture.
- Browser visual tests are driven by `scripts/run-browser-visual-regression.mjs`,
  which starts Vite and a separate local result server, opens a headless
  Chrome/Chromium page, and waits for the page to POST its result. Browser
  stdout/stderr is hidden by default; set `RHODONITE_BROWSER_VERBOSE=1` to debug
  page progress and Chrome logs.
- The readback texture size is currently `800x600`, matching the native/demo
  sample canvas size.
