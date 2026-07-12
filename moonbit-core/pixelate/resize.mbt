// Image Resizing and Interpolation Algorithms
// This module provides functions to resize/rescale RGBA buffers using different interpolation filters:
// - Nearest Neighbor
// - Bilinear Interpolation
// - Bicubic Interpolation (Catmull-Rom)
// - Lanczos-2 and Lanczos-3 Windowed Sinc Interpolation

///|
pub fn nearest_neighbor_resize(
  rgba : Bytes,
  w1 : Int,
  h1 : Int,
  w2 : Int,
  h2 : Int,
) -> Bytes {
  let res_arr = Array::make(w2 * h2 * 4, (0).to_byte())
  let x_ratio = w1.to_double() / w2.to_double()
  let y_ratio = h1.to_double() / h2.to_double()

  for y = 0; y < h2; y = y + 1 {
    let py = (y.to_double() * y_ratio).to_int()
    let py_clamped = if py < 0 { 0 } else if py >= h1 { h1 - 1 } else { py }
    for x = 0; x < w2; x = x + 1 {
      let px = (x.to_double() * x_ratio).to_int()
      let px_clamped = if px < 0 { 0 } else if px >= w1 { w1 - 1 } else { px }

      let src_idx = (py_clamped * w1 + px_clamped) * 4
      let dest_idx = (y * w2 + x) * 4

      res_arr[dest_idx] = rgba[src_idx]
      res_arr[dest_idx + 1] = rgba[src_idx + 1]
      res_arr[dest_idx + 2] = rgba[src_idx + 2]
      res_arr[dest_idx + 3] = rgba[src_idx + 3]
    }
  }
  make_bytes(w2 * h2 * 4, fn(i) { res_arr[i] })
}

///|
pub fn bilinear_resize(
  rgba : Bytes,
  w1 : Int,
  h1 : Int,
  w2 : Int,
  h2 : Int,
) -> Bytes {
  let res_arr = Array::make(w2 * h2 * 4, (0).to_byte())
  let x_ratio = (w1 - 1).to_double() / w2.to_double()
  let y_ratio = (h1 - 1).to_double() / h2.to_double()

  for y = 0; y < h2; y = y + 1 {
    let y_val = y.to_double() * y_ratio
    let y_low = y_val.to_int()
    let y_high = y_low + 1
    let y_diff = y_val - y_low.to_double()

    for x = 0; x < w2; x = x + 1 {
      let x_val = x.to_double() * x_ratio
      let x_low = x_val.to_int()
      let x_high = x_low + 1
      let x_diff = x_val - x_low.to_double()

      let y_l = if y_low < 0 { 0 } else if y_low >= h1 { h1 - 1 } else { y_low }
      let y_h = if y_high < 0 {
        0
      } else if y_high >= h1 {
        h1 - 1
      } else {
        y_high
      }
      let x_l = if x_low < 0 { 0 } else if x_low >= w1 { w1 - 1 } else { x_low }
      let x_h = if x_high < 0 {
        0
      } else if x_high >= w1 {
        w1 - 1
      } else {
        x_high
      }

      let idx_a = (y_l * w1 + x_l) * 4
      let idx_b = (y_l * w1 + x_h) * 4
      let idx_c = (y_h * w1 + x_l) * 4
      let idx_d = (y_h * w1 + x_h) * 4

      for channel = 0; channel < 4; channel = channel + 1 {
        let a = rgba[idx_a + channel].to_int().to_double()
        let b = rgba[idx_b + channel].to_int().to_double()
        let c = rgba[idx_c + channel].to_int().to_double()
        let d = rgba[idx_d + channel].to_int().to_double()

        let val = a * (1.0 - x_diff) * (1.0 - y_diff) +
          b * x_diff * (1.0 - y_diff) +
          c * (1.0 - x_diff) * y_diff +
          d * x_diff * y_diff

        let val_clamped = if val < 0.0 {
          0
        } else if val > 255.0 {
          255
        } else {
          val.to_int()
        }
        res_arr[(y * w2 + x) * 4 + channel] = val_clamped.to_byte()
      }
    }
  }
  make_bytes(w2 * h2 * 4, fn(i) { res_arr[i] })
}

///|
fn cubic_interpolate(
  p0 : Double,
  p1 : Double,
  p2 : Double,
  p3 : Double,
  x : Double,
) -> Double {
  p1 +
  0.5 *
  x *
  (
    p2 -
    p0 +
    x * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3 + x * (3.0 * (p1 - p2) + p3 - p0))
  )
}

