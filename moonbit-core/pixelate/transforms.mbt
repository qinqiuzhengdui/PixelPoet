// Image Fourier and Cosine Transforms Library
// This module provides implementation of 1D/2D Fast Fourier Transform (FFT) 
// and 2D Discrete Cosine Transform (DCT) for frequency-domain analysis and filtering.

///|
pub struct Complex {
  pub re : Double
  pub im : Double
}

///|
pub fn complex_add(c1 : Complex, c2 : Complex) -> Complex {
  { re: c1.re + c2.re, im: c1.im + c2.im }
}

///|
pub fn complex_sub(c1 : Complex, c2 : Complex) -> Complex {
  { re: c1.re - c2.re, im: c1.im - c2.im }
}

///|
pub fn complex_mul(c1 : Complex, c2 : Complex) -> Complex {
  { re: c1.re * c2.re - c1.im * c2.im, im: c1.re * c2.im + c1.im * c2.re }
}

///|
pub fn complex_magnitude(c : Complex) -> Double {
  (c.re * c.re + c.im * c.im).sqrt()
}

///|
fn bit_reverse(n : Int, bits : Int) -> Int {
  let mut rev = 0
  let mut x = n
  for i = 0; i < bits; i = i + 1 {
    rev = (rev << 1) | (x & 1)
    x = x >> 1
  }
  rev
}

///|
pub fn fft_1d(arr : Array[Complex], inverse : Bool) -> Array[Complex] {
  let n = arr.length()
  let mut bits = 0
  while 1 << bits < n {
    bits = bits + 1
  }

  let res = Array::make(n, { re: 0.0, im: 0.0 })
  for i = 0; i < n; i = i + 1 {
    let rev_i = bit_reverse(i, bits)
    res[rev_i] = arr[i]
  }

  let sign = if inverse { 1.0 } else { -1.0 }
  let pi = 3.141592653589793

  let mut len = 2
  while len <= n {
    let angle = 2.0 * pi / len.to_double() * sign
    let wlen = { re: @math.cos(angle), im: @math.sin(angle) }

    for i = 0; i < n; i = i + len {
      let mut w = { re: 1.0, im: 0.0 }
      for j = 0; j < len / 2; j = j + 1 {
        let u = res[i + j]
        let t = complex_mul(res[i + j + len / 2], w)
        res[i + j] = complex_add(u, t)
        res[i + j + len / 2] = complex_sub(u, t)
        w = complex_mul(w, wlen)
      }
    }
    len = len * 2
  }

  if inverse {
    let n_d = n.to_double()
    for i = 0; i < n; i = i + 1 {
      res[i] = { re: res[i].re / n_d, im: res[i].im / n_d }
    }
  }
  res
}

///|
pub fn fft_2d(
  grid : Array[Complex],
  w : Int,
  h : Int,
  inverse : Bool,
) -> Array[Complex] {
  let res = Array::make(w * h, { re: 0.0, im: 0.0 })
  for i = 0; i < w * h; i = i + 1 {
    res[i] = grid[i]
  }

  // Transform rows
  for y = 0; y < h; y = y + 1 {
    let row = Array::make(w, { re: 0.0, im: 0.0 })
    for x = 0; x < w; x = x + 1 {
      row[x] = res[y * w + x]
    }
    let row_t = fft_1d(row, inverse)
    for x = 0; x < w; x = x + 1 {
      res[y * w + x] = row_t[x]
    }
  }

  // Transform columns
  for x = 0; x < w; x = x + 1 {
    let col = Array::make(h, { re: 0.0, im: 0.0 })
    for y = 0; y < h; y = y + 1 {
      col[y] = res[y * w + x]
    }
    let col_t = fft_1d(col, inverse)
    for y = 0; y < h; y = y + 1 {
      res[y * w + x] = col_t[y]
    }
  }
  res
}

///|
pub fn dct_2d(grid : Array[Double], w : Int, h : Int) -> Array[Double] {
  let res = Array::make(w * h, 0.0)
  let pi = 3.141592653589793

  for u = 0; u < h; u = u + 1 {
    let cu = if u == 0 { 1.0 / 2.0.sqrt() } else { 1.0 }
    for v = 0; v < w; v = v + 1 {
      let cv = if v == 0 { 1.0 / 2.0.sqrt() } else { 1.0 }
      let mut sum = 0.0

      for y = 0; y < h; y = y + 1 {
        let term_y = @math.cos(
          (2.0 * y.to_double() + 1.0) *
          u.to_double() *
          pi /
          (2.0 * h.to_double()),
        )
        for x = 0; x < w; x = x + 1 {
          let term_x = @math.cos(
            (2.0 * x.to_double() + 1.0) *
            v.to_double() *
            pi /
            (2.0 * w.to_double()),
          )
          sum = sum + grid[y * w + x] * term_x * term_y
        }
      }

      let factor = 2.0 / (w.to_double() * h.to_double()).sqrt()
      res[u * w + v] = factor * cu * cv * sum
    }
  }
  res
}

///|
pub fn idct_2d(grid : Array[Double], w : Int, h : Int) -> Array[Double] {
  let res = Array::make(w * h, 0.0)
  let pi = 3.141592653589793

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let mut sum = 0.0
      for u = 0; u < h; u = u + 1 {
        let cu = if u == 0 { 1.0 / 2.0.sqrt() } else { 1.0 }
        let term_y = @math.cos(
          (2.0 * y.to_double() + 1.0) *
          u.to_double() *
          pi /
          (2.0 * h.to_double()),
        )
        for v = 0; v < w; v = v + 1 {
          let cv = if v == 0 { 1.0 / 2.0.sqrt() } else { 1.0 }
          let term_x = @math.cos(
            (2.0 * x.to_double() + 1.0) *
            v.to_double() *
            pi /
            (2.0 * w.to_double()),
          )
          sum = sum + cu * cv * grid[u * w + v] * term_x * term_y
        }
      }
      let factor = 2.0 / (w.to_double() * h.to_double()).sqrt()
      res[y * w + x] = factor * sum
    }
  }
  res
}

///|
pub fn lowpass_filter_fft(
  grid : Array[Complex],
  w : Int,
  h : Int,
  cutoff : Double,
) -> Array[Complex] {
  let spectrum = fft_2d(grid, w, h, false)
  let res_spectrum = Array::make(w * h, { re: 0.0, im: 0.0 })

  let cx = w / 2
  let cy = h / 2

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let dx = (x - cx).to_double()
      let dy = (y - cy).to_double()
      let dist = (dx * dx + dy * dy).sqrt()

      let idx = y * w + x
      if dist <= cutoff {
        res_spectrum[idx] = spectrum[idx]
      } else {
        res_spectrum[idx] = { re: 0.0, im: 0.0 }
      }
    }
  }
  fft_2d(res_spectrum, w, h, true)
}

///|
pub fn highpass_filter_fft(
  grid : Array[Complex],
  w : Int,
  h : Int,
  cutoff : Double,
) -> Array[Complex] {
  let spectrum = fft_2d(grid, w, h, false)
  let res_spectrum = Array::make(w * h, { re: 0.0, im: 0.0 })

  let cx = w / 2
  let cy = h / 2

  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let dx = (x - cx).to_double()
      let dy = (y - cy).to_double()
      let dist = (dx * dx + dy * dy).sqrt()

      let idx = y * w + x
      if dist > cutoff {
        res_spectrum[idx] = spectrum[idx]
      } else {
        res_spectrum[idx] = { re: 0.0, im: 0.0 }
      }
    }
  }
  fft_2d(res_spectrum, w, h, true)
}
