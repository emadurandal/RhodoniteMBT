///|
priv struct PpmImage {
  width : Int
  height : Int
  rgb : FixedArray[Byte]
}

///|
extern "js" fn read_text_file(path : String) -> String =
  #| (path) => {
  #|   const fs = require("node:fs");
  #|   return fs.readFileSync(path, "utf8");
  #| }

///|
extern "js" fn read_binary_file(path : String) -> Bytes =
  #| (path) => {
  #|   const fs = require("node:fs");
  #|   return new Uint8Array(fs.readFileSync(path));
  #| }

///|
extern "js" fn write_binary_file(path : String, data : Bytes) -> Unit =
  #| (path, data) => {
  #|   const fs = require("node:fs");
  #|   const nodePath = require("node:path");
  #|   fs.mkdirSync(nodePath.dirname(path), { recursive: true });
  #|   fs.writeFileSync(path, Buffer.from(data));
  #| }

///|
extern "js" fn visual_snapshot_update_enabled() -> Bool =
  #| () => {
  #|   const env = globalThis.process && globalThis.process.env;
  #|   return !!(env && env.RHODONITE_UPDATE_VISUAL_SNAPSHOTS);
  #| }

///|
pub fn write_canvas_ppm_snapshot(
  t : @test.Test,
  canvas : @canvas.Canvas,
  filename~ : String,
) -> Unit raise {
  t.writeln("P3")
  t.writeln("\{canvas.width} \{canvas.height}")
  t.writeln("255")
  for y in 0..<canvas.height {
    let row = StringBuilder::new()
    for x in 0..<canvas.width {
      let offset = (y * canvas.width + x) * 4
      if x != 0 {
        row.write_string(" ")
      }
      row.write_string(canvas.pixels[offset].to_int().to_string())
      row.write_char(' ')
      row.write_string(canvas.pixels[offset + 1].to_int().to_string())
      row.write_char(' ')
      row.write_string(canvas.pixels[offset + 2].to_int().to_string())
    }
    t.writeln(row.to_string())
  }
  t.snapshot(filename~)
}

///|
pub fn match_or_update_canvas_ppm_snapshot(
  t : @test.Test,
  canvas : @canvas.Canvas,
  filename~ : String,
  max_mismatch_rate~ : Double,
  channel_tolerance? : Int = 0,
) -> Unit raise {
  if visual_snapshot_update_enabled() {
    write_canvas_ppm_snapshot(t, canvas, filename~)
  } else {
    assert_canvas_matches_ppm_snapshot(
      canvas,
      filename~,
      max_mismatch_rate~,
      channel_tolerance~,
    )
  }
}

///|
pub fn assert_canvas_matches_ppm_snapshot(
  canvas : @canvas.Canvas,
  filename~ : String,
  max_mismatch_rate~ : Double,
  channel_tolerance? : Int = 0,
) -> Unit raise {
  let image = read_ppm_snapshot(filename)
  if image.width != canvas.width || image.height != canvas.height {
    @test.fail(
      "visual snapshot dimensions differ: actual \{canvas.width}x\{canvas.height}, expected \{image.width}x\{image.height}",
    )
  }
  let pixels = canvas.width * canvas.height
  let mut mismatches = 0
  for i in 0..<pixels {
    let actual = i * 4
    let expected = i * 3
    if channel_diff_exceeds(
        canvas.pixels[actual],
        image.rgb[expected],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        canvas.pixels[actual + 1],
        image.rgb[expected + 1],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        canvas.pixels[actual + 2],
        image.rgb[expected + 2],
        channel_tolerance,
      ) {
      mismatches = mismatches + 1
    }
  }
  let mismatch_rate = mismatches.to_double() / pixels.to_double()
  if mismatch_rate > max_mismatch_rate {
    @test.fail(
      "visual snapshot mismatch rate \{mismatch_rate} exceeds \{max_mismatch_rate}: \{mismatches}/\{pixels} pixels differ",
    )
  }
}

///|
pub fn match_or_update_canvas_png_snapshot(
  canvas : @canvas.Canvas,
  filename~ : String,
  max_mismatch_rate~ : Double,
  channel_tolerance? : Int = 0,
) -> Unit raise {
  if visual_snapshot_update_enabled() {
    write_canvas_png_snapshot(canvas, filename~)
  } else {
    assert_canvas_matches_png_snapshot(
      canvas,
      filename~,
      max_mismatch_rate~,
      channel_tolerance~,
    )
  }
}

///|
pub fn match_or_update_canvas_png_snapshot_perceptual(
  canvas : @canvas.Canvas,
  filename~ : String,
  max_mismatch_rate~ : Double,
  perceptual_threshold? : Double = 0.1,
  include_aa? : Bool = false,
) -> Unit raise {
  if visual_snapshot_update_enabled() {
    write_canvas_png_snapshot(canvas, filename~)
  } else {
    assert_canvas_matches_png_snapshot_perceptual(
      canvas,
      filename~,
      max_mismatch_rate~,
      perceptual_threshold~,
      include_aa~,
    )
  }
}

///|
pub fn write_canvas_png_snapshot(
  canvas : @canvas.Canvas,
  filename~ : String,
) -> Unit raise {
  write_binary_file(png_snapshot_path(filename), canvas.to_png())
}

