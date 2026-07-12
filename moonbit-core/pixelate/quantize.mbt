// Color Quantization Algorithms
// This module provides advanced color clustering algorithms to generate optimal palettes:
// - K-Means Clustering Quantization
// - Octree Quantization

// ----------------------------------------------------
// K-Means Clustering Quantization
// ----------------------------------------------------

///|
struct KCentroid {
  mut cr : Double
  mut cg : Double
  mut cb : Double
}

///|
pub fn kmeans_quantize(
  colors : Array[Int],
  k : Int,
  max_iters : Int,
) -> Array[Int] {
  if colors.length() == 0 {
    return []
  }
  let actual_k = if k > colors.length() { colors.length() } else { k }

  // Initialize centroids by choosing colors at regular intervals
  let centroids = []
  let step = colors.length() / actual_k
  for i = 0; i < actual_k; i = i + 1 {
    let c = colors[i * step]
    centroids.push({
      cr: ((c >> 16) & 0xFF).to_double(),
      cg: ((c >> 8) & 0xFF).to_double(),
      cb: (c & 0xFF).to_double(),
    })
  }

  let cluster_assignments = Array::make(colors.length(), 0)

  for iter = 0; iter < max_iters; iter = iter + 1 {
    // 1. Assign colors to closest centroids
    let mut changed = false
    for i = 0; i < colors.length(); i = i + 1 {
      let c = colors[i]
      let cr = ((c >> 16) & 0xFF).to_double()
      let cg = ((c >> 8) & 0xFF).to_double()
      let cb = (c & 0xFF).to_double()

      let mut min_dist = 1000000000.0
      let mut best_cluster = 0
      for j = 0; j < actual_k; j = j + 1 {
        let cent = centroids[j]
        let dist = (cr - cent.cr) * (cr - cent.cr) +
          (cg - cent.cg) * (cg - cent.cg) +
          (cb - cent.cb) * (cb - cent.cb)
        if dist < min_dist {
          min_dist = dist
          best_cluster = j
        }
      }
      if cluster_assignments[i] != best_cluster {
        cluster_assignments[i] = best_cluster
        changed = true
      }
    }

    if !changed {
      break
    }

    // 2. Re-calculate centroids
    let r_sums = Array::make(actual_k, 0.0)
    let g_sums = Array::make(actual_k, 0.0)
    let b_sums = Array::make(actual_k, 0.0)
    let counts = Array::make(actual_k, 0)

    for i = 0; i < colors.length(); i = i + 1 {
      let assign = cluster_assignments[i]
      let c = colors[i]
      r_sums[assign] = r_sums[assign] + ((c >> 16) & 0xFF).to_double()
      g_sums[assign] = g_sums[assign] + ((c >> 8) & 0xFF).to_double()
      b_sums[assign] = b_sums[assign] + (c & 0xFF).to_double()
      counts[assign] = counts[assign] + 1
    }

    for j = 0; j < actual_k; j = j + 1 {
      if counts[j] > 0 {
        let c_d = counts[j].to_double()
        centroids[j].cr = r_sums[j] / c_d
        centroids[j].cg = g_sums[j] / c_d
        centroids[j].cb = b_sums[j] / c_d
      }
    }
  }

  // Extract palette
  let res_palette = []
  for j = 0; j < actual_k; j = j + 1 {
    let r = centroids[j].cr.to_int()
    let g = centroids[j].cg.to_int()
    let b = centroids[j].cb.to_int()
    let r_clamped = if r < 0 { 0 } else if r > 255 { 255 } else { r }
    let g_clamped = if g < 0 { 0 } else if g > 255 { 255 } else { g }
    let b_clamped = if b < 0 { 0 } else if b > 255 { 255 } else { b }
    res_palette.push((r_clamped << 16) | (g_clamped << 8) | b_clamped)
  }
  res_palette
}

// ----------------------------------------------------
// Octree Quantization
// ----------------------------------------------------

///|
struct OctreeNode {
  mut is_leaf : Bool
  mut pixel_count : Int
  mut red_sum : Int64
  mut green_sum : Int64
  mut blue_sum : Int64
  children : Array[OctreeNode?] // Up to 8 children
}

///|
fn make_octree_node() -> OctreeNode {
  {
    is_leaf: false,
    pixel_count: 0,
    red_sum: 0,
    green_sum: 0,
    blue_sum: 0,
    children: Array::make(8, None),
  }
}

