// Dithering and Error Diffusion Algorithms
// This module provides various dithering techniques to reduce color banding in quantized pixel art:
// - Floyd-Steinberg Dithering
// - Atkinson Dithering
// - Stucki Dithering
// - Burkes Dithering
// - Bayer Ordered Dithering (2x2, 4x4, and 8x8 matrices)

///|
fn find_closest_palette_color(
  r : Double,
  g : Double,
  b : Double,
  palette : Array[Int],
) -> Int {
  let mut min_dist = 1000000000.0
  let mut best_color = 0

  for i = 0; i < palette.length(); i = i + 1 {
    let p_color = palette[i]
    let pr = ((p_color >> 16) & 0xFF).to_double()
    let pg = ((p_color >> 8) & 0xFF).to_double()
    let pb = (p_color & 0xFF).to_double()

    let dist = (r - pr) * (r - pr) + (g - pg) * (g - pg) + (b - pb) * (b - pb)
    if dist < min_dist {
      min_dist = dist
      best_color = p_color
    }
  }
  best_color
}

///|
pub fn dither_floyd_steinberg(
  rgba : Bytes,
  w : Int,
  h : Int,
  palette : Array[Int],
) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())

  // Create mutable error buffer to prevent modify original image
  let buffer = Array::make(w * h * 3, 0.0)
  for i = 0; i < w * h; i = i + 1 {
    buffer[i * 3] = rgba[i * 4].to_int().to_double()
    buffer[i * 3 + 1] = rgba[i * 4 + 1].to_int().to_double()
    buffer[i * 3 + 2] = rgba[i * 4 + 2].to_int().to_double()
  }

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = (y * w + x) * 3
      let old_r = buffer[idx]
      let old_g = buffer[idx + 1]
      let old_b = buffer[idx + 2]

      let new_color = find_closest_palette_color(old_r, old_g, old_b, palette)
      let nr = ((new_color >> 16) & 0xFF).to_double()
      let ng = ((new_color >> 8) & 0xFF).to_double()
      let nb = (new_color & 0xFF).to_double()

      let res_idx = (y * w + x) * 4
      res_arr[res_idx] = nr.to_int().to_byte()
      res_arr[res_idx + 1] = ng.to_int().to_byte()
      res_arr[res_idx + 2] = nb.to_int().to_byte()
      res_arr[res_idx + 3] = rgba[res_idx + 3]

      let err_r = old_r - nr
      let err_g = old_g - ng
      let err_b = old_b - nb

      // Floyd-Steinberg error weights:
      //         *   7/16
      //   3/16 5/16 1/16

      if x + 1 < w {
        let n_idx = (y * w + (x + 1)) * 3
        buffer[n_idx] = buffer[n_idx] + err_r * 7.0 / 16.0
        buffer[n_idx + 1] = buffer[n_idx + 1] + err_g * 7.0 / 16.0
        buffer[n_idx + 2] = buffer[n_idx + 2] + err_b * 7.0 / 16.0
      }
      if y + 1 < h {
        if x - 1 >= 0 {
          let n_idx = ((y + 1) * w + (x - 1)) * 3
          buffer[n_idx] = buffer[n_idx] + err_r * 3.0 / 16.0
          buffer[n_idx + 1] = buffer[n_idx + 1] + err_g * 3.0 / 16.0
          buffer[n_idx + 2] = buffer[n_idx + 2] + err_b * 3.0 / 16.0
        }
        let n_idx = ((y + 1) * w + x) * 3
        buffer[n_idx] = buffer[n_idx] + err_r * 5.0 / 16.0
        buffer[n_idx + 1] = buffer[n_idx + 1] + err_g * 5.0 / 16.0
        buffer[n_idx + 2] = buffer[n_idx + 2] + err_b * 5.0 / 16.0
        if x + 1 < w {
          let n_idx = ((y + 1) * w + (x + 1)) * 3
          buffer[n_idx] = buffer[n_idx] + err_r * 1.0 / 16.0
          buffer[n_idx + 1] = buffer[n_idx + 1] + err_g * 1.0 / 16.0
          buffer[n_idx + 2] = buffer[n_idx + 2] + err_b * 1.0 / 16.0
        }
      }
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}

