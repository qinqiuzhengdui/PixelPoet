let target_colors = 128

struct ColorBox {
  colors: Array[Int]
}

fn bounding_volume(self: ColorBox) -> Int64 {
  let mut r_min = 256
  let mut r_max = -1
  let mut g_min = 256
  let mut g_max = -1
  let mut b_min = 256
  let mut b_max = -1
  for i = 0; i < self.colors.length(); i = i + 1 {
    let c = self.colors[i]
    let r = (c >> 16) & 0xFF
    let g = (c >> 8) & 0xFF
    let b = c & 0xFF
    if r < r_min { r_min = r }
    if r > r_max { r_max = r }
    if g < g_min { g_min = g }
    if g > g_max { g_max = g }
    if b < b_min { b_min = b }
    if b > b_max { b_max = b }
  }
  let dr = (r_max - r_min + 1).to_int64()
  let dg = (g_max - g_min + 1).to_int64()
  let db = (b_max - b_min + 1).to_int64()
  dr * dg * db
}

fn split_by_median(self: ColorBox) -> Array[ColorBox] {
  let mut r_min = 256
  let mut r_max = -1
  let mut g_min = 256
  let mut g_max = -1
  let mut b_min = 256
  let mut b_max = -1
  for i = 0; i < self.colors.length(); i = i + 1 {
    let c = self.colors[i]
    let r = (c >> 16) & 0xFF
    let g = (c >> 8) & 0xFF
    let b = c & 0xFF
    if r < r_min { r_min = r }
    if r > r_max { r_max = r }
    if g < g_min { g_min = g }
    if g > g_max { g_max = g }
    if b < b_min { b_min = b }
    if b > b_max { b_max = b }
  }
  let dr = r_max - r_min
  let dg = g_max - g_min
  let db = b_max - b_min
  
  if dr == 0 && dg == 0 && db == 0 {
    return []
  }
  
  let mut axis = 0
  if dr >= dg && dr >= db {
    axis = 0
  } else if dg >= db {
    axis = 1
  } else {
    axis = 2
  }
  
  // Sort the colors based on the chosen axis
  self.colors.sort_by(fn(c1, c2) {
    let v1 = if axis == 0 { (c1 >> 16) & 0xFF } else if axis == 1 { (c1 >> 8) & 0xFF } else { c1 & 0xFF }
    let v2 = if axis == 0 { (c2 >> 16) & 0xFF } else if axis == 1 { (c2 >> 8) & 0xFF } else { c2 & 0xFF }
    v1 - v2
  })
  
  let mid = self.colors.length() / 2
  if mid < 1 || mid >= self.colors.length() {
    return []
  }
  
  let left = []
  let right = []
  for i = 0; i < mid; i = i + 1 {
    left.push(self.colors[i])
  }
  for i = mid; i < self.colors.length(); i = i + 1 {
    right.push(self.colors[i])
  }
  
  [{ colors: left }, { colors: right }]
}

fn average_rgb(self: ColorBox) -> Int {
  let mut r : Int64 = 0
  let mut g : Int64 = 0
  let mut b : Int64 = 0
  for i = 0; i < self.colors.length(); i = i + 1 {
    let c = self.colors[i]
    r = r + ((c >> 16) & 0xFF).to_int64()
    g = g + ((c >> 8) & 0xFF).to_int64()
    b = b + (c & 0xFF).to_int64()
  }
  let n = self.colors.length().to_int64()
  let ri = (r / n).to_int()
  let gi = (g / n).to_int()
  let bi = (b / n).to_int()
  (ri << 16) | (gi << 8) | bi
}

fn pick_widest_box(boxes: Array[ColorBox]) -> Int {
  let mut best_idx = -1
  let mut best_vol : Int64 = -1
  for i = 0; i < boxes.length(); i = i + 1 {
    if boxes[i].colors.length() < 2 {
      continue
    }
    let vol = boxes[i].bounding_volume()
    if vol > best_vol {
      best_vol = vol
      best_idx = i
    }
  }
  best_idx
}

pub fn build_palette(pixelsRgb24: Array[Int]) -> Array[Int] {
  if pixelsRgb24.length() == 0 {
    return [0]
  }
  
  let initial_colors = []
  for i = 0; i < pixelsRgb24.length(); i = i + 1 {
    initial_colors.push(pixelsRgb24[i])
  }
  let boxes = [{ colors: initial_colors }]
  
  while boxes.length() < target_colors {
    let to_split_idx = pick_widest_box(boxes)
    if to_split_idx == -1 {
      break
    }
    let to_split = boxes[to_split_idx]
    let pair = to_split.split_by_median()
    if pair.length() == 0 {
      break
    }
    // Remove to_split_idx
    let _ = boxes.remove(to_split_idx)
    boxes.push(pair[0])
    boxes.push(pair[1])
  }
  
  let palette = []
  for i = 0; i < boxes.length(); i = i + 1 {
    palette.push(boxes[i].average_rgb())
  }
  palette
}

fn rgb_distance_sq(a: Int, b: Int) -> Int {
  let ar = (a >> 16) & 0xFF
  let ag = (a >> 8) & 0xFF
  let ab = a & 0xFF
  let br = (b >> 16) & 0xFF
  let bg = (b >> 8) & 0xFF
  let bb = b & 0xFF
  let dr = ar - br
  let dg = ag - bg
  let db = ab - bb
  dr * dr + dg * dg + db * db
}

pub fn nearest_palette_color(rgb24: Int, palette: Array[Int]) -> Int {
  if palette.length() == 0 { return rgb24 }
  let mut best = palette[0]
  let mut best_d = 2147483647
  for i = 0; i < palette.length(); i = i + 1 {
    let p = palette[i]
    let d = rgb_distance_sq(rgb24, p)
    if d < best_d {
      best_d = d
      best = p
    }
  }
  best
}
