// Color Space Models and Conversions
// This module provides representations of various color models (RGB, HSL, HSV, CMYK, YUV, XYZ, CIE L*a*b*, CIE LCh)
// and high-precision conversion algorithms between them, as well as CIE delta E distance metrics.

///|
pub struct RgbColor {
  pub r : Double // [0.0, 255.0]
  pub g : Double // [0.0, 255.0]
  pub b : Double // [0.0, 255.0]
}

///|
pub struct HslColor {
  pub h : Double // [0.0, 360.0)
  pub s : Double // [0.0, 1.0]
  pub l : Double // [0.0, 1.0]
}

///|
pub struct HsvColor {
  pub h : Double // [0.0, 360.0)
  pub s : Double // [0.0, 1.0]
  pub v : Double // [0.0, 1.0]
}

///|
pub struct CmykColor {
  pub c : Double // [0.0, 1.0]
  pub m : Double // [0.0, 1.0]
  pub y : Double // [0.0, 1.0]
  pub k : Double // [0.0, 1.0]
}

///|
pub struct YuvColor {
  pub y : Double // [0.0, 1.0]
  pub u : Double // [-0.436, 0.436]
  pub v : Double // [-0.615, 0.615]
}

///|
pub struct XyzColor {
  pub x : Double // [0.0, 95.047]
  pub y : Double // [0.0, 100.0]
  pub z : Double // [0.0, 108.883]
}

///|
pub struct LabColor {
  pub l : Double // [0.0, 100.0]
  pub a : Double // [-128.0, 127.0]
  pub b : Double // [-128.0, 127.0]
}

///|
pub struct LchColor {
  pub l : Double // [0.0, 100.0]
  pub c : Double // [0.0, 150.0]
  pub h : Double // [0.0, 360.0)
}

// ----------------------------------------------------
// Math utilities
// ----------------------------------------------------

///|
fn min3(a : Double, b : Double, c : Double) -> Double {
  let mut m = a
  if b < m {
    m = b
  }
  if c < m {
    m = c
  }
  m
}

///|
fn max3(a : Double, b : Double, c : Double) -> Double {
  let mut m = a
  if b > m {
    m = b
  }
  if c > m {
    m = c
  }
  m
}

///|
fn abs(val : Double) -> Double {
  if val < 0.0 {
    -val
  } else {
    val
  }
}

///|
fn sqr(val : Double) -> Double {
  val * val
}

///|
fn deg_to_rad(deg : Double) -> Double {
  deg * 3.141592653589793 / 180.0
}

///|
fn rad_to_deg(rad : Double) -> Double {
  rad * 180.0 / 3.141592653589793
}

// ----------------------------------------------------
// RGB & HSL Conversions
// ----------------------------------------------------

///|
pub fn rgb_to_hsl(rgb : RgbColor) -> HslColor {
  let r = rgb.r / 255.0
  let g = rgb.g / 255.0
  let b = rgb.b / 255.0

  let min_val = min3(r, g, b)
  let max_val = max3(r, g, b)
  let delta = max_val - min_val

  let l = (max_val + min_val) / 2.0

  if delta == 0.0 {
    return { h: 0.0, s: 0.0, l }
  }

  let s = if l <= 0.5 {
    delta / (max_val + min_val)
  } else {
    delta / (2.0 - max_val - min_val)
  }

  let mut h = 0.0
  if max_val == r {
    h = (g - b) / delta
    if h < 0.0 {
      h = h + 6.0
    }
  } else if max_val == g {
    h = (b - r) / delta + 2.0
  } else {
    h = (r - g) / delta + 4.0
  }
  h = h * 60.0

  { h, s, l }
}

///|
fn hue_to_rgb(p : Double, q : Double, t : Double) -> Double {
  let mut t_adj = t
  if t_adj < 0.0 {
    t_adj = t_adj + 1.0
  }
  if t_adj > 1.0 {
    t_adj = t_adj - 1.0
  }
  if t_adj < 1.0 / 6.0 {
    return p + (q - p) * 6.0 * t_adj
  }
  if t_adj < 1.0 / 2.0 {
    return q
  }
  if t_adj < 2.0 / 3.0 {
    return p + (q - p) * (2.0 / 3.0 - t_adj) * 6.0
  }
  p
}

///|
pub fn hsl_to_rgb(hsl : HslColor) -> RgbColor {
  if hsl.s == 0.0 {
    let grey = hsl.l * 255.0
    return { r: grey, g: grey, b: grey }
  }

  let q = if hsl.l < 0.5 {
    hsl.l * (1.0 + hsl.s)
  } else {
    hsl.l + hsl.s - hsl.l * hsl.s
  }
  let p = 2.0 * hsl.l - q

  let h_norm = hsl.h / 360.0

  let r = hue_to_rgb(p, q, h_norm + 1.0 / 3.0) * 255.0
  let g = hue_to_rgb(p, q, h_norm) * 255.0
  let b = hue_to_rgb(p, q, h_norm - 1.0 / 3.0) * 255.0

  { r, g, b }
}

