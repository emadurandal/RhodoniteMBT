///|
pub(all) struct VisualSample {
  target : String
  id : String
  name : String
  filename : String
  max_mismatch_rate : Double
  perceptual_threshold : Double
}

///|
pub fn visual_samples_for_target(target : String) -> Array[VisualSample] raise {
  let manifest = read_text_file(visual_manifest_path())
  if manifest.length() == 0 {
    @test.fail(
      "visual regression manifest is missing or empty: \{visual_manifest_path()}",
    )
  }
  parse_visual_manifest(manifest, target)
}

///|
fn visual_manifest_path() -> String {
  "moon/rhodonite_examples/src/visual_regression/visual_samples.tsv"
}

///|
fn parse_visual_manifest(
  manifest : String,
  target : String,
) -> Array[VisualSample] raise {
  let samples : Array[VisualSample] = []
  let lines = split_ascii(manifest, '\n')
  for i = 0; i < lines.length(); i = i + 1 {
    let line = trim_ascii(lines[i])
    if line.length() == 0 ||
      line.code_unit_at(0) == Char::to_int('#').to_uint16() {
      continue
    }
    let fields = split_ascii(line, '\t')
    if fields.length() != 6 {
      @test.fail(
        "visual regression manifest line \{i + 1} must have 6 TSV fields: \{line}",
      )
    }
    let sample_target = trim_ascii(fields[0])
    if sample_target == target {
      samples.push({
        target: sample_target,
        id: trim_ascii(fields[1]),
        name: trim_ascii(fields[2]),
        filename: trim_ascii(fields[3]),
        max_mismatch_rate: parse_decimal(
          trim_ascii(fields[4]),
          field="max_mismatch_rate",
        ),
        perceptual_threshold: parse_decimal(
          trim_ascii(fields[5]),
          field="perceptual_threshold",
        ),
      })
    }
  }
  if samples.length() == 0 {
    @test.fail(
      "visual regression manifest has no samples for target: \{target}",
    )
  }
  samples
}

///|
fn split_ascii(s : String, delimiter : Char) -> Array[String] {
  let out : Array[String] = []
  let buf = StringBuilder::new(size_hint=0)
  let delimiter_code = Char::to_int(delimiter).to_uint16()
  for i = 0; i < s.length(); i = i + 1 {
    let code_unit = s.code_unit_at(i)
    if code_unit == delimiter_code {
      out.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(UInt16::unsafe_to_char(code_unit))
    }
  }
  out.push(buf.to_string())
  out
}

///|
fn trim_ascii(s : String) -> String {
  let mut start = 0
  let mut end = s.length()
  while start < end && is_ascii_space(s.code_unit_at(start)) {
    start = start + 1
  }
  while end > start && is_ascii_space(s.code_unit_at(end - 1)) {
    end = end - 1
  }
  substring_ascii(s, start, end)
}

///|
fn is_ascii_space(code_unit : UInt16) -> Bool {
  code_unit == 9U.to_uint16() ||
  code_unit == 10U.to_uint16() ||
  code_unit == 13U.to_uint16() ||
  code_unit == 32U.to_uint16()
}

///|
fn substring_ascii(s : String, start : Int, end : Int) -> String {
  let buf = StringBuilder::new(size_hint=end - start)
  for i = start; i < end; i = i + 1 {
    buf.write_char(UInt16::unsafe_to_char(s.code_unit_at(i)))
  }
  buf.to_string()
}

///|
fn parse_decimal(s : String, field~ : String) -> Double raise {
  if s.length() == 0 {
    @test.fail("visual regression manifest \{field} is empty")
  }
  let mut whole = 0
  let mut fraction = 0
  let mut scale = 1
  let mut seen_dot = false
  for i = 0; i < s.length(); i = i + 1 {
    let code = s.code_unit_at(i).to_int()
    if code == Char::to_int('.') {
      if seen_dot {
        @test.fail("visual regression manifest \{field} is not a decimal: \{s}")
      }
      seen_dot = true
      continue
    }
    if code < Char::to_int('0') || code > Char::to_int('9') {
      @test.fail("visual regression manifest \{field} is not a decimal: \{s}")
    }
    let digit = code - Char::to_int('0')
    if seen_dot {
      fraction = fraction * 10 + digit
      scale = scale * 10
    } else {
      whole = whole * 10 + digit
    }
  }
  whole.to_double() + fraction.to_double() / scale.to_double()
}
