// Comprehensive Unit Tests for PixelPoet MoonBit Core Library
// This file tests color spaces, resizing, filter kernels, dithering, quantization, and export utilities.

///|
test "rgb_to_hsl_black" {
  let black = { r: 0.0, g: 0.0, b: 0.0 }
  let hsl = rgb_to_hsl(black)
  assert_eq(hsl.h, 0.0)
  assert_eq(hsl.s, 0.0)
  assert_eq(hsl.l, 0.0)
}

///|
test "rgb_to_hsl_white" {
  let white = { r: 255.0, g: 255.0, b: 255.0 }
  let hsl = rgb_to_hsl(white)
  assert_eq(hsl.h, 0.0)
  assert_eq(hsl.s, 0.0)
  assert_eq(hsl.l, 1.0)
}

///|
test "rgb_to_hsl_red" {
  let red = { r: 255.0, g: 0.0, b: 0.0 }
  let hsl = rgb_to_hsl(red)
  assert_eq(hsl.h, 0.0)
  assert_eq(hsl.s, 1.0)
  assert_eq(hsl.l, 0.5)
}

///|
test "rgb_to_hsl_green" {
  let green = { r: 0.0, g: 255.0, b: 0.0 }
  let hsl = rgb_to_hsl(green)
  assert_eq(hsl.h, 120.0)
  assert_eq(hsl.s, 1.0)
  assert_eq(hsl.l, 0.5)
}

///|
test "rgb_to_hsl_blue" {
  let blue = { r: 0.0, g: 0.0, b: 255.0 }
  let hsl = rgb_to_hsl(blue)
  assert_eq(hsl.h, 240.0)
  assert_eq(hsl.s, 1.0)
  assert_eq(hsl.l, 0.5)
}

///|
test "hsl_to_rgb_red" {
  let hsl = { h: 0.0, s: 1.0, l: 0.5 }
  let rgb = hsl_to_rgb(hsl)
  assert_eq(rgb.r, 255.0)
  assert_eq(rgb.g, 0.0)
  assert_eq(rgb.b, 0.0)
}

///|
test "hsl_to_rgb_green" {
  let hsl = { h: 120.0, s: 1.0, l: 0.5 }
  let rgb = hsl_to_rgb(hsl)
  assert_eq(rgb.r, 0.0)
  assert_eq(rgb.g, 255.0)
  assert_eq(rgb.b, 0.0)
}

///|
test "hsl_to_rgb_blue" {
  let hsl = { h: 240.0, s: 1.0, l: 0.5 }
  let rgb = hsl_to_rgb(hsl)
  assert_eq(rgb.r, 0.0)
  assert_eq(rgb.g, 0.0)
  assert_eq(rgb.b, 255.0)
}

///|
test "rgb_to_hsv_red" {
  let red = { r: 255.0, g: 0.0, b: 0.0 }
  let hsv = rgb_to_hsv(red)
  assert_eq(hsv.h, 0.0)
  assert_eq(hsv.s, 1.0)
  assert_eq(hsv.v, 1.0)
}

///|
test "hsv_to_rgb_red" {
  let hsv = { h: 0.0, s: 1.0, v: 1.0 }
  let rgb = hsv_to_rgb(hsv)
  assert_eq(rgb.r, 255.0)
  assert_eq(rgb.g, 0.0)
  assert_eq(rgb.b, 0.0)
}

///|
test "rgb_to_cmyk_red" {
  let red = { r: 255.0, g: 0.0, b: 0.0 }
  let cmyk = rgb_to_cmyk(red)
  assert_eq(cmyk.c, 0.0)
  assert_eq(cmyk.m, 1.0)
  assert_eq(cmyk.y, 1.0)
  assert_eq(cmyk.k, 0.0)
}

///|
test "cmyk_to_rgb_red" {
  let cmyk = { c: 0.0, m: 1.0, y: 1.0, k: 0.0 }
  let rgb = cmyk_to_rgb(cmyk)
  assert_eq(rgb.r, 255.0)
  assert_eq(rgb.g, 0.0)
  assert_eq(rgb.b, 0.0)
}

///|
test "rgb_to_yuv_red" {
  let red = { r: 255.0, g: 0.0, b: 0.0 }
  let yuv = rgb_to_yuv(red)
  assert_true(abs(yuv.y - 0.299) < 0.001)
  assert_true(abs(yuv.u - -0.14713) < 0.001)
  assert_true(abs(yuv.v - 0.615) < 0.001)
}