// ----------------------------------------------------
// RGB & HSV Conversions
// ----------------------------------------------------

///|
pub fn rgb_to_hsv(rgb : RgbColor) -> HsvColor {
  let r = rgb.r / 255.0
  let g = rgb.g / 255.0
  let b = rgb.b / 255.0

  let min_val = min3(r, g, b)
  let max_val = max3(r, g, b)
  let delta = max_val - min_val

  let v = max_val

  if max_val == 0.0 {
    return { h: 0.0, s: 0.0, v: 0.0 }
  }

  let s = delta / max_val

  if delta == 0.0 {
    return { h: 0.0, s: 0.0, v }
  }

  let mut h = 0.0
  if max_val == r {
    h = (g - b) / delta
    if h < 0.0 {
      h = h + 6.0
    }
  } else if max_val == g {
    h = (b - r) / delta + 2.0
  } else {
    h = (r - g) / delta + 4.0
  }
  h = h * 60.0

  { h, s, v }
}

///|
pub fn hsv_to_rgb(hsv : HsvColor) -> RgbColor {
  let h_div = hsv.h / 60.0
  let i = h_div.to_int()
  let f = h_div - i.to_double()

  let p = hsv.v * (1.0 - hsv.s)
  let q = hsv.v * (1.0 - hsv.s * f)
  let t = hsv.v * (1.0 - hsv.s * (1.0 - f))

  let v_scale = hsv.v * 255.0
  let p_scale = p * 255.0
  let q_scale = q * 255.0
  let t_scale = t * 255.0

  match i % 6 {
    0 => { r: v_scale, g: t_scale, b: p_scale }
    1 => { r: q_scale, g: v_scale, b: p_scale }
    2 => { r: p_scale, g: v_scale, b: t_scale }
    3 => { r: p_scale, g: q_scale, b: v_scale }
    4 => { r: t_scale, g: p_scale, b: v_scale }
    _ => { r: v_scale, g: p_scale, b: q_scale }
  }
}

// ----------------------------------------------------
// RGB & CMYK Conversions
// ----------------------------------------------------

///|
pub fn rgb_to_cmyk(rgb : RgbColor) -> CmykColor {
  let r = rgb.r / 255.0
  let g = rgb.g / 255.0
  let b = rgb.b / 255.0

  let k = 1.0 - max3(r, g, b)
  if k == 1.0 {
    return { c: 0.0, m: 0.0, y: 0.0, k: 1.0 }
  }

  let c = (1.0 - r - k) / (1.0 - k)
  let m = (1.0 - g - k) / (1.0 - k)
  let y = (1.0 - b - k) / (1.0 - k)

  { c, m, y, k }
}

///|
pub fn cmyk_to_rgb(cmyk : CmykColor) -> RgbColor {
  let r = 255.0 * (1.0 - cmyk.c) * (1.0 - cmyk.k)
  let g = 255.0 * (1.0 - cmyk.m) * (1.0 - cmyk.k)
  let b = 255.0 * (1.0 - cmyk.y) * (1.0 - cmyk.k)
  { r, g, b }
}

// ----------------------------------------------------
// RGB & YUV Conversions
// ----------------------------------------------------

///|
pub fn rgb_to_yuv(rgb : RgbColor) -> YuvColor {
  let r = rgb.r / 255.0
  let g = rgb.g / 255.0
  let b = rgb.b / 255.0

  let y = 0.299 * r + 0.587 * g + 0.114 * b
  let u = -0.14713 * r - 0.28886 * g + 0.436 * b
  let v = 0.615 * r - 0.51499 * g - 0.10001 * b

  { y, u, v }
}

///|
pub fn yuv_to_rgb(yuv : YuvColor) -> RgbColor {
  let r = (yuv.y + 1.13983 * yuv.v) * 255.0
  let g = (yuv.y - 0.39465 * yuv.u - 0.58060 * yuv.v) * 255.0
  let b = (yuv.y + 2.03211 * yuv.u) * 255.0

  { r, g, b }
}

// ----------------------------------------------------
// RGB & XYZ & Lab Conversions
// ----------------------------------------------------

