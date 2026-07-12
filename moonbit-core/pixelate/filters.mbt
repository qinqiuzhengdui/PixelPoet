// Image Processing Filters and Convolutions
// This module provides custom kernel convolutions and standard photographic filters.

///|
pub fn apply_kernel(
  rgba : Bytes,
  w : Int,
  h : Int,
  kernel : Array[Double],
  k_size : Int,
  factor : Double,
  bias : Double,
) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())
  let half = k_size / 2

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let mut r_sum = 0.0
      let mut g_sum = 0.0
      let mut b_sum = 0.0

      for ky = 0; ky < k_size; ky = ky + 1 {
        let py = y + ky - half
        let py_clamped = if py < 0 { 0 } else if py >= h { h - 1 } else { py }
        for kx = 0; kx < k_size; kx = kx + 1 {
          let px = x + kx - half
          let px_clamped = if px < 0 { 0 } else if px >= w { w - 1 } else { px }

          let src_idx = (py_clamped * w + px_clamped) * 4
          let w_val = kernel[ky * k_size + kx]

          r_sum = r_sum + rgba[src_idx].to_int().to_double() * w_val
          g_sum = g_sum + rgba[src_idx + 1].to_int().to_double() * w_val
          b_sum = b_sum + rgba[src_idx + 2].to_int().to_double() * w_val
        }
      }

      let out_idx = (y * w + x) * 4
      let r_val = (r_sum * factor + bias).to_int()
      let g_val = (g_sum * factor + bias).to_int()
      let b_val = (b_sum * factor + bias).to_int()

      res_arr[out_idx] = (if r_val < 0 {
        0
      } else if r_val > 255 {
        255
      } else {
        r_val
      }).to_byte()
      res_arr[out_idx + 1] = (if g_val < 0 {
        0
      } else if g_val > 255 {
        255
      } else {
        g_val
      }).to_byte()
      res_arr[out_idx + 2] = (if b_val < 0 {
        0
      } else if b_val > 255 {
        255
      } else {
        b_val
      }).to_byte()
      res_arr[out_idx + 3] = rgba[out_idx + 3] // preserve alpha
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}

