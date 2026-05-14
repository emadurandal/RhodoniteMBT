# Image Regression Tests

RhodoniteMBT keeps the first image regression layer inside
`emadurandal/rhodonite_examples`, not in the public `rhodonite_core`,
`rhodonite_webgpu`, or facade packages. The package
[`moon/rhodonite_examples/src/visual_regression`](../moon/rhodonite_examples/src/visual_regression)
depends on [`mizchi/canvas`](https://github.com/mizchi/canvas-mbt), which is a
pure MoonBit headless 2D canvas rasterizer with PNG output.

## Snapshot Formats

MoonBit snapshot tests store text, so small fixtures can use ASCII PPM (`P3`).
Large or rendering-technique fixtures should use PNG golden files instead.

### PPM

The PPM helper writes `canvas.pixels` as text and snapshots that file via
`@test.Test::snapshot` when visual snapshots are being updated. During normal
test runs, it reads the checked-in PPM and compares pixels with a configurable
mismatch rate:

```moonbit
test "visual basic triangle reference" (t : @test.Test) {
  let canvas = render_basic_triangle_reference()
  match_or_update_canvas_ppm_snapshot(
    t,
    canvas,
    filename="basic_triangle_reference.ppm",
    max_mismatch_rate=0.0,
  )
}
```

The checked-in snapshots live under the package-local `__snapshot__` directory.
PPM keeps the artifact image-like and viewer-friendly while still producing
plain text diffs in code review.

`max_mismatch_rate` is the allowed ratio of differing pixels, from `0.0` to
`1.0`. A pixel is different when any RGB channel exceeds `channel_tolerance`
(default `0`):

```moonbit
match_or_update_canvas_ppm_snapshot(
  t,
  canvas,
  filename="antialiased_shape.ppm",
  max_mismatch_rate=0.002,
  channel_tolerance=2,
)
```

### PNG

PNG golden files live under the package-local `__image_snapshots__` directory.
They are a better fit for larger images because the repository stores compact
binary PNGs instead of large text PPM files:

```moonbit
test "visual basic triangle PNG golden" {
  let canvas = render_basic_triangle_reference()
  match_or_update_canvas_png_snapshot(
    canvas,
    filename="basic_triangle_reference.png",
    max_mismatch_rate=0.0,
  )
}
```

Normal PNG comparison decodes the golden with `mizchi/image` and compares RGBA
pixels with `max_mismatch_rate` and `channel_tolerance`.

For perceptual comparison, use `mizchi/pixelmatch`, which compares colors in
YIQ space and can ignore anti-aliased edge pixels:

```moonbit
match_or_update_canvas_png_snapshot_perceptual(
  canvas,
  filename="lighting_1024.png",
  max_mismatch_rate=0.001,
  perceptual_threshold=0.1,
  include_aa=false,
)
```

`perceptual_threshold` follows pixelmatch semantics: lower values are more
sensitive, higher values tolerate larger perceptual color differences.

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

Use the update command only after inspecting the rendered change. The update
command sets `RHODONITE_UPDATE_VISUAL_SNAPSHOTS=1`, causing the helper to call
MoonBit's snapshot writer instead of the tolerance-based comparator.

## Scope

This layer is deterministic CPU-side visual regression testing. PPM is best for
small, stable render contracts: geometry placement, color palettes, sprite-like
fixtures, projection math outputs that can be rasterized in 2D, and expected
reference images for examples. PNG is the preferred path for larger fixtures,
lighting/material tests, or any output where text diffs would be too large.

It does not replace browser/native WebGPU pixel readback tests. For WebGPU
backend validation, add a separate integration path that renders to an
offscreen texture/canvas, reads RGBA bytes, and compares those bytes against a
fixture with a tolerance. Keep that path target-specific; keep the
`canvas-mbt` snapshot layer pure MoonBit and JS-targeted for fast CI feedback.

## Conventions

- Keep fixture canvases small, usually 32-128 px wide.
- Prefer `antialias=false` unless the test is specifically about raster edges.
- Keep `max_mismatch_rate=0.0` for deterministic fixtures. Use a non-zero rate
  only for intentionally tolerant output.
- Fill the background explicitly; PPM snapshots intentionally ignore alpha.
- Commit generated PPM files under `__snapshot__`.
- Commit generated PNG files under `__image_snapshots__`.
- Add new image fixtures under `moon/rhodonite_examples/src/visual_regression`
  unless a narrower package already owns the rendering contract.