///|
pub fn rgb_to_xyz(rgb : RgbColor) -> XyzColor {
  let mut r = rgb.r / 255.0
  let mut g = rgb.g / 255.0
  let mut b = rgb.b / 255.0

  r = if r > 0.04045 { @math.pow((r + 0.055) / 1.055, 2.4) } else { r / 12.92 }
  g = if g > 0.04045 { @math.pow((g + 0.055) / 1.055, 2.4) } else { g / 12.92 }
  b = if b > 0.04045 { @math.pow((b + 0.055) / 1.055, 2.4) } else { b / 12.92 }

  r = r * 100.0
  g = g * 100.0
  b = b * 100.0

  let x = r * 0.4124 + g * 0.3576 + b * 0.1805
  let y = r * 0.2126 + g * 0.7152 + b * 0.0722
  let z = r * 0.0193 + g * 0.1192 + b * 0.9505

  { x, y, z }
}

///|
pub fn xyz_to_rgb(xyz : XyzColor) -> RgbColor {
  let x = xyz.x / 100.0
  let y = xyz.y / 100.0
  let z = xyz.z / 100.0

  let r_linear = x * 3.2406 + y * -1.5372 + z * -0.4986
  let g_linear = x * -0.9689 + y * 1.8758 + z * 0.0415
  let b_linear = x * 0.0557 + y * -0.2040 + z * 1.0570

  let r_c = if r_linear < 0.0 { 0.0 } else { r_linear }
  let g_c = if g_linear < 0.0 { 0.0 } else { g_linear }
  let b_c = if b_linear < 0.0 { 0.0 } else { b_linear }

  let r = if r_c > 0.0031308 {
    1.055 * @math.pow(r_c, 1.0 / 2.4) - 0.055
  } else {
    12.92 * r_c
  }
  let g = if g_c > 0.0031308 {
    1.055 * @math.pow(g_c, 1.0 / 2.4) - 0.055
  } else {
    12.92 * g_c
  }
  let b = if b_c > 0.0031308 {
    1.055 * @math.pow(b_c, 1.0 / 2.4) - 0.055
  } else {
    12.92 * b_c
  }

  { r: r * 255.0, g: g * 255.0, b: b * 255.0 }
}

///|
fn f_xyz_to_lab(t : Double) -> Double {
  if t > 0.008856451679035631 {
    @math.pow(t, 1.0 / 3.0)
  } else {
    7.787037037037037 * t + 16.0 / 116.0
  }
}

///|
pub fn xyz_to_lab(xyz : XyzColor) -> LabColor {
  // D65 reference white points
  let x_n = 95.047
  let y_n = 100.0
  let z_n = 108.883

  let fx = f_xyz_to_lab(xyz.x / x_n)
  let fy = f_xyz_to_lab(xyz.y / y_n)
  let fz = f_xyz_to_lab(xyz.z / z_n)

  let l = 116.0 * fy - 16.0
  let a = 500.0 * (fx - fy)
  let b = 200.0 * (fy - fz)

  { l, a, b }
}

///|
fn f_lab_to_xyz(t : Double) -> Double {
  let t3 = t * t * t
  if t3 > 0.008856451679035631 {
    t3
  } else {
    (t - 16.0 / 116.0) / 7.787037037037037
  }
}

///|
pub fn lab_to_xyz(lab : LabColor) -> XyzColor {
  let x_n = 95.047
  let y_n = 100.0
  let z_n = 108.883

  let fy = (lab.l + 16.0) / 116.0
  let fx = lab.a / 500.0 + fy
  let fz = fy - lab.b / 200.0

  let x = f_lab_to_xyz(fx) * x_n
  let y = f_lab_to_xyz(fy) * y_n
  let z = f_lab_to_xyz(fz) * z_n

  { x, y, z }
}

///|
pub fn rgb_to_lab(rgb : RgbColor) -> LabColor {
  xyz_to_lab(rgb_to_xyz(rgb))
}

///|
pub fn lab_to_rgb(lab : LabColor) -> RgbColor {
  xyz_to_rgb(lab_to_xyz(lab))
}

// ----------------------------------------------------
// Lab & LCh Conversions
// ----------------------------------------------------

///|
pub fn lab_to_lch(lab : LabColor) -> LchColor {
  let c = (sqr(lab.a) + sqr(lab.b)).sqrt()
  let mut h_rad = @math.atan2(lab.b, lab.a)
  if h_rad < 0.0 {
    h_rad = h_rad + 2.0 * 3.141592653589793
  }
  let h = rad_to_deg(h_rad)
  { l: lab.l, c, h }
}

///|
pub fn lch_to_lab(lch : LchColor) -> LabColor {
  let h_rad = deg_to_rad(lch.h)
  let a = lch.c * @math.cos(h_rad)
  let b = lch.c * @math.sin(h_rad)
  { l: lch.l, a, b }
}

// ----------------------------------------------------
// Color Differences (Delta E)
// ----------------------------------------------------

///|
pub fn delta_e_76(c1 : LabColor, c2 : LabColor) -> Double {
  (sqr(c1.l - c2.l) + sqr(c1.a - c2.a) + sqr(c1.b - c2.b)).sqrt()
}