///|
pub fn assert_canvas_matches_png_snapshot(
  canvas : @canvas.Canvas,
  filename~ : String,
  max_mismatch_rate~ : Double,
  channel_tolerance? : Int = 0,
) -> Unit raise {
  let expected = read_png_snapshot(filename)
  if expected.width != canvas.width || expected.height != canvas.height {
    @test.fail(
      "PNG visual snapshot dimensions differ: actual \{canvas.width}x\{canvas.height}, expected \{expected.width}x\{expected.height}",
    )
  }
  let actual = canvas.to_image_data()
  let pixels = canvas.width * canvas.height
  let mut mismatches = 0
  for i in 0..<pixels {
    let offset = i * 4
    if channel_diff_exceeds(
        actual.data[offset],
        expected.data[offset],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        actual.data[offset + 1],
        expected.data[offset + 1],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        actual.data[offset + 2],
        expected.data[offset + 2],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        actual.data[offset + 3],
        expected.data[offset + 3],
        channel_tolerance,
      ) {
      mismatches = mismatches + 1
    }
  }
  assert_mismatch_rate(
    mismatches, pixels, max_mismatch_rate, "PNG visual snapshot",
  )
}

///|
pub fn assert_canvas_matches_png_snapshot_perceptual(
  canvas : @canvas.Canvas,
  filename~ : String,
  max_mismatch_rate~ : Double,
  perceptual_threshold? : Double = 0.1,
  include_aa? : Bool = false,
) -> Unit raise {
  let expected = read_png_snapshot(filename)
  if expected.width != canvas.width || expected.height != canvas.height {
    @test.fail(
      "PNG visual snapshot dimensions differ: actual \{canvas.width}x\{canvas.height}, expected \{expected.width}x\{expected.height}",
    )
  }
  let actual = image_data_to_pixelmatch_image(canvas.to_image_data())
  let expected = image_data_to_pixelmatch_image(expected)
  let options = @pixelmatch.Options::default()
  let options = { ..options, threshold: perceptual_threshold, include_aa }
  let mismatches = @pixelmatch.pixelmatch(actual, expected, None, options)
  assert_mismatch_rate(
    mismatches,
    canvas.width * canvas.height,
    max_mismatch_rate,
    "PNG perceptual visual snapshot",
  )
}

///|
fn read_ppm_snapshot(filename : String) -> PpmImage raise {
  parse_ppm(
    read_text_file(
      "moon/rhodonite_examples/src/visual_regression/__snapshot__/" + filename,
    ),
  )
}

///|
fn read_png_snapshot(filename : String) -> @image.ImageData raise {
  @image.decode_png(read_binary_file(png_snapshot_path(filename)))
}

///|
fn png_snapshot_path(filename : String) -> String {
  "moon/rhodonite_examples/src/visual_regression/__image_snapshots__/" +
  filename
}

///|
fn image_data_to_pixelmatch_image(
  image : @image.ImageData,
) -> @pixelmatch.Image {
  let out = @pixelmatch.Image::new(image.width, image.height)
  for i in 0..<(image.width * image.height * 4) {
    out.data[i] = image.data[i].to_int()
  }
  out
}

///|
fn assert_mismatch_rate(
  mismatches : Int,
  pixels : Int,
  max_mismatch_rate : Double,
  label : String,
) -> Unit raise {
  let mismatch_rate = mismatches.to_double() / pixels.to_double()
  if mismatch_rate > max_mismatch_rate {
    @test.fail(
      "\{label} mismatch rate \{mismatch_rate} exceeds \{max_mismatch_rate}: \{mismatches}/\{pixels} pixels differ",
    )
  }
}

///|
fn parse_ppm(src : String) -> PpmImage raise {
  let (magic, i0) = next_ppm_token(src, 0)
  if magic != "P3" {
    @test.fail("unsupported visual snapshot format: expected P3, got \{magic}")
  }
  let (width, i1) = next_ppm_int(src, i0)
  let (height, i2) = next_ppm_int(src, i1)
  let (max_value, i3) = next_ppm_int(src, i2)
  if max_value != 255 {
    @test.fail("unsupported visual snapshot max value: \{max_value}")
  }
  let len = width * height * 3
  let rgb = FixedArray::make(len, b'\x00')
  let mut pos = i3
  for i in 0..<len {
    let (value, next) = next_ppm_int(src, pos)
    if value < 0 || value > 255 {
      @test.fail("visual snapshot channel out of range: \{value}")
    }
    rgb[i] = value.to_byte()
    pos = next
  }
  { width, height, rgb }
}

///|
fn next_ppm_int(src : String, start : Int) -> (Int, Int) raise {
  let (token, next) = next_ppm_token(src, start)
  try @string.parse_int(token) catch {
    _ => @test.fail("invalid integer in visual snapshot: \{token}")
  } noraise {
    value => (value, next)
  }
}

///|
fn next_ppm_token(src : String, start : Int) -> (String, Int) raise {
  let len = src.length()
  let mut i = skip_ppm_ws_and_comments(src, start)
  if i >= len {
    @test.fail("unexpected end of visual snapshot")
  }
  let begin = i
  while i < len {
    match src.get_char(i) {
      Some(c) if is_ppm_ws(c) || c == '#' => break
      Some(_) => i = i + 1
      None => i = i + 1
    }
  }
  (src[begin:i].to_owned(), i)
}

///|
fn skip_ppm_ws_and_comments(src : String, start : Int) -> Int {
  let len = src.length()
  let mut i = start
  while i < len {
    match src.get_char(i) {
      Some(c) if is_ppm_ws(c) => i = i + 1
      Some('#') => {
        i = i + 1
        while i < len {
          match src.get_char(i) {
            Some('\n') => break
            Some(_) => i = i + 1
            None => i = i + 1
          }
        }
      }
      _ => break
    }
  }
  i
}

///|
fn is_ppm_ws(c : Char) -> Bool {
  c == ' ' || c == '\n' || c == '\r' || c == '\t'
}

///|
fn channel_diff_exceeds(
  actual : Byte,
  expected : Byte,
  tolerance : Int,
) -> Bool {
  let d = actual.to_int() - expected.to_int()
  if d < 0 {
    -d > tolerance
  } else {
    d > tolerance
  }
}
