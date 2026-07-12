// Extended Test Suite for Matrices, FFT/DCT, Contour Tracing, and Palettes
// This file extends unit testing coverage for the entire image processing package.

///|
test "matrix_make" {
  let m = make_matrix(2, 3)
  assert_eq(m.rows, 2)
  assert_eq(m.cols, 3)
  assert_eq(m.data.length(), 6)
  for i = 0; i < 6; i = i + 1 {
    assert_eq(m.data[i], 0.0)
  }
}

///|
test "matrix_identity" {
  let m = make_identity(3)
  assert_eq(m.rows, 3)
  assert_eq(m.cols, 3)
  assert_eq(m.matrix_get(0, 0), 1.0)
  assert_eq(m.matrix_get(0, 1), 0.0)
  assert_eq(m.matrix_get(1, 1), 1.0)
  assert_eq(m.matrix_get(2, 2), 1.0)
}

///|
test "matrix_get_set" {
  let m = make_matrix(2, 2)
  m.matrix_set(0, 1, 5.5)
  assert_eq(m.matrix_get(0, 1), 5.5)
}

///|
test "matrix_add_test" {
  let m1 = make_identity(2)
  let m2 = make_identity(2)
  match matrix_add(m1, m2) {
    Some(res) => {
      assert_eq(res.matrix_get(0, 0), 2.0)
      assert_eq(res.matrix_get(1, 1), 2.0)
      assert_eq(res.matrix_get(0, 1), 0.0)
    }
    None => assert_true(false)
  }
}

///|
test "matrix_sub_test" {
  let m1 = make_identity(2)
  let m2 = make_identity(2)
  match matrix_sub(m1, m2) {
    Some(res) => {
      assert_eq(res.matrix_get(0, 0), 0.0)
      assert_eq(res.matrix_get(1, 1), 0.0)
    }
    None => assert_true(false)
  }
}

///|
test "matrix_scale_test" {
  let m = make_identity(2)
  let res = matrix_scale(m, 3.5)
  assert_eq(res.matrix_get(0, 0), 3.5)
  assert_eq(res.matrix_get(1, 1), 3.5)
}

///|
test "matrix_mul_identity" {
  let m1 = make_identity(3)
  let m2 = make_identity(3)
  match matrix_mul(m1, m2) {
    Some(res) => {
      assert_eq(res.matrix_get(0, 0), 1.0)
      assert_eq(res.matrix_get(1, 1), 1.0)
      assert_eq(res.matrix_get(2, 2), 1.0)
    }
    None => assert_true(false)
  }
}

///|
test "matrix_mul_different_dims" {
  let m1 = make_matrix(2, 3)
  let m2 = make_matrix(3, 4)
  m1.matrix_set(0, 0, 1.0)
  m2.matrix_set(0, 0, 2.0)
  match matrix_mul(m1, m2) {
    Some(res) => {
      assert_eq(res.rows, 2)
      assert_eq(res.cols, 4)
      assert_eq(res.matrix_get(0, 0), 2.0)
    }
    None => assert_true(false)
  }
}

///|
test "matrix_transpose_test" {
  let m = make_matrix(2, 3)
  m.matrix_set(0, 1, 5.0)
  let t = matrix_transpose(m)
  assert_eq(t.rows, 3)
  assert_eq(t.cols, 2)
  assert_eq(t.matrix_get(1, 0), 5.0)
}

///|
test "matrix_inverse_gauss_jordan_test" {
  let m = make_matrix(2, 2)
  m.matrix_set(0, 0, 4.0)
  m.matrix_set(0, 1, 7.0)
  m.matrix_set(1, 0, 2.0)
  m.matrix_set(1, 1, 6.0)

  match matrix_inverse_gauss_jordan(m) {
    Some(inv) => {
      // Inverse of [[4, 7], [2, 6]] is [[0.6, -0.7], [-0.2, 0.4]]
      assert_true(abs_val(inv.matrix_get(0, 0) - 0.6) < 0.001)
      assert_true(abs_val(inv.matrix_get(0, 1) - -0.7) < 0.001)
      assert_true(abs_val(inv.matrix_get(1, 0) - -0.2) < 0.001)
      assert_true(abs_val(inv.matrix_get(1, 1) - 0.4) < 0.001)
    }
    None => assert_true(false)
  }
}

///|
test "matrix_lu_decomposition_test" {
  let m = make_matrix(3, 3)
  m.matrix_set(0, 0, 1.0)
  m.matrix_set(0, 1, 3.0)
  m.matrix_set(0, 2, 5.0)
  m.matrix_set(1, 0, 2.0)
  m.matrix_set(1, 1, 4.0)
  m.matrix_set(1, 2, 7.0)
  m.matrix_set(2, 0, 3.0)
  m.matrix_set(2, 1, 5.0)
  m.matrix_set(2, 2, 8.0)

  match matrix_lu_decomposition(m) {
    Some(_) => assert_true(true)
    None => assert_true(false)
  }
}

