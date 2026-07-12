// Vectorization and Path Simplification Algorithms
// This module provides implementation of Marching Squares contour tracing
// and Ramer-Douglas-Peucker path simplification to trace boundaries in pixel art.

///|
pub struct Point {
  pub x : Double
  pub y : Double
}

///|
pub fn point_dist(p1 : Point, p2 : Point) -> Double {
  let dx = p1.x - p2.x
  let dy = p1.y - p2.y
  (dx * dx + dy * dy).sqrt()
}

///|
fn point_line_distance(p : Point, start : Point, end : Point) -> Double {
  let dx = end.x - start.x
  let dy = end.y - start.y
  let len_sq = dx * dx + dy * dy

  if len_sq == 0.0 {
    return point_dist(p, start)
  }

  let t = ((p.x - start.x) * dx + (p.y - start.y) * dy) / len_sq
  let t_clamped = if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }

  let projection = { x: start.x + t_clamped * dx, y: start.y + t_clamped * dy }
  point_dist(p, projection)
}

// Ramer-Douglas-Peucker Simplification

///|
pub fn ramer_douglas_peucker(
  points : Array[Point],
  epsilon : Double,
) -> Array[Point] {
  if points.length() < 3 {
    return points
  }

  let mut dmax = 0.0
  let mut index = 0
  let end = points.length() - 1

  for i = 1; i < end; i = i + 1 {
    let d = point_line_distance(points[i], points[0], points[end])
    if d > dmax {
      index = i
      dmax = d
    }
  }

  if dmax > epsilon {
    let left_subset = []
    for i = 0; i <= index; i = i + 1 {
      left_subset.push(points[i])
    }
    let left = ramer_douglas_peucker(left_subset, epsilon)

    let right_subset = []
    for i = index; i <= end; i = i + 1 {
      right_subset.push(points[i])
    }
    let right = ramer_douglas_peucker(right_subset, epsilon)

    let result = []
    for i = 0; i < left.length() - 1; i = i + 1 {
      result.push(left[i])
    }
    for i = 0; i < right.length(); i = i + 1 {
      result.push(right[i])
    }
    result
  } else {
    [points[0], points[end]]
  }
}

// Marching Squares contour generation helper

///|
pub struct Contour {
  pub points : Array[Point]
}

///|
pub fn trace_contour_marching_squares(
  grid : Array[Int],
  w : Int,
  h : Int,
  threshold_color : Int,
) -> Array[Contour] {
  let w_cells = w - 1
  let h_cells = h - 1

  let mask = Array::make(w * h, false)
  for i = 0; i < w * h; i = i + 1 {
    mask[i] = (grid[i] & 0xFFFFFF) == threshold_color
  }

  let contours = []

  // Tracing cell vertices values
  // Vertex indexing:
  // (x, y)     (x+1, y)
  //   v0---------v1
  //   |          |
  //   |          |
  //   v3---------v2
  // (x, y+1)   (x+1, y+1)

  for y = 0; y < h_cells; y = y + 1 {
    for x = 0; x < w_cells; x = x + 1 {
      let v0 = mask[y * w + x]
      let v1 = mask[y * w + (x + 1)]
      let v2 = mask[(y + 1) * w + (x + 1)]
      let v3 = mask[(y + 1) * w + x]

      let mut cell_value = 0
      if v0 {
        cell_value = cell_value | 8
      }
      if v1 {
        cell_value = cell_value | 4
      }
      if v2 {
        cell_value = cell_value | 2
      }
      if v3 {
        cell_value = cell_value | 1
      }

      if cell_value > 0 && cell_value < 15 {
        // Trace a simple segment for this cell
        let x_d = x.to_double()
        let y_d = y.to_double()

        let p_top = { x: x_d + 0.5, y: y_d }
        let p_right = { x: x_d + 1.0, y: y_d + 0.5 }
        let p_bottom = { x: x_d + 0.5, y: y_d + 1.0 }
        let p_left = { x: x_d, y: y_d + 0.5 }

        let pts = match cell_value {
          1 => [p_left, p_bottom]
          2 => [p_bottom, p_right]
          3 => [p_left, p_right]
          4 => [p_top, p_right]
          5 => [p_top, p_left, p_bottom, p_right] // Saddle point
          6 => [p_top, p_bottom]
          7 => [p_top, p_left]
          8 => [p_top, p_left]
          9 => [p_top, p_bottom]
          10 => [p_top, p_right, p_bottom, p_left] // Saddle point
          11 => [p_top, p_right]
          12 => [p_left, p_right]
          13 => [p_bottom, p_right]
          14 => [p_left, p_bottom]
          _ => []
        }

        if pts.length() >= 2 {
          contours.push({ points: pts })
        }
      }
    }
  }

  contours
}

///|
pub fn generate_svg_path(points : Array[Point]) -> String {
  if points.length() == 0 {
    return ""
  }
  let mut path = "M " + points[0].x.to_string() + " " + points[0].y.to_string()
  for i = 1; i < points.length(); i = i + 1 {
    path = path +
      " L " +
      points[i].x.to_string() +
      " " +
      points[i].y.to_string()
  }
  path = path + " Z"
  path
}
