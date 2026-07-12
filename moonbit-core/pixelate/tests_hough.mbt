// Hough Transform Geometric Shape Detection Tests
// This file tests Hough lines and circles detection on geometric layouts.

///|
test "hough_lines_basic" {
  let w = 30
  let h = 30

  // Create a blank image with a single horizontal line at y=15
  let rgba_arr = Array::make(w * h * 4, (0).to_byte())
  for x = 0; x < w; x = x + 1 {
    let idx = (15 * w + x) * 4
    rgba_arr[idx] = (255).to_byte()
    rgba_arr[idx + 1] = (255).to_byte()
    rgba_arr[idx + 2] = (255).to_byte()
    rgba_arr[idx + 3] = (255).to_byte()
  }

  let rgba = make_bytes(w * h * 4, fn(i) { rgba_arr[i] })
  let lines = hough_lines(rgba, w, h, 100, 2)
  assert_true(lines.length() > 0)
}

///|
test "hough_lines_empty" {
  let w = 10
  let h = 10
  let rgba = Bytes::make(w * h * 4, (0).to_byte())
  let lines = hough_lines(rgba, w, h, 200, 5)
  assert_eq(lines.length(), 0)
}

///|
test "hough_circles_basic" {
  let w = 30
  let h = 30

  // Create a blank image with a single square/circle boundary around (15, 15) radius 8
  let rgba_arr = Array::make(w * h * 4, (0).to_byte())
  let cx = 15.0
  let cy = 15.0
  let r = 8.0

  let pi = 3.141592653589793
  for t = 0; t < 360; t = t + 5 {
    let rad = t.to_double() * pi / 180.0
    let px = (cx + r * @math.cos(rad)).to_int()
    let py = (cy + r * @math.sin(rad)).to_int()
    if px >= 0 && px < w && py >= 0 && py < h {
      let idx = (py * w + px) * 4
      rgba_arr[idx] = (255).to_byte()
      rgba_arr[idx + 1] = (255).to_byte()
      rgba_arr[idx + 2] = (255).to_byte()
      rgba_arr[idx + 3] = (255).to_byte()
    }
  }

  let rgba = make_bytes(w * h * 4, fn(i) { rgba_arr[i] })
  let circles = hough_circles(rgba, w, h, 100, 5, 10, 2)
  assert_true(circles.length() > 0)
}

///|
test "hough_circles_empty" {
  let w = 10
  let h = 10
  let rgba = Bytes::make(w * h * 4, (0).to_byte())
  let circles = hough_circles(rgba, w, h, 200, 3, 5, 2)
  assert_eq(circles.length(), 0)
}
