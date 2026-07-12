// Hough Transform Geometric Shape Detection
// This module provides Hough Line and Hough Circle Transforms to detect geometric lines 
// and circular patterns (bead alignments) within pixelated layouts.

///|
pub struct HoughLine {
  pub r : Double
  pub theta : Double
  pub votes : Int
}

///|
pub struct HoughCircle {
  pub cx : Int
  pub cy : Int
  pub radius : Int
  pub votes : Int
}

// Hough Line Transform

///|
pub fn hough_lines(
  rgba : Bytes,
  w : Int,
  h : Int,
  threshold : Int,
  max_lines : Int,
) -> Array[HoughLine] {
  // 1. Run Sobel edge detection to find edge pixels
  let edges = edge_detection_sobel(rgba, w, h)

  let num_thetas = 180
  let pi = 3.141592653589793

  // Pre-calculate sin and cos tables
  let cos_table = Array::make(num_thetas, 0.0)
  let sin_table = Array::make(num_thetas, 0.0)
  for t = 0; t < num_thetas; t = t + 1 {
    let rad = t.to_double() * pi / 180.0
    cos_table[t] = @math.cos(rad)
    sin_table[t] = @math.sin(rad)
  }

  let max_r = (w * w + h * h).to_double().sqrt().to_int()
  let r_bins = 2 * max_r + 1
  let accumulator = Array::make(num_thetas * r_bins, 0)

  // 2. Accumulate votes
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = (y * w + x) * 4
      let edge_val = edges[idx].to_int()

      if edge_val >= threshold {
        for t = 0; t < num_thetas; t = t + 1 {
          let r_val = x.to_double() * cos_table[t] +
            y.to_double() * sin_table[t]
          let r_idx = r_val.to_int() + max_r
          if r_idx >= 0 && r_idx < r_bins {
            let acc_idx = t * r_bins + r_idx
            accumulator[acc_idx] = accumulator[acc_idx] + 1
          }
        }
      }
    }
  }

  // 3. Find local maxima peaks
  let lines = []
  for t = 0; t < num_thetas; t = t + 1 {
    for r = 0; r < r_bins; r = r + 1 {
      let val = accumulator[t * r_bins + r]
      if val > 0 {
        // Simple peak check against neighbors
        let mut is_peak = true
        for dt = -2; dt <= 2; dt = dt + 1 {
          for dr = -2; dr <= 2; dr = dr + 1 {
            let nt = (t + dt + num_thetas) % num_thetas
            let nr = r + dr
            if nr >= 0 && nr < r_bins {
              if accumulator[nt * r_bins + nr] > val {
                is_peak = false
                break
              }
            }
          }
          if !is_peak {
            break
          }
        }

        if is_peak {
          lines.push({
            r: (r - max_r).to_double(),
            theta: t.to_double() * pi / 180.0,
            votes: val,
          })
        }
      }
    }
  }

  // Sort descending by votes
  lines.sort_by(fn(l1, l2) { l2.votes - l1.votes })

  let res_lines = []
  let limit = if max_lines < lines.length() {
    max_lines
  } else {
    lines.length()
  }
  for i = 0; i < limit; i = i + 1 {
    res_lines.push(lines[i])
  }
  res_lines
}

// Hough Circle Transform

///|
pub fn hough_circles(
  rgba : Bytes,
  w : Int,
  h : Int,
  threshold : Int,
  min_rad : Int,
  max_rad : Int,
  max_circles : Int,
) -> Array[HoughCircle] {
  let edges = edge_detection_sobel(rgba, w, h)
  let rad_range = max_rad - min_rad + 1
  let accumulator = Array::make(w * h * rad_range, 0)

  // Accumulate
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = (y * w + x) * 4
      if edges[idx].to_int() >= threshold {
        for rad = min_rad; rad <= max_rad; rad = rad + 1 {
          let r_idx = rad - min_rad

          // Vote for all circles passing through (x, y) with radius rad
          let pi = 3.141592653589793
          for t = 0; t < 360; t = t + 5 {
            let rad_angle = t.to_double() * pi / 180.0
            let cx = (x.to_double() - rad.to_double() * @math.cos(rad_angle)).to_int()
            let cy = (y.to_double() - rad.to_double() * @math.sin(rad_angle)).to_int()

            if cx >= 0 && cx < w && cy >= 0 && cy < h {
              let acc_idx = (cy * w + cx) * rad_range + r_idx
              accumulator[acc_idx] = accumulator[acc_idx] + 1
            }
          }
        }
      }
    }
  }

  // Find local peaks
  let circles = []
  for cy = 0; cy < h; cy = cy + 1 {
    for cx = 0; cx < w; cx = cx + 1 {
      for rad = min_rad; rad <= max_rad; rad = rad + 1 {
        let r_idx = rad - min_rad
        let val = accumulator[(cy * w + cx) * rad_range + r_idx]
        if val > 10 {
          let mut is_peak = true
          for dy = -2; dy <= 2; dy = dy + 1 {
            for dx = -2; dx <= 2; dx = dx + 1 {
              for dr = -1; dr <= 1; dr = dr + 1 {
                let ncy = cy + dy
                let ncx = cx + dx
                let nrad = r_idx + dr
                if ncx >= 0 &&
                  ncx < w &&
                  ncy >= 0 &&
                  ncy < h &&
                  nrad >= 0 &&
                  nrad < rad_range {
                  if accumulator[(ncy * w + ncx) * rad_range + nrad] > val {
                    is_peak = false
                    break
                  }
                }
              }
              if !is_peak {
                break
              }
            }
            if !is_peak {
              break
            }
          }

          if is_peak {
            circles.push({ cx, cy, radius: rad, votes: val })
          }
        }
      }
    }
  }

  circles.sort_by(fn(c1, c2) { c2.votes - c1.votes })

  let res_circles = []
  let limit = if max_circles < circles.length() {
    max_circles
  } else {
    circles.length()
  }
  for i = 0; i < limit; i = i + 1 {
    res_circles.push(circles[i])
  }
  res_circles
}