///|
pub fn filter_grayscale_luminance(rgba : Bytes) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 4 {
    let r = rgba[i].to_int().to_double()
    let g = rgba[i + 1].to_int().to_double()
    let b = rgba[i + 2].to_int().to_double()

    // ITU-R BT.709 standard formula
    let gray = 0.2126 * r + 0.7152 * g + 0.0722 * b
    let gray_byte = gray.to_int().to_byte()

    res_arr[i] = gray_byte
    res_arr[i + 1] = gray_byte
    res_arr[i + 2] = gray_byte
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

///|
pub fn filter_grayscale_bt601(rgba : Bytes) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 4 {
    let r = rgba[i].to_int().to_double()
    let g = rgba[i + 1].to_int().to_double()
    let b = rgba[i + 2].to_int().to_double()

    // ITU-R BT.601 standard formula
    let gray = 0.299 * r + 0.587 * g + 0.114 * b
    let gray_byte = gray.to_int().to_byte()

    res_arr[i] = gray_byte
    res_arr[i + 1] = gray_byte
    res_arr[i + 2] = gray_byte
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

///|
pub fn filter_grayscale_average(rgba : Bytes) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 4 {
    let sum = rgba[i].to_int() + rgba[i + 1].to_int() + rgba[i + 2].to_int()
    let gray = (sum / 3).to_byte()
    res_arr[i] = gray
    res_arr[i + 1] = gray
    res_arr[i + 2] = gray
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

///|
pub fn filter_sepia(rgba : Bytes) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 4 {
    let r = rgba[i].to_int().to_double()
    let g = rgba[i + 1].to_int().to_double()
    let b = rgba[i + 2].to_int().to_double()

    let tr = 0.393 * r + 0.769 * g + 0.189 * b
    let tg = 0.349 * r + 0.686 * g + 0.168 * b
    let tb = 0.272 * r + 0.534 * g + 0.131 * b

    let r_out = if tr > 255.0 { 255 } else { tr.to_int() }
    let g_out = if tg > 255.0 { 255 } else { tg.to_int() }
    let b_out = if tb > 255.0 { 255 } else { tb.to_int() }

    res_arr[i] = r_out.to_byte()
    res_arr[i + 1] = g_out.to_byte()
    res_arr[i + 2] = b_out.to_byte()
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

///|
pub fn filter_invert(rgba : Bytes) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 4 {
    res_arr[i] = (255 - rgba[i].to_int()).to_byte()
    res_arr[i + 1] = (255 - rgba[i + 1].to_int()).to_byte()
    res_arr[i + 2] = (255 - rgba[i + 2].to_int()).to_byte()
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

///|
pub fn filter_adjust_brightness(rgba : Bytes, value : Int) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  for i = 0; i < len; i = i + 4 {
    let r = rgba[i].to_int() + value
    let g = rgba[i + 1].to_int() + value
    let b = rgba[i + 2].to_int() + value

    res_arr[i] = (if r < 0 { 0 } else if r > 255 { 255 } else { r }).to_byte()
    res_arr[i + 1] = (if g < 0 { 0 } else if g > 255 { 255 } else { g }).to_byte()
    res_arr[i + 2] = (if b < 0 { 0 } else if b > 255 { 255 } else { b }).to_byte()
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

///|
pub fn filter_adjust_contrast(rgba : Bytes, val : Double) -> Bytes {
  let len = rgba.length()
  let res_arr = Array::make(len, (0).to_byte())
  let factor = 259.0 * (val + 255.0) / (255.0 * (259.0 - val))

  for i = 0; i < len; i = i + 4 {
    let r = factor * (rgba[i].to_int().to_double() - 128.0) + 128.0
    let g = factor * (rgba[i + 1].to_int().to_double() - 128.0) + 128.0
    let b = factor * (rgba[i + 2].to_int().to_double() - 128.0) + 128.0

    res_arr[i] = (if r < 0.0 {
      0
    } else if r > 255.0 {
      255
    } else {
      r.to_int()
    }).to_byte()
    res_arr[i + 1] = (if g < 0.0 {
      0
    } else if g > 255.0 {
      255
    } else {
      g.to_int()
    }).to_byte()
    res_arr[i + 2] = (if b < 0.0 {
      0
    } else if b > 255.0 {
      255
    } else {
      b.to_int()
    }).to_byte()
    res_arr[i + 3] = rgba[i + 3]
  }
  make_bytes(len, fn(i) { res_arr[i] })
}

// Preset kernels

///|
pub fn blur_box(rgba : Bytes, w : Int, h : Int) -> Bytes {
  let kernel = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
  apply_kernel(rgba, w, h, kernel, 3, 1.0 / 9.0, 0.0)
}

///|
pub fn blur_gaussian_3x3(rgba : Bytes, w : Int, h : Int) -> Bytes {
  let kernel = [1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0]
  apply_kernel(rgba, w, h, kernel, 3, 1.0 / 16.0, 0.0)
}

///|
pub fn blur_gaussian_5x5(rgba : Bytes, w : Int, h : Int) -> Bytes {
  let kernel = [
    1.0, 4.0, 7.0, 4.0, 1.0, 4.0, 16.0, 26.0, 16.0, 4.0, 7.0, 26.0, 41.0, 26.0, 7.0,
    4.0, 16.0, 26.0, 16.0, 4.0, 1.0, 4.0, 7.0, 4.0, 1.0,
  ]
  apply_kernel(rgba, w, h, kernel, 5, 1.0 / 273.0, 0.0)
}

///|
pub fn filter_sharpen(rgba : Bytes, w : Int, h : Int) -> Bytes {
  let kernel = [0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0]
  apply_kernel(rgba, w, h, kernel, 3, 1.0, 0.0)
}

///|
pub fn filter_emboss(rgba : Bytes, w : Int, h : Int) -> Bytes {
  let kernel = [-2.0, -1.0, 0.0, -1.0, 1.0, 1.0, 0.0, 1.0, 2.0]
  apply_kernel(rgba, w, h, kernel, 3, 1.0, 128.0)
}

///|
pub fn edge_detection_sobel(rgba : Bytes, w : Int, h : Int) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())

  let kernel_x = [-1.0, 0.0, 1.0, -2.0, 0.0, 2.0, -1.0, 0.0, 1.0]

  let kernel_y = [-1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0]

  for y = 1; y < h - 1; y = y + 1 {
    for x = 1; x < w - 1; x = x + 1 {
      let mut xr = 0.0
      let mut xg = 0.0
      let mut xb = 0.0
      let mut yr = 0.0
      let mut yg = 0.0
      let mut yb = 0.0

      for ky = 0; ky < 3; ky = ky + 1 {
        let py = y + ky - 1
        for kx = 0; kx < 3; kx = kx + 1 {
          let px = x + kx - 1
          let src_idx = (py * w + px) * 4

          let wx = kernel_x[ky * 3 + kx]
          let wy = kernel_y[ky * 3 + kx]

          let r = rgba[src_idx].to_int().to_double()
          let g = rgba[src_idx + 1].to_int().to_double()
          let b = rgba[src_idx + 2].to_int().to_double()

          xr = xr + r * wx
          xg = xg + g * wx
          xb = xb + b * wx

          yr = yr + r * wy
          yg = yg + g * wy
          yb = yb + b * wy
        }
      }

      let out_idx = (y * w + x) * 4

      let r_val = (xr * xr + yr * yr).sqrt().to_int()
      let g_val = (xg * xg + yg * yg).sqrt().to_int()
      let b_val = (xb * xb + yb * yb).sqrt().to_int()

      res_arr[out_idx] = (if r_val > 255 { 255 } else { r_val }).to_byte()
      res_arr[out_idx + 1] = (if g_val > 255 { 255 } else { g_val }).to_byte()
      res_arr[out_idx + 2] = (if b_val > 255 { 255 } else { b_val }).to_byte()
      res_arr[out_idx + 3] = rgba[out_idx + 3]
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}