///|
test "yuv_to_rgb_red" {
  let yuv = { y: 0.299, u: -0.14713, v: 0.615 }
  let rgb = yuv_to_rgb(yuv)
  assert_true(abs(rgb.r - 255.0) < 0.1)
  assert_true(abs(rgb.g - 0.0) < 0.1)
  assert_true(abs(rgb.b - 0.0) < 0.1)
}

///|
test "delta_e_76_identity" {
  let c = { l: 50.0, a: 10.0, b: -20.0 }
  let dist = delta_e_76(c, c)
  assert_eq(dist, 0.0)
}

///|
test "delta_e_94_identity" {
  let c = { l: 50.0, a: 10.0, b: -20.0 }
  let dist = delta_e_94(c, c)
  assert_eq(dist, 0.0)
}

///|
test "delta_e_00_identity" {
  let c = { l: 50.0, a: 10.0, b: -20.0 }
  let dist = delta_e_00(c, c)
  assert_eq(dist, 0.0)
}

///|
test "delta_e_76_different" {
  let c1 = { l: 50.0, a: 10.0, b: -20.0 }
  let c2 = { l: 55.0, a: 12.0, b: -18.0 }
  let dist = delta_e_76(c1, c2)
  assert_true(dist > 0.0)
}

///|
test "delta_e_94_different" {
  let c1 = { l: 50.0, a: 10.0, b: -20.0 }
  let c2 = { l: 55.0, a: 12.0, b: -18.0 }
  let dist = delta_e_94(c1, c2)
  assert_true(dist > 0.0)
}

///|
test "delta_e_00_different" {
  let c1 = { l: 50.0, a: 10.0, b: -20.0 }
  let c2 = { l: 55.0, a: 12.0, b: -18.0 }
  let dist = delta_e_00(c1, c2)
  assert_true(dist > 0.0)
}

// ----------------------------------------------------
// Resizing Tests
// ----------------------------------------------------

///|
test "nearest_neighbor_resize_test" {
  let src = Bytes::make(16, 128) // 2x2 grid of RGBA pixels
  let resized = nearest_neighbor_resize(src, 2, 2, 4, 4)
  assert_eq(resized.length(), 64)
  for i = 0; i < 64; i = i + 1 {
    assert_eq(resized[i].to_int(), 128)
  }
}

///|
test "bilinear_resize_test" {
  let src = Bytes::make(16, 200)
  let resized = bilinear_resize(src, 2, 2, 4, 4)
  assert_eq(resized.length(), 64)
  for i = 0; i < 64; i = i + 1 {
    assert_eq(resized[i].to_int(), 200)
  }
}

///|
test "bicubic_resize_test" {
  let src = Bytes::make(16, 100)
  let resized = bicubic_resize(src, 2, 2, 4, 4)
  assert_eq(resized.length(), 64)
  for i = 0; i < 64; i = i + 1 {
    assert_eq(resized[i].to_int(), 100)
  }
}

///|
test "lanczos_resize_test" {
  let src = Bytes::make(16, 150)
  let resized = lanczos_resize(src, 2, 2, 4, 4, 3)
  assert_eq(resized.length(), 64)
}

// ----------------------------------------------------
// Convolution & Filter Tests
// ----------------------------------------------------

