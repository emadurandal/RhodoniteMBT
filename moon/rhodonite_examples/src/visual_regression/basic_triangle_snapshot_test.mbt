///|
fn render_basic_triangle_reference() -> @canvas.Canvas {
  let canvas = @canvas.Canvas::new(64, 64, antialias=false)
  let ctx = canvas.context()
  ctx.set_fill_style(@canvas.Color::rgb(0, 0, 51))
  ctx.fill_rect(0.0, 0.0, 64.0, 64.0)
  ctx.begin_path()
  ctx.move_to(32.0, 8.0)
  ctx.line_to(8.0, 56.0)
  ctx.line_to(56.0, 56.0)
  ctx.close_path()
  ctx.set_fill_style(@canvas.Color::rgb(224, 224, 224))
  ctx.fill()
  ctx.set_fill_style(@canvas.Color::rgb(255, 0, 0))
  ctx.fill_rect(29.0, 5.0, 6.0, 6.0)
  ctx.set_fill_style(@canvas.Color::rgb(0, 255, 0))
  ctx.fill_rect(5.0, 53.0, 6.0, 6.0)
  ctx.set_fill_style(@canvas.Color::rgb(0, 0, 255))
  ctx.fill_rect(53.0, 53.0, 6.0, 6.0)
  canvas
}

///|
test "visual basic triangle reference" (t : @test.Test) {
  let canvas = render_basic_triangle_reference()
  match_or_update_canvas_ppm_snapshot(
    t,
    canvas,
    filename="basic_triangle_reference.ppm",
    max_mismatch_rate=0.0,
  )
}

///|
test "visual basic triangle PNG golden" {
  let canvas = render_basic_triangle_reference()
  match_or_update_canvas_png_snapshot(
    canvas,
    filename="basic_triangle_reference.png",
    max_mismatch_rate=0.0,
  )
}

///|
test "visual comparison allows configured pixel mismatch rate" {
  let canvas = render_basic_triangle_reference()
  canvas.pixels[0] = b'\xff'
  assert_canvas_matches_ppm_snapshot(
    canvas,
    filename="basic_triangle_reference.ppm",
    max_mismatch_rate=0.001,
  )
}

///|
test "PNG visual comparison allows configured pixel mismatch rate" {
  let canvas = render_basic_triangle_reference()
  canvas.pixels[0] = b'\xff'
  assert_canvas_matches_png_snapshot(
    canvas,
    filename="basic_triangle_reference.png",
    max_mismatch_rate=0.001,
  )
}

///|
test "PNG perceptual visual comparison allows configured pixel mismatch rate" {
  let canvas = render_basic_triangle_reference()
  canvas.pixels[0] = b'\xff'
  assert_canvas_matches_png_snapshot_perceptual(
    canvas,
    filename="basic_triangle_reference.png",
    max_mismatch_rate=0.001,
    perceptual_threshold=0.1,
  )
}