///|
pub fn delta_e_94(c1 : LabColor, c2 : LabColor) -> Double {
  let dl = c1.l - c2.l
  let da = c1.a - c2.a
  let db = c1.b - c2.b

  let c1_val = (sqr(c1.a) + sqr(c1.b)).sqrt()
  let c2_val = (sqr(c2.a) + sqr(c2.b)).sqrt()
  let dc = c1_val - c2_val

  let mut dh_sqr = sqr(da) + sqr(db) - sqr(dc)
  if dh_sqr < 0.0 {
    dh_sqr = 0.0
  }

  let k_l = 1.0
  let k_c = 1.0
  let k_h = 1.0

  let s_l = 1.0
  let s_c = 1.0 + 0.045 * c1_val
  let s_h = 1.0 + 0.015 * c1_val

  let term_l = dl / (k_l * s_l)
  let term_c = dc / (k_c * s_c)
  let term_h_sqr = dh_sqr / sqr(k_h * s_h)

  (sqr(term_l) + sqr(term_c) + term_h_sqr).sqrt()
}

///|
pub fn delta_e_00(c1 : LabColor, c2 : LabColor) -> Double {
  let l1 = c1.l
  let a1 = c1.a
  let b1 = c1.b
  let l2 = c2.l
  let a2 = c2.a
  let b2 = c2.b

  let c1_val = (sqr(a1) + sqr(b1)).sqrt()
  let c2_val = (sqr(a2) + sqr(b2)).sqrt()

  let c_bar = (c1_val + c2_val) / 2.0
  let c_bar7 = @math.pow(c_bar, 7.0)
  let g = 0.5 * (1.0 - (c_bar7 / (c_bar7 + 6103515625.0)).sqrt()) // 25^7 = 6103515625

  let a1_prime = a1 * (1.0 + g)
  let a2_prime = a2 * (1.0 + g)

  let c1_prime = (sqr(a1_prime) + sqr(b1)).sqrt()
  let c2_prime = (sqr(a2_prime) + sqr(b2)).sqrt()

  let mut h1 = rad_to_deg(@math.atan2(b1, a1_prime))
  if h1 < 0.0 {
    h1 = h1 + 360.0
  }
  let mut h2 = rad_to_deg(@math.atan2(b2, a2_prime))
  if h2 < 0.0 {
    h2 = h2 + 360.0
  }

  let delta_l = l2 - l1
  let delta_c = c2_prime - c1_prime

  let mut delta_h = h2 - h1
  if abs(delta_h) > 180.0 {
    if h2 <= h1 {
      delta_h = delta_h + 360.0
    } else {
      delta_h = delta_h - 360.0
    }
  }

  let delta_h_prime = 2.0 *
    (c1_prime * c2_prime).sqrt() *
    @math.sin(deg_to_rad(delta_h / 2.0))

  let l_bar = (l1 + l2) / 2.0
  let c_bar_prime = (c1_prime + c2_prime) / 2.0

  let mut h_bar = (h1 + h2) / 2.0
  if abs(h1 - h2) > 180.0 {
    if h1 + h2 < 360.0 {
      h_bar = h_bar + 180.0
    } else {
      h_bar = h_bar - 180.0
    }
  }

  let t = 1.0 -
    0.17 * @math.cos(deg_to_rad(h_bar - 30.0)) +
    0.24 * @math.cos(deg_to_rad(2.0 * h_bar)) +
    0.32 * @math.cos(deg_to_rad(3.0 * h_bar + 6.0)) -
    0.20 * @math.cos(deg_to_rad(4.0 * h_bar - 63.0))

  let s_l = 1.0 + 0.015 * sqr(l_bar - 50.0) / (20.0 + sqr(l_bar - 50.0)).sqrt()
  let s_c = 1.0 + 0.045 * c_bar_prime
  let s_h = 1.0 + 0.015 * c_bar_prime * t

  let delta_theta = 30.0 * @math.exp(-sqr((h_bar - 275.0) / 25.0))
  let c_bar_prime7 = @math.pow(c_bar_prime, 7.0)
  let r_c = 2.0 * (c_bar_prime7 / (c_bar_prime7 + 6103515625.0)).sqrt()
  let r_t = -r_c * @math.sin(deg_to_rad(2.0 * delta_theta))

  let k_l = 1.0
  let k_c = 1.0
  let k_h = 1.0

  let term_l = delta_l / (k_l * s_l)
  let term_c = delta_c / (k_c * s_c)
  let term_h = delta_h_prime / (k_h * s_h)

  (sqr(term_l) + sqr(term_c) + sqr(term_h) + r_t * term_c * term_h).sqrt()
}
