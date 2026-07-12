// This file provides the pixelate logic and the FFI boundaries.

///|
pub fn pixelate(
  rgba_buffer : Bytes,
  width : Int,
  height : Int,
  block_size : Int,
) -> Array[Int] {
  let mut bs = block_size
  if bs < 2 {
    bs = 2
  }
  let small_w = @math.maximum(1, width / bs)
  let small_h = @math.maximum(1, height / bs)

  // 1. Downscale to logical grid (nearest neighbor)
  let logical_grid = Array::make(small_w * small_h, 0)
  for y = 0; y < small_h; y = y + 1 {
    for x = 0; x < small_w; x = x + 1 {
      let src_x = x * bs
      let src_y = y * bs
      let idx = (src_y * width + src_x) * 4
      let r = rgba_buffer[idx].to_int()
      let g = rgba_buffer[idx + 1].to_int()
      let b = rgba_buffer[idx + 2].to_int()
      let a = rgba_buffer[idx + 3].to_int()
      logical_grid[y * small_w + x] = (a << 24) | (r << 16) | (g << 8) | b
    }
  }

  // 2. Quantize Logical Grid
  let all_colors = []
  for i = 0; i < logical_grid.length(); i = i + 1 {
    // Ignore alpha for quantization
    all_colors.push(logical_grid[i] & 0xFFFFFF)
  }

  let palette = build_palette(all_colors)

  for i = 0; i < logical_grid.length(); i = i + 1 {
    let old_rgb = logical_grid[i] & 0xFFFFFF
    let q = nearest_palette_color(old_rgb, palette)
    logical_grid[i] = (0xFF << 24) | q
  }

  logical_grid
}

// Map for counting frequencies

///|
struct IntMap {
  keys : Array[Int]
  values : Array[Int]
}

///|
fn add_to_map(map : IntMap, key : Int) -> Unit {
  for i = 0; i < map.keys.length(); i = i + 1 {
    if map.keys[i] == key {
      map.values[i] = map.values[i] + 1
      return
    }
  }
  map.keys.push(key)
  map.values.push(1)
}

///|
struct BeadStat {
  hex : String
  r : Int
  g : Int
  b : Int
  count : Int
}

///|
fn to_hex_string(rgb24 : Int) -> String {
  // A simple hack for hex string representation
  let hex_chars = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
  ]
  let mut res = "#"
  for shift = 20; shift >= 0; shift = shift - 4 {
    let nibble = (rgb24 >> shift) & 0xF
    res = res + hex_chars[nibble]
  }
  res
}

///|
pub fn count_beads(logical_grid : Array[Int]) -> Array[BeadStat] {
  let map = { keys: [], values: [] }
  for i = 0; i < logical_grid.length(); i = i + 1 {
    let rgb = logical_grid[i] & 0xFFFFFF
    add_to_map(map, rgb)
  }

  // Create stats
  let stats = []
  for i = 0; i < map.keys.length(); i = i + 1 {
    let rgb = map.keys[i]
    let count = map.values[i]
    let r = (rgb >> 16) & 0xFF
    let g = (rgb >> 8) & 0xFF
    let b = rgb & 0xFF
    stats.push({ hex: to_hex_string(rgb), r, g, b, count })
  }

  // Sort descending by count
  stats.sort_by(fn(a, b) { b.count - a.count })
  stats
}