///|
struct OctreeTracker {
  mut leaf_count : Int
  // Track nodes at each level to facilitate reduction
  levels : Array[Array[OctreeNode]]
}

///|
fn add_color_to_node(
  node : OctreeNode,
  r : Int,
  g : Int,
  b : Int,
  level : Int,
  tracker : OctreeTracker,
) -> Unit {
  if level == 8 {
    node.is_leaf = true
    node.pixel_count = node.pixel_count + 1
    node.red_sum = node.red_sum + r.to_int64()
    node.green_sum = node.green_sum + g.to_int64()
    node.blue_sum = node.blue_sum + b.to_int64()
    return
  }

  // Calculate index: bits from MSB to LSB
  let shift = 7 - level
  let idx = (((r >> shift) & 1) << 2) |
    (((g >> shift) & 1) << 1) |
    ((b >> shift) & 1)

  match node.children[idx] {
    None => {
      let child = make_octree_node()
      node.children[idx] = Some(child)
      tracker.levels[level].push(child)
      add_color_to_node(child, r, g, b, level + 1, tracker)
    }
    Some(child) => add_color_to_node(child, r, g, b, level + 1, tracker)
  }
}

///|
fn reduce_node(node : OctreeNode) -> Int {
  let mut children_count = 0
  let mut sum_r : Int64 = 0
  let mut sum_g : Int64 = 0
  let mut sum_b : Int64 = 0
  let mut count = 0

  for i = 0; i < 8; i = i + 1 {
    match node.children[i] {
      Some(child) => {
        children_count = children_count + 1
        sum_r = sum_r + child.red_sum
        sum_g = sum_g + child.green_sum
        sum_b = sum_b + child.blue_sum
        count = count + child.pixel_count
        node.children[i] = None
      }
      None => ()
    }
  }

  node.is_leaf = true
  node.pixel_count = count
  node.red_sum = sum_r
  node.green_sum = sum_g
  node.blue_sum = sum_b

  children_count - 1
}

///|
fn collect_colors_from_tree(node : OctreeNode, palette : Array[Int]) -> Unit {
  if node.is_leaf {
    if node.pixel_count > 0 {
      let c_d = node.pixel_count.to_int64()
      let r = (node.red_sum / c_d).to_int()
      let g = (node.green_sum / c_d).to_int()
      let b = (node.blue_sum / c_d).to_int()
      palette.push((r << 16) | (g << 8) | b)
    }
    return
  }

  for i = 0; i < 8; i = i + 1 {
    match node.children[i] {
      Some(child) => collect_colors_from_tree(child, palette)
      None => ()
    }
  }
}

///|
pub fn octree_quantize(colors : Array[Int], k : Int) -> Array[Int] {
  if colors.length() == 0 {
    return []
  }

  let root = make_octree_node()
  let levels = []
  for i = 0; i < 8; i = i + 1 {
    levels.push([])
  }
  let tracker = { leaf_count: 0, levels }

  // Insert all colors into octree
  for i = 0; i < colors.length(); i = i + 1 {
    let c = colors[i]
    let r = (c >> 16) & 0xFF
    let g = (c >> 8) & 0xFF
    let b = c & 0xFF
    add_color_to_node(root, r, g, b, 0, tracker)
  }

  // Count leaves
  fn count_leaves(node : OctreeNode) -> Int {
    if node.is_leaf {
      return 1
    }
    let mut sum = 0
    for i = 0; i < 8; i = i + 1 {
      match node.children[i] {
        Some(child) => sum = sum + count_leaves(child)
        None => ()
      }
    }
    sum
  }

  tracker.leaf_count = count_leaves(root)

  // Reduce leaves until <= k
  for level = 7; level >= 0; level = level - 1 {
    let lvl_nodes = tracker.levels[level]
    for i = 0; i < lvl_nodes.length(); i = i + 1 {
      if tracker.leaf_count <= k {
        break
      }
      let node = lvl_nodes[i]
      if !node.is_leaf {
        let reduction = reduce_node(node)
        tracker.leaf_count = tracker.leaf_count - reduction
      }
    }
    if tracker.leaf_count <= k {
      break
    }
  }

  let palette = []
  collect_colors_from_tree(root, palette)
  palette
}
