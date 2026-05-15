///|
pub(all) struct RgbaImage {
  width : Int
  height : Int
  data : Bytes
}

///|
#cfg(target="native")
#borrow(path)
extern "C" fn read_binary_file(path : String) -> Bytes = "rhodonite_visual_read_binary_file"

///|
#cfg(target="native")
#borrow(path)
extern "C" fn read_text_file(path : String) -> String = "rhodonite_visual_read_text_file"

///|
#cfg(target="native")
#borrow(path, data)
extern "C" fn write_binary_file(path : String, data : Bytes) -> Unit = "rhodonite_visual_write_binary_file"

///|
#cfg(target="native")
pub extern "C" fn visual_snapshot_update_enabled() -> Bool = "rhodonite_visual_snapshot_update_enabled"

///|
pub(all) struct VisualComparisonResult {
  mismatches : Int
  pixels : Int
  mismatch_rate : Double
}

///|
pub fn match_or_update_rgba_png_snapshot(
  image : RgbaImage,
  filename~ : String,
  max_mismatch_rate~ : Double,
  channel_tolerance? : Int = 0,
) -> Unit raise {
  if visual_snapshot_update_enabled() {
    write_rgba_png_snapshot(image, filename~)
  } else {
    assert_rgba_matches_png_snapshot(
      image,
      filename~,
      max_mismatch_rate~,
      channel_tolerance~,
    )
  }
}

///|
pub fn match_or_update_rgba_png_snapshot_perceptual(
  image : RgbaImage,
  filename~ : String,
  max_mismatch_rate~ : Double,
  perceptual_threshold? : Double = 0.1,
  include_aa? : Bool = false,
) -> Unit raise {
  if visual_snapshot_update_enabled() {
    write_rgba_png_snapshot(image, filename~)
  } else {
    assert_rgba_matches_png_snapshot_perceptual(
      image,
      filename~,
      max_mismatch_rate~,
      perceptual_threshold~,
      include_aa~,
    )
  }
}

///|
pub fn write_rgba_png_snapshot(
  image : RgbaImage,
  filename~ : String,
) -> Unit raise {
  write_binary_file(
    png_snapshot_path(filename),
    @image.encode_png({
      width: image.width,
      height: image.height,
      data: image.data,
    }),
  )
}

///|
pub fn assert_rgba_matches_png_snapshot(
  image : RgbaImage,
  filename~ : String,
  max_mismatch_rate~ : Double,
  channel_tolerance? : Int = 0,
) -> Unit raise {
  let expected = read_png_snapshot(filename)
  assert_same_dimensions(image, expected, filename)
  let pixels = image.width * image.height
  let mut mismatches = 0
  for i in 0..<pixels {
    let offset = i * 4
    if channel_diff_exceeds(
        image.data[offset],
        expected.data[offset],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        image.data[offset + 1],
        expected.data[offset + 1],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        image.data[offset + 2],
        expected.data[offset + 2],
        channel_tolerance,
      ) ||
      channel_diff_exceeds(
        image.data[offset + 3],
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
pub fn assert_rgba_matches_png_snapshot_perceptual(
  image : RgbaImage,
  filename~ : String,
  max_mismatch_rate~ : Double,
  perceptual_threshold? : Double = 0.1,
  include_aa? : Bool = false,
) -> Unit raise {
  ignore(
    compare_rgba_matches_png_snapshot_perceptual(
      image,
      filename~,
      max_mismatch_rate~,
      perceptual_threshold~,
      include_aa~,
    ),
  )
}

///|
pub fn compare_rgba_matches_png_snapshot_perceptual(
  image : RgbaImage,
  filename~ : String,
  max_mismatch_rate~ : Double,
  perceptual_threshold? : Double = 0.1,
  include_aa? : Bool = false,
) -> VisualComparisonResult raise {
  let expected = read_png_snapshot(filename)
  assert_same_dimensions(image, expected, filename)
  let actual = rgba_to_pixelmatch_image(image)
  let expected = image_data_to_pixelmatch_image(expected)
  let options = @pixelmatch.Options::default()
  let options = { ..options, threshold: perceptual_threshold, include_aa }
  let mismatches = @pixelmatch.pixelmatch(actual, expected, None, options)
  assert_mismatch_rate(
    mismatches,
    image.width * image.height,
    max_mismatch_rate,
    "PNG perceptual visual snapshot",
  )
  {
    mismatches,
    pixels: image.width * image.height,
    mismatch_rate: mismatches.to_double() /
    (image.width * image.height).to_double(),
  }
}

///|
fn assert_same_dimensions(
  actual : RgbaImage,
  expected : @image.ImageData,
  filename : String,
) -> Unit raise {
  if expected.width != actual.width || expected.height != actual.height {
    @test.fail(
      "PNG visual snapshot dimensions differ for \{filename}: actual \{actual.width}x\{actual.height}, expected \{expected.width}x\{expected.height}",
    )
  }
}

///|
fn read_png_snapshot(filename : String) -> @image.ImageData raise {
  let bytes = read_binary_file(png_snapshot_path(filename))
  if bytes.length() == 0 {
    @test.fail(
      "PNG visual snapshot \{filename} is missing or empty. Run `pnpm run test:examples:visual:update` on a native WebGPU-capable machine to generate it.",
    )
  }
  @image.decode_png(bytes)
}

///|
fn png_snapshot_path(filename : String) -> String {
  "moon/rhodonite_examples/src/visual_regression/__image_snapshots__/" +
  filename
}

///|
fn rgba_to_pixelmatch_image(image : RgbaImage) -> @pixelmatch.Image {
  let out = @pixelmatch.Image::new(image.width, image.height)
  for i in 0..<(image.width * image.height * 4) {
    out.data[i] = image.data[i].to_int()
  }
  out
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
