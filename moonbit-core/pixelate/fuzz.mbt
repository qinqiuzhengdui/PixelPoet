// Property-Based Testing and Fuzzing Utilities
// This module provides pseudo-random generation and round-trip fuzz validation for:
// - Color space conversions
// - Resizing and kernel filters
// - Matrix algebra properties

///|
pub struct LcgRandom {
  pub mut seed : Int64
}

///|
pub fn make_random(s : Int64) -> LcgRandom {
  { seed: s }
}

///|
pub fn LcgRandom::next_int(
  self : LcgRandom,
  min_val : Int,
  max_val : Int,
) -> Int {
  // LCG parameters
  let a : Int64 = 6364136223846793005
  let c : Int64 = 1442695040888963407
  self.seed = self.seed * a + c

  let val = (self.seed >> 33).to_int()
  let abs_val = if val < 0 { -val } else { val }
  let range = max_val - min_val + 1
  min_val + abs_val % range
}

///|
pub fn LcgRandom::next_double(self : LcgRandom) -> Double {
  let a : Int64 = 6364136223846793005
  let c : Int64 = 1442695040888963407
  self.seed = self.seed * a + c

  let val = (self.seed >> 11) & 0x1FFFFFFFFFFFFF // 53 bits
  val.to_double() / 9007199254740992.0 // 2^53
}

// Generates a mock RGBA byte buffer with random pixel values

///|
pub fn LcgRandom::generate_random_rgba(self : LcgRandom, size : Int) -> Bytes {
  let res_arr = Array::make(size * 4, (0).to_byte())
  for i = 0; i < size * 4; i = i + 4 {
    res_arr[i] = self.next_int(0, 255).to_byte() // R
    res_arr[i + 1] = self.next_int(0, 255).to_byte() // G
    res_arr[i + 2] = self.next_int(0, 255).to_byte() // B
    res_arr[i + 3] = (255).to_byte() // A
  }
  make_bytes(size * 4, fn(i) { res_arr[i] })
}

///|
fn abs_diff(d1 : Double, d2 : Double) -> Double {
  if d1 < d2 {
    d2 - d1
  } else {
    d1 - d2
  }
}

// ----------------------------------------------------
// Fuzz Testing Rules
// ----------------------------------------------------

///|
test "fuzz_rgb_hsl_roundtrip" {
  let rng = make_random(12345L)
  for i = 0; i < 200; i = i + 1 {
    let r = rng.next_double() * 255.0
    let g = rng.next_double() * 255.0
    let b = rng.next_double() * 255.0

    let original : RgbColor = { r, g, b }
    let hsl = rgb_to_hsl(original)
    let back = hsl_to_rgb(hsl)

    // Accept small deviation in double division
    assert_true(abs_diff(original.r, back.r) < 1.0)
    assert_true(abs_diff(original.g, back.g) < 1.0)
    assert_true(abs_diff(original.b, back.b) < 1.0)
  }
}

///|
test "fuzz_rgb_hsv_roundtrip" {
  let rng = make_random(54321L)
  for i = 0; i < 200; i = i + 1 {
    let r = rng.next_double() * 255.0
    let g = rng.next_double() * 255.0
    let b = rng.next_double() * 255.0

    let original : RgbColor = { r, g, b }
    let hsv = rgb_to_hsv(original)
    let back = hsv_to_rgb(hsv)

    assert_true(abs_diff(original.r, back.r) < 1.0)
    assert_true(abs_diff(original.g, back.g) < 1.0)
    assert_true(abs_diff(original.b, back.b) < 1.0)
  }
}

///|
test "fuzz_rgb_lab_roundtrip" {
  let rng = make_random(987654L)
  for i = 0; i < 200; i = i + 1 {
    let r = rng.next_double() * 255.0
    let g = rng.next_double() * 255.0
    let b = rng.next_double() * 255.0

    let original : RgbColor = { r, g, b }
    let lab = rgb_to_lab(original)
    let back = lab_to_rgb(lab)

    let diff_r = abs_diff(original.r, back.r)
    let diff_g = abs_diff(original.g, back.g)
    let diff_b = abs_diff(original.b, back.b)
    if diff_r >= 10.0 || diff_g >= 10.0 || diff_b >= 10.0 {
      println(
        "i=\{i}: original=(\{original.r}, \{original.g}, \{original.b}), lab=(\{lab.l}, \{lab.a}, \{lab.b}), back=(\{back.r}, \{back.g}, \{back.b})",
      )
      assert_true(false)
    }
  }
}

///|
test "fuzz_matrix_algebra" {
  let rng = make_random(11111L)
  for i = 0; i < 50; i = i + 1 {
    let dim = rng.next_int(2, 5)
    let m1 = make_matrix(dim, dim)
    let m2 = make_matrix(dim, dim)

    for r = 0; r < dim; r = r + 1 {
      for c = 0; c < dim; c = c + 1 {
        m1.matrix_set(r, c, rng.next_double() * 10.0)
        m2.matrix_set(r, c, rng.next_double() * 10.0)
      }
    }

    // Addition & subtraction identity: (A + B) - B = A
    match matrix_add(m1, m2) {
      Some(sum_m) =>
        match matrix_sub(sum_m, m2) {
          Some(back_m) =>
            for r = 0; r < dim; r = r + 1 {
              for c = 0; c < dim; c = c + 1 {
                let diff = abs_diff(
                  m1.matrix_get(r, c),
                  back_m.matrix_get(r, c),
                )
                assert_true(diff < 0.000000001)
              }
            }
          None => assert_true(false)
        }
      None => assert_true(false)
    }
  }
}

///|
test "fuzz_filters_integrity" {
  let rng = make_random(99999L)
  let w = 10
  let h = 10
  let rgba = rng.generate_random_rgba(w * h)

  // Test all filters to check they don't crash
  let gray1 = filter_grayscale_luminance(rgba)
  let gray2 = filter_grayscale_bt601(rgba)
  let gray3 = filter_grayscale_average(rgba)
  let sepia = filter_sepia(rgba)
  let invert = filter_invert(rgba)
  let bright = filter_adjust_brightness(rgba, 15)
  let contrast = filter_adjust_contrast(rgba, 15.0)

  assert_eq(gray1.length(), w * h * 4)
  assert_eq(gray2.length(), w * h * 4)
  assert_eq(gray3.length(), w * h * 4)
  assert_eq(sepia.length(), w * h * 4)
  assert_eq(invert.length(), w * h * 4)
  assert_eq(bright.length(), w * h * 4)
  assert_eq(contrast.length(), w * h * 4)
}
