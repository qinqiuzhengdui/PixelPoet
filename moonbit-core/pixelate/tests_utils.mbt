// Extended Image Utilities Tests
// This file tests blending, compositing, gamma correction, and sorting helper functions.

///|
test "blend_rgb_basic" {
  let c1 : RgbColor = { r: 100.0, g: 100.0, b: 100.0 }
  let c2 : RgbColor = { r: 200.0, g: 200.0, b: 200.0 }
  let b = blend_rgb(c1, c2, 0.5)
  assert_eq(b.r, 150.0)
  assert_eq(b.g, 150.0)
  assert_eq(b.b, 150.0)
}

///|
test "blend_rgb_clamp" {
  let c1 : RgbColor = { r: 0.0, g: 0.0, b: 0.0 }
  let c2 : RgbColor = { r: 255.0, g: 255.0, b: 255.0 }
  let b_low = blend_rgb(c1, c2, -1.0)
  let b_high = blend_rgb(c1, c2, 2.0)
  assert_eq(b_low.r, 0.0)
  assert_eq(b_high.r, 255.0)
}

///|
test "composite_source_over_transparent" {
  let out = composite_source_over(255, 0, 0, 0, 0, 0, 255, 255)
  assert_eq(out.r, 0.0)
  assert_eq(out.g, 0.0)
  assert_eq(out.b, 255.0)
}

///|
test "composite_source_over_opaque" {
  let out = composite_source_over(255, 0, 0, 255, 0, 0, 255, 255)
  assert_eq(out.r, 255.0)
  assert_eq(out.g, 0.0)
  assert_eq(out.b, 0.0)
}

///|
test "gamma_correct_value_limits" {
  let low = gamma_correct_value(-10.0, 2.2)
  let high = gamma_correct_value(300.0, 2.2)
  assert_eq(low, 0.0)
  assert_eq(high, 255.0)
}

///|
test "srgb_luts" {
  let dec = get_srgb_decoding_lut()
  let enc = get_srgb_encoding_lut()
  assert_eq(dec.length(), 256)
  assert_eq(enc.length(), 256)
  assert_eq(dec[0], 0.0)
  assert_eq(dec[255], 255.0)
}

///|
test "sort_palette_brightness" {
  let pal = [0xFFFFFF, 0x000000, 0x808080]
  let sorted = sort_palette_by_brightness(pal)
  assert_eq(sorted[0], 0x000000) // Black is darkest
  assert_eq(sorted[1], 0x808080) // Grey is medium
  assert_eq(sorted[2], 0xFFFFFF) // White is brightest
}

///|
test "blend_rgb_detailed" {
  let c1 : RgbColor = { r: 50.0, g: 50.0, b: 50.0 }
  let c2 : RgbColor = { r: 150.0, g: 150.0, b: 150.0 }
  let b1 = blend_rgb(c1, c2, 0.25)
  let b2 = blend_rgb(c1, c2, 0.75)
  assert_eq(b1.r, 75.0)
  assert_eq(b2.r, 125.0)
}

///|
test "composite_source_over_semitransparent" {
  let out = composite_source_over(255, 0, 0, 128, 0, 0, 255, 255)
  // sa = 128/255 = 0.50196
  // output is roughly 128 R, 127 B
  assert_true(out.r > 127.0 && out.r < 129.0)
  assert_true(out.b > 126.0 && out.b < 128.0)
}

///|
test "gamma_correct_detailed" {
  let v1 = gamma_correct_value(128.0, 1.0)
  assert_true(abs_diff(v1, 128.0) < 0.001)
}

///|
test "lerp_double_test" {
  let v = lerp_double(10.0, 20.0, 0.5)
  assert_eq(v, 15.0)
}