///|
pub fn dither_atkinson(
  rgba : Bytes,
  w : Int,
  h : Int,
  palette : Array[Int],
) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())
  let buffer = Array::make(w * h * 3, 0.0)
  for i = 0; i < w * h; i = i + 1 {
    buffer[i * 3] = rgba[i * 4].to_int().to_double()
    buffer[i * 3 + 1] = rgba[i * 4 + 1].to_int().to_double()
    buffer[i * 3 + 2] = rgba[i * 4 + 2].to_int().to_double()
  }

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = (y * w + x) * 3
      let old_r = buffer[idx]
      let old_g = buffer[idx + 1]
      let old_b = buffer[idx + 2]

      let new_color = find_closest_palette_color(old_r, old_g, old_b, palette)
      let nr = ((new_color >> 16) & 0xFF).to_double()
      let ng = ((new_color >> 8) & 0xFF).to_double()
      let nb = (new_color & 0xFF).to_double()

      let res_idx = (y * w + x) * 4
      res_arr[res_idx] = nr.to_int().to_byte()
      res_arr[res_idx + 1] = ng.to_int().to_byte()
      res_arr[res_idx + 2] = nb.to_int().to_byte()
      res_arr[res_idx + 3] = rgba[res_idx + 3]

      let err_r = old_r - nr
      let err_g = old_g - ng
      let err_b = old_b - nb

      // Atkinson error weights (divided by 8):
      //         *   1/8  1/8
      //    1/8  1/8  1/8
      //         1/8

      let propagate = fn(px : Int, py : Int) {
        if px >= 0 && px < w && py >= 0 && py < h {
          let n_idx = (py * w + px) * 3
          buffer[n_idx] = buffer[n_idx] + err_r / 8.0
          buffer[n_idx + 1] = buffer[n_idx + 1] + err_g / 8.0
          buffer[n_idx + 2] = buffer[n_idx + 2] + err_b / 8.0
        }
      }

      propagate(x + 1, y)
      propagate(x + 2, y)
      propagate(x - 1, y + 1)
      propagate(x, y + 1)
      propagate(x + 1, y + 1)
      propagate(x, y + 2)
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}

///|
pub fn dither_stucki(
  rgba : Bytes,
  w : Int,
  h : Int,
  palette : Array[Int],
) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())
  let buffer = Array::make(w * h * 3, 0.0)
  for i = 0; i < w * h; i = i + 1 {
    buffer[i * 3] = rgba[i * 4].to_int().to_double()
    buffer[i * 3 + 1] = rgba[i * 4 + 1].to_int().to_double()
    buffer[i * 3 + 2] = rgba[i * 4 + 2].to_int().to_double()
  }

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = (y * w + x) * 3
      let old_r = buffer[idx]
      let old_g = buffer[idx + 1]
      let old_b = buffer[idx + 2]

      let new_color = find_closest_palette_color(old_r, old_g, old_b, palette)
      let nr = ((new_color >> 16) & 0xFF).to_double()
      let ng = ((new_color >> 8) & 0xFF).to_double()
      let nb = (new_color & 0xFF).to_double()

      let res_idx = (y * w + x) * 4
      res_arr[res_idx] = nr.to_int().to_byte()
      res_arr[res_idx + 1] = ng.to_int().to_byte()
      res_arr[res_idx + 2] = nb.to_int().to_byte()
      res_arr[res_idx + 3] = rgba[res_idx + 3]

      let err_r = old_r - nr
      let err_g = old_g - ng
      let err_b = old_b - nb

      // Stucki error weights (divided by 42):
      //             *   8/42  4/42
      //   2/42  4/42  8/42  4/42  2/42
      //   1/42  2/42  4/42  2/42  1/42

      let propagate = fn(px : Int, py : Int, weight : Double) {
        if px >= 0 && px < w && py >= 0 && py < h {
          let n_idx = (py * w + px) * 3
          buffer[n_idx] = buffer[n_idx] + err_r * weight / 42.0
          buffer[n_idx + 1] = buffer[n_idx + 1] + err_g * weight / 42.0
          buffer[n_idx + 2] = buffer[n_idx + 2] + err_b * weight / 42.0
        }
      }

      propagate(x + 1, y, 8.0)
      propagate(x + 2, y, 4.0)

      propagate(x - 2, y + 1, 2.0)
      propagate(x - 1, y + 1, 4.0)
      propagate(x, y + 1, 8.0)
      propagate(x + 1, y + 1, 4.0)
      propagate(x + 2, y + 1, 2.0)

      propagate(x - 2, y + 2, 1.0)
      propagate(x - 1, y + 2, 2.0)
      propagate(x, y + 2, 4.0)
      propagate(x + 1, y + 2, 2.0)
      propagate(x + 2, y + 2, 1.0)
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}