// ----------------------------------------------------
// FFT & DCT Tests
// ----------------------------------------------------

///|
test "complex_ops" {
  let c1 = { re: 1.0, im: 2.0 }
  let c2 = { re: 3.0, im: 4.0 }

  let add = complex_add(c1, c2)
  assert_eq(add.re, 4.0)
  assert_eq(add.im, 6.0)

  let sub = complex_sub(c1, c2)
  assert_eq(sub.re, -2.0)
  assert_eq(sub.im, -2.0)

  let mul = complex_mul(c1, c2)
  assert_eq(mul.re, -5.0)
  assert_eq(mul.im, 10.0)

  let mag = complex_magnitude(c1)
  assert_true(abs(mag - 5.0.sqrt()) < 0.001)
}

///|
test "fft_1d_identity" {
  let arr = [
    { re: 1.0, im: 0.0 },
    { re: 2.0, im: 0.0 },
    { re: 3.0, im: 0.0 },
    { re: 4.0, im: 0.0 },
  ]
  let spectrum = fft_1d(arr, false)
  let reconstructed = fft_1d(spectrum, true)
  for i = 0; i < arr.length(); i = i + 1 {
    assert_true(abs(reconstructed[i].re - arr[i].re) < 0.001)
    assert_true(abs(reconstructed[i].im - arr[i].im) < 0.001)
  }
}

///|
test "fft_2d_identity" {
  let arr = [
    { re: 1.0, im: 0.0 },
    { re: 2.0, im: 0.0 },
    { re: 3.0, im: 0.0 },
    { re: 4.0, im: 0.0 },
  ]
  let spectrum = fft_2d(arr, 2, 2, false)
  let reconstructed = fft_2d(spectrum, 2, 2, true)
  for i = 0; i < arr.length(); i = i + 1 {
    assert_true(abs(reconstructed[i].re - arr[i].re) < 0.001)
  }
}

///|
test "dct_2d_identity" {
  let arr = [10.0, 20.0, 30.0, 40.0]
  let spectrum = dct_2d(arr, 2, 2)
  let reconstructed = idct_2d(spectrum, 2, 2)
  for i = 0; i < arr.length(); i = i + 1 {
    assert_true(abs_val(reconstructed[i] - arr[i]) < 0.001)
  }
}

///|
test "fft_filters" {
  let arr = [
    { re: 10.0, im: 0.0 },
    { re: 20.0, im: 0.0 },
    { re: 30.0, im: 0.0 },
    { re: 40.0, im: 0.0 },
  ]
  let lp = lowpass_filter_fft(arr, 2, 2, 1.0)
  let hp = highpass_filter_fft(arr, 2, 2, 1.0)
  assert_eq(lp.length(), 4)
  assert_eq(hp.length(), 4)
}

// ----------------------------------------------------
// Vectorization Tests
// ----------------------------------------------------

///|
test "point_line_dist" {
  let p = { x: 0.0, y: 5.0 }
  let start = { x: 0.0, y: 0.0 }
  let end = { x: 10.0, y: 0.0 }
  let dist = point_line_distance(p, start, end)
  assert_eq(dist, 5.0)
}

///|
test "ramer_douglas_peucker_collinear" {
  let points = [{ x: 0.0, y: 0.0 }, { x: 5.0, y: 0.0 }, { x: 10.0, y: 0.0 }]
  let simplified = ramer_douglas_peucker(points, 1.0)
  assert_eq(simplified.length(), 2)
  assert_eq(simplified[0].x, 0.0)
  assert_eq(simplified[1].x, 10.0)
}

///|
test "marching_squares_contour" {
  let grid = [
    0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0x000000, 0xFFFFFF, 0xFFFFFF, 0xFFFFFF,
    0xFFFFFF,
  ]
  let contours = trace_contour_marching_squares(grid, 3, 3, 0x000000)
  assert_true(contours.length() > 0)
}

///|
test "svg_path_generation" {
  let points = [{ x: 0.0, y: 0.0 }, { x: 10.0, y: 0.0 }, { x: 10.0, y: 10.0 }]
  let path = generate_svg_path(points)
  assert_true(path.length() > 0)
}

// ----------------------------------------------------
// Brand Palette Tests
// ----------------------------------------------------

///|
test "brand_palettes" {
  let perler = get_perler_palette()
  let hama = get_hama_palette()
  let artkal = get_artkal_palette()
  assert_true(perler.length() > 0)
  assert_true(hama.length() > 0)
  assert_true(artkal.length() > 0)
}

///|
test "closest_brand_color" {
  let c : RgbColor = { r: 255.0, g: 0.0, b: 0.0 }
  let palette = get_perler_palette()
  let closest = find_closest_brand_color(c, palette)
  assert_true(closest.name == "Red" || closest.name == "Orange")
}