///|
test "apply_kernel_test" {
  let src = Bytes::make(36, 100) // 3x3 RGBA pixels
  let kernel = [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
  let result = apply_kernel(src, 3, 3, kernel, 3, 1.0, 0.0)
  assert_eq(result.length(), 36)
  assert_eq(result[0].to_int(), 100)
}

///|
test "filter_grayscale_luminance_test" {
  let src = Bytes::make(16, 100)
  let result = filter_grayscale_luminance(src)
  assert_eq(result.length(), 16)
}

///|
test "filter_grayscale_bt601_test" {
  let src = Bytes::make(16, 100)
  let result = filter_grayscale_bt601(src)
  assert_eq(result.length(), 16)
}

///|
test "filter_grayscale_average_test" {
  let src = Bytes::make(16, 100)
  let result = filter_grayscale_average(src)
  assert_eq(result.length(), 16)
  assert_eq(result[0].to_int(), 100)
}

///|
test "filter_sepia_test" {
  let src = Bytes::make(16, 100)
  let result = filter_sepia(src)
  assert_eq(result.length(), 16)
}

///|
test "filter_invert_test" {
  let src = Bytes::make(16, 100)
  let result = filter_invert(src)
  assert_eq(result.length(), 16)
  assert_eq(result[0].to_int(), 155)
}

///|
test "filter_adjust_brightness_test" {
  let src = Bytes::make(16, 100)
  let result = filter_adjust_brightness(src, 20)
  assert_eq(result.length(), 16)
  assert_eq(result[0].to_int(), 120)
}

///|
test "filter_adjust_contrast_test" {
  let src = Bytes::make(16, 100)
  let result = filter_adjust_contrast(src, 20.0)
  assert_eq(result.length(), 16)
}

///|
test "blur_box_test" {
  let src = Bytes::make(36, 100)
  let result = blur_box(src, 3, 3)
  assert_eq(result.length(), 36)
}

///|
test "blur_gaussian_3x3_test" {
  let src = Bytes::make(36, 100)
  let result = blur_gaussian_3x3(src, 3, 3)
  assert_eq(result.length(), 36)
}

///|
test "blur_gaussian_5x5_test" {
  let src = Bytes::make(100, 100)
  let result = blur_gaussian_5x5(src, 5, 5)
  assert_eq(result.length(), 100)
}

///|
test "filter_sharpen_test" {
  let src = Bytes::make(36, 100)
  let result = filter_sharpen(src, 3, 3)
  assert_eq(result.length(), 36)
}

///|
test "filter_emboss_test" {
  let src = Bytes::make(36, 100)
  let result = filter_emboss(src, 3, 3)
  assert_eq(result.length(), 36)
}

///|
test "edge_detection_sobel_test" {
  let src = Bytes::make(36, 100)
  let result = edge_detection_sobel(src, 3, 3)
  assert_eq(result.length(), 36)
}

// ----------------------------------------------------
// Dithering Tests
// ----------------------------------------------------

///|
test "dither_floyd_steinberg_test" {
  let src = Bytes::make(36, 120)
  let pal = [0xFF0000, 0x00FF00, 0x0000FF]
  let result = dither_floyd_steinberg(src, 3, 3, pal)
  assert_eq(result.length(), 36)
}

///|
test "dither_atkinson_test" {
  let src = Bytes::make(36, 120)
  let pal = [0xFF0000, 0x00FF00, 0x0000FF]
  let result = dither_atkinson(src, 3, 3, pal)
  assert_eq(result.length(), 36)
}

///|
test "dither_stucki_test" {
  let src = Bytes::make(36, 120)
  let pal = [0xFF0000, 0x00FF00, 0x0000FF]
  let result = dither_stucki(src, 3, 3, pal)
  assert_eq(result.length(), 36)
}

///|
test "dither_burkes_test" {
  let src = Bytes::make(36, 120)
  let pal = [0xFF0000, 0x00FF00, 0x0000FF]
  let result = dither_burkes(src, 3, 3, pal)
  assert_eq(result.length(), 36)
}

///|
test "dither_ordered_bayer_test" {
  let src = Bytes::make(36, 120)
  let pal = [0xFF0000, 0x00FF00, 0x0000FF]
  let result2 = dither_ordered_bayer(src, 3, 3, pal, 2)
  let result4 = dither_ordered_bayer(src, 3, 3, pal, 4)
  let result8 = dither_ordered_bayer(src, 3, 3, pal, 8)
  assert_eq(result2.length(), 36)
  assert_eq(result4.length(), 36)
  assert_eq(result8.length(), 36)
}

// ----------------------------------------------------
// Quantization Tests
// ----------------------------------------------------

///|
test "kmeans_quantize_test" {
  let colors = [0xFF0000, 0xFF0000, 0x00FF00, 0x00FF00, 0x0000FF]
  let pal = kmeans_quantize(colors, 2, 5)
  assert_true(pal.length() > 0)
}

///|
test "octree_quantize_test" {
  let colors = [0xFF0000, 0xFF0000, 0x00FF00, 0x00FF00, 0x0000FF]
  let pal = octree_quantize(colors, 2)
  assert_true(pal.length() > 0)
}

// ----------------------------------------------------
// Exporter Tests
// ----------------------------------------------------

///|
test "export_csv_test" {
  let grid = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF]
  let csv = export_csv(grid, 2, 2)
  assert_true(csv.length() > 0)
}

///|
test "export_svg_test" {
  let grid = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF]
  let svg = export_svg(grid, 2, 2, 10)
  assert_true(svg.length() > 0)
}

///|
test "export_html_report_test" {
  let grid = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF]
  let html = export_html_report(grid, 2, 2)
  assert_true(html.length() > 0)
}