///|
pub fn dither_burkes(
  rgba : Bytes,
  w : Int,
  h : Int,
  palette : Array[Int],
) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())
  let buffer = Array::make(w * h * 3, 0.0)
  for i = 0; i < w * h; i = i + 1 {
    buffer[i * 3] = rgba[i * 4].to_int().to_double()
    buffer[i * 3 + 1] = rgba[i * 4 + 1].to_int().to_double()
    buffer[i * 3 + 2] = rgba[i * 4 + 2].to_int().to_double()
  }

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = (y * w + x) * 3
      let old_r = buffer[idx]
      let old_g = buffer[idx + 1]
      let old_b = buffer[idx + 2]

      let new_color = find_closest_palette_color(old_r, old_g, old_b, palette)
      let nr = ((new_color >> 16) & 0xFF).to_double()
      let ng = ((new_color >> 8) & 0xFF).to_double()
      let nb = (new_color & 0xFF).to_double()

      let res_idx = (y * w + x) * 4
      res_arr[res_idx] = nr.to_int().to_byte()
      res_arr[res_idx + 1] = ng.to_int().to_byte()
      res_arr[res_idx + 2] = nb.to_int().to_byte()
      res_arr[res_idx + 3] = rgba[res_idx + 3]

      let err_r = old_r - nr
      let err_g = old_g - ng
      let err_b = old_b - nb

      // Burkes error weights (divided by 32):
      //             *   8/32  4/32
      //   2/32  4/32  8/32  4/32  2/32

      let propagate = fn(px : Int, py : Int, weight : Double) {
        if px >= 0 && px < w && py >= 0 && py < h {
          let n_idx = (py * w + px) * 3
          buffer[n_idx] = buffer[n_idx] + err_r * weight / 32.0
          buffer[n_idx + 1] = buffer[n_idx + 1] + err_g * weight / 32.0
          buffer[n_idx + 2] = buffer[n_idx + 2] + err_b * weight / 32.0
        }
      }

      propagate(x + 1, y, 8.0)
      propagate(x + 2, y, 4.0)

      propagate(x - 2, y + 1, 2.0)
      propagate(x - 1, y + 1, 4.0)
      propagate(x, y + 1, 8.0)
      propagate(x + 1, y + 1, 4.0)
      propagate(x + 2, y + 1, 2.0)
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}

// Ordered Dithering matrices

///|
let bayer_matrix_2x2 : ReadOnlyArray[Double] = [0.0, 2.0, 3.0, 1.0]

///|
let bayer_matrix_4x4 : ReadOnlyArray[Double] = [
  0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0,
  5.0,
]

///|
let bayer_matrix_8x8 : ReadOnlyArray[Double] = [
  0.0, 48.0, 12.0, 60.0, 3.0, 51.0, 15.0, 63.0, 32.0, 16.0, 44.0, 28.0, 35.0, 19.0,
  47.0, 31.0, 8.0, 56.0, 4.0, 52.0, 11.0, 59.0, 7.0, 55.0, 40.0, 24.0, 36.0, 20.0,
  43.0, 27.0, 39.0, 23.0, 2.0, 50.0, 14.0, 62.0, 1.0, 49.0, 13.0, 61.0, 34.0, 18.0,
  46.0, 30.0, 33.0, 17.0, 45.0, 29.0, 10.0, 58.0, 6.0, 54.0, 9.0, 57.0, 5.0, 53.0,
  42.0, 26.0, 38.0, 22.0, 41.0, 25.0, 37.0, 21.0,
]

///|
pub fn dither_ordered_bayer(
  rgba : Bytes,
  w : Int,
  h : Int,
  palette : Array[Int],
  size : Int,
) -> Bytes {
  let res_arr = Array::make(w * h * 4, (0).to_byte())
  let matrix = if size == 2 {
    bayer_matrix_2x2
  } else if size == 4 {
    bayer_matrix_4x4
  } else {
    bayer_matrix_8x8
  }
  let size_d = size.to_double()
  let max_val = size_d * size_d

  for y = 0; y < h; y = y + 1 {
    let my = y % size
    for x = 0; x < w; x = x + 1 {
      let mx = x % size
      let threshold = (matrix[my * size + mx] + 0.5) / max_val - 0.5

      let idx = (y * w + x) * 4
      let r = rgba[idx].to_int().to_double() + threshold * 64.0
      let g = rgba[idx + 1].to_int().to_double() + threshold * 64.0
      let b = rgba[idx + 2].to_int().to_double() + threshold * 64.0

      let new_color = find_closest_palette_color(r, g, b, palette)
      res_arr[idx] = ((new_color >> 16) & 0xFF).to_byte()
      res_arr[idx + 1] = ((new_color >> 8) & 0xFF).to_byte()
      res_arr[idx + 2] = (new_color & 0xFF).to_byte()
      res_arr[idx + 3] = rgba[idx + 3]
    }
  }
  make_bytes(w * h * 4, fn(i) { res_arr[i] })
}
