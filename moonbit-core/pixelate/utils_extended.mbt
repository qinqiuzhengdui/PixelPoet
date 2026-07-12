// Extended Image Processing Utilities
// This module provides advanced helper functions for color blending, 
// alpha compositing, gamma correction, and palette organization.

// Linear interpolation between two double values

///|
fn lerp_double(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

///|
pub fn make_bytes(length : Int, value : (Int) -> Byte) -> Bytes {
  Bytes::makei(length, fn(i) { value(i) }) catch {
    _ => []
  }
}

// Linearly blend two RGB colors

///|
pub fn blend_rgb(c1 : RgbColor, c2 : RgbColor, ratio : Double) -> RgbColor {
  let r_clamped = if ratio < 0.0 {
    0.0
  } else if ratio > 1.0 {
    1.0
  } else {
    ratio
  }
  {
    r: lerp_double(c1.r, c2.r, r_clamped),
    g: lerp_double(c1.g, c2.g, r_clamped),
    b: lerp_double(c1.b, c2.b, r_clamped),
  }
}

// Alpha compositing (Porter-Duff source-over-destination) for RGBA values

///|
pub fn composite_source_over(
  src_r : Int,
  src_g : Int,
  src_b : Int,
  src_a : Int,
  dst_r : Int,
  dst_g : Int,
  dst_b : Int,
  dst_a : Int,
) -> RgbColor {
  let sa = src_a.to_double() / 255.0
  let da = dst_a.to_double() / 255.0

  let out_a = sa + da * (1.0 - sa)

  if out_a == 0.0 {
    return { r: 0.0, g: 0.0, b: 0.0 }
  }

  let sr = src_r.to_double()
  let sg = src_g.to_double()
  let sb = src_b.to_double()

  let dr = dst_r.to_double()
  let dg = dst_g.to_double()
  let db = dst_b.to_double()

  let r = (sr * sa + dr * da * (1.0 - sa)) / out_a
  let g = (sg * sa + dg * da * (1.0 - sa)) / out_a
  let b = (sb * sa + db * da * (1.0 - sa)) / out_a

  { r, g, b }
}

// Gamma correction function (applies encoding gamma or decoding gamma)

///|
pub fn gamma_correct_value(val : Double, gamma : Double) -> Double {
  if val <= 0.0 {
    return 0.0
  }
  if val >= 255.0 {
    return 255.0
  }
  let normalized = val / 255.0
  let corrected = @math.pow(normalized, gamma)
  corrected * 255.0
}

// Pre-computed lookup table (LUT) for sRGB decoding gamma (gamma = 2.2)

///|
pub fn get_srgb_decoding_lut() -> Array[Double] {
  let lut = Array::make(256, 0.0)
  for i = 0; i < 256; i = i + 1 {
    lut[i] = gamma_correct_value(i.to_double(), 2.2)
  }
  lut
}

// Pre-computed lookup table (LUT) for sRGB encoding gamma (gamma = 1.0 / 2.2)

///|
pub fn get_srgb_encoding_lut() -> Array[Double] {
  let lut = Array::make(256, 0.0)
  for i = 0; i < 256; i = i + 1 {
    lut[i] = gamma_correct_value(i.to_double(), 1.0 / 2.2)
  }
  lut
}

// Sorts a list of hex colors by their perceived brightness

///|
pub fn sort_palette_by_brightness(palette : Array[Int]) -> Array[Int] {
  let sorted = []
  for i = 0; i < palette.length(); i = i + 1 {
    sorted.push(palette[i])
  }

  sorted.sort_by(fn(c1, c2) {
    let r1 = ((c1 >> 16) & 0xFF).to_double()
    let g1 = ((c1 >> 8) & 0xFF).to_double()
    let b1 = (c1 & 0xFF).to_double()

    let r2 = ((c2 >> 16) & 0xFF).to_double()
    let g2 = ((c2 >> 8) & 0xFF).to_double()
    let b2 = (c2 & 0xFF).to_double()

    // Perceived brightness coefficients
    let l1 = 0.299 * r1 + 0.587 * g1 + 0.114 * b1
    let l2 = 0.299 * r2 + 0.587 * g2 + 0.114 * b2

    if l1 < l2 {
      -1
    } else if l1 > l2 {
      1
    } else {
      0
    }
  })

  sorted
}