///|
pub fn bicubic_resize(
  rgba : Bytes,
  w1 : Int,
  h1 : Int,
  w2 : Int,
  h2 : Int,
) -> Bytes {
  let res_arr = Array::make(w2 * h2 * 4, (0).to_byte())
  let x_ratio = w1.to_double() / w2.to_double()
  let y_ratio = h1.to_double() / h2.to_double()

  let temp_row = Array::make(4, 0.0)

  for y = 0; y < h2; y = y + 1 {
    let y_val = y.to_double() * y_ratio
    let y_idx = y_val.to_int()
    let y_diff = y_val - y_idx.to_double()

    for x = 0; x < w2; x = x + 1 {
      let x_val = x.to_double() * x_ratio
      let x_idx = x_val.to_int()
      let x_diff = x_val - x_idx.to_double()

      for channel = 0; channel < 4; channel = channel + 1 {
        for j = -1; j <= 2; j = j + 1 {
          let curr_y = y_idx + j
          let cy = if curr_y < 0 {
            0
          } else if curr_y >= h1 {
            h1 - 1
          } else {
            curr_y
          }

          let p0 = rgba[(
              cy * w1 +
              (if x_idx - 1 < 0 {
                0
              } else if x_idx - 1 >= w1 {
                w1 - 1
              } else {
                x_idx - 1
              })
            ) *
            4 +
            channel]
            .to_int()
            .to_double()
          let p1 = rgba[(
              cy * w1 +
              (if x_idx < 0 { 0 } else if x_idx >= w1 { w1 - 1 } else { x_idx })
            ) *
            4 +
            channel]
            .to_int()
            .to_double()
          let p2 = rgba[(
              cy * w1 +
              (if x_idx + 1 < 0 {
                0
              } else if x_idx + 1 >= w1 {
                w1 - 1
              } else {
                x_idx + 1
              })
            ) *
            4 +
            channel]
            .to_int()
            .to_double()
          let p3 = rgba[(
              cy * w1 +
              (if x_idx + 2 < 0 {
                0
              } else if x_idx + 2 >= w1 {
                w1 - 1
              } else {
                x_idx + 2
              })
            ) *
            4 +
            channel]
            .to_int()
            .to_double()

          temp_row[j + 1] = cubic_interpolate(p0, p1, p2, p3, x_diff)
        }

        let final_val = cubic_interpolate(
          temp_row[0],
          temp_row[1],
          temp_row[2],
          temp_row[3],
          y_diff,
        )
        let final_clamped = if final_val < 0.0 {
          0
        } else if final_val > 255.0 {
          255
        } else {
          final_val.to_int()
        }
        res_arr[(y * w2 + x) * 4 + channel] = final_clamped.to_byte()
      }
    }
  }
  make_bytes(w2 * h2 * 4, fn(i) { res_arr[i] })
}

///|
fn sinc(x : Double) -> Double {
  if x == 0.0 {
    1.0
  } else {
    let val = x * 3.141592653589793
    @math.sin(val) / val
  }
}

///|
fn lanczos_weight(x : Double, a : Double) -> Double {
  let abs_x = if x < 0.0 { -x } else { x }
  if abs_x < a {
    sinc(abs_x) * sinc(abs_x / a)
  } else {
    0.0
  }
}

///|
pub fn lanczos_resize(
  rgba : Bytes,
  w1 : Int,
  h1 : Int,
  w2 : Int,
  h2 : Int,
  size : Int,
) -> Bytes {
  let res_arr = Array::make(w2 * h2 * 4, (0).to_byte())
  let a = size.to_double()

  let x_ratio = w1.to_double() / w2.to_double()
  let y_ratio = h1.to_double() / h2.to_double()

  for y = 0; y < h2; y = y + 1 {
    let sy = y.to_double() * y_ratio
    let y_min = (sy - a).to_int()
    let y_max = (sy + a).to_int()

    for x = 0; x < w2; x = x + 1 {
      let sx = x.to_double() * x_ratio
      let x_min = (sx - a).to_int()
      let x_max = (sx + a).to_int()

      let mut r_sum = 0.0
      let mut g_sum = 0.0
      let mut b_sum = 0.0
      let mut a_sum = 0.0
      let mut weight_sum = 0.0

      for j = y_min; j <= y_max; j = j + 1 {
        let cy = if j < 0 { 0 } else if j >= h1 { h1 - 1 } else { j }
        let wy = lanczos_weight(sy - j.to_double(), a)
        if wy == 0.0 {
          continue
        }
        for i = x_min; i <= x_max; i = i + 1 {
          let cx = if i < 0 { 0 } else if i >= w1 { w1 - 1 } else { i }
          let wx = lanczos_weight(sx - i.to_double(), a)
          let w = wx * wy
          if w == 0.0 {
            continue
          }

          let idx = (cy * w1 + cx) * 4
          r_sum = r_sum + rgba[idx].to_int().to_double() * w
          g_sum = g_sum + rgba[idx + 1].to_int().to_double() * w
          b_sum = b_sum + rgba[idx + 2].to_int().to_double() * w
          a_sum = a_sum + rgba[idx + 3].to_int().to_double() * w
          weight_sum = weight_sum + w
        }
      }

      let idx_out = (y * w2 + x) * 4
      if weight_sum > 0.0 {
        let r = r_sum / weight_sum
        let g = g_sum / weight_sum
        let b = b_sum / weight_sum
        let a_val = a_sum / weight_sum

        res_arr[idx_out] = (if r < 0.0 {
          0
        } else if r > 255.0 {
          255
        } else {
          r.to_int()
        }).to_byte()
        res_arr[idx_out + 1] = (if g < 0.0 {
          0
        } else if g > 255.0 {
          255
        } else {
          g.to_int()
        }).to_byte()
        res_arr[idx_out + 2] = (if b < 0.0 {
          0
        } else if b > 255.0 {
          255
        } else {
          b.to_int()
        }).to_byte()
        res_arr[idx_out + 3] = (if a_val < 0.0 {
          0
        } else if a_val > 255.0 {
          255
        } else {
          a_val.to_int()
        }).to_byte()
      } else {
        let idx_nearest = (sy.to_int() * w1 + sx.to_int()) * 4
        res_arr[idx_out] = rgba[idx_nearest]
        res_arr[idx_out + 1] = rgba[idx_nearest + 1]
        res_arr[idx_out + 2] = rgba[idx_nearest + 2]
        res_arr[idx_out + 3] = rgba[idx_nearest + 3]
      }
    }
  }
  make_bytes(w2 * h2 * 4, fn(i) { res_arr[i] })
}
